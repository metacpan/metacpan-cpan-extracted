package Date::Holidays::Adapter::Local;

use strict;
use warnings;
use File::Slurp qw(slurp);
use JSON; #from_json
use Env qw($HOLIDAYS_FILE);
use vars qw($VERSION);

$VERSION = '1.25';

sub new {
    my $class = shift;

    my $self = bless {}, $class;

    return $self;
};

sub holidays {
    my ($self, %params) = @_;

    my $local_holiday_file = $self->_resolve_holiday_file();

    my $local_holidays;
    if (-r $local_holiday_file) {

        my $json = slurp($local_holiday_file);
        $local_holidays = from_json($json);
    }

    my $filtered_holidays = {};

    if ($params{date} and $params{month} and $params{year}) {

        foreach my $key (keys %{$local_holidays}) {

            if ($key =~ m/^(\d{4})(\d{2})(\d{2})$/
                    and $1 == $params{year}
                    and $2 == $params{month}
                    and $3 == $params{day}) {

                $filtered_holidays->{$key} = $local_holidays->{$key};

            } elsif ($key =~ m/^(\d{2})(\d{2})$/
                    and $1 == $params{month}
                    and $2 == $params{day}) {

                $filtered_holidays->{$key} = $local_holidays->{$key};
            }
        }

        return $filtered_holidays;

    } else {
        return $local_holidays;
    }
}

sub is_holiday {
    my ($self, %params) = @_;

    my $holidays = $self->holidays(%params);

    # First we check if a year is specified
    my $key = $params{year}.$params{month}.$params{day};

    if (defined $holidays->{$key}) {
        return $holidays->{$key};
    }

    # Then we check if just month and day is specified

    $key = $params{month}.$params{day};

    if (defined $holidays->{$key}) {
        return $holidays->{$key};
    }

    # no holiday defined
    return undef;
}

sub _resolve_holiday_file {
    my $self = shift;

    my $filename = '';

    if (-e $HOLIDAYS_FILE and -f _) {
        $filename = $HOLIDAYS_FILE;
    }
}

1;

__END__

=pod

=head1 NAME

Date::Holidays::Adapter::Local - a specialized adapter for local calendars

=head1 VERSION

This POD describes version 1.25 of Date::Holidays::Adapter::Local

=head1 SYNOPSIS

    my $calendar = Date::Holidays->new(countrycode => 'local');

    my ($year, $month, $day) = (localtime)[ 5, 4, 3 ];
    $year  += 1900;
    $month += 1;

    print "Woohoo" if $calendar->is_holiday(
        year  => $year,
        month => $month,
        day   => $day
    );

    my $holidays = $adapter->holidays(year => $year);

    printf "Jan. 15th is named '%s'\n", $holidays->{'0115'}; #my birthday I hope

=head1 DESCRIPTION

The is the SUPER adapter class. All of the adapters in the distribution of
Date::Holidays are subclasses of this class. (SEE also L<Date::Holidays>).

The SUPER adapter class is at the same time a generic adapter. It attempts to
adapt to the most used API for modules in the Date::Holidays::* namespace. So
it should only be necessary to implement adapters to the exceptions to modules
not following the the defacto standard or suffering from other local
implementations.

=head1 SUBROUTINES/METHODS

The public methods in this class are all expected from the adapter, so it
actually corresponds with the abstract is outlined in L<Date::Holidays::Abstract>.

Not all methods/subroutines may be implemented in the adaptee classes, the
adapters attempt to make the adaptee APIs adaptable where possible. This is
afterall the whole idea of the Adapter Pattern, but apart from making the
single Date::Holidays::* modules uniform towards the clients and
L<Date::Holidays> it is attempted to make the multitude of modules uniform in
the extent possible.

=head2 new

The constructor, takes a single named argument, B<countrycode>

=head2 is_holiday

The B<holidays> method, takes 3 named arguments, B<year>, B<month> and B<day>

returns an indication of whether the day is a holiday in the calendar of the
country referenced by B<countrycode> in the call to the constructor B<new>.

=head2 holidays

The B<holidays> method, takes a single named argument, B<year>

returns a reference to a hash holding the calendar of the country referenced by
B<countrycode> in the call to the constructor B<new>.

The calendar will spand for a year and the keys consist of B<month> and B<day>
concatenated.

=head1 DEFINING A LOCAL CALENDAR

Please refer to the DEVELOPER section in L<Date::Holidays> about contributing to
the Date::Holidays::* namespace or attempting for adaptability with
L<Date::Holidays>.

=head1 DIAGNOSTICS

Please refer to DIAGNOSTICS in L<Date::Holidays>

=head1 DEPENDENCIES

=over

=item * L<Carp>

=item * L<Module::Load>

=item * L<JSON>

=item * L<File::Slurp>

=back

Please see the F<cpanfile> included in the distribution for a complete listing.

=head1 INCOMPATIBILITIES

Please refer to INCOMPATIBILITIES in L<Date::Holidays>

=head1 BUGS AND LIMITATIONS

Please refer to BUGS AND LIMITATIONS in L<Date::Holidays>

=head1 BUG REPORTING

Please refer to BUG REPORTING in L<Date::Holidays>

=head1 AUTHOR

Jonas B. Nielsen, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

L<Date::Holidays> and related modules are (C) by Jonas B. Nielsen, (jonasbn)
2004-2020

L<Date::Holidays> and related modules are released under the Artistic License 2.0

=cut
