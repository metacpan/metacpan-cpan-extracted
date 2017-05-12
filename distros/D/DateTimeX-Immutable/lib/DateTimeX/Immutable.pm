package DateTimeX::Immutable;

# ABSTRACT: An immutable subclass of DateTime

use strict;
use warnings;
use base 'DateTime';
use Role::Tiny::With;
use namespace::autoclean;

our $VERSION = '0.36';

with 'DateTimeX::Role::Immutable';

sub st { return shift->strftime("%FT%T%Z"); }
sub dt { return shift->st; }

1;

__END__

=pod

=head1 NAME

DateTimeX::Immutable - An immutable subclass of DateTime

=head1 VERSION

version 0.36

=for html <img src="https://travis-ci.org/mvgrimes/DateTimeX-Immutable.svg?branch=master" alt="Build Status">

=head1 SYNOPSIS

    use DateTimeX::Immutable;
    my $now = DateTimeX::Immutable->now;  # 2012-12-12T11:15:10
    my $day = $now->with_hour( 0 )->with_minute( 0 )->with_second( 0 );
    say $now;           # 2012-12-12T11:15:10
    say $day;           # 2012-12-12T00:00:00
    $now->set_day( 1 ); # throws an exception

or with aliased:

    use aliased 'DateTimeX::Immutable' => 'DateTime';
    my $now = DateTime->now;  # 2012-12-12T11:15:10
    my $day = $now->with_hour( 0 )->with_minute( 0 )->with_second( 0 );
    say $now;           # 2012-12-12T11:15:10
    say $day;           # 2012-12-12T00:00:00
    $now->set_day( 1 ); # throws an exception

=head1 DESCRIPTION

This is subclass of L<DateTime> which throws an exception when methods that
modify the object are called. Those methods are replaced with new methods that
leave the original object untouched, and return a new C<DateTimeX::Immutable>
object with the expected changes.

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

=head1 WHY

Reasons why this module eixsts:

=over 4

=item Mutability is bad!

=item DateTime::Moonpig: Great idea but changes too much. We still want to be to truncate,
set_*, etc, we just want the result returned. Changing the math goes beyond
the scope of our needs. No integration with DBIC.

=item Time::Moment: Excellent, but for code that already uses DateTime we want
to continue. Also, Time::Moment's plugin for DBIC doesn't support native db
date formats.

=back

(TODO: Expand on explanation for this module's existence.)

=head1 SEE ALSO

L<DateTime>, L<DateTime::Moonpig>, L<Time::Moment>

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
