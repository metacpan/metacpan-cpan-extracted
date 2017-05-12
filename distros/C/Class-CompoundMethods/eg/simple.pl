use Class::CompoundMethods 'append_method';

append_method('object::foo', 'foo');
$o = new object;
$o->foo;

sub foo { die "foo!\n" }
sub object::new { my $o; bless \$o, shift() }