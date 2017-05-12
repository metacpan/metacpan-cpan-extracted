#   -*- perl -*-

use strict qw(vars subs);

use Test::More tests => 18;

use_ok("Data::Lazy");

#---------------------------------------------------------------------
#  Test Examples in Synopsis
{
    no strict 'subs';
    package SomePackage;
    use Data::Lazy variablename => '"code"', Data::Lazy::LAZY_READONLY;
}

is($SomePackage::variablename, "code",
   "use Data::Lazy foo => 'code'");

{
    package SomeOtherPackage;
    use Data::Lazy variablename => \&fun;
    sub fun { "hooray!" }
}

is($SomeOtherPackage::variablename, "hooray!",
   "use Data::Lazy foo => \&fun");

{
    package SomeThirdPackage;
    use Data::Lazy '@variablename' => \&fun;
    sub fun { (qw(how about that))[shift] }
}

is($SomeThirdPackage::variablename[0], "how", "use Data::Lazy ()");
is($SomeThirdPackage::variablename[2], "that", "use Data::Lazy ()");
is(@SomeThirdPackage::variablename, 3, "use Data::Lazy (@)");

# new example, that works ;)
{
    package SomeFourthPackage;
    use Data::Lazy;
    my $c = 0;
    use vars qw($foo);
    tie $foo, "Data::Lazy", sub { "foo".($c++) }, LAZY_READONLY;
}

is($SomeFourthPackage::foo, "foo0", 'tie $variable, Data::Lazy => ...');
is($SomeFourthPackage::foo, "foo0", 'data fetched only once');
eval {
    $SomeFourthPackage::foo = "bar";
};
isnt($@, "", "Read-only variables are read-only");

#---------------------------------------------------------------------
#  Test LAZY_STORECODE
{
    package SomePackage;
    use vars qw($foo);
    use Data::Lazy;
    my $c = 0;
    tie $foo, 'Data::Lazy' => sub { "foo".($c++) }, LAZY_STORECODE;
}

is($SomePackage::foo, "foo0", "Returned OK");
is($SomePackage::foo, "foo0", "Called once only");
eval {
    my $c = 0;
    $SomePackage::foo = sub { "bar".($c++) };
};
is($@, "", "LAZY_STORECODE");
is($SomePackage::foo, "bar0", "New sub called");
is($SomePackage::foo, "bar0", "New sub called once only");

undef($SomePackage::foo);
is($SomePackage::foo, "bar1", "New sub called again after undef");

$SomePackage::foo = undef;
is($SomePackage::foo, "bar2", "New sub called again after = undef");

# test for scalar code version left as an exercise for the maintainer
# :)

#---------------------------------------------------------------------
#  Test LAZY_STOREVALUE
{
    package SomePackage;
    use vars qw($bar $see);
    use Data::Lazy;
    $see = 0;
    tie $foo, 'Data::Lazy' => sub { "cheese".($see++) },
	LAZY_STOREVALUE;
}

eval {
    $SomePackage::bar = "hello";
};
is($SomePackage::bar, "hello", "LAZY_STOREVALUE");
is($SomePackage::see, 0, "sub not called with LAZY_STOREVALUE");

