package MyTest;

use CatalystX::self (
	self => { -as => 'this' },
	args => { -as => 'hiya' },
	catalyst => { -as => 'c' },
	'-all'
);

sub new { bless({},shift); }

sub test_self {
	return self;
}

sub test_catalyst {
	return catalyst;
}

sub test_args {
	my @a = args;
	return @a;
}

1;

