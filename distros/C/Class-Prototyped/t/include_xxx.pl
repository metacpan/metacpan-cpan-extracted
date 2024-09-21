sub b { 'xxx.b' }

sub c { return thisObject(); }

thisObject()->reflect->addSlots(
	'parent*' => 'A',
	d => 'added.d',
	e => sub { 'xxx.e' },
);

1;
