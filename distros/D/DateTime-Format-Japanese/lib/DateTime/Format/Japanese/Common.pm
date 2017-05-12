# $Id: /mirror/datetime/DateTime-Format-Japanese/trunk/lib/DateTime/Format/Japanese/Common.pm 69499 2008-08-24T16:17:57.045540Z lestrrat  $

package DateTime::Format::Japanese::Common;
use strict;
use warnings;
use utf8;
use Exporter;
use vars qw(@ISA %EXPORT_TAGS);
use constant FORMAT_KANJI_WITH_UNIT  => 'FORMAT_KANJI_WITH_UNIT';
use constant FORMAT_KANJI            => 'FORMAT_KANJI';
use constant FORMAT_ZENKAKU          => 'FORMAT_ZENKAKU';
use constant FORMAT_ROMAN            => 'FORMAT_ROMAN';
use constant FORMAT_ERA              => 'FORMAT_ERA';
use constant FORMAT_GREGORIAN        => 'FORMAT_GREGORIAN';
BEGIN
{
    @ISA     = qw(Exporter);
    %EXPORT_TAGS = (
        constants => [ qw(
            FORMAT_KANJI_WITH_UNIT FORMAT_KANJI FORMAT_ZENKAKU
            FORMAT_ROMAN FORMAT_ERA FORMAT_GREGORIAN) ]
    );
    Exporter::export_ok_tags('constants');
}
use DateTime::Calendar::Japanese::Era;
use Encode ();
use Encode::Guess ();

BEGIN
{
    my($euc2utf8_sub, $normalize_utf8_sub);

    $normalize_utf8_sub = sub {
        my %args = @_;

        my $self = $args{self};
        if (ref($self) && $self->{input_encoding} ne 'Guess') {
            return Encode::decode($self->{input_encoding}, $args{input});
        } else {
            if (Encode::is_utf8($args{input})) {
                return $args{input};
            } else {
                my $enc  = Encode::Guess::guess_encoding(
                    $args{input}, qw(euc-jp shiftjis 7bit-jis)) or
                die "Could not guess encoding for input!";
                return Encode::decode($enc->name, $args{input});
			}
        }
    };

    {
        no strict 'refs';
        *_normalize_utf8 = $normalize_utf8_sub;
    }
}

sub _make_utf8_re_str
{
    my $u = shift;
    my $l = length($u);
    return sprintf( '\x{%04X}' x $l, unpack('U ' x $l, $u));
}

sub _make_utf8_re
{
    _make_re(_make_utf8_re_str(@_));
}

sub _make_re
{
    my $re = shift;
    return qr($re);
}

# Declare a bunch of variables
use vars qw(
    @DAY_OF_WEEKS
    @ZENKAKU_NUMBERS @KANJI_NUMBERS %ZENKAKU2ASCII %KANJI2ASCII %JP2ASCII
    %AMPM
    $KANJI_TEN
    $KANJI_ZERO
    $BC_MARKER
    $GREGORIAN_MARKER
    $YEAR_MARKER
    $MONTH_MARKER
    $DAY_MARKER
    $DAY_MARKER
    $HOUR_MARKER
    $MINUTE_MARKER
    $SECOND_MARKER
    $AM_MARKER
    $PM_MARKER
    $DAY_OF_WEEK_SHORT_MARKER
    $DAY_OF_WEEK_MARKER
    $TRADITIONAL_MARKER
    $RE_KANJI_TEN
    $RE_KANJI_ZERO
    $RE_BC_MARKER
    $RE_GREGORIAN_MARKER
    $RE_YEAR_MARKER
    $RE_MONTH_MARKER
    $RE_DAY_MARKER
    $RE_DAY_MARKER
    $RE_HOUR_MARKER
    $RE_MINUTE_MARKER
    $RE_SECOND_MARKER
    $RE_AM_MARKER
    $RE_PM_MARKER
    $RE_TRADITIONAL_MARKER
    $RE_ZENKAKU_NUM
    $RE_KANJI_NUM
    $RE_ZENKAKU_NUM
    $RE_JP_OR_ASCII_NUM
    $RE_GREGORIAN_YEAR
    $RE_ERA_YEAR_SPECIAL
    $RE_ERA_YEAR
    $RE_ERA_NAME
    $RE_TWO_DIGITS
    $RE_AM_PM_MARKER
    $RE_DAY_OF_WEEKS
);

{ # XXX - eh, not need to put this in different scope, but _makes this stand out
    $KANJI_TEN        = '十';
    $KANJI_ZERO       = '零';
    $BC_MARKER        = '紀元前';
    $GREGORIAN_MARKER = '西暦';
    $YEAR_MARKER      = '年';
    $MONTH_MARKER     = '月';
    $DAY_MARKER       = '日';
    $HOUR_MARKER      = '時';
    $MINUTE_MARKER    = '分';
    $SECOND_MARKER    = '秒';
    $AM_MARKER        = '午前';
    $PM_MARKER        = '午後';
    $TRADITIONAL_MARKER = '旧暦';
    $DAY_OF_WEEK_SHORT_MARKER = '曜';
    $DAY_OF_WEEK_MARKER = $DAY_OF_WEEK_SHORT_MARKER . $DAY_MARKER;

    @ZENKAKU_NUMBERS = qw(０ １ ２ ３ ４ ５ ６ ７ ８ ９);
    @KANJI_NUMBERS   = qw(〇 一 二 三 四 五 六 七 八 九);
    %ZENKAKU2ASCII = map { ($ZENKAKU_NUMBERS[$_] => $_) } 0..$#ZENKAKU_NUMBERS;
    %KANJI2ASCII   = map { ($KANJI_NUMBERS[$_] => $_) } 0.. $#KANJI_NUMBERS;
    $KANJI2ASCII{ $KANJI_ZERO } = 0;
    %JP2ASCII = (%ZENKAKU2ASCII, %KANJI2ASCII);

    @DAY_OF_WEEKS = qw( 月 火 水 木 金 土 日 );

    %AMPM = (
        $AM_MARKER =>  0,
        $PM_MARKER => 1
    );

    $RE_DAY_OF_WEEKS = _make_re(
        '(?:' . join( '|', map { _make_utf8_re_str($_) } @DAY_OF_WEEKS ) . ')' .
        _make_utf8_re_str($DAY_OF_WEEK_SHORT_MARKER) . 
        '(?:' . _make_utf8_re_str($DAY_MARKER) . ')?');

    $RE_ZENKAKU_NUM = _make_re( sprintf( '[%s]',
        _make_utf8_re_str( join('', @ZENKAKU_NUMBERS) ) ) );

    $RE_KANJI_NUM = _make_re( sprintf( '[%s]',
        _make_utf8_re_str( join('', @KANJI_NUMBERS) ) ) );
    $RE_ZENKAKU_NUM = _make_re( sprintf( '[%s]',
        _make_utf8_re_str( join('', @ZENKAKU_NUMBERS, @KANJI_NUMBERS) ) ) );
    $RE_JP_OR_ASCII_NUM    = qr([0-9]|$RE_ZENKAKU_NUM);
    $RE_BC_MARKER          = _make_utf8_re($BC_MARKER);
    $RE_GREGORIAN_MARKER   = _make_utf8_re($GREGORIAN_MARKER);
    $RE_TRADITIONAL_MARKER = _make_utf8_re($TRADITIONAL_MARKER);
    $RE_AM_PM_MARKER       = _make_re( join( '|',
        _make_utf8_re_str($AM_MARKER), _make_utf8_re_str($PM_MARKER), '') );
    $RE_YEAR_MARKER        = _make_utf8_re($YEAR_MARKER);
    $RE_MONTH_MARKER       = _make_utf8_re($MONTH_MARKER);
    $RE_DAY_MARKER         = _make_utf8_re($DAY_MARKER);
    $RE_HOUR_MARKER        = _make_utf8_re($HOUR_MARKER);
    $RE_MINUTE_MARKER      = _make_utf8_re($MINUTE_MARKER);
    $RE_SECOND_MARKER      = _make_utf8_re($SECOND_MARKER);
    $RE_KANJI_TEN          = _make_utf8_re($KANJI_TEN);
    $RE_KANJI_ZERO         = _make_utf8_re($KANJI_ZERO);

    $RE_TWO_DIGITS         = qr(
        ${RE_KANJI_NUM}?${RE_KANJI_TEN}?${RE_KANJI_NUM} |
        ${RE_ZENKAKU_NUM}?${RE_ZENKAKU_NUM}             | 
        [0-9]?[0-9]
    )x;
    
    $RE_GREGORIAN_YEAR     = qr(-?$RE_JP_OR_ASCII_NUM+);
    $RE_ERA_YEAR_SPECIAL   = _make_utf8_re('元');
    $RE_ERA_YEAR           = qr($RE_ERA_YEAR_SPECIAL|$RE_TWO_DIGITS);
    $RE_ERA_NAME           = _make_re(join( "|",
        map { $_->name } DateTime::Calendar::Japanese::Era->registered) );
}

my %valid_number_format = (
    FORMAT_KANJI_WITH_UNIT() => 1,
    FORMAT_KANJI()           => 1,
    FORMAT_ZENKAKU()         => 1,
    FORMAT_ROMAN()           => 1,
);

sub _valid_number_format  { exists $valid_number_format{$_[0]} }

my %valid_year_format = (
    FORMAT_ERA()       => 1,
    FORMAT_GREGORIAN() => 1
);

sub _valid_year_format { exists $valid_year_format{$_[0]} }

# Era year 1 can be written as "元年"
sub _fix_era_year
{
    my %args = @_;
    if ($args{parsed}->{era_year} =~ /$RE_ERA_YEAR_SPECIAL/) {
        $args{parsed}->{era_year} = 1;
    }
    return 1;
}

sub _normalize_numbers
{
    my %args = @_;
    foreach my $key qw(year month day era_year hour minute second) {
        if (defined $args{parsed}->{$key}) {
            $args{parsed}->{$key} =~ s/^$RE_KANJI_TEN/1/;
            $args{parsed}->{$key} =~ s/$RE_KANJI_TEN//;
        }

        # check for definedness here so that we don't get use uninitialized
        # ... warnings  in the substitution, plus so that DateTime doesn't
        # complain + it uses the appropriate default value
        if (!defined $args{parsed}->{$key}) {
            delete $args{parsed}->{$key};
        }

        if (exists $args{parsed}->{$key} && defined($args{parsed}->{$key})) {
            $args{parsed}->{$key} =~ s/($RE_KANJI_NUM|$RE_ZENKAKU_NUM)/$JP2ASCII{$1}/ge;
        }
    }

    return 1;
}

sub _fix_am_pm
{
    my %args = @_;
    if (my $am_pm = delete $args{parsed}->{am_pm}) {
        if (!exists $AMPM{ $am_pm }) {
            return 0;
        }

        my $is_pm = $AMPM{ $am_pm };

        if (!$is_pm && $args{parsed}->{hour} >= 12) {
            return 0;
        }

        if ($is_pm && $args{parsed}->{hour} < 12) {
            $args{parsed}->{hour} += 12;
        }
    }
    return 1;
}

sub _format_number
{
    my($number, $number_format) = @_;

    if($number_format eq FORMAT_KANJI_WITH_UNIT()) {
        if ($number > 99) {
            Carp::croak("format_number doesn't support formatting numbers that are greater than 99");
        }

        if ($number < 10) {
            $number = $KANJI_NUMBERS[$number];
        } else {
            my $tens = int($number / 10);
            my $ones = $number % 10;
            if ($tens > 1) {
                $number = $KANJI_NUMBERS[$tens] . $KANJI_TEN . $KANJI_NUMBERS[$ones];
            } else {
                $number = $KANJI_TEN . $KANJI_NUMBERS[$ones];
            }
        }
    } elsif ($number_format eq FORMAT_ZENKAKU()) {
        $number =~ s/(\d)/$ZENKAKU_NUMBERS[$1]/ge;
    } elsif ($number_format eq FORMAT_KANJI()) {
        $number =~ s/(\d)/$KANJI_NUMBERS[$1]/ge;
    }

    return $number;
}

sub _format_era
{
    my($dt, $number_format) = @_;

    my $era = DateTime::Calendar::Japanese::Era->lookup_by_date(
        datetime => $dt);
    if (!$era) {
        Carp::croak("No era defined for specified date");
    }

    my $era_year = ($dt->year - $era->start->year) + 1; 
    my $era_name = Encode::decode_utf8($era->name);

    return $era_name .
        _format_number($era_year, $number_format) .
        $YEAR_MARKER;
}

sub _format_common_with_marker
{
    my($marker, $number, $number_format) = @_;
    return _format_number($number, $number_format) . $marker;
}

1;

__END__

=head1 NAME

DateTime::Format::Japanese::Common - Utilities To Format Japanese Dates

=head1 SYNOPSIS

  use DateTime::Format::Japanese::Common;
  # internal use only

=head1 AUTHOR

(c) 2004-2008 Daisuke Maki E<lt>daisuke@endeworks.jp<gt>. 

=cut
