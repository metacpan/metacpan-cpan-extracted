package DateTime::Format::GeekTime;
use 5.005;
use strict;
use warnings;
use DateTime;
use Carp;
use vars '$VERSION';

$VERSION='1.001';
$VERSION=eval $VERSION;

sub new {
    my ($class,$year)=@_;

    if (!defined $year) {
        $year = DateTime->now->year;
    }

    return bless {year=>$year},$class;
}

sub parse_datetime {
    my ($self,$string)=@_;

    my ($seconds,$days) =
        ($string =~ m{\A \s*
                      (?:0x)? ( [0-9a-fA-F]{4} )
                      (?: [\w\s]*? )
                      (?:0x)? ( [0-9a-fA-F]{3,4} )
                      (?: \s+ .)?  # optional character representation
                      \s* \z}smx);
    if (!(defined $seconds and defined $days)) {
        croak "<$string> is not a proper GeekTime string";
    }

    $seconds=hex($seconds);$days=hex($days);

    $seconds=int($seconds*86_400/65_536+0.5);

    my $base_year;
    if (ref($self)) {
        $base_year=$self->{year};
    }
    else {
        $base_year=DateTime->now->year;
    }

    my $dt=DateTime->new(year=>$base_year,time_zone=>'UTC');
    $dt->add(days=>$days,seconds=>$seconds);

    return $dt;
}

sub format_datetime {
    my ($self,$dt)=@_;

    my $start_of_day=$dt->clone->set_time_zone('UTC')->truncate(to=>'day');

    my $seconds=$dt->subtract_datetime_absolute($start_of_day)->in_units('seconds');

    my $days=$dt->day_of_year - 1;

    $seconds=int($seconds/86_400*65_536+0.5);

    my $chr = $seconds <= 0xD800 || $seconds >= 0xDFFF
        ? ' '.chr($seconds)
        : '';

    return sprintf '0x%04X on day 0x%03X%s',$seconds,$days,$chr;
}

1;
__END__

=head1 NAME

DateTime::Format::GeekTime - parse and format GeekTime

=head1 SYNOPSIS

  use DateTime::Format::GeekTime;
  use DateTime;

  my $dt=DateTime->now();
  print DateTime::Format::GeekTime->format_datetime($dt);

  $dt=DateTime::Format::GeekTime->parse_datetime('0xBA45 on day 0x042');

  $dt=DateTime::Format::GeekTime->new(2010)
        ->parse_datetime('0xBA45 on day 0x042');

=head1 DESCRIPTION

This module formats and parses "GeekTime". See L<http://geektime.org/>
for the inspiration.

=head1 METHODS

=over 4

=item C<new>

  my $dtf=DateTime::Format::GeekTime->new(2010);

The single optional parameter to C<new> is the year to use for
parsing. Since GeekTime does not carry this information, we have to
supply it externally. If you don't specify it, or if you call
C<parse_datetime> as a class method, the current yuor will be used.

=item C<format_datetime>

  my $string=DateTime::Format::GeekTime->format_datetime($dt);

Returns the full GeekTime string, like C<0x0041 on day 0x042 A>.

Note the character at the end of the string: it's the character
corresponding to the Unicode codepoint with the same value as the
first word in the string. If the codepoint corresponds to a "high
surrogate" or a "low surrogate", the character (and the preceding
space) will not be returned.

=item C<parse_datetime>

  my $dt=DateTime::Format::GeekTime->parse_datetime('0xb4b1 0x0042');

Parses a GeekTime and returns a C<DateTime> object.

The parsing is somewhat lenient: you can omit the C<0x>, you can
express the day as 3 or 4 digits, all space is optional (as is the "on
day" in the middle). The character after the day number is ignored, if
present.

=back

=head1 NOTES

Since GeekTime divides the day in 65536 intervals, but we usually
divide it in 86400 seconds, don't expect all times to round-trip
correctly: some loss of precision is to be expected. Note that going
from GeekTime to a C<DateTime> object and back to GeekTime is
guaranteed to give you the same numbers you started from. Going the
other way can lose one second.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

GeekTime http://geektime.org/ http://twitter.com/geektime

=head1 COPYRIGHT and LICENSE

This program is E<copy> 2010 Gianni Ceccarelli. This library is free
software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

http://geektime.org/

L<DateTime>

=cut
