package App::Greple::xlate::Mask;

use v5.24;
use warnings;
use Data::Dumper;

use Hash::Util qw(lock_keys);

my %default = (
    TAG       => 'm',
    INDEX     => 'id',
    NUMBER    => 0,
    PATTERN   => [],
    TABLE     => [],
    AUTORESET => 0,
);

sub new {
    my $class = shift;
    my $obj = bless { %default }, $class;
    lock_keys %{$obj};
    $obj->configure(@_);
    $obj;
}

sub reset {
    my $obj = shift;
    $obj->{NUMBER} = 0;
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
	elsif ($a eq 'file') {
	    open my $fh, '<:encoding(utf8)', $b or die "$b: $!\n";
	    my @p = map s/\\(?=\n)//gr, split /(?<!\\)\n/, do { local $/; <$fh> };
	    push @{$obj->{PATTERN}}, @p;
	}
	else {
	    $obj->{$a} = $b;
	}
    }
}

sub mask {
    my $obj = shift;
    my $pattern = $obj->{PATTERN} // die;
    my @patterns = ref $pattern ? @$pattern : $pattern;
    my $fromto = $obj->{TABLE};
    # edit parameters in place
    for (@_) {
	for my $pat (@patterns) {
	    next if $pat =~ /^\s*(#|$)/;
	    s{$pat}{
		my $tag = sprintf("<%s %s=%d />",
				  $obj->{TAG}, $obj->{INDEX}, ++$obj->{NUMBER});
		push @$fromto, [ $tag, ${^MATCH} ];
		$tag;
	    }gpe;
	}
    }
    return $obj;
}

sub unmask {
    my $obj = shift;
    my @tags = map $_->[0], @{$obj->{TABLE}};
    my %tags = map { $_ => 1 } @tags;
    # edit parameters in place
    for (@_) {
	for my $fromto (reverse @{$obj->{TABLE}}) {
	    my($from, $to) = @$fromto;
	    # update the first one
	    if (my $n = s/\Q$from/$to/) {
		if ($n > 1 or not exists $tags{$from}) {
		    warn "Masking error: \"$from\" duplicated.\n";
		}
		delete $tags{$from};
	    }
	}
    }
    if (%tags) {
	die sprintf("Masking error: \"%s\" missing in the output(%s).\n",
		    join('", "', keys %tags),
		    join('', @_),
		);
    }
    $obj->reset if $obj->{AUTORESET};
    return $obj;
}

1;
