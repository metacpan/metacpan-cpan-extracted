package Date::Holidays::GB::EAW;

our $VERSION = '0.020'; # VERSION

use strict;
use warnings;

use Date::Holidays::GB;

use base qw( Exporter );
our @EXPORT_OK = qw(
  holidays
  is_holiday
);

sub holidays {
    my %args
        = $_[0] =~ m/\D/
        ? @_
        : ( year => $_[0] );

    return Date::Holidays::GB::holidays( %args, regions => [ 'EAW' ] );
}

sub is_holiday {
    my %args
        = $_[0] =~ m/\D/
        ? @_
        : ( year => $_[0], month => $_[1], day => $_[2] );

    return Date::Holidays::GB::is_holiday( %args, regions => [ 'EAW' ] );
}

1;

__END__

=head1 NAME

Date::Holidays::GB::EAW - Date::Holidays class for GB-EAW (England & Wales)

=head1 SYNOPSIS

    use Date::Holidays::GB::EAW qw( holidays is_holiday );

    # All holidays for England & Wales
    my $holidays = holidays( year => 2013 );

    if ( is_holiday( year => 2013, month => 12, day => 25 ) ) {
        print "No work today!";
    }

=cut

