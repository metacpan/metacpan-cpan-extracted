package CPANPLUS::Dist::Slackware::Util;

use strict;
use warnings;

our $VERSION = '1.030';

use base qw(Exporter);

our @EXPORT_OK
    = qw(can_run run catdir catfile tmpdir slurp spurt filetype gzip strip);

use English qw( -no_match_vars );

use CPANPLUS::Error;

use Cwd qw();
use File::Spec::Functions qw(catdir catfile tmpdir);
use IO::Compress::Gzip qw();
use IPC::Cmd qw(can_run);
use Locale::Maketext::Simple ( Style => 'gettext' );

my $file_cmd  = can_run('file');
my $strip_cmd = can_run('strip');

sub run {
    my ( $cmd, $param_ref ) = @_;

    my $dir     = $param_ref->{dir};
    my $verbose = $param_ref->{verbose};
    my $buf_ref = $param_ref->{buffer};
    if ( !$buf_ref ) {
        my $buf;
        $buf_ref = \$buf;
    }

    my $orig_dir;
    if ($dir) {
        $orig_dir = Cwd::cwd();
        if ( !chdir($dir) ) {
            return;
        }
    }

    my $fail = 0;
    if (!IPC::Cmd::run(
            command => $cmd,
            buffer  => $buf_ref,
            verbose => $verbose
        )
        )
    {
        my $cmdline = join q{ }, @{$cmd};
        error( loc( q{Could not run '%1': %2}, $cmdline, ${$buf_ref} ) );
        ++$fail;
    }

    if ($orig_dir) {
        if ( !chdir($orig_dir) ) {
            ++$fail;
        }
    }

    return ( $fail ? 0 : 1 );
}

sub slurp {
    my $filename = shift;

    my $fh;
    if ( !open $fh, '<', $filename ) {
        error( loc( q{Could not open file '%1': %2}, $filename, $OS_ERROR ) );
        return;
    }

    my $text = do { local $RS = undef; <$fh> };

    if ( !close $fh ) {
        error(
            loc( q{Could not close file '%1': %2}, $filename, $OS_ERROR ) );
        return;
    }

    return $text;
}

sub spurt {
    my ( $filename, @lines ) = @_;

    my $param_ref = ( ref $lines[0] eq 'HASH' ) ? shift @lines : {};
    my $mode      = ( $param_ref->{append} )    ? '>>'         : '>';
    my $binmode   = $param_ref->{binmode};

    my $fh;
    if ( !open $fh, $mode, $filename ) {
        error(
            loc( q{Could not create file '%1': %2}, $filename, $OS_ERROR ) );
        return;
    }

    if ($binmode) {
        if ( !binmode $fh, $binmode ) {
            error(
                loc(q{Could not set binmode for file '%1' to '%2': %3},
                    $filename, $binmode, $OS_ERROR
                )
            );
            return;
        }
    }

    my $fail = 0;
    if ( !print {$fh} @lines ) {
        error(
            loc( q{Could not write to file '%1': %2}, $filename, $OS_ERROR )
        );
        ++$fail;
    }

    if ( !close $fh ) {
        error(
            loc( q{Could not close file '%1': %2}, $filename, $OS_ERROR ) );
        ++$fail;
    }

    return ( $fail ? 0 : 1 );
}

sub filetype {
    my $filename = shift;

    my $type;
    if ($file_cmd) {
        my $cmd = [ $file_cmd, '-b', $filename ];
        if ( !run( $cmd, { buffer => \$type } ) ) {
            undef $type;
        }
    }
    if ($type) {
        chomp $type;
    }
    else {
        $type = 'data';
    }
    return $type;
}

sub gzip {
    my $filename = shift;

    my $gzname = "$filename.gz";
    if ( -l $filename ) {
        my $target = readlink $filename;
        if ($target) {
            if ( symlink "$target.gz", $gzname ) {
                return $gzname;
            }
        }
    }
    elsif ( -f $filename ) {
        if ( IO::Compress::Gzip::gzip( $filename, $gzname ) ) {
            return $gzname;
        }
    }
    return;
}

sub strip {
    my (@filenames) = @_;

    return 1 if !$strip_cmd;

    my $cmd = [ $strip_cmd, '--strip-unneeded', @filenames ];
    return run($cmd);
}

1;
__END__

=head1 NAME

CPANPLUS::Dist::Slackware::Util - Utility functions

=head1 VERSION

This document describes CPANPLUS::Dist::Slackware::Util version 1.030.

=head1 SYNOPSIS

    use CPANPLUS::Dist::Slackware::Util qw(can_run run slurp spurt filetype gzip);

    my $program = can_run('perl');
    if ( $program ) {
        my $cmd = [ $program, '-v' ];
        my $output = '';
        if ( run( $cmd, { buffer => \$output } ) ) {
            print $output;
        }
    }

    if ( spurt( '/tmp/hello.txt', 'hello, world' ) ) {
        my $str = slurp('/tmp/hello.txt');
        if ( my $filename = gzip('/tmp/hello.txt') ) {
            print $filename, ': ', filetype($filename), "\n";
        }
    }

=head1 DESCRIPTION

This module provides utility functions for CPANPLUS::Dist::Slackware.

=head1 FUNCTIONS

=over 4

=item B<< $path = can_run( $program ) >>

Locate a program and return the path to the binary or undef.

=item B<< $ok = run( $cmd, { dir => $dir, buffer => \$str, verbose => 0|1 } ) >>

Run a command in the current or a specified directory. Optionally stores the
output in a scalar.

=item B<< $str = slurp( $filename ) >>

Read a file.

=item B<< $ok = spurt( $filename, $str, ... ) >>

Write to a file.

=item B<< $str = filetype( $filename ) >>

Get a file's type.

=item B<< $gzname = gzip( $filename ) >>

Compress a file.

=item B<< $ok = strip( $filename, ... ) >>

Strip object files.

=back

=head1 DIAGNOSTICS

=over 4

=item B<< Could not create file FILE >>

A file could not be opened for writing.

=item B<< Could not write to file FILE >>

Is a file system full?

=item B<< Could not run COMMAND >>

An external command failed to execute.

=back

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

See CPANPLUS::Dist::Slackware.

=head1 INCOMPATIBILITIES

None known.

=head1 SEE ALSO

CPANPLUS::Dist::Slackware

=head1 AUTHOR

Andreas Voegele E<lt>voegelas@cpan.orgE<gt>

=head1 BUGS AND LIMITATIONS

Please report any bugs using the issue tracker at
L<https://github.com/graygnuorg/CPANPLUS-Dist-Slackware/issues>.

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2020 Andreas Voegele

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See https://dev.perl.org/licenses/ for more information.

=cut
