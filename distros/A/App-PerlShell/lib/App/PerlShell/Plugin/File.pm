package App::PerlShell::Plugin::File;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;
use Pod::Usage;
use Pod::Find qw( pod_where );

use Exporter;

our @EXPORT = qw(
  File
  file_eval
  file_read
);

our @ISA = qw ( Exporter );

sub File {
    pod2usage(
        -verbose => 2,
        -exitval => "NOEXIT",
        -input   => pod_where( {-inc => 1}, __PACKAGE__ )
    );
}

########################################################

sub file_eval {
    if ( $#_ < 0 ) {
        _help("COMMANDS/file_eval - run Perl commands in file");
        return;
    }

    my %params = (
        argv    => undef,
        line    => 0,
        verbose => 0
    );

    if ( @_ == 1 ) {
        ( $params{file} ) = @_;
    } else {
        if ( ( @_ % 2 ) == 1 ) {
            $params{file} = shift;
        }
        my %args = @_;
        for ( keys(%args) ) {
            if (/^-?file$/i) {
                $params{file} = $args{$_};
            } elsif (/^-?argv$/i) {
                $params{argv}
                  = "\@ARGV = qw ( $args{$_} ); # ADDED argv => ...\n";
            } elsif (/^-?line$/i) {
                $params{line} = 1;
            } elsif (/^-?verbose$/i) {
                $params{verbose} = 1;
            } else {
                die("Unknown parameter: `$_'");
            }
        }
    }

    if ( not defined $params{file} ) {
        die("No file provided");
    }

    my @rets;
    my $retType = wantarray;
    if ($retType) {
        $params{line} = 1;
    }

    if ( -e $params{file} ) {
        open( my $IN, '<', $params{file} );

        no strict;
        use strict 'subs';

        if ( $params{line} ) {
            while (<$IN>) {
                print "$_" if ( $params{verbose} );

                if ( not defined $retType ) {

                    # skip blank lines and #comments
                    next if ( ( $_ =~ /^[\n\r]+$/ ) or ( $_ =~ /^\s*#/ ) );
                    chomp $_;
                    eval $_;
                    warn $@ if $@;
                } else {
                    push @rets, $_;
                }
            }
            close $IN;
            if ($retType) {
                return @rets;
            } else {
                my $ret = join "", @rets;
                return $ret;
            }
        } else {
            my $fullfile;
            if ( defined $params{argv} ) {
                $fullfile = $params{argv};
                print $fullfile if ( $params{verbose} );
            }
            while (<$IN>) {
                print "$_" if ( $params{verbose} );
                $fullfile .= $_;
            }

            if ( not defined wantarray ) {
                eval $fullfile;
                warn $@ if $@;
            } else {
                return $fullfile;
            }
            close($IN);
        }

    } else {
        die("Cannot find file - `$params{file}'");
    }
}

sub file_read {
    if ( $#_ < 0 ) {
        _help("COMMANDS/file_read - read contents of a file");
        return;
    }

    my ($file) = @_;

    if ( not defined $file ) {
        print "file required\n";
        return;
    }

    open my $fh, "<", $file
      or die "$!";

    my @rets = <$fh>;
    close $fh;

    my $retType = wantarray;

    if ( not defined $retType ) {
        print @rets;
    } elsif ($retType) {
        return @rets;
    } else {
        my $ret = join "", @rets;
        return $ret;
    }
}

sub _help {
    my ($section) = @_;

    pod2usage(
        -verbose  => 99,
        -exitval  => "NOEXIT",
        -sections => $section,
        -input    => pod_where( {-inc => 1}, __PACKAGE__ )
    );
}

1;

__END__

=head1 NAME

File - Provides routines for working with external files

=head1 SYNOPSIS

 use App::PerlShell::Plugin::File;

=head1 DESCRIPTION

This module provides useful routines for working with external files.

=head1 COMMANDS

=head2 File - provide help

Provides help.

=head2 file_eval - run Perl commands in file

 [$file | @lines =] file_eval "[[/]path/to/]file" [OPTIONS]

Open and parse provided file of Perl commands.  By default, entire file
is read and then parsed at once.

  Option     Description                       Default Value
  ------     -----------                       -------------
  argv       Argument string to pass to the    (none)
               @ARGV variable in the file
  file       File (with optional path) to      (none)
               execute.
  line       Parse file line-by-line (1 = on)  (off)
  verbose    Show file content       (1 = on)  (off)

Current directory is searched unless relative or absolute path is also
provided.

To pass parameters to a file the B<argv> option can contain a string such as
would be present on the command line if the file was called from the command
line.  For example, a script may take an option switch "-r" and a string
option for hostname such as "-h name".  The B<argv> option can be used as
such:

  file "filename.txt", argv => "-h name -r";

In "filename.txt", the arguments can be processed from @ARGV with standard
modules like B<Getopt::Long>.

Note the B<line> option should I<never> be used unless debugging or some
other strange and odd situation.

Single option indicates B<file>.

=over 4

=item B<no return>

Called alone evals (executes) the file contents.

=item B<scalar>

Called in scalar context returns the contents to the scalar variable without
eval-ing them (similar to B<file_read>).

=item B<array>

Called in array context returns each file line as an item in the array
without eval-ing them (similar to B<file_read>).  Note array context
forces B<line> option on.

=back

=head2 file_read - read contents of a file

 [$file | @lines =] file_read "[[/]path/to/]file"

Open file and return the contents.  Current directory is searched unless
relative or absolute path is also provided.

=over 4

=item B<no return>

Called alone prints contents to screen.

=item B<scalar>

Called in scalar context returns the contents to the scalar variable.

=item B<array>

Called in array context returns each file line as an item in the array.

=back

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (c) 2013, 2019 Michael Vincent

L<http://www.VinsWorld.com>

All rights reserved

=cut
