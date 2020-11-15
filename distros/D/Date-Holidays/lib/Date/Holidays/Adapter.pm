package Date::Holidays::Adapter;

use strict;
use warnings;
use Carp; # croak
use TryCatch;
use Module::Load qw(load);
use Locale::Country;
use Scalar::Util qw(blessed);

use vars qw($VERSION);

$VERSION = '1.29';

sub new {
    my ($class, %params) = @_;

    my $self = bless {
        _countrycode => $params{countrycode},
        _adaptee     => undef,
    }, $class || ref $class;

    my $adaptee = $self->_fetch(\%params);

    if ($adaptee) {
        $self->{_adaptee} = $adaptee;
    } else {
        die 'Unable to initialize adaptee class';
    }

    return $self;
}

sub holidays {
    my ($self, %params) = @_;

    my $r;
    my $adaptee;

    # Adaptee has a constructor
    if (    $self->{_adaptee}->can('new')
        and $self->isa('Date::Holidays::Adapter')) {

        $adaptee = $self->{_adaptee}->new();

    # Adaptee has no constructor
    } else {
        $adaptee = $self->{'_adaptee'};
    }

    if (blessed $adaptee) {

        # Adapting non-polymorphic interface
        my $method = "$self->{'_countrycode'}_holidays";
        my $sub = $adaptee->can($method);

        # Adapting polymorphic interface
        if (! $sub) {
            $method = 'holidays';
            $sub = $adaptee->can($method);
        }

        if ($sub) {
            $r = $adaptee->$method($params{'year'});
        }

        return $r;

    } else {

        # Adapting non-polymorphic interface
        my $method = "$self->{'_countrycode'}_holidays";
        my $sub = $adaptee->can($method);

        # Adapting polymorphic interface
        if (! $sub) {
            $sub = $adaptee->can('holidays');
        }

        if ($sub) {
            $r = &{$sub}($params{'year'});
        }

        return $r;
    }
}

sub is_holiday {
    my ($self, %params) = @_;

    my $r;
    my $adaptee;

    if (    $self->{'_adaptee'}->can('new')
        and $self->isa('Date::Holidays::Adapter')) {

        $adaptee = $self->{'_adaptee'}->new();

    } else {
        $adaptee = $self->{'_adaptee'};
    }

    if (blessed $adaptee) {

        # Adapting non-polymorphic interface
        my $method = "is_$self->{'_countrycode'}_holiday";

        if ($adaptee->can($method)) {

            $r = $adaptee->$method(
                $params{'year'},
                $params{'month'},
                $params{'day'}
            );

            return $r;

        # Adapting polymorphic interface
        } else {

            if ($adaptee->can('is_holiday')) {
                $r = $adaptee->is_holiday(
                    $params{'year'},
                    $params{'month'},
                    $params{'day'}
                );
            }

            return $r;
        }

    } else {
        # Adapting non-polymorphic interface
        my $method = "is_$self->{_countrycode}_holiday";
        my $sub = $adaptee->can($method);

        # We have an interface
        if ($sub) {

            $r = &{$sub}(
                $params{'year'},
                $params{'month'},
                $params{'day'}
            );

            return $r;
        }

        # Adapting polymorphic interface
        $sub = $adaptee->can('is_holiday');

        if ($sub) {
            $r = &{$sub}(
                $params{'year'},
                $params{'month'},
                $params{'day'}
            );

            return $r;
        }
    }

    return $r;
}

sub _load {
    my ( $self, $module ) = @_;

    # Trying to load module
    eval { load $module; }; # From Module::Load

    # Asserting success of load
    if ($@) {
        die "Unable to load: $module - $@\n";
    }

    # Returning name of loaded module upon success
    return $module;
}

sub _fetch {
    my ( $self, $params ) = @_;

    # Do we have a country code?
    if ( not $self->{'_countrycode'} and not $params->{countrycode} ) {
        croak 'No country code specified';
    }

    my $countrycode = $params->{countrycode} || $self->{'_countrycode'};

    # Do we do country code assertion?
    if ( !$params->{'nocheck'} ) {

        # Is our country code valid or local?
        if ( $countrycode !~ m/local/i and !code2country( $countrycode ) ) {  #from Locale::Country
            die "$countrycode is not a valid country code";
        }
    }

    # Trying to load adapter module for country code
    my $module;

    try {
        # We load an adapter implementation
        if ( code2country( $countrycode ) ) {
            $module = 'Date::Holidays::' . uc $countrycode;
        } else {
            $module = 'Date::Holidays::' . $countrycode;
        }

        $module = $self->_load($module);

    } catch ($error) {
        warn "Unable to load module: $module - $error";

        try {
            #$countrycode = uc $countrycode;

            if ($countrycode =~ m/local/i) {
                $module = 'Date::Holidays::Local';
            } else {
                $module = 'Date::Holidays::' . $countrycode;
            }

            # We load an adapter implementation

            if ($module = $self->_load($module)) {
                warn "we got a module and we return\n";
            }

        } catch ($error) {
            warn "Unable to load module: $module - $error";

            $module = 'Date::Holidays::Adapter';
            $module = $self->_load($module);
        };
    };

    # Returning name of loaded module upon success
    return $module;
}

1;

__END__

=pod

=head1 NAME

Date::Holidays::Adapter - an adapter class for Date::Holidays::* modules

=head1 VERSION

This POD describes version 1.25 of Date::Holidays::Adapter

=head1 SYNOPSIS

    my $adapter = Date::Holidays::Adapter->new(countrycode => 'NO');

    my ($year, $month, $day) = (localtime)[ 5, 4, 3 ];
    $year  += 1900;
    $month += 1;

    print "Woohoo" if $adapter->is_holiday( year => $year, month => $month, day => $day );

    my $hashref = $adapter->holidays(year => $year);
    printf "Dec. 24th is named '%s'\n", $hashref->{'1224'}; #christmas I hope

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

=head1 DEVELOPING A DATE::HOLIDAYS::* ADAPTER

If you want to develop an adapter compatible with interface specified in this
class. You have to implement the following 3 methods:

=over

=item new

A constructor, taking a single argument a two-letter countrycode
(SEE: L<Locale::Country>)

You can also inherit the one implemented and offered by this class

B<NB>If inheritance is used, please remember to overwrite the two following
methods, if applicable.

=item holidays

This has to follow the API outlined in SUBROUTINES/METHODS.

For the adaptee class anything goes, hence the use of an adapter.

Please refer to the DEVELOPER section in L<Date::Holidays> about contributing to
the Date::Holidays::* namespace or attempting for adaptability with
L<Date::Holidays>.

=item is_holiday

This has to follow the API outlined in SUBROUTINES/METHODS.

For the adaptee class anything goes, hence the use of an adapter.

Please refer to the DEVELOPER section in L<Date::Holidays> about contributing to
the Date::Holidays::* namespace or attempting for adaptability with
L<Date::Holidays>.

=back

Apart from the methods described above you can also overwrite the _fetch method
in this class, This is used if your module is not a part of the
Date::Holidays::* namespace or the module bears a name which is not ISO3166
compliant.

See also:

=over

=item * L<Date::Holidays::UK>

=item * L<Date::Japanese::Holiday>

=back

=head1 DIAGNOSTICS

=over

=item * L<Date::Holidays::Exception::AdapterLoad>

Exception thrown in the case where the B<_load> method is unable to load a
requested adapter module.

The exception is however handled internally.

=item * L<Date::Holidays::Exception::AdapterInitialization>

Exception thrown in the case where the B<_new> method is unable to
initialize a requested adapter module.

=item * L<Date::Holidays::Exception::UnsupportedMethod>

Exception thrown in the case where the loaded and initialized module does not
support the called method. (SEE: METHODS/SUBROUTINES).

=back

=head1 DEPENDENCIES

=over

=item * L<Carp>

=item * L<Module::Load>

=item * L<TryCatch>

=item * L<Locale::Country>

=item * L<Scalar::Util>

=back

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

Date-Holidays and related modules are released under the Artistic License 2.0


=cut
