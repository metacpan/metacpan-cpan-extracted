package DarkPAN::Compare;
use Moo;

use ExtUtils::Installed;
use ExtUtils::MakeMaker;
use HTTP::Tiny;
use Parse::CPAN::Packages;
use Module::Extract::Namespaces;

our $VERSION = "0.03";

has darkpan_url                   => (is => 'ro', required => 1);
has missing_modules               => (is => 'rw', default => sub { [] });
has extra_modules                 => (is => 'rw', default => sub { [] });
has modules_with_version_mismatch => (is => 'rw', default => sub { [] });
has tmp_file                      => (is => 'rw', builder => 1);

sub _build_tmp_file { "/tmp/02packages.details.txt.gz" };

sub run {
    my ($self)     = @_;
    my $darkpan    = $self->darkpan;
    my $local_pkgs = $self->get_pkgs_from_local_environment;

    for my $pkg_name (sort keys %$local_pkgs) {
        my $pkg = $darkpan->package($pkg_name);
        if (!$pkg) {
            my $version = $local_pkgs->{$pkg_name};
            $version =~ s/^v//;

            push @{ $self->extra_modules }, {
                name    => $pkg_name,
                version => $version,
            };
        }
        else {
            my $local_version = $local_pkgs->{$pkg_name};
            $local_version =~ s/^v//;

            my $darkpan_version = $pkg->version;
            $darkpan_version =~ s/^v//;

            push @{ $self->modules_with_version_mismatch }, { 
                name            => $pkg_name,
                darkpan_version => $darkpan_version,
                local_version   => $local_version,
            } if $darkpan_version ne $local_version;
        }
    }
}

# returns a Parse::CPAN::Packages object
sub darkpan {
    my ($self)   = @_;
    my $url      = $self->darkpan_url . '/modules/02packages.details.txt.gz';
    my $res = HTTP::Tiny->new->mirror($url, $self->tmp_file);
    die "download failed!\n" unless $res->{success};
    return Parse::CPAN::Packages->new($self->tmp_file);
}

# returns: { $package => $version, ... }
sub get_pkgs_from_local_environment {
    my $self = shift;
    my $inst = ExtUtils::Installed->new(skip_cwd => 1);
    my @modules = $inst->modules;

    my $local_modules;
    for my $m (@modules) {
        my $file  = $self->_installed_file_for_module($m);
        my $class = $m;

        if (!$file) {
            $file  = $self->_shortest_module_name_in_packlist($inst, $m);
            my $name = Module::Extract::Namespaces->from_file($file);

            if (Module::Extract::Namespaces->error) {
                warn Module::Extract::Namespaces->error, "\n";
            }
            else {
                $class = $name;
            }
        }

        if (!$file) {
            print "warning: could not find $m\n";
            next;
        }

        $local_modules->{$class} = MM->parse_version($file);
    }   

    return $local_modules;
}

sub _shortest_module_name_in_packlist {
    my ($self, $inst, $m) = @_;

    my $length = 999999999999999999999999999;
    my $shortest;

    for my $file ($inst->files($m)) {
        next unless $file =~ /\.pm$/i;

        if ($length > length $file) {
            $shortest = $file;
            $length   = length $file;
        }
    }

    return $shortest;
}

sub _installed_file_for_module {
    my $self   = shift;
    my $prereq = shift;
 
    my $file = "$prereq.pm";
    $file =~ s{::}{/}g;
 
    my $path;
    for my $dir (@INC) {
        my $tmp = File::Spec->catfile($dir, $file);
        if ( -r $tmp ) {
            $path = $tmp;
            last;
        }
    }
 
    return $path;
}


sub DEMOLISH {
    my $self = shift;
    unlink $self->tmp_file if $self->tmp_file && -e $self->tmp_file;
}


1;
__END__

=encoding utf-8

=head1 NAME

DarkPAN::Compare - Compare local Perl packages/versions with your DarkPAN

=head1 SYNOPSIS

    use DarkPAN::Compare;

    my $compare = DarkPAN::Compare->new(
        darkpan_url => 'https://darkpan.mycompany.com'
    );

    # Do analysis
    $compare->run;

    # local modules which are not in your darkpan
    # returns an arrayref of hashes
    my $modules = $compare->extra_modules();  
    for my $m (@$modules) {
        print "$m->{name}: $m->{version}\n";
    }

    # local modules which have different versions than your darkpan
    # returns an arrayref of hashes
    my $modules = $compare->modules_with_version_mismatch(); 
    for my $m (@$modules) {
        print "$m->{name}: $m->{darkpan_version}\t$m->{local_version}\n";
    }

=head1 DESCRIPTION

Learn what Perl packages/versions are different in your environment compared to
whats in your darkpan (pinto or orepan2 or whatever).

This module comes with a handy script as well: L<compare_to_darkpan>

=head1 LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Eric Johnson E<lt>eric.git@iijo.orgE<gt>

=cut

