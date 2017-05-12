use 5.010;
use Capture::Attribute;

sub Some::Module::foo {
	print "Hello";
}

sub CAP :Capture { (shift)->(@_) } # generic wrapper

my $orig = \&Some::Module::foo;
local *Some::Module::foo = sub { CAP($orig, @_) };

say lc(Some::Module::foo());

