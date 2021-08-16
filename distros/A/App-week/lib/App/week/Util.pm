package App::week;
use v5.14;
use warnings;
use utf8;

use Data::Dumper;
use Text::ANSI::Fold;
use Date::Japanese::Era;
use List::Util qw(pairmap);

sub make_options {
    map {
	# "foo_bar" -> "foo_bar|foo-bar|foobar"
	s{^(?=\w+_)(\w+)\K}{
	    "|" . $1 =~ tr[_][-]r . "|" . $1 =~ tr[_][]dr
	}er;
    }
    grep {
	s/#.*//;
	s/\s+//g;
	/\S/;
    }
    map { split /\n+/ }
    @_;
}

my %abbr = do {
    pairmap {
	( $a => $b, substr($b, 0, 1) => $b )
    }
    map { split /:/ }
    qw( M:明治 T:大正 S:昭和 H:平成 R:令和 );
};

my @month_name = qw(JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC);
my %month = map { $month_name[$_] => $_ + 1 } 0 .. $#month_name;
my $month_re = do { local $" = '|'; qr/(?:@month_name)/i };

sub guess_date {
    my $__ = $_;
    my @args = \(
	my($year, $mon, $mday, $show_year) = @_
    );

    # Jan ... Dec
    if (/^($month_re)/) {
	$mon = $month{uc($1)};
    }
    elsif (m{
	^
	  (?<Y> (?: [A-Z] | \p{Han}+ ) \d++ ) [-./年]?
	  (?: (?<M> \d++ ) [-./月]?
	      (?: (?<D> \d++ ) [日]? )?
	  )?
	$
	}ix)
    {
	my %m = %+;
	(my $era_str = $m{Y}) =~ s{^([A-Z\p{Han}])(?=\d)}{
	    $abbr{uc $1} // $1
	}ie;
	my $era = eval { Date::Japanese::Era->new($era_str) } or do {
	    my $warn = $@ =~ s/ at .*//sr;
	    die "$_: format error ($warn)\n";
	};
	$year = $era->gregorian_year;
	if ($m{D}) {
	    ($mon, $mday) = ($m{M}, $m{D});
	} else {
	    $show_year++;
	    undef $mday;
	}
    }
    else {
	$mday = $1 if s{[-./]*(\d+)日?$}{};
	$mon  = $1 if s{[-./]*(\d+)月?$}{};
	$year = $1 if s{(?:西暦)?(\d+)年?$}{};
	if (defined $mday and $mday > 31) {
	    $year = $mday;
	    undef $mday;
	    $show_year++;
	}
	if (length) {
	    die "$__: format error\n";
	}
    }

    map ${$_}, @args;
}

sub split_week {
    state $fold = new Text::ANSI::Fold width => [ (1, 2) x 7, 1 ];
    $fold->text(+shift)->chops;
}

sub transpose {
    my @x;
    my @orig = map { [ @$_ ] } @_;
    while (my @l = grep { @$_ > 0 } @orig) {
	push @x, [ map { shift @$_ } @l ];
    }
    @x;
}

sub decode_argv {
    map {
	utf8::is_utf8($_) ? $_ : decode('utf8', $_);
    }
    @_;
}

sub apply {
    my($sub, $hash, @keys) = @_;
    @{$hash}{@keys} = $sub->(@{$hash}{@keys});
}

sub call {
    my($sub, %opt) = @_;
    my $hash = $opt{for} or die;
    my $with = $opt{with} // [];
    my @keys = ref $with eq 'ARRAY' ? @{$with} : $with;
    @{$hash}{@keys} = $sub->(@{$hash}{@keys});
}

1;
