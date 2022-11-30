package App::week;
our $VERSION = "1.0303";

use v5.14;
use warnings;

use utf8;
use Encode;
use Time::localtime;
use List::Util qw(min max);
use Hash::Util qw(lock_keys);
use Pod::Usage;
use Data::Dumper;
use open IO => ':utf8', ':std';
use Getopt::EX::Colormap;

use App::week::Util;
use App::week::CalYear qw(@calyear);

my @DOW_LABELS = qw(
    DOW_SU
    DOW_MO
    DOW_TU
    DOW_WE
    DOW_TH
    DOW_FR
    DOW_SA
    DOW_CW
    );

my %DEFAULT_COLORMAP = (
    (),      DAYS => "L05/335",
    (),      WEEK => "L05/445",
    (),     FRAME => "L05/445",
    (),     MONTH => "L05/335",
    (),   THISDAY => "522/113",
    (),  THISDAYS => "555/113",
    (),  THISWEEK => "L05/445",
    (), THISMONTH => "555/113",
    map { $_ => "" } @DOW_LABELS,
    );

use Getopt::EX::Hashed; {

    Getopt::EX::Hashed->configure(DEFAULT => [ is => 'rw' ]);

    has ARGV     => default => [];
    has COLORMAP => ;
    has CM       => ;

    my($sec, $min, $hour, $mday, $mon, $year) = CORE::localtime(time);
    has year => default => $year + 1900;
    has mday => default => $mday;
    has mon  => default => $mon + 1;

    has cell_width   => default => undef;
    has frame        => default => '  ';
    has frame_height => default => 1;

    # option params
    has help        => ' h        ' ;
    has version     => ' v        ' ;
    has months      => ' m =i     ' , default => 0;
    has after       => ' A :1     ' , min => 0;
    has before      => ' B :1     ' , min => 0, default => 1;
    has center      => ' C :4     ' , min => 0;
    has column      => ' c =i     ' , min => 1, default => 3;
    has colordump   => '          ' ;
    has colormap    => '   =s@ cm ' , default => [];
    has show_year   => ' y        ' ;
    has years       => ' Y :1     ' , max => 100;
    has rgb24       => '   !      ' ;
    has year_on_all => ' P        ' ;
    has year_on     => ' p =i     ' , min => 0, max => 12;
    has config      => '   =s%    ' , default => {};
    has weeknumber  => ' W :1     ' ;

    has '+center' => sub {
	$_->after = $_->before = $_[1];
    };

    has '+weeknumber' => sub {
	App::week::CalYear::Configure $_[0] => $_[1];
    };

    has '+rgb24' => sub {
	$Getopt::EX::Colormap::RGB24 = !!$_[1];
    };

    has '+config' => sub {
	App::week::CalYear::Configure $_[1] => $_[2];
    };

    has '+help' => sub {
	pod2usage
	    -verbose  => 99,
	    -sections => [ qw(SYNOPSIS VERSION) ];
    };

    has '+version' => sub {
	print "Version: $VERSION\n";
	exit;
    };

    has "<>" => sub {
	my $obj = $_;
	local $_ = $_[0];
	if (/^-+([0-9]+)$/) {
	    $obj->months = $1;
	} elsif (/^-/) {
	    die "$_: Option error\n";
	} else {
	    push @{$obj->ARGV}, $_;
	}
    };

} no Getopt::EX::Hashed;

sub color {
    (+shift)->CM->color(@_);
}

sub usage {
    pod2usage(-verbose => 0, -exitval => "NOEXIT");
    print "Version: $VERSION\n";
    exit 2;
}

sub run {
    my $app = shift;
    local @ARGV = decode_argv @_;

    $app->read_option()
	->argv()
	->deal_option()
	->prepare()
	->show();

    return 0;
}

sub read_option {
    my $app = shift;
    use Getopt::EX::Long qw(:DEFAULT Configure ExConfigure);
    ExConfigure BASECLASS => [ "App::week", "Getopt::EX", "" ];
    Configure qw(bundling no_getopt_compat no_ignore_case pass_through);
    $app->getopt || usage;
    return $app;
}

sub argv {
    my $app = shift;
    for (@{$app->ARGV}) {
	call \&guess_date,
	    for  => $app,
	    with => [ qw(year mon mday show_year) ];
    }
    return $app;
}

sub deal_option {
    my $app = shift;

    # load --colormap option
    my %colormap = %DEFAULT_COLORMAP;
    $app->COLORMAP(\%colormap);
    $app->CM(Getopt::EX::Colormap->new(HASH => \%colormap)
	     ->load_params(@{$app->colormap}));

    # --colordump
    if ($app->colordump) {
	print $app->CM->colormap(
	    name   => '--changeme',
	    option => '--colormap');
	exit;
    }

    # -p, -P
    $app->year_on //= $app->mon if $app->mday;
    if ($app->year_on_all) {
	App::week::CalYear::Configure show_year => [ 1..12 ];
    }
    elsif (defined(my $m = $app->year_on)) {
	if ($m < 0 or 12 < $m) {
	    die "$m: Month must be within 0 to 12\n";
	}
	App::week::CalYear::Configure
	    show_year => { $app->year => $m, '*' => 1 };
    } else {
	App::week::CalYear::Configure show_year => 1;
    }

    # -y, -Y
    $app->years //= 1 if $app->show_year;

    return $app;
}

sub prepare {
    my $app = shift;
    call \&_prepare,
	for  => $app,
	with => [ qw(years months before after year mon column) ];
    return $app;
}

sub _prepare {
    my @args = \(
	my($years, $months, $before, $after, $year, $mon, $column) = @_
    );

    use integer;
    if ($months == 1) {
	$before = $after = 0;
    }
    elsif ($months > 1) {
	if (defined $before) {
	    $after = $months - $before - 1;
	} elsif (defined $after) {
	    $before = $months - $after - 1;
	} else {
	    $before = ($months - 1) / 2;
	    $after = $months - $before - 1;
	}
    }
    elsif ($years) {
	$months = 12 * ($years // 1);
	$before = $mon - 1;
	$after = $months - $mon;
    }
    else {
	$before //= 1;
	$after  //= max(0, $column - $before - 1);
	$months = $before + $after + 1;
    }

    $before //= 1;
    $after  //= 1;

    $year += $year < 50 ? 2000 : $year < 100 ? 1900 : 0;

    map ${$_}, @args;
}

sub show {
    my $app = shift;
    $app->display(
	map {
	    $app->cell( $app->year,
			$app->mon + $_,
			$_ ? () : $app->mday )
	} -$app->before .. $app->after
	);
    return $app;
}

######################################################################

sub display {
    my $obj = shift;
    @_ or return;
    $obj->h_rule(min($obj->column, int @_));
    while (@_) {
	my @cell = splice @_, 0, $obj->column;
	for my $row (transpose @cell) {
	    $obj->h_line(@{$row});
	}
	$obj->h_rule(int @cell);
    }
}

sub h_rule {
    my $obj = shift;
    my $column = shift;
    my $hr1 = " " x $obj->cell_width;
    my $s = join($obj->frame, '', ($hr1) x $column, '');
    my $rule = $obj->color(FRAME => $s) . "\n";
    print $rule x $obj->frame_height;
}

sub h_line {
    my $obj = shift;
    my $frame = $obj->color(FRAME => $obj->frame);
    print join($frame, '', @_, '') . "\n";
}

sub cell {
    my $obj = shift;
    my($y, $m, $d) = @_;

    while ($m > 12) { $y += 1; $m -= 12 }
    while ($m <= 0) { $y -= 1; $m += 12 }

    my @cal = @{$calyear[$y][$m]};

    # XXX this is not the best place to initialize...
    $obj->cell_width //= length $cal[2];

    my %label;
    @label{qw(month week days)} = $d
	? qw(THISMONTH THISWEEK THISDAYS)
	: qw(    MONTH     WEEK     DAYS);

    $cal[0] = $obj->color($label{month}, $cal[0]);
    $cal[1] = $obj->color($label{week},
			  state $week = $obj->week_line($cal[1]));
    my $day_re = $d ? qr/^(?: [ \d]{2}){0,6} \K(${\(sprintf '%2d', $d)})\b/ : undef;
    for (@cal[ 2 .. $#cal ]) {
	s/$day_re/$obj->color("THISDAY", $1)/e if $day_re;
	$_ = $obj->color($label{days}, $_);
    }

    return \@cal;
}

sub week_line {
    my $obj = shift;
    my $week = shift;
    my @week = split_week $week;
    for (0..7) {
	if (my $color = $obj->COLORMAP->{$DOW_LABELS[$_]}) {
	    my $i = $_ * 2 + 1;
	    $i > $#week and last;
	    $week[$i] = $obj->color($color, $week[$i]);
	}
    }
    join '', @week;
}

1;

__END__

=encoding utf-8

=head1 NAME

week - colorful calendar command for ANSI terminal

=head1 SYNOPSIS

B<week> [ -MI<module> ] [ option ] [ date ]

=head1 VERSION

Version 1.0303

=head1 DESCRIPTION

Yet another calendar command.  Read the script's manual for detail.

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2018- Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
