use Contextual::Return;

sub foo {
    return LAZY { print "ok 3   # In lazy eval of foo()\n"; 'foo' }
}

print "1..4\n";
print "ok 1   # Before call to foo()\n";
my $foo = foo();
print "ok 2   # After call to foo()\n";

print "not " unless $foo eq 'foo';
print "ok 4   # After lazy eval of foo()\n";

