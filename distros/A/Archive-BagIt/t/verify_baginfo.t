use strict;
use warnings;
use diagnostics;
use File::Temp qw(tempdir);
use File::Slurp qw(read_file write_file);
use Test::More tests =>50;
use Test::Exception;
use Test::File;
use Archive::BagIt;
BEGIN { chdir 't' if -d 't' }
my @ROOT = grep {length} 'src';
### TESTS
my $SRC_BAG = File::Spec->catdir( @ROOT, 'src_bag');
my $SRC_FILES = File::Spec->catdir( @ROOT, 'src_files');
my $DST_BAG = File::Spec->catdir(@ROOT, 'dst_bag');
my $Class = 'Archive::BagIt';
## tests
use_ok($Class);
my $bag = $Class->new({bag_path=>$SRC_BAG});

{
    is(Archive::BagIt::_check_key(""), "key should have a length > null (key='')", "_check_key('')");
    is(Archive::BagIt::_check_key("foo:"), "key should not contain a colon! (key='foo:')", "_check_key('foo:')" );
    like(Archive::BagIt::_check_key("fo\no"), qr{key should match .* but contains newlines}, "_check_key('fo\\no')" );
    is(Archive::BagIt::_check_key(), "key should match '[^\\r\\n:]+', but is not defined", "_check_key()");
    is(Archive::BagIt::_check_value(""), "value should have a length > null (value='')", "_check_value('')");
    is(Archive::BagIt::_check_value(), "value should match '[^\\r\\n:]+', but is not defined", "_check_value()");
    $bag->{bag_info_file}="$SRC_BAG/bag-info.txt";
    my @tmp;
    @tmp= $bag->_extract_key_from_textblob(undef);
    is_deeply(\@tmp, [undef, undef], "extract_key_from_textblob(undef)");
    @tmp= $bag->_extract_key_from_textblob("");
    is_deeply(\@tmp, [undef, ""], "extract_key_from_textblob('')");
    @tmp= $bag->_extract_key_from_textblob("foo:");
    is_deeply(\@tmp, ["foo", undef], "extract_key_from_textblob('foo:')");
    @tmp= $bag->_extract_key_from_textblob("foo:\nbar");
    is_deeply(\@tmp, ["foo", "\nbar"], "extract_key_from_textblob('foo:\\nbar')");
    @tmp= $bag->_extract_key_from_textblob("foo:bar");
    is_deeply(\@tmp, ["foo", "bar"], "extract_key_from_textblob('foo:bar')");
    @tmp= $bag->_extract_key_from_textblob("foo: bar");
    is_deeply(\@tmp, ["foo", "bar"], "extract_key_from_textblob('foo: bar')");
    @tmp= $bag->_extract_key_from_textblob("foo : bar");
    is_deeply(\@tmp, ["foo", "bar"], "extract_key_from_textblob('foo : bar')");
    @tmp= $bag->_extract_key_from_textblob("foo : bar\n  baz");
    is_deeply(\@tmp, ["foo", "bar\n  baz"], "extract_key_from_textblob('foo : bar\\n  baz')");
    @tmp= $bag->_extract_key_from_textblob("foo : bar\n  baz\n  tss");
    is_deeply(\@tmp, ["foo", "bar\n  baz\n  tss"], "extract_key_from_textblob('foo : bar\\n  baz\\n  tss')");
    @tmp= $bag->_extract_key_from_textblob("foo:bar\nfoo2:bar2");
    is_deeply(\@tmp, ["foo", "bar\nfoo2:bar2"], "extract_key_from_textblob('foo:bar\\nfoo2:bar2')");
    @tmp= $bag->_extract_key_from_textblob("foo:bar\n  baz\n  tss\nfoo2:bar2");
    is_deeply(\@tmp, ["foo", "bar\n  baz\n  tss\nfoo2:bar2"], "extract_key_from_textblob('foo:bar\\n  baz\\n  tss\\nfoo2:bar2')");
    @tmp= $bag->_extract_key_from_textblob("foo:bar:baz");
    is_deeply(\@tmp, ["foo", "bar:baz"], "extract_key_from_textblob('foo:bar:baz')");
    ###
    @tmp= $bag->_extract_value_from_textblob(undef);
    is_deeply(\@tmp, [undef, undef], "extract_value_from_textblob(undef)");
    @tmp= $bag->_extract_value_from_textblob("");
    is_deeply(\@tmp, [undef, ""], "extract_value_from_textblob('')");
    @tmp= $bag->_extract_value_from_textblob("bar");
    is_deeply(\@tmp, ["bar", ""], "extract_value_from_textblob('bar')");
    @tmp= $bag->_extract_value_from_textblob("bar\n  baz");
    is_deeply(\@tmp, ["bar\n  baz", ""], "extract_value_from_textblob('bar\\n  baz')");
    @tmp= $bag->_extract_value_from_textblob("bar\n  baz\n  tss");
    is_deeply(\@tmp, ["bar\n  baz\n  tss", ""], "extract_value_from_textblob('bar\\n  baz\\n  tss')");
    @tmp= $bag->_extract_value_from_textblob("bar\nfoo2:bar2");
    is_deeply(\@tmp, ["bar", "foo2:bar2"], "extract_value_from_textblob('bar\\nfoo2:bar2')");
    @tmp= $bag->_extract_value_from_textblob("bar\n  baz\n  tss\nfoo2:bar2");
    is_deeply(\@tmp, ["bar\n  baz\n  tss", "foo2:bar2"], "extract_value_from_textblob('bar\\n  baz\\n  tss\\nfoo2:bar2')");
    @tmp= $bag->_extract_value_from_textblob("bar:baz");
    is_deeply(\@tmp, ["bar:baz", ""], "extract_value_from_textblob('bar:baz')");
    @tmp= $bag->_extract_value_from_textblob("bar\nfoo:baz");
    is_deeply(\@tmp, ["bar", "foo:baz"], "extract_value_from_textblob('bar\\nfoo:baz')");
}

{
    delete $bag->{'warnings'};
    delete $bag->{'errors'};
    delete $bag->{'bag_info'};
    throws_ok( sub{$bag->_parse_bag_info( undef )}, qr{_parse_baginfo.* called with undef value}, "bag-info parsing undef");
}
{
    delete $bag->{'warnings'};
    delete $bag->{'errors'};
    delete $bag->{'bag_info'};
    my $got = $bag->_parse_bag_info( "" );
    is_deeply( $got, [], "bag-info parsing valid empty");
    $bag->{"bag_info"} = $got;
    ok($bag->verify_baginfo(), "bag-info verify valid empty");
    is_deeply( $bag->{warnings}, ["Payload-Oxum was expected in bag-info.txt, but not found!"], "bag-info parsing valid empty, warning for missed payload oxum");
}

{
    delete $bag->{'warnings'};
    delete $bag->{'errors'};
    delete $bag->{'bag_info'};
    my $input =<<BAGINFO;
Foo: Bar
Foo1: Baz
Foo2 : Bar2
Foo3:   Bar3
Foo4: Bar4
  Baz4
  Bay4
Foo5: Bar5
Foo6: Bar6: Baz6
BAGINFO
    my @expected = (
        { "Foo", "Bar" },
        { "Foo1", "Baz"},
        { "Foo2", "Bar2"},
        { "Foo3", "Bar3"},
        { "Foo4", "Bar4\n  Baz4\n  Bay4"},
        { "Foo5", "Bar5"},
        { "Foo6", "Bar6: Baz6"}
    );
    my $got = $bag->_parse_bag_info( $input );
    is_deeply( $got, \@expected, "bag-info parsing valid");
    $bag->{"bag_info"} = $got;
    ok($bag->verify_baginfo(), "bag-info verify valid");
    is_deeply( $bag->{warnings}, ["Payload-Oxum was expected in bag-info.txt, but not found!"], "bag-info parsing valid, warning for missed payload oxum");
}

{
    delete $bag->{'warnings'};
    delete $bag->{'errors'};
    delete $bag->{'bag_info'};
    my $input =<<BAGINFO;
Foo:
BAGINFO
    my $got = $bag->_parse_bag_info( $input );
    is_deeply( $got, [], "bag-info parsing invalid");
    $bag->{"bag_info"} = $got;
    ok(!$bag->verify_baginfo(), "bag-info verify invalid");
    #is_deeply( $bag->{warnings}, ["Payload-Oxum was expected in bag-info.txt, but not found!"], "bag-info parsing valid, warning for missed payload oxum");
    is_deeply($bag->{errors}, ["the baginfo file '$SRC_BAG/bag-info.txt' could not be parsed correctly, because following text blob not fullfill the match requirements for values: '\n'"], "bag-info parsing valid, error logged" );
}

{
    my $input =<<BAGINFO;
 ::: foo
BAGINFO
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, "bag-info.txt"), $input);
    my $bag2 = $Class->new({bag_path=>$dir});
    my $got = $bag2->verify_baginfo();
    ok(!$bag2->verify_baginfo(), "bag-info verify fully invalid");
    is_deeply($bag2->{errors}, ["the baginfo file '$dir/bag-info.txt' could not be parsed correctly, because following text blob not fullfill the match requirements for keys: '$input'"], "bag-info parsing valid, error logged" );
}
{

    my $input =<<BAGINFO;
Foo: Bar
Foo: Baz
Foo2 : Bar2
Foo3:   Bar3
Foo4: Bar4
  Baz4
  Bay4
Foo5: Bar5
Foo6: Bar6: Baz6
BAGINFO
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, "bag-info.txt"), $input);
    my $bag2 = $Class->new({bag_path=>$dir});
    ok($bag2->verify_baginfo(), "bag-info verify fully valid");
    is_deeply($bag2->{warnings}, ["Payload-Oxum was expected in bag-info.txt, but not found!"], "bag-info parsing fully valid, warning for missed payload oxum");
    is_deeply($bag2->{errors}, [], "bag-info verify fully valid, no error log exists");
}

{
    delete $bag->{'warnings'};
    delete $bag->{'errors'};
    delete $bag->{'bag_info'};
    my $input = <<BAGINFO;
test:
Bagging-Date: 2025-02-20
Bag-Software-Agent: Archive::BagIt <https://metacpan.org/pod/Archive::BagIt>
Payload-Oxum: 1.1
Bag-Size: 1 B
BAGINFO
    my $expected = <<EXPECTED;

Bagging-Date: 2025-02-20
Bag-Software-Agent: Archive::BagIt <https://metacpan.org/pod/Archive::BagIt>
Payload-Oxum: 1.1
Bag-Size: 1 B
EXPECTED

    my $got = $bag->_parse_bag_info($input);
    is_deeply($got, [], "bag-info verify fully valid, parsed output");
    #is_deeply($bag->{warnings}, ["Payload-Oxum was expected in bag-info.txt, but not found!"], "bag-info parsing fully valid, warning for missed payload oxum");
    is_deeply($bag->{errors},
        ["the baginfo file 'src/src_bag/bag-info.txt' could not be parsed correctly, because following text blob not fullfill the match requirements for values: '$expected'"], "bag-info verify fully valid, no error log exists");
}

{
    my $dir = tempdir(CLEANUP => 1);
    my $input =<<BAGINFO;
test:
BAGINFO
    mkdir(File::Spec->catdir($dir, "data"));
    write_file(File::Spec->catfile($dir, "data", "1.txt"), "1");
    write_file(File::Spec->catfile($dir, "bag-info.txt"), $input);
    throws_ok ( sub {my $bag3=$Class->make_bag($dir);}, qr{Could not create baginfo, because current file.* has parsing errors}, "check bag_info.txt while calling make_bag()");
}

{
    my $dir = tempdir(CLEANUP => 1);
    my $input =<<BAGINFO;
test:
BAGINFO
    mkdir(File::Spec->catdir($dir, "data"));
    write_file(File::Spec->catfile($dir, "bagit.txt"), "BagIt-Version: 1.0\nTag-File-Character-Encoding: UTF-8");
    write_file(File::Spec->catfile($dir, "bag-info.txt"), $input);
    write_file(File::Spec->catfile($dir, "manifest-sha512.txt"), "");

    my $bag4=$Class->new($dir);
    ok(!$bag4->verify_baginfo(), "verify_baginfo() with broken bag-info.txt");
    throws_ok(sub{$bag4->verify_bag({report_all_errors => 1})}, qr{the baginfo file .* could not be parsed correctly, because following text blob not fullfill the match requirements for values}, "verify_bag() with broken bag-info.txt");
}

{
    my $bag = new_ok("Archive::BagIt" => [ bag_path => File::Spec->catdir(@ROOT, 'broken_baginfo') ]);
    throws_ok(sub {$bag->verify_bag({ report_all_errors => 1 })}, qr{bag verify for bagit version '1.0' failed with invalid files.\nthe baginfo file .* could not be parsed correctly, because following text blob not fullfill the match requirements for values}, "broken baginfo bag");
}

1;
