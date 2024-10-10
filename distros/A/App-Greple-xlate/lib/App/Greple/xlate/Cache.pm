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
    $obj->access($key);
    exists $obj->current->{$key} or exists $obj->saved->{$key};
}

sub FETCH {
    my($obj, $key) = @_;
    $obj->access($key);
    $obj->get($key);
}

sub STORE {
    my($obj, $key, $val) = @_;
    $obj->access($key);
    $obj->set($key, $val);
}

sub DESTROY {
    my $obj = shift;
    $obj->update;
}

my %default = (
    name => '',		# cache filename
    saved => undef,	# saved hash
    current => undef,	# current using hash
    clear => 0,		# clean up cache data
    accessed => {},	# accessed keys
    order => [],	# accessed keys in order
    accumulate => 0,	# do not delete unused entry
    force_update => 0,	# update cache file anyway
    updated => 0,	# number of updated entries
    format => 'list',	# saving cache file format
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

sub access {
    my $obj = shift;
    my $key = shift;
    push @{$obj->order}, $key if not $obj->accessed->{$key}++;
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
	my $data = do { local $/; <$fh> };
	my $json = $data eq '' ? {} : $json_obj->decode($data);
	$obj->{saved} = do {
	    if    (ref $json eq 'HASH')  { $json }
	    elsif (ref $json eq 'ARRAY') { +{ map @{$_}[0,1], @$json } }
	    else  { die "unexpected json data." }
	};
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
	my $data = $obj->format eq 'list' ? $obj->list_data : $obj->hash_data;
	my $json = $json_obj->encode($data);
	print $fh $json;
	warn "write cache to $file\n";
    } else {
	warn "$file: $!\n";
    }
}

sub hash_data {
    my $obj = shift;
    $obj->current;
}

sub list_data {
    my $obj = shift;
    my %hash = %{$obj->current};
    my @list;
    for my $key (@{$obj->order}) {
	if (exists $hash{$key}) {
	    push @list, [ $key => delete $hash{$key} ];
	} else {
	    warn "$key: not in cache.";
	}
    }
    for my $key (sort keys %hash) {
	warn "$key: not in order list.";
	push @list, [ $key => delete $hash{$key} ];
    }
    die if %hash;
    \@list;
}

1;
