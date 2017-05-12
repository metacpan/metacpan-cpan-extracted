package DateTime::Span::Birthdate;

use strict;
use base qw( DateTime::Span );
our $VERSION = '0.03';

use Carp;
use DateTime;
use DateTime::Span;

sub new {
    my $class = shift;
    my %p     = @_;

    $p{on} ||= DateTime->now;

    my @dates;
    if ($p{from} && $p{to}) {
        @dates = $class->_from_array($p{from}, $p{to}, $p{on});
    } elsif ($p{age}) {
        @dates = $class->_from_age($p{age}, $p{on});
    } else {
        croak "DateTime::Span::Birthdate->new() requires from, to or age parameter";
    }

    return $class->from_datetimes( start => $dates[0], end => $dates[1] );
}

sub _from_array {
    my($class, $from, $to, $dt) = @_;

    my $start = $dt->clone->subtract(years => $to + 1, days => -1);
    my $end   = $dt->clone->subtract(years => $from);

    return ($start, $end);
}

sub _from_age {
    my($class, $age, $dt) = @_;

    my $start = $dt->clone->subtract(years => $age + 1, days => -1);
    my $end   = $dt->clone->subtract(years => $age);

    return ($start, $end);
}

1;
__END__

=for stopwords SQL datetime

=head1 NAME

DateTime::Span::Birthdate - Date span of birthdays for an age

=head1 SYNOPSIS

  use DateTime::Span::Birthdate;

  # birthday span for people who are 28 years old today
  my $span = DateTime::Span::Birthdate->new(age => 28);

  # birthday span for 20 years old in $dt
  my $span = DateTime::Span::Birthdate->new(age => 28, on => $dt);

  # birthday span for teenagers
  my $span = DateTime::Span::Birthdate->new(from => 13, to => 19);

=head1 DESCRIPTION

DateTime::Span::Birthdate is a port of Date::Range::Birth module and works
with DateTime::Span object. This module allows you to say "who is now
28 years old, based on their birthday dates?"

This would be particularly useful when you build an SQL query to, say,
select teenagers from your customers database which has 'birthday'
datetime column.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<DateTime::Span>, L<Date::Range::Birth>

=cut
