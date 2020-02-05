#!perl
# libucl-0.8.1/python/tests/test_dump.py

use strict;
use warnings;
use Test::More;
use Test::Exception;
use List::Util qw(any);

use JSON::PP;
sub true  { JSON::PP::true(@_) }
sub false { JSON::PP::false(@_) }

use Config::UCL;

sub assertIn {
    my ($got, @valid) = @_;
    ok any { $got eq $_ } @valid or diag $got;
}

dies_ok { eval "ucl_dump()"; die $@ if $@ };

is ucl_dump(undef), 'null';
is ucl_dump({ a => undef }), "a = null;\n";
is ucl_dump({ a => 1 })    , "a = 1;\n";
is ucl_dump({ a => { b => 1 } }), "a {\n    b = 1;\n}\n";
is ucl_dump({ a => [1,2,3,4] }), "a [\n    1,\n    2,\n    3,\n    4,\n]\n";
is ucl_dump({ a => "b" }), "a = \"b\";\n";

#     @unittest.skipIf(sys.version_info[0] > 2, "Python3 uses unicode only")
#     def test_unicode(self):
#         data = { unicode("a") : unicode("b") }
#         valid = unicode("a = \"b\";\n")
#         self.assertEqual(ucl.dump(data), valid)

is ucl_dump({ a => 1.1 }), "a = 1.100000;\n";
assertIn ucl_dump({ a => true, b => false }), "a = true;\nb = false;\n", "b = false;\na = true;\n";
is ucl_dump({}), "";
assertIn ucl_dump({ a => 1, b => "bleh;" }, { ucl_emitter => UCL_EMIT_JSON } ),
    qq#{\n    "a": 1,\n    "b": "bleh;"\n}#, qq#{\n    "b": "bleh;",\n    "a": 1\n}#;

{
    my $out = ucl_dump({ key => "val" });
    ok !utf8::is_utf8($out);
}
{
    my $out = ucl_dump({ key => "val" }, { utf8 => 1 });
    ok  utf8::is_utf8($out);
}
{
    use utf8;
    my $out = ucl_dump({ "キー" => "値" }, { utf8 => 1 });
    ok  utf8::is_utf8($out);
    is $out, qq#キー = "値";\n#;
}
{
    my $out = ucl_dump({ "キー" => "値" }, { utf8 => 1 });
    ok  utf8::is_utf8($out);
    isnt $out, qq#キー = "値";\n#;
}
{
    use Encode;
    my $out = ucl_dump({ "キー" => "値" });
    ok !utf8::is_utf8($out);
    isnt $out, decode_utf8(qq#キー = "値";\n#);
}

done_testing;
