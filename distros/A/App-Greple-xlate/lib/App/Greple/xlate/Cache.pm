package App::Greple::xlate::Cache;

use v5.14;
use warnings;

use Data::Dumper;
use JSON;
use List::Util qw(pairmap mesh);
use Hash::Util qw(lock_keys);

sub TIEHASH {
    my $self = shift;
    my $obj = $self->new(name => @_);
    $obj;
}

sub EXISTS {
    my($obj, $key) = @_;
    exists $obj->current->{$key} or exists $obj->saved->{$key};
}

sub FETCH {
    my($obj, $key) = @_;
    $obj->get($key);
}

sub STORE {
    my($obj, $key, $val) = @_;
    $obj->set($key, $val);
}

sub DESTROY {
    my $obj = shift;
    $obj->update;
}

my %default = (
    name => '',
    saved => undef,
    current => undef,
    clear => 0,
    accumulate => 0,
    force_update => 0,
    updated => 0,
);

for my $key (keys %default) {
    no strict 'refs';
    *{$key} = sub :lvalue { $_[0]->{$key} }
}

sub new {
    my $class = shift;
    my $obj = bless { %default }, $class;
    lock_keys %{$obj};
    pairmap { $obj->{$a} = $b } @_;
    $obj->open if $obj->name;
    $obj;
}

sub get {
    my $obj = shift;
    my $key = shift;
    $obj->current->{$key} //= delete $obj->saved->{$key};
}

sub set {
    my $obj = shift;
    pairmap {
	if (ref $a eq 'ARRAY' and ref $b eq 'ARRAY') {
	    @$a == @$b or die;
	    $obj->set(mesh $a, $b);
	} else {
	    my $c = $obj->current->{$a} //= delete $obj->saved->{$a};
	    if (not defined $c or $c ne $b) {
		$obj->current->{$a} = $b;
		$obj->updated++;
	    }
	}
    } @_;
    $obj;
}

sub json {
    JSON->new->utf8->canonical->pretty;
}

sub open {
    my $obj = shift;
    my $file = $obj->name || return;
    if ($obj->clear) {
	warn "created $file\n" unless -f $file;
	open my $fh, '>', $file or die "$file: $!\n";
	print $fh "{}\n";
    }
    my $json_obj //= &json;
    if (CORE::open my $fh, $file) {
	my $json = do { local $/; <$fh> };
	my $hash = $json eq '' ? {} : $json_obj->decode($json);
	$obj->{saved} = $hash;
	warn "read cache from $file\n";
    } else {
	$obj->{saved} = {};
    }
    $obj;
}

sub update {
    my $obj = shift;
    my $file = $obj->name || return;
    if (not $obj->force_update and $obj->updated == 0) {
	if (%{$obj->saved} == 0) {
	    return;
	} elsif ($obj->accumulate) {
	    for (keys %{$obj->saved}) {
		$obj->current->{$_} //= delete $obj->saved->{$_};
	    }
	}
    }
    while (my($k, $v) = each %{$obj->current}) {
	delete $obj->current->{$k} if not defined $v;
    }
    %{$obj->current} > 0 or return;
    my $json_obj //= &json; # this is necessary to be called from DESTROY
    if (CORE::open my $fh, '>', $file) {
	my $json = $json_obj->encode($obj->current);
	print $fh $json;
	warn "write cache to $file\n";
    } else {
	warn "$file: $!\n";
    }
}

1;
