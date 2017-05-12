use Acme::Wabby;

my $text = <<EOF;
From fairest creatures we desire increase,
That thereby beauty's rose might never die,
But as the riper should by time decease,
His tender heir might bear his memory:
But thou contracted to thine own bright eyes,
Feed'st thy light's flame with self-substantial fuel,
Making a famine where abundance lies,
Thy self thy foe, to thy sweet self too cruel:
Thou that art now the world's fresh ornament,
And only herald to the gaudy spring,
Within thine own bud buriest thy content,
And tender churl mak'st waste in niggarding:
Pity the world, or else this glutton be,
To eat the world's due, by the grave and thee.
EOF
my ($wabby1, $wabby2, $wabby3, $line);
my $TEST_COUNT = 12;
my $TEST_NUM = 1;

print "$TEST_NUM..$TEST_COUNT\n";
if ($wabby1 = Acme::Wabby->new) {
    print "ok $TEST_NUM\n";
}
else {
    print "not ok $TEST_NUM\n";
    exit 1;
}
$TEST_NUM++;
print "$TEST_NUM..$TEST_COUNT\n";
if ($wabby1->add($text)) {
    print "ok $TEST_NUM\n";
}
else {
    print "not ok $TEST_NUM\n";
    exit 1;
}
$TEST_NUM++;
print "$TEST_NUM..$TEST_COUNT\n";
if ($line = $wabby1->spew) {
    print "ok $TEST_NUM\n";
}
else {
    print "not ok $TEST_NUM\n";
    exit 1;
}
$TEST_NUM++;
print "$TEST_NUM..$TEST_COUNT\n";
if ($line = $wabby1->spew("Thy")) {
    print "ok $TEST_NUM\n";
}
else {
    print "not ok $TEST_NUM\n";
    exit 1;
}
$TEST_NUM++;
print "$TEST_NUM..$TEST_COUNT\n";
if ($wabby2 = Acme::Wabby->new( min_len => 3, max_len => 30,
            punctuation => [".","?","!","..."], case_sensitive => 1,
            hash_file => "./wabbyhash.dat",
            list_file => "./wabbylist.dat",
            autosave_on_destroy => 0, max_attempts => 1000 )) {
    print "ok $TEST_NUM\n";
}
else {
    print "not ok $TEST_NUM\n";
    exit 1;
}
$TEST_NUM++;
print "$TEST_NUM..$TEST_COUNT\n";
if ($wabby2->add($text)) {
    print "ok $TEST_NUM\n";
}
else {
    print "not ok $TEST_NUM\n";
    exit 1;
}
$TEST_NUM++;
print "$TEST_NUM..$TEST_COUNT\n";
if ($line = $wabby2->spew) {
    print "ok $TEST_NUM\n";
}
else {
    print "not ok $TEST_NUM\n";
    exit 1;
}
$TEST_NUM++;
print "$TEST_NUM..$TEST_COUNT\n";
if ($line = $wabby2->spew("Thy")) {
    print "ok $TEST_NUM\n";
}
else {
    print "not ok $TEST_NUM\n";
    exit 1;
}
$TEST_NUM++;
print "$TEST_NUM..$TEST_COUNT\n";
if ($wabby3 = Acme::Wabby->new( {min_len => 3, max_len => 30,
            punctuation => [".","?","!","..."], case_sensitive => 1,
            hash_file => "./wabbyhash.dat",
            list_file => "./wabbylist.dat",
            autosave_on_destroy => 0, max_attempts => 1000} )) {
    print "ok $TEST_NUM\n";
}
else {
    print "not ok $TEST_NUM\n";
    exit 1;
}
$TEST_NUM++;
print "$TEST_NUM..$TEST_COUNT\n";
if ($wabby2->add($text)) {
    print "ok $TEST_NUM\n";
}
else {
    print "not ok $TEST_NUM\n";
    exit 1;
}
$TEST_NUM++;
print "$TEST_NUM..$TEST_COUNT\n";
if ($line = $wabby2->spew) {
    print "ok $TEST_NUM\n";
}
else {
    print "not ok $TEST_NUM\n";
    exit 1;
}
$TEST_NUM++;
print "$TEST_NUM..$TEST_COUNT\n";
if ($line = $wabby2->spew("Thy")) {
    print "ok $TEST_NUM\n";
}
else {
    print "not ok $TEST_NUM\n";
    exit 1;
}
