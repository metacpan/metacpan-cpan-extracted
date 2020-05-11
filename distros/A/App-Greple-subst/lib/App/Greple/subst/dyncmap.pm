package App::Greple::subst::dyncmap;

use v5.14;
use strict;
use warnings;

use Carp;
use Data::Dumper;
use List::Util qw(notall pairmap);

##
## Dyamic colormap generator
##

sub dyncmap {
    my %opt = @_;
    for ($opt{range}) {
	my @range = pairmap { [ $a..$b ] } /([0-5])-([0-5])/g or die;
	push @range, $range[-1] while @range < 3;
	$_ = \@range;
    }
    my @cm = cmap(%opt);
    join ',', @cm;
}

sub combination {
    my $this = shift;
    return map [ $_ ], @$this if @_ == 0;
    my @sub = combination(@_);
    map {
	my $c = $_;
	map { [ $c, @$_ ] } @sub;
    } @$this;
}

sub rgb {
    croak "Invalid value (@_)" if notall { 0 <= $_ && $_ <= 5 } @_;
    my($r, $g, $b) = @_;
    if ($r == $g and $r == $b) {
	qw(L03 L07 L11 L15 L19 L23)[$r];
    } else {
	"$r$g$b";
    }
}

sub cmap {
    my %opt = (shift => 0, except => '', @_);
    my @cm = combination @{$opt{range}};
    if (my %except = map { $_ => 1 } $opt{except} =~ /\b(\d\d\d)\b/g) {
	local $" = '';
	@cm = grep { not $except{"@$_"} } @cm;
    }
    my @map = map {
	( sprintf($opt{even}, rgb(@$_) ),
	  sprintf($opt{odd},  rgb(map $_ + $opt{shift}, @$_) ) );
    } @cm;
}

1;

__DATA__

mode function

option --dyncmap &dyncmap($<shift>)
