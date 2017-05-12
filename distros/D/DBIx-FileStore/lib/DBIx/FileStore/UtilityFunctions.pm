package DBIx::FileStore::UtilityFunctions;
use strict;
use warnings;

# utility functions for DBIx::FileStore

use base qw(Exporter);
our @EXPORT_OK = qw( convert_bytes_to_human_size get_date_and_time get_user_homedir );


############################################
# converts bytes to human-readable
#  my $human_size = convert_bytes_to_human_size( 2341414 ); 
#  yeilds ie 2.34M
sub convert_bytes_to_human_size {
    my $bytes  = shift;
    return unless defined( $bytes );
    my $precision = 2;  # in more advanced versions we let the caller optionally specify this.
    my $k_size = 1024;
    return "?" unless ($bytes =~ s/ ^ \s* (\d+( \. \d* )?) $//x );   # negative bytes not allowed
    $bytes = $1;                # pull out the cleaned up version

    # this should be factored out
    my @table = (   [ $k_size**5, 	"P" ],
                    [ $k_size**4, 	"T" ],
                    [ $k_size**3, 	"G" ],
                    [ $k_size**2,   "M" ],
                    [ $k_size,    	"K" ] );

    # convert to relevant units if bytecount is
    # larger than 1 unit of (P, T, G, M, or K)
    for my $row (@table) {
        if ($bytes > $row->[0]) {  
            my $value =  $bytes / $row->[0];
            if ($value =~ /^\d+(\.0*)?$/) { # if it's .000*
                $value = int( $value );     # truncate fraction
            } else {
                $value = sprintf( "%.${precision}f", $value);   # show to desired precision
            }
            return $value . $row->[1];  # return the value followed by the unit name, like 14.5G or 12M or 12.44K
        } 
    }
    return "${bytes}B";
}

############################################
# returns date and time, in the current TMZ and locale,
#  like '0000-00-00 00:00:00'  
sub get_date_and_time {
    my $t = shift || time();
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($t);
    return sprintf("%04d-%02d-%02d %02d:%02d:%02d",
        1900+$year, $mon+1, $mday, $hour, $min, $sec);
}

############################################
# my $homedir = get_user_homedir(); 
#  or 
# my $homedir = get_user_homedir( "username" ); 
############################################
sub get_user_homedir {
    my $user = shift || $ENV{USER};
    my ( $name, $passwd, $uid, $gid, $quota, $comment, $gcos, $homedir, $shell, $expire ) =
        getpwnam( $user );  # get the userid and the homedir
    return $homedir;

}

1;

=pod

=head1 NAME

DBIx::FileStore::UtilityFunctions -- Utility functions for DBIx::FileStore

=head1 SYNOPSIS

    # converts from bytes to something prettier like 10.1G.
    my $size = convert_bytes_to_human_size( $bytecount)
    print "12345678 bytes is " . convert_bytes_to_human_size(12345678) . "\n";

    # get a pretty string with the date and time, either for now
    # or the epoch-based time passed:
    my $date_string = get_date_and_time();
    my $once_upon_a_time = get_date_and_time( 1 );  # 1 second into 1970GMT

    # homedir fetching...
    my $my_homedir = get_user_homedir(); 
    my $bobs_homedir = get_user_homedir( "bob" ); 


=head1 DESCRIPTION

Provides three functions: 

get_user_homedir(), get_date_and_time(), and convert bytes_to_human_size().

=head1 FUNCTIONS

=over 4

=item my $size = convert_bytes_to_human_size( $bytecount )

Converts an integer (like 5 or 10100) into a string for display
like 5B, 10.1K, 20.7M, or 33G.

=item my $date_string = get_date_and_time( $optional_time );

Returns a string with the date and time, either for now
or the epoch-based $time passed.

=item my $homedir = get_user_homedir( $optional_username ); 

Returns the home directory for the current user,
or the one whose name is passed.

=back

=head1 COPYRIGHT

Copyright (c) 2010-2015 Josh Rabinowitz, All Rights Reserved.

=head1 AUTHORS

Josh Rabinowitz

=cut    

