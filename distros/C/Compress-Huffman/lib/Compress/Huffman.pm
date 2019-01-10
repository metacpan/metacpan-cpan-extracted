package Compress::Huffman;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw//;
%EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
use warnings;
use strict;
use Carp;
use Scalar::Util 'looks_like_number';
use POSIX qw/ceil/;
use JSON::Create '0.22', 'create_json';
use JSON::Parse '0.42', 'parse_json';
our $VERSION = '0.08';

# eps is the allowed floating point error for summing the values of
# the symbol table to ensure they form a probability distribution.

use constant 'eps' => 0.0001;

# Private methods/functions

# Add the prefix $i to everything underneath us.

sub addcodetosubtable
{
    my ($fakes, $h, $k, $size, $i) = @_;
    my $subhuff = $fakes->{$k};
    for my $j (0..$size - 1) {
	my $subk = $subhuff->[$j];
	if ($subk =~ /^fake/) {
	    addcodetosubtable ($fakes, $h, $subk, $size, $i);
	}
	else {
	    $h->{$subk} = $i . $h->{$subk};
	}
    }
}

# Public methods below here

sub new
{
    return bless {};
}

sub symbols
{
    # Object and the table of symbols.
    my ($o, $s, %options) = @_;
    if ($options{verbose}) {
	$o->{verbose} = 1;
    }
    else {
	$o->{verbose} = undef;
    }
    # Check $s is a hash reference.
    if (ref $s ne 'HASH') {
	croak "Use as \$o->symbols (\\\%symboltable, options...)";
    }
    # Copy the symbol table into our own thing. We need to put extra
    # symbols in to it.
    my %c = %$s;
    $o->{c} = \%c;
    # The number of symbols we encode with this Huffman code.
    my $nentries = scalar keys %$s;
    if (! $nentries) {
	croak "Symbol table has no entries";
    }
    # Check we have numbers.
    for my $k (keys %$s) {
	if (! looks_like_number ($s->{$k})) {
	    croak "Non-numerical value '$s->{$k}' for key '$k'";
	}
    }
    if ($o->{verbose}) {
	print "Checked for numerical keys.\n";
    }
    my $size = $options{size};
    if (! defined $size) {
	$size = 2;
    }
    if ($size < 2 || int ($size) != $size) {
	croak "Bad size $size for Huffman table, must be integer >= 2";
    }
    if ($size > 10 && ! $options{alphabet}) {
	croak "Use \$o->symbols (\%t, alphabet => ['a', 'b',...]) for table sizes bigger than 10";
    }
    if ($o->{verbose}) {
	print "Set size of Huffman code alphabet to $size.\n";
    }
    # If this is supposed to be a probability distribution, check
    my $notprob = $options{notprob};
    if ($notprob) {
	for my $k (keys %$s) {
	    my $value = $s->{$k};
	    if ($value < 0.0) {
		croak "Negative weight $value for symbol $k";
	    }
	}
    }
    else {
	my $total = 0.0;
	for my $k (keys %$s) {
	    my $value = $s->{$k};
	    if ($value < 0.0 || $value > 1.0) {
		croak "Value $value for symbol $k is not a probability; use \$o->symbols (\\\%s, notprob => 1) if not a probability distribution";
	    }
	    $total += $s->{$k};
	}
	if (abs ($total - 1.0) > eps) {
	    croak "Input values don't sum to 1.0; use \$o->symbols (\\\%s, notprob => 1) if not a probability distribution";
	}
	if ($o->{verbose}) {
	    print "Is a valid probability distribution (total = $total).\n";
	}
    }
    # The number of tables. We need $t - 1 pointers to tables, which
    # each require one table entry, so $t is the smallest number which
    # satisfies
    #
    # $t * $size >= $nentries + $t - 1

    my $t = ceil (($nentries -1) / ($size - 1));
    if ($o->{verbose}) {
	print "This symbol table requires $t Huffman tables of size $size.\n";
    }
    if ($size > 2) {
	# The number of dummy entries we need is
	my $ndummies = $t * ($size - 1) - $nentries + 1;
	if ($o->{verbose}) {
	    print "The Huffman tables need $ndummies dummy entries.\n";
	}
	if ($ndummies > 0) {
	    # Insert $ndummies dummy entries with probability zero into
	    # our copy of the symbol table.
	    for (0..$ndummies - 1) {
		my $dummy = "dummy$_";
		if ($c{$dummy}) {
		    # This is a bug not a user error.
		    die "The symbol table already has an entry '$dummy'";
		}
		$c{$dummy} = 0.0;
	    }
	}
    }
    # The end-product, the Huffman encoding of the symbol table.
    my %h;
    my $nfake = 0;
    my %fakes;
    while ($nfake < $t) {
	if ($o->{verbose}) {
	    print "Making key list for sub-table $nfake / $t.\n";
	}
	my $total = 0;
	my @keys;

	# Find the $size keys with the minimum value and go through,
	# picking them out.
	for my $i (0..$size - 1) {
	    # This method is from
	    # https://stackoverflow.com/questions/1185822/how-do-i-create-or-test-for-nan-or-infinity-in-perl/1185828#1185828

	    # inf doesn't work on some versions of Perl, see
	    # http://www.cpantesters.org/cpan/report/314e30b0-6bfb-1014-8e6c-c1e3e4f7669d
	    my $min = 9**9**9;
	    my $minkey;
	    for my $k (sort keys %c) {
		if ($c{$k} < $min) {
		    $min = $c{$k};
		    $minkey = $k;
		}
	    }
	    $total += $min;
	    if ($o->{verbose}) {
		print "Choosing $minkey with $min for symbol $i\n";
	    }
	    delete $c{$minkey};
	    push @keys, $minkey;
	    $h{$minkey} = $i;
	}
	# The total weight of this table.
	# The next table
	my @huff;
	for my $i (0..$size - 1) {
	    my $k = $keys[$i];
	    if (! defined $k) {
		last;
	    }
	    push @huff, $k;
	    if ($k =~ /^fake/) {
		addcodetosubtable (\%fakes, \%h, $k, $size, $i);
	    }
	}
	my $fakekey = 'fake'.$nfake;
	$c{$fakekey} = $total;
	$fakes{$fakekey} = \@huff;
	$nfake++;
    }
    if ($o->{verbose}) {
	print "Deleting dummy keys.\n";
    }
    for my $k (keys %h) {
	if ($k =~ /fake|dummy/) {
	    delete $h{$k};
	}
    }
    $o->{h} = \%h;
    $o->{s} = $s;
    # Blank this out for the case that the user inserts a new symbol
    # table, etc.
    $o->{value_re} = undef;
    $o->{r} = undef;
}

sub xl
{
    my ($o) = @_;
    my $h = $o->{h};
    my $s = $o->{s};
    croak "Bad object" unless $h && $s;
    my $len = 0.0;
    my $total = 0.0;
    for my $k (keys %$h) {
	$len += length ($h->{$k}) * $s->{$k};
	$total += $s->{$k};
	if ($o->{verbose}) {
	    print "$k $h->{$k} $s->{$k} $len\n";
	}
    }
    return $len / $total;
}

sub table
{
    my ($o) = @_;
    return $o->{h};
}

sub encode_array
{
    my ($o, $msg) = @_;
    my @output;
    for my $k (@$msg) {
	my $h = $o->{h}{$k};
	if (! defined $h) {
	    carp "Symbol '$k' is not in the symbol table";
	    next;
	}
	push @output, $h;
    }
    return \@output;
}

sub encode
{
    my ($o, $msg) = @_;
    my $output = $o->encode_array ($msg);
    return join '', @$output;
}

sub decode
{
    my ($o, $msg) = @_;
    if (! $o->{value_re}) {
	my @values = sort {length ($b) <=> length ($a)} values %{$o->{h}};
	my $value_re = '(' . join ('|', @values) . ')';
	$o->{value_re} = $value_re;
	if ($o->{verbose}) {
	    print "Value regex is ", $o->{value_re}, "\n";
	}
    }
    if (! $o->{r}) {
	$o->{r} = {reverse %{$o->{h}}};
    }
    my @output;
    while ($msg =~ s/^$o->{value_re}//) {
	push @output, $o->{r}{$1};
    }
    if (length ($msg) > 0) {
	carp "Input starting from $msg was not Huffman encoded using this table";
    }
    return \@output;
}

sub save
{
    my ($o) = @_;
    return create_json ($o);
}

sub load
{
    my ($o, $data) = @_;
    my $input = parse_json ($data);
    for my $k (keys %$input) {
	$o->{$k} = $input->{$k};
    }
}


1;
