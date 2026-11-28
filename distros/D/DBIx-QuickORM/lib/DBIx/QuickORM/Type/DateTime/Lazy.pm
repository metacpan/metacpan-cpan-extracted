package DBIx::QuickORM::Type::DateTime::Lazy;
use strict;
use warnings;

our $VERSION = '0.000031';

use DateTime();
use DateTime::TimeZone();
use Scalar::Util qw/blessed/;

use overload(
    '""'   => sub { $_[0]->string },
    'bool' => sub { 1 },
    '<=>'  => \&_compare,
    'cmp'  => \&_compare,
);

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Type::DateTime::Lazy - A DateTime built on first use.

=head1 DESCRIPTION

What L<DBIx::QuickORM::Type::DateTime> inflates to. It holds the value as the
database returned it and builds the L<DateTime> the first time one is needed.

It has three methods: C<datetime> (a copy to use and change), C<datetime_ref>
(the DateTime itself, read only), and C<string>. Call DateTime methods on one
of the first two:

    my $year = $at->datetime_ref->year;          # read: no copy
    my $next = $at->datetime->add(days => 1);    # change a copy
    $row->update({created => $next});

Comparisons work as DateTime's do, against a DateTime or another lazy value:
C<==>, C<< < >>, C<eq>, C<lt>, C<sort>, and the rest. Comparing with
anything else, such as a plain string, croaks.

With a DateTime on the left, DateTime's own comparison runs, and it croaks on
a lazy value. Put the lazy value first, or compare its C<datetime_ref>.

It stringifies to C<string>, an ISO 8601 form for display. It is always true.

A row hands out the same cached lazy value on every read (see
L<DBIx::QuickORM::Role::Type/Cached inflated values>), so never change the
DateTime C<datetime_ref> returns.

The object is a blessed closure, so dumps show only a code reference. A
fetched value that does not parse croaks when the DateTime is built, not when
it is fetched.

=head1 SYNOPSIS

    my $at   = $row->field('created');    # nothing parsed yet
    my $year = $at->datetime_ref->year;   # builds the DateTime once
    my $text = "$at";                     # 2024-02-03T04:05:06
    my $soon = $at < DateTime->now;       # compares the dates

=head1 PUBLIC METHODS

=over 4

=item $lazy = DBIx::QuickORM::Type::DateTime::Lazy->new(\&build, $kind)

A lazy value. C<build> returns the DateTime, and is called once, on first
need. C<$kind> is the field's: C<date>, C<timestamp>, or C<timestamptz>. It
picks the C<string> form.

=back

=cut

sub new {
    my $class = shift;
    my ($build, $kind) = @_;

    my $dt;
    return bless(sub { $_[0] ? $kind : ($dt //= $build->()) }, $class);
}

=pod

=over 4

=item $dt = $lazy->datetime

The DateTime: a copy, so changing it does not change this value.

=item $dt = $lazy->datetime_ref

The DateTime itself, without copying it. Fast, but discouraged: changing it
changes every reader's value. Use it only to read.

=back

=cut

sub datetime     { $_[0]->()->clone }
sub datetime_ref { $_[0]->() }

=pod

=over 4

=item $text = $lazy->string

The value in ISO 8601, for display. It is never sent to the database.

=over 4

=item *

A timestamp with time zone: C<YYYY-MM-DDTHH:MM:SS+HH:MM>.

=item *

A timestamp without one: the same without the offset.

=item *

A date: C<YYYY-MM-DD>.

=back

Fractional seconds follow the seconds when there are any. Croaks, as
C<datetime_ref> does, when the value does not parse.

=back

=cut

sub string {
    my $self = shift;
    my $dt   = $self->();
    my $kind = $self->('kind');
    return $dt->ymd if $kind eq 'date';

    my $out = $dt->ymd . 'T' . $dt->hms;
    $out .= sprintf('.%09d', $dt->nanosecond) =~ s/0+$//r          if $dt->nanosecond;
    $out .= DateTime::TimeZone->offset_as_string($dt->offset, ':') if $kind eq 'timestamptz';
    return $out;
}

=pod

=head1 PRIVATE METHODS

=over 4

=item $cmp = $lazy->_compare($other, $swapped)

The overloaded C<< <=> >> and C<cmp>: L<DateTime>'s C<compare>, which croaks
when C<$other> is not a DateTime. A lazy C<$other> counts as its DateTime.

=back

=cut

sub _compare {
    my ($self, $other, $swap) = @_;
    $other = $other->() if blessed($other) && $other->isa(__PACKAGE__);
    my $c = DateTime->compare($self->(), $other);
    return $swap ? -$c : $c;
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
