package CPANPLUS::Dist::Debora::Util;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

our $VERSION = '0.017';

use parent qw(Exporter);

our @EXPORT_OK = qw(
    parse_version
    module_is_distributed_with_perl
    decode_utf8
    slurp_utf8
    spew_utf8
    can_run
    run
    unix_path
    filetype
    find_most_recent_mtime
    find_shared_objects
    is_testing
);

use Carp qw(croak);
use Cwd qw(cwd);
use Encode qw(decode);
use English qw(-no_match_vars);
use File::Spec::Functions qw(catfile splitdir splitpath);
use File::Spec::Unix qw();
use IPC::Cmd qw(can_run);
use Module::CoreList 2.32;
use version 0.77;

use CPANPLUS::Error qw(error);

# Avoid warnings from IO::Select by using IPC::Run.
$IPC::Cmd::USE_IPC_RUN = IPC::Cmd->can_use_ipc_run;

my $perl_version = parse_version($PERL_VERSION);

sub parse_version {
    my $string = shift;

    return version->parse($string);
}

sub module_is_distributed_with_perl {
    my ($module_name, $version) = @_;

    my $ok = 0;

    # cpan2dist is run with -w, which triggers a warning in Module::CoreList.
    local $WARNING = 0;

    my $upper = Module::CoreList->removed_from($module_name);
    if (!defined $upper || $perl_version < parse_version($upper)) {
        my $lower = Module::CoreList->first_release($module_name, $version);
        if (defined $lower && $perl_version >= parse_version($lower)) {
            $ok = 1;
        }
    }

    return $ok;
}

sub decode_utf8 {
    my $bytes = shift;

    return decode('UTF-8', $bytes);
}

sub slurp_utf8 {
    my $filename = shift;

    my $data;

    my $ok = open my $fh, '<:encoding(UTF-8)', $filename;
    if ($ok) {
        local $RS = undef;
        $data = <$fh>;
        close $fh or $ok = 0;
    }

    return $data;
}

sub spew_utf8 {
    my ($filename, $string) = @_;

    my $ok = open my $fh, '>:encoding(UTF-8)', $filename;
    if ($ok) {
        $ok = print {$fh} $string;
        close $fh or $ok = 0;
    }

    return $ok;
}

sub run {
    my (%options) = @_;

    my $ok = 0;

    my $command = $options{command};
    if (!$command) {
        error('No command');
        return $ok;
    }

    my $dir = $options{dir};
    delete $options{dir};

    if (!exists $options{buffer}) {
        my $buf = q{};
        $options{buffer} = \$buf;
    }

    my $on_error = $options{on_error}
        // sub { error("Could not run '$_[0]': $_[1]") };
    delete $options{on_error};

    my $origdir;
    if ($dir) {
        $origdir = cwd;
        if (!chdir $dir) {
            return $ok;
        }
    }

    $ok = IPC::Cmd::run(%options);
    if (!$ok) {
        my $cmdline = join q{ }, @{$command};
        my $output  = ${$options{buffer}} // q{};
        $on_error->($cmdline, $output);
    }

    if ($origdir) {
        if (!chdir $origdir) {
            $ok = 0;
        }
    }

    return $ok;
}

sub unix_path {
    my $path = shift;

    (undef, $path) = splitpath($path, 1);
    $path = File::Spec::Unix->catfile(splitdir($path));

    return $path;
}

sub filetype {
    my $filename = shift;

    my %type_for = (
        '1'     => 'text',
        '1p'    => 'text',
        '3'     => 'text',
        '3perl' => 'text',
        '3pm'   => 'text',
        'bat'   => 'script',
        'dll'   => 'executable',
        'dylib' => 'executable',
        'exe'   => 'executable',
        'pl'    => 'script',
        'pm'    => 'text',
        'pod'   => 'text',
        'so'    => 'executable',
    );

    my @magic = (
        [0, 4, '7F454C46', 'executable'],    # ELF
        [0, 4, 'FEEDFACE', 'executable'],    # Mach-O
        [0, 4, 'CEFAEDFE', 'executable'],    # Mach-O
        [0, 4, 'FEEDFACF', 'executable'],    # Mach-O
        [0, 4, 'CFFAEDFE', 'executable'],    # Mach-O
        [0, 2, '4D5A',     'executable'],    # PE
        [0, 2, '2321',     'script'],        # Shebang
    );

    my $type = 'data';

    if ($filename =~ m{[.]([^.]+) \z}xms) {
        my $suffix = lc $1;
        if (exists $type_for{$suffix}) {
            $type = $type_for{$suffix};
        }
    }

    if ($type eq 'data') {
        if (open my $fh, '<:raw', $filename) {
            if (read $fh, my $data, 16) {
                TYPE:
                for (@magic) {
                    if (substr($data, $_->[0], $_->[1]) eq pack 'H*', $_->[2]) {
                        $type = $_->[3];
                        last TYPE;
                    }
                }
            }
            close $fh or undef;
        }
    }

    return $type;
}

sub find_most_recent_mtime {
    my $sourcedir = shift;

    my $most_recent_mtime = 0;

    my $find = sub {
        my $dir = shift;

        opendir my $dh, $dir or croak "Could not traverse '$dir': $OS_ERROR";
        ENTRY:
        while (defined(my $entry = readdir $dh)) {
            next ENTRY if $entry eq q{.} || $entry eq q{..};

            my $path = catfile($dir, $entry);

            # Skip symbolic links.
            next ENTRY if -l $path;

            if (-d $path) {
                __SUB__->($path);
            }
            else {
                my @stat = stat $path;
                if (@stat) {
                    my $mtime = $stat[9];
                    if ($most_recent_mtime < $mtime) {
                        $most_recent_mtime = $mtime;
                    }
                }
            }
        }
        closedir $dh;

        return;
    };
    $find->($sourcedir);

    return $most_recent_mtime;
}

sub find_shared_objects {
    my $stagingdir = shift;

    my @shared_objects;

    my $find = sub {
        my $dir = shift;

        opendir my $dh, $dir
            or croak "Could not traverse '$dir': $OS_ERROR";
        ENTRY:
        while (defined(my $entry = readdir $dh)) {
            next ENTRY if $entry eq q{.} || $entry eq q{..};

            my $path = catfile($dir, $entry);

            # Skip symbolic links.
            next ENTRY if -l $path;

            if (-d $path) {
                __SUB__->($path);
            }
            else {
                if (filetype($path) eq 'executable') {
                    push @shared_objects, $path;
                }
            }
        }
        closedir $dh;

        return;
    };
    $find->($stagingdir);

    return \@shared_objects;
}

sub is_testing {
    return $ENV{AUTOMATED_TESTING} || $ENV{RELEASE_TESTING};
}

1;
__END__

=encoding UTF-8

=head1 NAME

CPANPLUS::Dist::Debora::Util - Utility functions

=head1 VERSION

version 0.017

=head1 SYNOPSIS

  use CPANPLUS::Dist::Debora::Util qw(
      parse_version
      module_is_distributed_with_perl
      decode_utf8
      slurp_utf8
      spew_utf8
      can_run
      run
      find_most_recent_mtime
      find_shared_objects
  );

  my $name    = 'Module::CoreList';
  my $version = parse_version('2.32');
  my $ok      = module_is_distributed_with_perl($name, $version);

  my $string = decode_utf8($bytes);
  my $ok     = spew_utf8($filename, $string);
  my $string = slurp_utf8($filename);

  my $program = can_run('perl');
  if ($program) {
      my $output = '';
      if (run(command => [$program, '-v'], buffer => \$output)) {
          print $output;
      }
  }

  my $last_modification = find_most_recent_mtime($sourcedir);
  for my $filename (@{find_shared_objects($stagingdir)}) {
    say $filename;
  }

=head1 DESCRIPTION

This module provides utility functions for CPANPLUS::Dist::Debora.

=head1 SUBROUTINES/METHODS

=head2 parse_version

  my $version = parse_version($string);

Returns a version object.

=head2 module_is_distributed_with_perl

  my $is_included = module_is_distributed_with_perl($name, $version);

Checks whether the specified module is part of the standard Perl distribution.

=head2 decode_utf8

  my $string = decode_utf8($bytes);

Decodes UTF-8 encoded bytes to a string.

=head2 slurp_utf8

  my $string = slurp_utf8($filename);

Reads UTF-8 encoded data from a file.

=head2 spew_utf8

  my $ok = spew_utf8($filename, $string);

Writes a string to a file.

=head2 can_run

  my $path = can_run($program);

Locates an external command and returns the path to the binary or the
undefined value.

=head2 run

  my $ok = run(
      command  => [$program, @args],
      dir      => $dir,
      buffer   => \$bytes,
      verbose  => 0|1,
      on_error => sub { say "Could not run '$_[0]': $_[1]" },
  );

Runs an external command in the current or specified directory.  Optionally
stores the command output in a variable.

=head2 unix_path

  my $path = unix_path($path);

Converts an OS specific path into a Unix path with forward slashes.

=head2 filetype

  my $type = filetype($filename);

Determines a file's type.  Returns "data", "executable", "script" or "text";

=head2 find_most_recent_mtime

  my $mtime = find_most_recent_mtime($sourcedir);

Searches the specified directory recursively for the last modified file.
Returns the modification time.

=head2 find_shared_objects

  my @filenames = @{find_shared_objects($stagingdir)};

Searches the specified directory recursively for shared objects and executable
programs.

=head2 is_testing

  my $is_testing = is_testing;

Returns true if automated or release testing is enabled.

=head1 DIAGNOSTICS

=over

=item B<< Could not run 'COMMAND' >>

An external command could not be run.

=back

=head1 CONFIGURATION AND ENVIRONMENT

=head2 Environment variables

=head3 AUTOMATED_TESTING, RELEASE_TESTING

The test mode is enabled if any of these variables is set.  No packages are
installed in test mode.

=head1 DEPENDENCIES

Requires only modules that are distributed with Perl.

=head1 INCOMPATIBILITIES

None.

=head1 BUGS AND LIMITATIONS

Install L<IPC::Run> if IPC::Open3 causes IO::Select to output warnings.

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
