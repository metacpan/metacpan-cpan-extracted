package CPAN::Patches::Plugin::Debian;

use warnings;
use strict;

our $VERSION = '0.03';

use Moose::Role;

use Carp 'croak';
use IO::Any;
use Scalar::Util 'blessed';
use File::Path 'make_path';
use Storable 'dclone';
use Test::Deep::NoTest 'eq_deeply';
use File::Copy 'copy';
use Parse::Deb::Control '0.03';
use File::chdir;
use Debian::Dpkg::Version 'version_compare';
use CPAN::Patches 0.04;
use File::Basename 'basename';

sub update_debian {
    my $self = shift;
    my $path = shift || '.';
    
    $self = $self->new()
        if not blessed $self;
    
    my $debian_path             = File::Spec->catdir($path, 'debian');
    my $debian_patches_path     = File::Spec->catdir($debian_path, 'patches');
    my $debian_control_filename = File::Spec->catdir($debian_path, 'control');
    croak 'debian/ folder not found'
        if not -d $debian_path;

    my $meta     = $self->read_meta($path);
    my $name     = $self->clean_meta_name($meta->{'name'}) or croak 'no name in meta';
    my $debian_data = $self->read_debian_control($name);
    my $deb_control = Parse::Deb::Control->new([$debian_control_filename]);
    
    die $name.' has disabled auto build'
        if $debian_data->{'No-Auto'};
    
    my @series = $self->get_patch_series($name);
    if (@series) {
		# apply patches to the source (quilt 3.0 source format)
		$self->patch($path);
		
        make_path($debian_patches_path)
            if not -d $debian_patches_path;
            
        foreach my $patch_filename (@series) {
            print 'copy ', $patch_filename,' to ', $debian_patches_path, "\n"
                if $self->verbose;
            copy($patch_filename, $debian_patches_path) or die $!;
        }
        IO::Any->spew(
			[$debian_patches_path, 'series'],
			join(
				"\n",
				map { basename($_) } @series
			)."\n"
		);
    }

    # write new debian/rules
    IO::Any->spew(
        [$debian_path, 'rules'],
        "#!/usr/bin/make -f\n\n"
        .($debian_data->{'X'} ? "override_dh_auto_test:\n	xvfb-run -a dh_auto_test\n\n" : '')
		."%:\n	"
        .'dh $@'
        ."\n"
    );
	
	# if there are patches set the format to quilt 3.0
	if (@series) {
		my $debian_source_folder = File::Spec->catdir($debian_path, 'source');
		mkdir($debian_source_folder)
			if (not -d $debian_source_folder);
		
		IO::Any->spew(
			[$debian_path, 'source', 'format'],
			"3.0 (quilt)\n",
		);
	}
    
    # update dependencies
    my $cpanp = CPAN::Patches->new;
    foreach my $dep_type ('Depends', 'Build-Depends', 'Build-Depends-Indep') {
        my $dep = {$cpanp->get_deb_package_names($deb_control, $dep_type)};
        my $new_dep = $cpanp->merge_debian_versions($dep, $debian_data->{$dep_type} || {});
        
        if ($debian_data->{'X'} and ($dep_type eq 'Build-Depends-Indep')) {
            $new_dep->{'xauth'} = '';
            $new_dep->{'xvfb'}  = '';
        }
        if (@series and ($dep_type eq 'Build-Depends-Indep')) {
            $new_dep->{'debhelper'} = '(>= 7.0.50~)';
        }
        
        # update if dependencies if needed
        if (not eq_deeply($dep, $new_dep)) {
            my ($control_key) = $deb_control->get_keys($dep_type =~ m/Build/ ? 'Source' : 'Package');
            next if not $control_key;
            
            my $new_value =
                ' '.(
                    join ', ',
                    map { $_.($new_dep->{$_} ? ' '.$new_dep->{$_} : '') }
                    sort
                    keys %{$new_dep}
                )."\n"
            ;
            $control_key->{'para'}->{$dep_type} = $new_value;
        }
    }
    IO::Any->spew([$debian_control_filename], $deb_control->control);
    
    if (my $app_name = $debian_data->{'App'}) {
        local $CWD = $debian_path;
        my $lib_name = '(?:lib)?'.$name.'-perl';    # "(?:lib)?" becasue libwww-perl has no "double lib" prefix
        system(q{perl -lane 's/}.$lib_name.q{/}.$app_name.q{/;print' -i *});
        foreach my $filename (glob($lib_name.'*')) {
            rename($filename, $app_name.substr($filename, 0-length($lib_name)));
        }
    }
    
	# copy all post/pre inst
	foreach my $inst ($self->debian_inst_script_names) {
		my $src = File::Spec->catfile($self->get_module_folder($name), 'debian', $inst);
		my $dst = File::Spec->catfile($debian_path, $inst);
		
		if (-r $src) {
			print 'copy ', $src,' to ', $dst, "\n"
				if $self->verbose;
			copy($src, $dst) or die $!;
		}
	}
    
    return;
}

sub cmd_update_debian {
	shift->update_debian();
}

sub merge_debian_versions {
    my $self = shift;
	my $versions1_orig = shift or die;
	my $versions2      = shift or die;
    
	my $versions1 = dclone $versions1_orig;
	
	while (my ($p, $v2) = each %{$versions2}) {
		if (exists $versions1->{$p}) {
			next if not $v2;
			my $v1 = $versions1->{$p} || '(>= 0)';
			if ($v1 !~ m/\(\s* >= \s* ([^\)]+?) \s*\)/xms) {
				warn 'invalid version '.$v1.' in conflic resolution';
				die;
				next;
			}
			my $v1n = $1;
			if ($v2 !~ m/\(\s* >= \s* ([^\)]+?) \s*\)/xms) {
				warn 'invalid version '.$v2.' in conflic resolution';
				die;
				next;
			}
			my $v2n = $1;

			# only when newer version is needed
			$versions1->{$p} = $v2
				if version_compare($v2n, $v1n) == 1;
		}
		else {
			$versions1->{$p} = $v2;
		}
	}
	
	return $versions1;    
}

sub get_deb_package_names {
    my $self    = shift;
    my $control = shift or croak 'pass control object';
    my $key     = shift or croak 'pass key name';
	
	return
		map {
			my ($p, $v) = split('\s+', $_, 2);
			$v ||= '';
			($p => $v)
		}
		grep { $_ }
		map { s/^\s*//;$_; }
		map { s/\s*$//;$_; }
		map { split(',', $_) }
		map { ${$_->{'value'}} }
		$control->get_keys($key)
	;
}

sub read_debian_control {
    my $self = shift;
    my $name = shift or croak 'pass name param';
    
    my $debian_filename  = File::Spec->catfile($self->get_module_folder($name), 'debian', 'control');
    return {}
        if not -r $debian_filename;
    
    return $self->decode_debian_control([$debian_filename]);
}

sub decode_debian_control {
    my $self = shift;
    my $src  = shift or die 'pass source';
    
    my $cpanp = CPAN::Patches->new;
    my $deb_control = Parse::Deb::Control->new($src);
    my %depends             = $cpanp->get_deb_package_names($deb_control, 'Depends');
    my %build_depends       = $cpanp->get_deb_package_names($deb_control, 'Build-Depends');
    my %build_depends_indep = $cpanp->get_deb_package_names($deb_control, 'Build-Depends-Indep');
    my ($app) = 
        map { s/^\s*//;$_; }
		map { s/\s*$//;$_; }
		map { ${$_->{'value'}} }
		$deb_control->get_keys('App')
    ;
    my ($x_for_testing) = 
        map { s/^\s*//;$_; }
		map { s/\s*$//;$_; }
		map { ${$_->{'value'}} }
		$deb_control->get_keys('X')
    ;
    my ($no_auto) = 
        map { s/^\s*//;$_; }
		map { s/\s*$//;$_; }
		map { ${$_->{'value'}} }
		$deb_control->get_keys('No-Auto')
    ;

    
    return {
        'Depends'             => \%depends,
        'Build-Depends'       => \%build_depends,
        'Build-Depends-Indep' => \%build_depends_indep,
        (defined $app ? ('App' => $app) : ()),
        (defined $x_for_testing ? ('X' => $x_for_testing) : ()),
        (defined $no_auto ? ('No-Auto' => $no_auto) : ()),
    };
}

sub encode_debian {
    my $self = shift;
    my $data = shift;
    
    my $content = '';
    $content .= 'App: '.$data->{'App'}."\n"
        if exists $data->{'App'};
    
    foreach my $dep_type ('Build-Depends', 'Build-Depends-Indep', 'Depends') {
        next if (not $data->{$dep_type}) or (not keys %{$data->{$dep_type}});
        
        my $new_value = (
            join ', ',
            map { $_.($data->{$dep_type}->{$_} ? ' '.$data->{$dep_type}->{$_} : '') }
            sort
            keys %{$data->{$dep_type}}
        );
        $content .= $dep_type.': '.$new_value."\n";
    }

    $content .= 'No-Auto: '.$data->{'No-Auto'}."\n"
        if exists $data->{'No-Auto'};
    $content .= 'X: '.$data->{'X'}."\n"
        if exists $data->{'X'};
    
    return $content;
}

sub debian_inst_script_names {
	return qw{
		preinst
		postinst
		prerm
		postrm
	};
}

1;


__END__

=head1 NAME

CPAN::Patches::Plugin::Debian - patch CPAN distributions Debian package

=head1 SYNOPSIS

    cd Some-Distribution
    dh-make-perl
    cpan-patches list
    cpan-patches update-debian
    cpan-patches --patch-set $HOME/cpan-patches-set list
    cpan-patches --patch-set $HOME/cpan-patches-set update-debian

=head1 DESCRIPTION

This module allows to apply custom patches to the CPAN distributions
Debian package.

See L<http://github.com/jozef/CPAN-Patches-Debian-Set> for example generated
Debian patches set folder.

=head1 METHODS

=head2 update_debian

Copy all patches and F<series> file from F<.../module-name/patches/> to
F<debian/patches> folder. If there are any patches add C<quilt> as
C<Build-Depends-Indep> and runs adds C<--with quilt> to F<debian/rules>.
Adds dependencies from F<.../module-name/debian>, adds usage of C<xvfb-run>
if the modules requires X and renames C<s/lib(.*)-perl/$1/> if the distribution
is an application.

=head1 cpan-patches command

=head2 cmd_update_debian

See L</update_debian>.

=head1 INTERNAL METHODS

=head2 merge_debian_versions($v1, $v2)

Merges dependencies from C<$v1> and C<$v2> by keeping the ones that has
higher version (if the same).

=head2 get_deb_package_names($control, $key)

Return hash with package name as key and version string as value for
given C<$key> in Debian C<$control> file.

=head2 read_debian_control($name)

Read F<.../module-name/debian> for given C<$name>.

=head2 decode_debian_control($src)

Parses F<.../module-name/debian> into a hash. Returns hash reference.

=head2 encode_debian($data)

Return F<.../module-name/debian> content string generated from C<$data>.

=head2 debian_inst_script_names

Returns array of pre/post installation file names.

=head1 AUTHOR

jozef@kutej.net, C<< <jkutej at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cpan-patches at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-Patches>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CPAN::Patches


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CPAN-Patches>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CPAN-Patches>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CPAN-Patches>

=item * Search CPAN

L<http://search.cpan.org/dist/CPAN-Patches/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of CPAN::Patches
