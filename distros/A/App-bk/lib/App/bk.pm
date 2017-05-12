package App::bk;

use warnings;
use strict;

use Getopt::Long qw(:config no_ignore_case bundling no_auto_abbrev);
use Pod::Usage;
use English 'no-match-vars';
use POSIX qw(strftime);
use File::Basename;
use File::Copy;
use File::Which qw(which);
use Carp;

=head1 NAME

App::bk - A module for functions used by the F<bk> program.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.06';

my %opts = (
    'help|h|?'  => 0,
    'man'       => 0,
    'version|V' => 0,
    'debug:+'   => 0,
    'diff|d'    => 0,
    'edit|e'    => 0,
);
my %options;

# 'tidier' way to store global variables
# probably shouldnt do it like this - will rework later
$options{debug} ||= 0;
$options{username} = getpwuid($EUID);

if ( $options{username} eq 'root' ) {
    logmsg( 2, 'Running as root so dropping username from file backups' );
    $options{username} = '';
}

=head1 SYNOPSIS

Please see the file F<bk> for more information about the F<bk> program.

=head1 SUBROUTINES/METHODS

=head2 backup_files

Main function to process ARGV and backup files as necessary

=cut

sub backup_files {

    # make sure we don't clobber any callers variables

    local @ARGV = @ARGV;
    GetOptions( \%options, keys(%opts) ) || pod2usage( -verbose => 1 );

    die("Version: $VERSION\n") if ( $options{version} );
    pod2usage( -verbose => 1 ) if ( $options{'?'}  || $options{help} );
    pod2usage( -verbose => 2 ) if ( $options{HELP} || $options{man} );

    $options{debug} ||= 0;
    $options{debug} = 8 if ( $options{debug} > 8 );

    if ( !@ARGV ) {
        pod2usage(
            -message => 'No filenames provided.',
            -verbose => 0,
        );
    }

    my $date = strftime( '%Y%m%d', localtime() );
    my $time = strftime( '%H%M%S', localtime() );

    foreach my $filename (@ARGV) {
        my ( $basename, $dirname ) = fileparse($filename);

      # do this via savedir as we might move this somewhere else dir in future
        my $savedir = $dirname;

        logmsg( 2, "dirname=$dirname" );
        logmsg( 2, "basename=$basename" );

        if ( !-f $filename ) {
            warn "WARNING: File $filename not found", $/;
            next;
        }

        if ( !$savedir ) {
            warn "WARNING: $savedir does not exist", $/;
            next;
        }

        # compare the last file found with the current file
        my $last_backup = get_last_backup( $savedir, $basename );

        if ( $options{diff} ) {
            if ( !$last_backup ) {
                print "'$filename' not previously backed up.", $/;
            }
            else {
                print get_diff( $last_backup, $filename );
            }
            next;
        }

        if ($last_backup) {
            logmsg( 1, "Found last backup as: $last_backup" );

            my $last_backup_sum = get_chksum($last_backup);
            my $current_sum     = get_chksum($filename);

            logmsg( 2, "Last backup file $options{sum}: $last_backup_sum" );
            logmsg( 2, "Current file $options{sum}: $current_sum" );

            if ( $last_backup_sum eq $current_sum ) {
                logmsg( 0, "No change since last backup of $filename" );
                next;
            }
        }

        my $savefilename = "$savedir$basename";
        $savefilename .= ".$options{username}" if ( $options{username} );
        $savefilename .= ".$date";
        if ( -f $savefilename ) {
            $savefilename .= ".$time";
        }

        logmsg( 1, "Backing up to $savefilename" );

        # use OS cp to preserve ownership/permissions/etc
        if ( system("cp $filename $savefilename") != 0 ) {
            warn "Failed to back up $filename", $/;
            next;
        }

        logmsg( 0, "Backed up $filename to $savefilename" );
    }

    if ( $options{edit} ) {
        my $editor 
            = $ENV{EDITOR}
            || $ENV{VISUAL}
            || die 'Neither "EDITOR" nor "VISUAL" environment variables set',
            $/;

        print "Running: $editor @ARGV", $/;
        exec("$editor @ARGV");
    }

    return 1;
}

=head2 logmsg($level, @message);

Output @message if $level is equal or less than $options{debug}

=cut

sub logmsg {
    my ( $level, @text ) = @_;
    print @text, $/ if ( $level <= $options{debug} );
}

=head2 $binary = find_sum_binary();

Locate a binary to use to calculate a file checksum.  Looks first for md5sum, then sum.  Dies on failure to find either.

=cut

sub find_sum_binary {
    return
           which('md5sum')
        || which('sum')
        || die 'Unable to locate "md5sum" or "sum"', $/;
}

=head2 $sum = get_chksum($file);

Get the chksum of a file

=cut

sub get_chksum {
    my ($filename) = @_;

    croak 'No filename provided' if ( !$filename );

    if ( !$options{sum} ) {
        $options{sum} = find_sum_binary();
        logmsg( 2, "Using $options{sum}" );
    }

    my $chksum = qx/$options{sum} $filename/;
    chomp($chksum);

    ($chksum) = $chksum =~ m/^(\w+)\s/;
    return $chksum;
}

=head2 $binary = find_diff_binary();

Locate a binary to use for diff

=cut

sub find_diff_binary {
    return which('diff')
        || die 'Unable to locate "diff"', $/;
}

=head2 $differences = get_diff ($old, $new);

Get the differences between two files

=cut

sub get_diff {
    my ( $old, $new ) = @_;

    my $diff_binary = find_diff_binary();
    my $differences = qx/$diff_binary -u $old $new/;
    return $differences
        ? $differences
        : "No differences between '$old' and '$new'" . $/;
}

=head2 $filename = get_last_backup($file);

Get the last backup filename for given file

=cut

sub get_last_backup {
    my ( $savedir, $filename ) = @_;

    if ( !$savedir || !-d $savedir ) {
        croak 'Invalid save directory provided';
    }

    # get last backup and compare to current file to prevent
    # unnecessary backups being created
    opendir( my $savedir_fh, $savedir )
        || die( "Unable to read $savedir: $!", $/ );
    my @save_files = sort
        grep( /$filename\.(?:$options{username}\.)?\d{8}/,
        readdir($savedir_fh) );
    closedir($savedir_fh) || die( "Unable to close $savedir: $!", $/ );

    if ( $options{debug} > 2 ) {
        logmsg( 3, "Previous backups found:" );
        foreach my $bk (@save_files) {
            logmsg( 3, "\t$bk" );
        }
    }

    return $save_files[-1];
}

=head1 AUTHOR

Duncan Ferguson, C<< <duncan_j_ferguson at yahoo.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests via the web interface at 
L<https://github.com/duncs/perl-app-bk/issues>/  
I will be notified, and then you'll automatically be notified of 
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::bk


You can also look for information at:

=over 4

=item * HitHUB: request tracker

L<https://github.com/duncs/perl-app-bk/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-bk>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-bk>

=item * Search CPAN

L<http://search.cpan.org/dist/App-bk/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Duncan Ferguson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of App::bk
