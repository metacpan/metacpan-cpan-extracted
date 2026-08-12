
use strict;
use warnings;

use require::relative q (test-helper.pl);

ok q (singleton Contrive::Class should not exist yet)
	=> got    => does_singleton_exist (q (Sample::Context::Singleton::Contrive::Class))
	;

contrive_class q (Sample::Context::Singleton::Contrive::Class);

it q (should resolve known class singleton (Sample::Context::Singleton::Contrive::Class))
	=> got    => sub { deduce q (Sample::Context::Singleton::Contrive::Class) }
	=> expect => q (Sample::Context::Singleton::Contrive::Class)
	;

it q (should load class dynamically)
	=> got    => sub { Sample::Context::Singleton::Contrive::Class->foo }
	=> expect => q (C:C:foo called)
	;

contrive_class q (Foo::Bar);

it q (shouldn't resolve unknown class singleton (Foo::Bar))
	=> got    => sub { deduce q (Foo::Bar) }
	=> throws => re (qr/Can't locate Foo.Bar.pm/)
	;

had_no_warnings;

done_testing;
