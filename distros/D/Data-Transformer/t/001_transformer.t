#!/usr/bin/perl

use strict;
use Test::More tests => 29;

############## PRELIMINARIES #############

my $str = 'abc';
my $data = {
			ar => [qw(a b),
				   [ qw(x y z) ],
				   sub { $_[0] + $_[1] },
				   qw(c d e f 1 2 3 4 5 6 7 8),
				   { hmm=> { x=>'y', z=>sub{ $_[0] + $_[1] } }},
				  ],
			ha => { a   => 1,
					b   => 2,
					ar2 => [1,1,2,3,5,8,13,21,34,55], },
			st => 'ALL UPPER CASE',
			co => sub { $_[0] + $_[1] },
			gl => \*DATA,
			sc => \$str,
			ob => new DummyObj,
};
# Add a couple of circularities, to make things tougher
$data->{DATA} = $data;
$data->{'ha'}->{'circular'} = $data->{'ar'};


my %opt;
# switch case of strings, multiply numbers by 3
$opt{normal} = sub {
	local($_) = shift;
	if    ($$_ =~ /^\d+$/) { $$_*= 3 }
	elsif (lc($$_) eq $$_) { $$_ = uc($$_) }
	else                   { $$_ = lc($$_) }
};
# remove first elem of arrays
$opt{array} = sub {	shift @{ $_[0] } };
# prefix 'KEY:' to hash keys
$opt{hash} = sub {
	my $h = shift;
	my @k = keys %$h;
	for (@k) {
		next if m{^KEY:}; # ##};
		$h->{'KEY:'.$_} = $h->{$_};
		delete $h->{$_};
	}
};
# replace with different sub (avoid infinite loop!)
$opt{code} = sub {
	my $cr = shift;
	return unless $cr->(1,1) == 2;
	return sub { sub { 7 * $cr->(@_) } };
};
# read first line of filehandle, replace node with reversed contents
$opt{glob} = sub {
	my $g = shift;
	my $txt = <$g>;
	chomp $txt;
	return sub { reverse($txt) };
};
# dereference scalar ref
$opt{scalar} = sub {
	my $contents = ${ $_[0] };
	return sub { $contents; }
};
# set param of DummyObj obj
$opt{DummyObj} = sub {
	shift->param("tested","yes");
};


############## TESTS #############

BEGIN { use_ok('Data::Transformer') }
my $t;
ok ( $t = Data::Transformer->new(%opt), "new Data::Transformer");
isa_ok ( $t, 'Data::Transformer');
can_ok ( $t, qw(traverse) );

ok ( limited($data,normal=>sub{}), "limited traverse - normal only");
ok ( limited($data,hash=>sub{}), "limited traverse - hash only");
ok ( limited($data,glob=>sub{}), "limited traverse - glob only");
ok ( limited($data,scalar=>sub{}), "limited traverse - scalar only");
ok ( limited($data,array=>sub{}), "limited traverse - array only");
ok ( limited($data,code=>sub{}), "limited coderef only");

ok ( $t->traverse($data) , "comprehensive traverse");
is ( scalar(grep {not /^KEY/} keys %$data), 0, "key transform" );
is ( $data->{'KEY:sc'}, "ABC", "case switch 1" );
is ( $data->{'KEY:st'}, "all upper case", "case switch 2" );
is ( $data->{'KEY:ar'}->[-1]->{'KEY:hmm'}->{'KEY:x'}, "Y", "deep + case switch 3" );
is ( $data->{'KEY:ar'}->[0], "B", "array shift 1" );
is ( $data->{'KEY:ar'}->[1]->[0], 'Y', "array shift 2" );
is ( $data->{'KEY:ha'}->{'KEY:ar2'}->[1], 6, "array shift 3 + multiplication 1" );
is ( $data->{'KEY:ar'}->[-2], "24", "multiplication 2" );
is ( $data->{'KEY:ha'}->{'KEY:ar2'}->[-1], "165", "multiplication 3" );
is ( $data->{'KEY:gl'}, "GNITSET", "glob + reiteration");
is ( $data->{'KEY:co'}->(3,4), 49, "coderef");
is ( $data->{'KEY:sc'}, "ABC", "scalar ref + reiteration");
is ( eval{ $data->{'KEY:ob'}->param("tested") }, "yes", "object node");

is( deviant($data,1,%opt), "Maximum node calls (1) reached", "small node_limit" );
is( deviant($data,2**20,%opt), "Cannot set node_limit higher than 2**20-1", "big node_limit" );
is( deviant($data,0), "You need to specify an action for some node type", "missing option" );
is( deviant($data,0,%opt,glob=>1), "The value for the 'glob' option needs to be a coderef", "non-coderef option" );
is( deviant(1,0,%opt), "Data needs to be a reference", "non-reference data" );

sub deviant {
	my ($data,$limit,%opt) = @_;
	my $t;
	eval {
		$t = Data::Transformer->new(%opt,node_limit=>$limit);
		$t->traverse($data);
	};
	if ($@) {
		$@ =~ s/(.*) at.*$/$1/s;
		$@ =~ s/:.*$//;
		my $err = $@;
		return $err;
	}
	return "No exception raised??";
}

sub limited {
	my ($data,%opt) = @_;
	my $t;
	eval {
		$t = Data::Transformer->new(%opt);
		$t->traverse($data);
	};
	return 0 if $@;
	return 1;
}

# Class for testing...
package DummyObj;
sub new { return bless {}; }
sub param {
	my ($self,$key,$val) = @_;
	$self->{$key} = $val if defined($val);
	return $self->{$key};
}

__END__
testing
