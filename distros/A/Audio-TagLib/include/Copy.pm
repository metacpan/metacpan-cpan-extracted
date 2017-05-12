#
#===============================================================================
#
#         FILE:  Copy.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Geoffrey Leach (), geoff@hughes.net
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  12/17/2013 04:06:47 PM
#     REVISION:  ---
#===============================================================================

package Copy;

use warnings;

use Fcntl qw( :DEFAULT ) ;
use POSIX qw( :fcntl_h ) ;

sub DupName {
    my $file = shift;
    # Courtesy Festut Hagen, Windows compaitble
    return $file =~ m/(.*)[\\\/](.+)/ ? ( $1 . '/dup_' . $2 ) : ( undef );
}

sub Copy {
    my ($filein, $fileout) = @_;
    return 0 unless -f $filein;
    my $filein_fd;
    sysopen( $filein_fd, $filein, O_RDONLY );
    return 0 unless defined $filein_fd;
    my $filein_size = (stat $filein)[7];
    sysread( $filein_fd, my $filein_data, $filein_size, 0 );
    sysopen( my $fileout_fd, $fileout, O_CREAT | O_WRONLY );
    return 0 unless defined $fileout_fd;
    my $fileout_size = syswrite( $fileout_fd, $filein_data );
    return 0 unless $fileout_size == $filein_size;
    return 1;
}

sub Dup {
    my $filein = shift;
    return Copy( $filein,  DupName( $filein ) );
}

sub Unlink {
    my $filein = shift;
    unlink DupName( $filein );
}

1;
