package DateTimeX::Role::Immutable;

# ABSTRACT: A role that can be composed into a DateTime subclass to make it immutable

use strict;
use warnings;
use Carp;
use Role::Tiny;
use Sub::Install;
use DateTime;
use namespace::autoclean;

our $VERSION = '0.36';

my %mutators = (
    add_duration      => 'plus_duration',
    subtract_duration => 'minus_duration',
    add               => 'plus',
    subtract          => 'minus',
    truncate          => 'trunc',
    set               => 'with_component',
    set_year          => 'with_year',
    set_month         => 'with_month',
    set_day           => 'with_day',
    set_hour          => 'with_hour',
    set_minute        => 'with_minute',
    set_second        => 'with_second',
    set_nanosecond    => 'with_nanosecond',
);
## Consider: set_time_zone set_locale set_formatter

before keys %mutators => sub {
    my $orig = shift;
    my $self = shift;

    croak "Attempted to mutate a DateTime object";
};

while ( my ( $orig_method, $new_method ) = each %mutators ) {
    Sub::Install::install_sub( {
            code => sub {
                my $self = shift;
                my $new_dt = DateTime->from_object( object => $self );
                $new_dt->$orig_method(@_);
                return bless $new_dt, ref $self;
            },
            as => $new_method,
        } );
}

# Methods that return a duration, but mutate during processing
for my $method (
    qw(delta_md delta_days delta_ms subtract_datetime subtract_datetime_absolute)
  )
{
    Sub::Install::install_sub( {
            code => sub {
                my $dt1 = DateTime->from_object( object => shift );
                my $dt2 = DateTime->from_object( object => shift );
                return $dt1->$method( $dt2, @_ );
            },
            as => $method,
        } );
}

# Need to replace today, as the DateTime
sub today { shift->now(@_)->trunc( to => 'day' ) }

1;

__END__

=pod

=head1 NAME

DateTimeX::Role::Immutable - A role that can be composed into a DateTime subclass to make it immutable

=head1 VERSION

version 0.36

=head1 SYNOPSIS

    package Your::DateTime;
    use base 'DateTime';
    use Role::Tiny::With;
    with 'DateTimeX::Role::Immutable';

=head1 DESCRIPTION

This is role that can be composed into a L<DateTime> subclass to make those
objects immutable. The C<set> methods are replaced with new methods that leave
the original object untouched, and return a new DateTime object with the
expected changes.

The following methods now thrown an exception:

    $dt->add_duration()
    $dt->subtract_duration()
    $dt->add()
    $dt->subtract()
    $dt->set()
    $dt->set_year()
    $dt->set_month()
    $dt->set_day()
    $dt->set_hour()
    $dt->set_minute()
    $dt->set_second()
    $dt->set_nanosecond()
    $dt->truncate()

and are replaced by these methods which return the changed value:

    $dt->plus_duration()
    $dt->minus_duration()
    $dt->plus()
    $dt->minus()
    $dt->with_component()
    $dt->with_year()
    $dt->with_month()
    $dt->with_day()
    $dt->with_hour()
    $dt->with_minute()
    $dt->with_second()
    $dt->with_nanosecond()
    $dt->trunc()

At the moment, C<set_time_zone>, C<set_locale>, and C<set_formatter> continue
to act as mutators. DateTime uses these internally and changing them creates
unexpected behavior. These methods also do not really change the time value.

See L<DateTime> for the rest of the documentation.

=head1 SEE ALSO

L<DateTimeX::Role::Immutable>, L<DateTime>, L<DateTime::Moonpig>,
L<Time::Moment>

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
