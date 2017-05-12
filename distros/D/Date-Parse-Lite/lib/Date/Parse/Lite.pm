package Date::Parse::Lite;

use 5.008_001;
use strict;
use warnings FATAL => 'all';
use Carp;

=head1 NAME

Date::Parse::Lite - Light weight parsing of human-entered date strings

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Parse human-entered strings that are intended to contain dates and attempt
to extract machine-readable date information from them while being as
generous as possible with format interpretation.

    use Date::Parse::Lite;

    my $parser = Date::Parse::Lite->new();
    $parser->parse('June 1st 17');

    if($parser->parsed()) {
        my $day = $parser->day();

    ...

=head1 DESCRIPTION

This simple module attempts to parse a day, a month and a year from a string
on the assumption that the string is intended to represent a date. Note that
it does B<not> validate the date except to the extent that doing so informs the
parsing, e.g. numbers in the range 13 to 31 will be parsed as days rather than
months but 31 will still be parsed as a day even when the month is 2. The
responsibility for validating the results and/or representing them in a more
useful form remains with the caller, if it is interested in doing so.

The parser will extract dates from a wide range of inputs, including a lot
which would not look like dates to a human reader. The intention is to
maximise the likelihood that a date entered by a human being will be accepted
as such without the need to place difficult restrictions on what may be
entered. To add to the flexibility there are some configuration options. These
are described with their corresponding methods, below.

The API is entirely object oriented - you must instantiate an object, which
will encapsulate the configuration and the strings to be parsed, and then
query that object to get the results.

=head1 DATE FORMATS

The parser is very forgiving about date formats - anything that's not a string
of digits or letters is essentially treated as a separator and then the remaining
numbers and words are understood as a day, month and year with words describing
months taken as priority over numbers. Any trailing text is ignored and any
amount of non-alphanumeric text may surround and separate the recognised parts.
While this means that a wide range of formats are accepted it does also mean
that the fact that this parser was able to extract date information from a string
does not guarantee that the string would have looked like a date to a human
observer. The parser is founded on the assumption that the string to be parsed
is intended to be a date.

There is a single special case: a string of 8 digits, with or without leading
and/or trailing whitespace, is treated as YYYYMMDD.

=head1 METHODS

=head2 new([param => $value [, ...]])

Create a new parser object. You may pass in a hash to initialise the object
with the following keys:

=over

=item prefer_month_first_order

=item literal_years_below_100

=item month_names

Initialise the configuration set by the methods of the same names -
see below.

=item date

A string to be parsed - this will be passed to the C<parse> method.
Note that this is optional; you can just call C<parse> later (and
repeatedly) if you wish.

=back

=cut

sub new {
    my $invocant = shift;
    my %params = @_;

    my $self = bless {}, ref $invocant || $invocant;
    $self->prefer_month_first_order(1);
    $self->_set_default_month_names;
    $self->_reset;
    foreach my $initialiser (qw{prefer_month_first_order literal_years_below_100 month_names date}) {
        $self->$initialiser($params{$initialiser}) if exists $params{$initialiser};
    }
    return $self;
}

sub _reset {
    my $self = shift;

    delete @$self{qw{day month year parsed _possible_month_or_day}};
}

sub _set_default_month_names {
    my $self = shift;

    $self->{_month_names} = [
        january     =>  1,
        february    =>  2,
        march       =>  3,
        april       =>  4,
        may         =>  5,
        june        =>  6,
        july        =>  7,
        august      =>  8,
        september   =>  9,
        october     => 10,
        november    => 11,
        december    => 12,
    ];
}

=head2 day()

Returns the day parsed from the date string, if any. This will be a
number in the range 1 to 31 if the parse was succesful.

=head2 month()

Returns the month parsed from the date string, if any. This will be
a number in the range 1 to 12 if the parse was succesful.

=head2 year()

Returns the year parsed from the date string, if any. This will be
a number if the parse was succesful.

=head2 parsed()

Reaturns a flag indicating whether a date has been successfully parsed
from a string.

=cut

sub day     { return shift->_access('day'); }
sub month   { return shift->_access('month'); }
sub year    { return shift->_access('year'); }
sub parsed  { return shift->_access('parsed'); }
sub _access {
    my $self = shift;
    my($attr) = @_;

    return $self->{$attr};
}

=head2 prefer_month_first_order([$flag])

Returns a flag indicating how day-month order ambiguity will be resolved,
e.g. in a date like C<1/2/2015>. Defaults to true so that American dates are
parsed as expected. You may optionally pass a value to set the flag.

=head2 literal_years_below_100([$flag])

Returns a flag indicating whether years below 100 will be interpreted literally
(i.e. as being in the first century). If this is not set then such years
will be intepreted as being the one nearest the system date that suits,
e.g. in 2015 the year C<15> is interpreted as 2015, C<50> as 2050 and
C<90> as 1990. Defaults to false. You may optionally pass a value to set
the flag.

=cut

sub prefer_month_first_order { return shift->_mutate_bool('prefer_month_first_order', @_); }
sub literal_years_below_100  { return shift->_mutate_bool('literal_years_below_100', @_); }
sub _mutate_bool {
    my($self, $attr) = (shift, shift);

    $self->{$attr} = ! ! $_[0] if @_;
    return exists $self->{$attr} ? $self->{$attr} : '';
}

=head2 parse($string)

Parse a string and attempt to extract a date. Returns a success flag
(see the C<parsed> method). You can call this as many times as you like if
you need to parse multiple strings. The results available from the methods
described above will always be for the most recently parsed date string.

=cut

sub date { &parse; }
sub parse {
    my $self = shift;
    my($string) = @_;

    $self->_reset;
    my $tokens = _extract_tokens($string);
    $self->_parse_tokens($tokens) if @$tokens >= 3;

    delete @$self{qw{day month year}} unless $self->parsed;

    return $self->parsed;
}

=head2 month_names($name => $number [, ...])

Add new names to be recognised as months, typically for internationalisation. You
may pass an array with an even number of elements or a reference to the same. Month
names are matched by comparing the number of characters found in the
parsed string with the same number of characters at the start of the names
provided through this method. Thus abreviations are understood as long as they
are intial sections of the provided names. Other abbreviations must be specified
separately - you may pass as many names with the same month number as you
wish. Comparisons are case-insensitive.

Multiple calls to this method will add to the list of names - to reset the list
you must create a new object but note that all objects include the twelve
common English month names. This means that you won't have much luck with
languages that have the same names, or abbreviations of them, for different
months. I don't know of any such though.

=cut

sub month_names {
    my $self = shift;
    my @params = ref $_[0] ? @{$_[0]} : @_;

    while(@params > 1) {
        my($month_name, $month_number) = splice @params, 0, 2;
        $month_name ||= '';
        croak "Month name '$month_name' should be more than two characters" unless length $month_name > 2;
        $month_number ||= 0;
        croak "Invalid month number '$month_number'" unless $month_number >= 1 && $month_number <= 12;
        push @{$self->{_month_names}}, lc $month_name, $month_number;
    }
}

sub _extract_tokens {
    my($string) = @_;

    $string = '' unless defined $string;
    return [$1, $2, $3] if $string =~ m{^\s*(\d\d\d\d)(\d\d)(\d\d)\s*$};
    return [ $string =~ m{[[:alpha:]]+|\d+}ig ];
}

sub _parse_tokens {
    my $self = shift;
    my($tokens) = @_;

    foreach my $token (@$tokens) {
        return unless $self->_process_token($token);
        if($self->day && $self->month && defined $self->year) {
            $self->{parsed} = 1;
            last;
        }
    }
}

sub _process_token {
    my $self = shift;
    my($token) = @_;

    if($token =~ m{^\d+$}) {
        return $self->_process_numeric_token($token);
    }
    else {
        return $self->_process_word_token($token);
    }
}

sub _process_numeric_token {
    my $self = shift;
    my($token) = @_;

    if($token > 31 || $token == 0 || length $token > 2 || ($self->month && $self->day)) {
        return 0 if defined $self->year;
        $self->_set_year($token + 0);
        return 1;
    }
    else {
        return $self->_process_month_or_day_token($token + 0);
    }
}

sub _set_year {
    my $self = shift;
    my($year) = @_;

    if($year < 100 && ! $self->literal_years_below_100) {
        my $this_year = 1900 + (localtime)[5];
        $year += $this_year - $this_year % 100;
        $year -= 100 if $year > $this_year + 50;
    }
    $self->{year} = $year;
}

sub _process_month_or_day_token {
    my $self = shift;
    my($token) = @_;

    if($token > 12) {
        return 0 if $self->day;
        $self->{day} = $token;
        $self->{month} = $self->{_possible_month_or_day} if exists $self->{_possible_month_or_day};
    }
    else {
        $self->_store_month_or_day($token);
    }
    return 1;
}

sub _store_month_or_day {
    my $self = shift;
    my($token) = @_;

    if($self->month) {
        $self->{day} = $token;
    }
    elsif($self->day) {
        $self->{month} = $token;
    }
    else {
        $self->_check_uncertain_month_or_day($token);
    }
}

sub _check_uncertain_month_or_day {
    my $self = shift;
    my($token) = @_;

    if(exists $self->{_possible_month_or_day}) {
        my $day = $self->{_possible_month_or_day};
        my $month = $token;
        ($day, $month) = ($month, $day) if defined $self->year || $self->prefer_month_first_order;
        $self->{day} = $day;
        $self->{month} = $month;
    }
    else {
        $self->{_possible_month_or_day} = $token;
    }
}

sub _process_word_token {
    my $self = shift;
    my($token) = @_;

    my $check_month = $self->_month_from_name($token);
    return 1 unless $check_month;
    return 0 if $self->month;
    $self->{month} = $check_month;
    $self->{day} = $self->{_possible_month_or_day} if exists $self->{_possible_month_or_day};
    return 1;
}

sub _month_from_name {
    my $self = shift;
    my($name) = @_;

    return unless length $name > 2;
    $name = lc $name;
    for(my $index = 0; $index < $#{$self->{_month_names}}; $index += 2) {
        return $self->{_month_names}->[$index + 1] if substr($self->{_month_names}->[$index], 0, length $name) eq $name;
    }
    return;
}

=head1 AUTHOR

Merlyn Kline, C<< <pause.perl.org at binary.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-date-parse-lite at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Parse-Lite>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Date::Parse::Lite


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Parse-Lite>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Date-Parse-Lite>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Date-Parse-Lite>

=item * Search CPAN

L<http://search.cpan.org/dist/Date-Parse-Lite/>

=item * Source code on GitHub

L<https://github.com/merlynkline/Date-Parse-Lite>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Merlyn Kline.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Date::Parse::Lite
