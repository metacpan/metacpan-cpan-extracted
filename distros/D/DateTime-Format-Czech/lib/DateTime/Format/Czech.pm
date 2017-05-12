package DateTime::Format::Czech;
BEGIN {
  $DateTime::Format::Czech::VERSION = '0.2';
}

use utf8;
use Moose;

=encoding utf-8

=head1 SYNOPSIS

Format your DateTime values as usual in Czech. Now also
with month names, day names and less sugar!

=head1 DESCRIPTION

    my $fmt = DateTime::Format::Czech->new;
    my $date = DateTime->new(year => 2010, month => 6, day => 13);
    say $fmt->format_datetime($date); # 13. června 2010

=head1 ATTRIBUTES

=over 4

=item B<show_time>

Include time in the output. Off by default.

=item B<show_date>

Include date in the output. On by default.

=item B<show_year>

Include year in the date output (“1. 12. 2010”). Off by default.

=item B<show_day_name>

Include day name in date output (“neděle 13. 6.”). Off by
default.

=item B<show_month_name>

Use month name instead of its number (“1. prosince 2010”).
On by default.

=item B<compound_format>

The C<sprintf> pattern used to glue the time and date parts.
The default value is C<%s v %s> (“5. 6. v 16.30”).

=back

=cut

has show_time => (is => 'ro', isa => 'Bool', default => 0);
has show_date => (is => 'ro', isa => 'Bool', default => 1);
has show_year => (is => 'ro', isa => 'Bool', default => 0);
has show_day_name => (is => 'ro', isa => 'Bool', default => 0);
has show_month_name => (is => 'ro', isa => 'Bool', default => 1);
has compound_format => (is => 'ro', isa => 'Str', default => '%s v %s');

my @MONTH_NAMES = qw/
    ledna února března dubna
    května června července srpna září
    října listopadu prosince/;

my @DAY_NAMES = qw/
    pondělí úterý středa čtvrtek
    pátek sobota neděle/;

=head1 METHODS

=over 4

=item B<format_date>

Takes a L<DateTime> value, returns a string representation
of its date part.

=cut

sub format_date
{
    my ($self, $date) = @_;
    my $output = $self->show_month_name ?
        join('. ', $date->day, $MONTH_NAMES[$date->month_0]) :
        sprintf '%i. %i.', $date->day, $date->month;
    $output = $DAY_NAMES[$date->wday_0] . ' ' . $output if $self->show_day_name;
    $output .= ' ' . $date->year if $self->show_year;
    return $output;
}

=item B<format_time>

Takes a L<DateTime> value, returns a string representation
of its time part in 24-hour time system. Minutes are zero-padded
if needed (“13.00”, “19.01”).

=cut

sub format_time
{
    my ($self, $date) = @_;
    return sprintf '%i.%02i', $date->hour, $date->minute;
}

=item B<format_datetime>

Formats a given L<DateTime> value, returning date and time parts
as configured by the C<show_date> and C<show_time> attributes. The
date and time parts are glued together using the C<compound_format>
pattern. You can also call this method using the shorter C<format>
name.

=back

=cut

sub format_datetime
{
    my ($self, $date) = @_;
    if ($self->show_time && $self->show_date) {
        return sprintf $self->compound_format,
            $self->format_date($date), $self->format_time($date);
    }
    return $self->format_date($date) if $self->show_date;
    return $self->format_time($date);
}

sub format {
    return shift->format_datetime(@_);
}

=head1 AUTHOR

Tomáš Znamenáček, zoul@fleuron.cz

=cut

'SDG';
