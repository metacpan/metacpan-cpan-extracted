package CGI::Session::Driver::aggregator::Drivers;

# $Id$

=head1 NAME

 CGI::Session::Driver::aggregator::Drivers - Drivers container for CGI::Session::Driver::aggregator

=cut

use strict;
use Carp qw(croak);

sub new { bless { drivers => [] }, shift }

=head1 METHODS

=cut

=head2 add($driver_name, $driver_arguments)

Adding a driver with extra arguments. driver_arguments will be used to instanctiate the driver. The driver must be an instance of CGI::Session::Driver.

 $drivers = CGI::Session::Driver::aggregator::Drivers->new;
 $drivers->add('file', { Directory => '/tmp' });
 $drivers->add('mysql', { Handle => $dbh });

NOTE: session data is read from drivers in the added order. In above example, reading from 'file' first, and then from 'mysql' (only when cannot read from 'file'). On the other hand, When writing session data, the order is 'mysql' -> 'file'.

=cut
sub add {
    my ($self, $name, $args) = @_;
    $name = lc $name;

    my $package = "CGI::Session::Driver::$name";
    if (!exists $INC{$package}) {
        eval "require $package";
        if ($@) {
            croak "Failed to load a driver: $@";
        }
    }

    push @{ $self->{drivers} }, { package => $package, args => $args };
}

sub drivers { @{ shift->{drivers} } }

1;
