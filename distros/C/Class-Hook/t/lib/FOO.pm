package FOO;
use Data::Dumper;

sub new {
	my $class = shift;
	my $param = shift;
#	print "new called with ".Dumper(\@_) . "from ".caller(0)."\n";
	$self = { key1 => 'Hello there',
              key2 => $param };
	return bless $self => $class;
}

sub bar {
#	print "bar called with ".Dumper(\@_) . "from ".caller(0)."\n";
	my $self = shift;
	return "Bar return string";
}

sub bur {
#	print "bur called with ".Dumper(\@_) . "from ".caller(0)."\n";
	return (0, 1, 3, [0, 1, { k1 => 'lkjlkj', k2 => 9} ]);
}
1;
