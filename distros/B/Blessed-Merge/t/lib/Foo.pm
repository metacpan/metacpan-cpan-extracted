package Foo;

sub new {
	bless {}, $_[0];
}

sub test {
	return 'okay';
}

1;
