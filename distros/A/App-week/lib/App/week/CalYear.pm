package App::week::CalYear;

use v5.14;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT_OK = qw(@calyear);

use Encode;
use Data::Dumper;
use open IO => ':utf8';
use List::Util qw(uniq);
use Hash::Util qw(lock_keys);
use Text::VisualWidth::PP qw(vwidth);
use Text::ANSI::Fold;
use Date::Japanese::Era;

tie our @calyear, __PACKAGE__;

sub TIEARRAY {
    my $pkg = shift;
    bless {}, $pkg;
}

sub FETCH {
    my($obj, $year) = @_;
    $obj->{$year} //= [ CalYear($year) ];
}

my %config = (
    netbsd     => undef,
    crashspace => undef,
    show_year  => 1,
    wareki     => undef,
);
lock_keys %config;

sub Configure {
    while (my($k, $v) = splice(@_, 0, 2)) {
	$config{$k} = $v;
    }
}

sub CalYear {
    my $year = sprintf "%4d", shift;
    my $cal = `cal $year` =~ s/_[\b]//gr;

    if ($config{crashspace}) {
	$cal =~ s/ +$//mg;
    }
    if ($config{netbsd}) {
	$cal =~ s/(Su|Mo|We|Fr|Sa)/' ' . substr($1,0,1)/mge;
    }

    my @cal = split /\n/, $cal, -1;
    my @monthline = do {
	map  { $_ - 2 }                 # 2 lines up
	grep { $cal[$_] =~ /\s 1 \s/x } # find 1st day
	0 .. $#cal;
    };
    @monthline == 4 or die "cal(1) command format error.\n";

    state $fielder = do {
	my @weekline = map $_ + 1, @monthline;
	fielder($cal[ $weekline[0] ]);
    };

    my @month = ( [ $cal[0] ], map [], 1..12 );
    for my $i (0 .. $#monthline) {
	my $start = $monthline[$i];
	for my $n (0..7) {
	    my @m = $fielder->($cal[$start + $n]);
	    push @{$month[$i * 3 + 1]}, $m[0];
	    push @{$month[$i * 3 + 2]}, $m[1];
	    push @{$month[$i * 3 + 3]}, $m[2];
	}
    }

    tidy_up(\@month);

    my $wareki = $config{wareki} // $month[1][1] =~ /火/;
    for my $month (&show_year($year)) {
	1 <= $month and $month <= 12 or next;
	insert_year(\$month[$month][0], $year, $month, $wareki);
    }
    @month;
}

sub tidy_up {
    my $cals = shift;
    for my $month (@{$cals}[1..12]) {
	for (@{$month}) {
	    $_ = " $_ ";
	}
	for ($month->[0]) {
	    ## Fix month name:
	    ## 1) Take care of cal(1) multibyte string bug.
	    ## 2) Normalize off-to-right to off-to-left.
	    while (/^ (( +)\S+( +))$/ and length($2) >= length($3)) {
		$_ = "$1 ";
	    }
	}
    }
}

sub fielder {
    my $dow_line = shift;
    use Unicode::EastAsianWidth;
    my $dow_re = qr/\p{InFullwidth}|[ \S]\S/;
    $dow_line =~ m{^   (\s*)
		       ( (?: $dow_re [ ]){6} $dow_re ) (\s+)
		       ( (?: $dow_re [ ]){6} $dow_re ) (\s+)
		       ( (?: $dow_re [ ]){6} $dow_re )
    }x or die "cal(1): unexpected day-of-week line.";
    my $w = vwidth $2;
    my @w = (length $1, $w, length $3, $w, length $5, $w);
    my $blank = ' ' x $w;
    my $fold = Text::ANSI::Fold->new(width => \@w, padding => 1);
    sub {
	my $l = shift;
	my @f = $fold->text($l)->chops;
	map { $_ // $blank } @f[1, 3, 5];
    };
}

sub show_year {
    my $conf = $config{show_year};
    my $year = shift;
    if ((my $ref = ref $conf) eq '') {
	( $conf );
    }
    elsif ($ref eq 'ARRAY') {
	@{$conf};
    }
    elsif ($ref eq 'HASH') {
	uniq do {
	    map  {
		my $v = $conf->{$_};
		ref $v eq 'ARRAY' ? @$v : $v
	    }
	    grep { $_ eq '*' or $_ == $year }
	    keys %$conf;
	};
    }
}

sub insert_year {
    local *_ = shift;
    my($year, $month, $wareki) = @_;
    my $len = length($year);
    s/^[ ]\K[ ]{$len}/$year/;
    if (1873 <= $year and $wareki) {
	my $era = Date::Japanese::Era->new($year, $month, 1);
	$year = sprintf '%s%d', $era->name, $era->year;
	$len = vwidth $year;
    }
    s/[ ]{$len}(?=[ ]$)/$year/;
}

1;
