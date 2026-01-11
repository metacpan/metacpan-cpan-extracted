use Test::More;

my @BUILD;

{
	package Local::Foo;
	use Class::XSConstructor;
	sub BUILD { push @BUILD, __PACKAGE__ };
}

{
	package Local::Bar;
	use parent -norequire, 'Local::Foo';
	use Class::XSConstructor;
	sub BUILD { push @BUILD, __PACKAGE__ };
}

my $o = Local::Bar->new;

is_deeply(
	\@BUILD,
	[qw/ Local::Foo Local::Bar /],
);

@BUILD = ();

is_deeply( $o->BUILDALL( {} ), $o );

is_deeply(
	\@BUILD,
	[qw/ Local::Foo Local::Bar /],
);

done_testing;
