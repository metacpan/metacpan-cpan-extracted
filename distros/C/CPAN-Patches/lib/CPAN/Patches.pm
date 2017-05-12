package CPAN::Patches;

use warnings;
use strict;

our $VERSION = '0.05';

use Moose;
use CPAN::Patches::SPc;
use Carp;
use IO::Any;
use JSON::Util;
use YAML::Syck;
use File::chdir;
use Scalar::Util 'blessed';
use Module::Pluggable require => 1;

has 'patch_set_locations' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [ File::Spec->catdir(CPAN::Patches::SPc->sharedstatedir, 'cpan-patches', 'set') ] }
);
has 'verbose' => ( is => 'rw', isa => 'Int', default => 1 );

sub BUILD {
	my $self = shift;
	
	my $pkg = __PACKAGE__;
	foreach my $plugin ($self->plugins) {
		# ignore nested package names, only one level
		next if $plugin =~ m/^ $pkg :: Plugin :: [^:]+ ::/xms;
		$plugin->meta->apply($self);
	}
};

sub patch {
    my $self = shift;
    my $path = shift || '.';
    
    $self = $self->new()
        if not blessed $self;
    
    local $CWD = $path;
	my $name = $self->clean_meta_name();
 
    foreach my $patch_filename ($self->get_patch_series) {
        print 'patching ', $name,' with ', $patch_filename, "\n"
            if $self->verbose;
        system('cat '.$patch_filename.' | patch --quiet --force -p1') and die 'failed';
    }
    
    return;
}

sub cmd_list {
    my $self = shift;
	foreach my $patch_filename ($self->get_patch_series) {
		print $patch_filename, "\n";
	}
}

sub cmd_patch {
	shift->patch();
}

sub get_patch_series {
    my $self = shift;
    my $name = shift || $self->clean_meta_name;
    
    my $patches_folder  = File::Spec->catdir($self->get_module_folder($name), 'patches');
    my $series_filename = File::Spec->catfile($patches_folder, 'series');

    return if not -r $series_filename;
    
    return
        map  { File::Spec->catfile($patches_folder, $_) }
        map  { s/^\s*//;$_; }
        map  { s/\s*$//;$_; }
        map  { split "\n" }
        eval { IO::Any->slurp([$series_filename]) };
}

sub get_module_folder {
    my $self = shift;
    my $name = shift || $self->clean_meta_name;
	
	foreach my $patch_set_location (@{$self->patch_set_locations}) {
    	my $folder  = File::Spec->catdir($patch_set_location, $name);
		return $folder
			if -d $folder;
	}
	
	return;
}

sub clean_meta_name {
    my $self = shift;
    my $name = shift || $self->read_meta->{'name'};
    
    $name =~ s/::/-/xmsg;
    $name =~ s/\s*$//;
    $name =~ s/^\s*//;
    $name = lc $name;

    return $name;    
}

sub read_meta {
    my $self = shift;
    my $path = shift || '.';
    
    my $yml  = File::Spec->catfile($path, 'META.yml');
    my $json = File::Spec->catfile($path, 'META.json');
    if (-f $json) {
        my $meta = eval { JSON::Util->decode([$json]) };
        return $meta
            if $meta;
    }
    if (-f $yml) {
        my $meta = eval { YAML::Syck::LoadFile($yml) };
        return $meta
            if $meta;
    }
    croak 'failed to read META.(yml|json)';
}

sub read_meta_intrusive {
    my $self = shift;
    my $path = shift || '.';

    my $buildpl    = File::Spec->catfile($path, 'Build.PL');
    my $makefilepl = File::Spec->catfile($path, 'Makefile.PL');
	if (-f $buildpl or -f $makefilepl) {
		warn 'going to generate META.yml';
		
		my $meta;
		my $distmeta  = 'perl Makefile.PL && make distmeta && cp */META.yml ./';
		my $distclean = 'make distclean';
		if (-f $buildpl) {
			$distmeta  = 'perl Build.PL && ./Build distmeta';
			$distclean = './Build distclean';
		}
		
		do {
			local $CWD = $path;
			system($distmeta);
			$meta = eval { $self->read_meta };
			system($distclean);
		};
		
		return $meta
			if $meta;
	}
	
    croak 'failed to read META.(yml|json)';
}

__PACKAGE__->meta->make_immutable;

1;


__END__

=encoding utf8

=head1 NAME

CPAN::Patches - patch CPAN distributions

=head1 SYNOPSIS

    cd Some-Distribution
    cpan-patches list
    cpan-patches patch
    cpan-patches --patch-set $HOME/cpan-patches-set list
    cpan-patches --patch-set $HOME/cpan-patches-set patch

=head1 DESCRIPTION

This module allows to apply custom patches to the CPAN distributions.

See L</patch> and L</update_debian> for a detail description how.

See L<http://github.com/jozef/CPAN-Patches-Example-Set> for example generated
Debian patches set folder.

=head1 PROPERTIES

=head2 patch_set_locations

An array ref of folders where are the distribution patches located. Default is
F<< Sys::Path->sharedstatedir/cpan-patches/set >> which is
F</var/lib/cpan-patches/set> on Linux.

=head2 verbose

Turns on/off some verbose output. By default it is on.

=head1 METHODS

=head2 new()

Object constructor.

=head2 BUILD

All plugins (Moose roles) from C<CPAN::Patches::Plugin::*> will be loaded.

=head2 patch

Apply all patches that are listed in F<.../module-name/patches/series>.

=head1 cpan-patch commands

=head2 cmd_list

Print out list of all patches files.

=head2 cmd_patch

Apply all patches to the current CPAN distribution.

=head1 INTERNAL METHODS

=head2 get_patch_series($module_name)

Return an array of patches filenames for given C<$module_name>.

=head2 get_module_folder($module_name)

Returns a folder that exists in one of the C<patch_set_locations> for a
given C<$module_name>.

=head2 clean_meta_name($name)

Returns lowercased :: by - substituted and trimmed module name.

=head2 read_meta([$path])

Reads a F<META.yml> or F<META.json> from C<$path>. If C<$path> is not provided
than tries to read from current folder.

=head2 read_meta_intrusive

Generates and reads the F<META.yml> using F<Build.PL> or F<Makefile.PL>.

=head1 CONTRIBUTORS

The following people have contributed to the CPAN::Patches by committing their
code, sending patches, reporting bugs, asking questions, suggesting useful
advises, nitpicking, chatting on IRC or commenting on my blog (in no particular
order):

	Slaven Rezić

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
