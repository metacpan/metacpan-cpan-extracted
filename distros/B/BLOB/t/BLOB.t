use BLOB;

print "1..11\n";

my $test = 0;
sub ok {
    my ($ok, $comment) = @_;
    ++$test;
    print "not " if not $ok;
    print "ok $test  # $comment\n";
}


ok(mark_blob(my $foo), "Marking a blob returns a true value");
ok(is_blob($foo), "The marked blob is recognized by is_blob");

ok(!is_blob(my $bar), "An uninitialized variable is not recognized as a blob");
ok(!is_blob(undef), "A literal undef is not recognized as a blob");
ok(!is_blob(0), "A numeric literal is not recognized as a blob");
ok(!is_blob(""), "A string literal is not recognized as a blob");

ok(my $ref = BLOB->mark(my $quux), "Marking a blob OO-wise returns a true value");
ok(is_blob($quux), "The OO-wise marked blob is recognized by is_blob");
ok($ref == \$quux, "The mark method returns a reference to its argument");
ok($ref->isa("BLOB"), "The reference is an object, and isa BLOB");
ok(ref($ref->can("can")) eq "CODE", "UNIVERSAL->can works as expected");
