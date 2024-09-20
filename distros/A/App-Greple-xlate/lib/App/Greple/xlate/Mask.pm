package App::Greple::xlate::Mask;

use v5.14;
use warnings;
use Data::Dumper;

my %default = (
    PATTERN => [],
    TABLE => [],
    );

sub new {
    my $class = shift;
    my $obj = bless { %default }, $class;
    $obj->configure(@_);
    $obj;
}

sub reset {
    my $obj = shift;
    $obj->{TABLE} = [];
    $obj;
}

sub configure {
    my $obj = shift;
    while (my($a, $b) = splice @_, 0, 2) {
	if ($a eq 'pattern') {
	    my @pattern = ref $b ? @$b : $b;
	    push @{$obj->{PATTERN}}, @pattern;
	}
	if ($a eq 'file') {
	    open my $fh, $b or die "$b: $!";
	    chomp(my @pattern = <$fh>);
	    push @{$obj->{PATTERN}}, @pattern;
	}
    }
}

sub mask {
    my $obj = shift;
    my $pattern = $obj->{PATTERN} // die;
    my @patterns = ref $pattern ? @$pattern : $pattern;
    my $id = 0;
    my $fromto = $obj->{TABLE};
    # edit parameters in place
    for (@_) {
	for my $pat (@patterns) {
	    next if $pat =~ /^\s*(#|$)/;
	    s{$pat}{
		my $tag = sprintf("<m id=%d />", ++$id);
		push @$fromto, [ $tag, ${^MATCH} ];
		$tag;
	    }gpe;
	}
    }
    return $obj;
}

sub unmask {
    my $obj = shift;
    # edit parameters in place
    for (@_) {
	for my $fromto (@{$obj->{TABLE}}) {
	    my($from, $to) = @$fromto;
	    s/\Q$from/$to/g
	}
    }
    return $obj;
}

1;
