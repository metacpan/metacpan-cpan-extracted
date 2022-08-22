package CPANPLUS::Dist::Debora::Package::Tar;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

our $VERSION = '0.010';

use parent qw(CPANPLUS::Dist::Debora::Package);

use Archive::Tar qw(COMPRESS_GZIP);
use Archive::Tar::Constant qw(DIR);
use Carp qw(croak);
use Config;
use Cwd qw(cwd);
use English qw(-no_match_vars);
use File::Spec::Functions qw(catdir catfile);

use CPANPLUS::Dist::Debora::Util qw(can_run run unix_path is_testing);

sub format_priority {
    my $class = shift;

    my @commands = qw(tar);

    my $priority = 0;
    if (@commands == grep { can_run($_) } @commands) {
        $priority = 1;
    }

    if (is_testing) {
        $priority = ~0;
    }

    return $priority;
}

sub create {
    my ($self, %options) = @_;

    my $ok = 0;

    my $tar = $self->_tar_create;
    if (defined $tar) {
        $ok = $tar->write($self->outputname, COMPRESS_GZIP);
    }

    return $ok;
}

sub install {
    my ($self, %options) = @_;

    my $sudo_cmd    = $self->sudo_cmd;
    my @install_cmd = ($sudo_cmd, qw(tar -C / -xvzf), $self->outputname);

    my $ok = 0;
    if (is_testing) {
        my $tar = Archive::Tar->new($self->outputname, COMPRESS_GZIP);
        if (defined $tar) {
            $ok = 1;
            my @properties = qw(mode uname gname size mtime prefix name);
            for my $file ($tar->list_files([@properties])) {
                say $self->_format_file($file) or $ok = 0;
            }
        }
    }
    else {
        $ok = run(command => \@install_cmd, verbose => $options{verbose});
    }

    return $ok;
}

sub outputname {
    my $self = shift;

    my $outputname = $self->_read(
        'outputname',
        sub {
            catfile($self->outputdir,
                      $self->name . q{-}
                    . $self->version . q{-}
                    . $self->build_number
                    . q{.tar.gz});
        }
    );

    return $outputname;
}

sub _docdir {
    my $self = shift;

    my $docdir = $self->_read(
        '_docdir',
        sub {
            catdir($Config{$self->installdirs . 'prefix'},
                'share', 'doc', $self->name);
        }
    );

    return $docdir;
}

sub _clamp_mtime {
    my ($self, $tarfile) = @_;

    my $last_modification = $self->last_modification;
    if ($tarfile->mtime > $last_modification) {
        $tarfile->mtime($last_modification);
    }

    return;
}

sub _add_dir {
    my ($self, $tar, $dir) = @_;

    my %properties = (
        type  => DIR,
        mode  => oct '0755',
        uid   => 0,
        gid   => 0,
        uname => 'root',
        gname => 'root',
        mtime => $self->last_modification,
    );

    my $tarfile = $tar->add_data(catdir(q{.}, $dir), q{}, \%properties);

    return $tarfile;
}

sub _add_file {
    my ($self, $tar, $path) = @_;

    my ($tarfile) = $tar->add_files(catfile(q{.}, $path));
    if (defined $tarfile) {
        $tarfile->chown('root', 'root');
        $self->_clamp_mtime($tarfile);
    }

    return $tarfile;
}

sub _add_doc {
    my ($self, $tar, $path) = @_;

    my $docdir   = $self->_docdir;
    my $file     = substr $path, length $self->builddir;
    my $new_name = unix_path(catfile(q{.}, $docdir, $file));

    my ($tarfile) = $tar->add_files($path);
    if (defined $tarfile) {
        $tarfile->chown('root', 'root');
        $tarfile->rename($new_name);
        $self->_clamp_mtime($tarfile);
    }

    return $tarfile;
}

sub _add_docdir {
    my ($self, $tar, $dir) = @_;

    opendir my $dh, $dir or croak "Could not traverse '$dir': $OS_ERROR";
    ENTRY:
    while (defined(my $entry = readdir $dh)) {
        next ENTRY if $entry eq q{.} || $entry eq q{..};

        my $path = catfile($dir, $entry);

        # Skip symbolic links.
        next ENTRY if -l $path;

        $self->_add_doc($tar, $path);

        if (-d $path) {
            $self->_add_docdir($tar, $path);
        }
    }
    closedir $dh;

    return;
}

sub _tar_create {
    my $self = shift;

    my $builddir   = $self->builddir;
    my $stagingdir = $self->stagingdir;

    my $tar;

    my $origdir = cwd;
    if (chdir $stagingdir) {
        $tar = Archive::Tar->new;

        my %is_doc = map { $_ => 1 } qw(changelog doc license);

        my $is_first = 1;
        for my $file (@{$self->files}) {
            my $name = $file->{name};
            my $type = $file->{type};

            if ($is_doc{$type}) {
                if ($is_first) {
                    $self->_add_dir($tar, $self->_docdir);
                    $is_first = 0;
                }

                my $path    = catfile($builddir, $name);
                my $tarfile = $self->_add_doc($tar, $path);

                if (-d $path) {
                    $self->_add_docdir($tar, $path);
                }
            }
            else {
                $self->_add_file($tar, $name);
            }
        }

        if (!chdir $origdir) {
            undef $tar;
        }
    }

    return $tar;
}

sub _format_file {
    my ($self, $file) = @_;

    my (undef, $min, $hour, $mday, $mon, $year) = localtime $file->{mtime};
    my $string = sprintf '%s%s %s/%s %10d %d-%02d-%02d %02d:%02d %s/%s',
        $file->{name} =~ m{/\z}xms ? q{d}        : q{-},
        $file->{mode} & oct '0111' ? 'rwxr-xr-x' : 'rw-r--r--',
        $file->{uname}, $file->{gname}, $file->{size},
        $year + 1900, $mon + 1, $mday, $hour, $min, $file->{prefix},
        $file->{name};
    return $string;
}

1;
__END__

=encoding UTF-8

=head1 NAME

CPANPLUS::Dist::Debora::Package::Tar - Create tar archives

=head1 VERSION

version 0.010

=head1 SYNOPSIS

  use CPANPLUS::Dist::Debora::Package::Tar;

  my $package =
      CPANPLUS::Dist::Debora::Package::Tar->new(module => $module);

  my $ok = $package->create(verbose => 0|1);
  my $ok = $package->install(verbose => 0|1);

=head1 DESCRIPTION

This L<CPANPLUS::Dist::Debora::Package> subclass creates tar archives from
Perl distributions.

=head1 SUBROUTINES/METHODS

=head2 format_priority

  my $priority = CPANPLUS::Dist::Debora::Package::Tar->format_priority;

Checks if the tar program is available.

=head2 create

  my $ok = $package->create(verbose => 0|1);

Creates a tar archive.

=head2 install

  my $ok = $package->install(verbose => 0|1);

Extracts the tar archive.

=head2 outputname

  my $tar = $package->outputname;

Returns the tar archive's name, e.g.
F<~/.cpanplus/5.34.0/build/XXXX/perl-Some-Module-1.0-1.tar.gz>.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

Requires the tar program and the Perl module L<Archive::Tar>.

=head1 INCOMPATIBILITIES

None.

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 BUGS AND LIMITATIONS

This module cannot be used in taint mode.

=head1 LICENSE AND COPYRIGHT

Copyright 2022 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
