package Date::Japanese::Era;

use strict;
our $VERSION = '0.07';

use Carp;
use constant END_OF_LUNAR => 1872;

our(%ERA_TABLE, %ERA_JA2ASCII, %ERA_ASCII2JA);

sub import {
    my $self = shift;
    if (@_) {
	my $table = shift;
	eval qq{use Date::Japanese::Era::Table::$table};
	die $@ if $@;
    }
    else {
	require Date::Japanese::Era::Table;
	import Date::Japanese::Era::Table;
    }
}

sub new {
    my($class, @args) = @_;
    my $self = bless {
	name => undef,
	year => undef,
	gregorian_year => undef,
    }, $class;

    if (@args == 3) {
	$self->_from_ymd(@args);
    }
    elsif (@args == 2) {
	$self->_from_era(@args);
    }
    elsif (@args == 1) {
	$self->_dwim(@args);
    }
    else {
        croak "odd number of arguments: ", scalar(@args);
    }

    return $self;
}

sub _from_ymd {
    my($self, @ymd) = @_;

    if ($ymd[0] <= END_OF_LUNAR) {
	Carp::carp("In $ymd[0] they didn't use gregorious date.");
    }

    require Date::Calc;

    # XXX can be more efficient
    for my $era (keys %ERA_TABLE) {
	my $data = $ERA_TABLE{$era};
	if (Date::Calc::Delta_Days(@{$data}[1..3], @ymd) >= 0 &&
            Date::Calc::Delta_Days(@ymd, @{$data}[4..6]) >= 0) {
	    $self->{name} = $era;
	    $self->{year} = $ymd[0] - $data->[1] + 1;
	    $self->{gregorian_year} = $ymd[0];
	    return;
	}
    }

    croak "Unsupported date: ", join('-', @ymd);
}

sub _from_era {
    my($self, $era, $year) = @_;
    if ($era =~ /^[a-zA-Z]+$/) {
	$era = $self->_ascii2ja($era);
    }

    unless (utf8::is_utf8($era)) {
        croak "Era needs to be Unicode string";
    }

    my $data = $ERA_TABLE{$era}
        or croak "Unknown era name: $era";

    my $g_year = $data->[1] + $year - 1;
    if ($g_year > $data->[4]) {
	croak "Invalid combination of era and year: $era-$year";
    }

    $self->{name} = $era;
    $self->{year} = $year;
    $self->{gregorian_year} = $g_year;
}

sub _dwim {
    my($self, $str) = @_;

    unless (utf8::is_utf8($str)) {
        croak "Era should be in Unicode";
    }

    my $gengou_re = join "|", keys %ERA_JA2ASCII;

    $str =~ s/^($gengou_re)//
        or croak "Can't extract Era from $str";

    my $era = $1;

    $str =~ s/\x{5E74}$//; # nen
    my $year = _number($str);

    unless (defined $year) {
        croak "Can't parse year from $str";
    }

    $self->_from_era($era, $year);
}

sub _number {
    my $str = shift;

    $str =~ s/([\x{FF10}-\x{FF19}])/;ord($1)-0xff10/eg;

    if ($str =~ /^\d+$/) {
        return $str;
    } else {
        eval { require Lingua::JA::Numbers };
        if ($@) {
            croak "require Lingua::JA::Numbers to read Japanized numbers";
        }

        return Lingua::JA::Numbers::ja2num($str);
    }
}

sub _ascii2ja {
    my($self, $ascii) = @_;
    return $ERA_ASCII2JA{$ascii} || croak "Unknown era name: $ascii";
}

sub _ja2ascii {
    my($self, $ja) = @_;
    return $ERA_JA2ASCII{$ja} || croak "Unknown era name: $ja";
}

sub name {
    my $self = shift;
    return $self->{name};
}

*gengou = \&name;

sub name_ascii {
    my $self = shift;
    return $self->_ja2ascii($self->name);
}

sub year {
    my $self = shift;
    return $self->{year};
}

sub gregorian_year {
    my $self = shift;
    return $self->{gregorian_year};
}

1;
__END__

=encoding utf-8

=head1 NAME

Date::Japanese::Era - Conversion between Japanese Era / Gregorian calendar

=head1 SYNOPSIS

  use utf8;
  use Date::Japanese::Era;

  # from Gregorian (month + day required)
  $era = Date::Japanese::Era->new(1970, 1, 1);

  # from Japanese Era
  $era = Date::Japanese::Era->new("昭和", 52); # SHOWA

  $name      = $era->name;         # 昭和 (in Unicode)
  $gengou    = $era->gengou;       # Ditto

  $year      = $era->year;	   # 52
  $gregorian = $era->gregorian_year;  	   # 1977

  # use JIS X0301 table for conversion
  use Date::Japanese::Era 'JIS_X0301';

  # more DWIMmy
  $era = Date::Japanese::Era->new("昭和五十二年");
  $era = Date::Japanese::Era->new("昭和52年");

=head1 DESCRIPTION

Date::Japanese::Era handles conversion between Japanese Era and
Gregorian calendar.

=head1 METHODS

=over 4

=item new

  $era = Date::Japanese::Era->new($year, $month, $day);
  $era = Date::Japanese::Era->new($era_name, $year);
  $era = Date::Japanese::Era->new($era_year_string);

Constructs new Date::Japanese::Era instance. When constructed from
Gregorian date, month and day is required. You need Date::Calc to
construct from Gregorian.

Name of era can be either of Japanese / ASCII. If you pass Japanese
text, they should be in Unicode.

Errors will be thrown if you pass byte strings such as UTF-8 or
EUC-JP, since Perl doesn't understand what encoding they're in. Use
the L<utf8> pragma if you want to write them in literals.

Exceptions are thrown when inputs are invalid, such as non-existent
era name and year combination, unknwon era-name, etc.

=item name

  $name = $era->name;

returns era name in Japanese in Unicode.

=item gengou

alias for name().

=item name_ascii

  $name_ascii = $era->name_ascii;

returns era name in US-ASCII.

=item year

  $year = $era->year;

returns year as Japanese era.

=item gregorian_year

  $year = $era->gregorian_year;

returns year as Gregorian.

=back

=head1 EXAMPLES

  use utf8;
  use Date::Japanese::Era;

  # 2001 is H-13
  my $era = Date::Japanese::Era->new(2001, 8, 31);
  printf "%s-%s", uc(substr($era->name_ascii, 0, 1)), $era->year;

  # to Gregorian
  my $era = Date::Japanese::Era->new("平成", 13); # HEISEI 13
  print $era->gregorian_year;	# 2001

=head1 CAVEATS

=over 4

=item *

Currently supported era is up to 'meiji'. And before Meiji 05.12.02,
gregorius calendar was not used there, but lunar calendar was. This
module does not support lunar calendar, but gives warnings in such
cases ("In %d they didn't use gregorius calendar").

To use calendar ealier than that, see
L<DateTime::Calendar::Japanese::Era>, which is based on DateTime
framework and is more comprehensive.

=item *

There should be discussion how we handle the exact day the era has
changed (former one or latter one?). This module default handles the
day as newer one, but you can change so that it sticks to JIS table
(older one) by saying:

  use Date::Japanese::Era 'JIS_X0301';

For example, 1912-07-30 is handled as:

  default	Taishou 1 07-30
  JIS_X0301	Meiji 45 07-30

=item *

If someday current era (reiwa) is changed, Date::Japanese::Era::Table
should be upgraded.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Tatsuhiko Miyagawa, 2001-

=head1 LICENSE

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<DateTime::Calendar::Japanese::Era>, L<Date::Calc>, L<Encode>

=cut
