use Test::More;
use Test::Exception;

use App::Kit;

diag("Testing str() for App::Kit $App::Kit::VERSION");

my $app = App::Kit->new();

is( $app->str->portable_crlf, "\015\012", 'portable_crlf() returns \015\012' );

my $zbt = $app->str->zero_but_true;
is( $zbt, "0E0", 'zero_but_true() returns 0E0' );
cmp_ok( $zbt, '==', 0, 'zero_but_true() is zero in numeric context' );
ok( $zbt, "zero_but_true() is true" );

ok( !exists $INC{'String/UnicodeUTF8.pm'}, 'lazy under pinning not loaded before' );
is( $app->str->bytes_size("I ♥ perl"), "10", "bytes_size() correct" );
ok( exists $INC{'String/UnicodeUTF8.pm'}, 'lazy under pinning loaded after' );
is( $app->str->char_count("I ♥ perl"), "8", "char_count() correct" );

is( $app->str->prefix, "appkit", 'prefix() default' );
throws_ok { $app->str->prefix('') } qr{prefix must be at least 1 character},             'prefix() too short';
throws_ok { $app->str->prefix('sevenly') } qr{prefix can not be more than 6 characters}, 'prefix() too long';
throws_ok { $app->str->prefix('../etc') } qr{prefix can only contain A\-Z and 0\-9},     'prefix() invalid char';
is( $app->str->prefix('new'), 'new', 'prefix setting returns prefix' );
is( $app->str->prefix,        'new', 'prefix setting retained' );

ok( !exists $INC{'Data/Rand.pm'}, 'lazy under pinning not loaded before' );
my $rand = $app->str->rand();
ok( exists $INC{'Data/Rand.pm'}, 'lazy under pinning loaded after' );
is( length($rand), 32, "rand() default length correct" );
like( $rand, qr/\A[0-9a-zA-Z]+\Z/, "rand() default items correct" );

my $randx = $app->str->rand( 2, [ "\xe2\x99\xa5", "\xe2\x98\xba" ] );
is( $app->str->char_count($randx), 2, "rand() given length correct" );
like( $randx, qr/\A(:?\xe2\x99\xa5|\xe2\x98\xba)+\Z/, "rand() given items correct" );

#####################
#### YAML and JSON ##
#####################

my $my_data = {
    'str'   => 'I am a string.',
    'true'  => 1,
    'false' => 0,
    'undef' => undef,
    'empty' => "",
    'hash'  => {
        'nested' => {
            zop => 'bar',
        },
        'array' => [qw(a b c 42)],
    },
    'utf8' => "I \xe2\x99\xa5 Perl",    # (utf8 bytes)
    'int'  => int(42.42),
    'abs'  => abs(42.42),
};

my $yaml_cont = q{--- 
"abs": '42.42'
"empty": ''
"false": 0
"hash": 
  "array": 
    - 'a'
    - 'b'
    - 'c'
    - 42
  "nested": 
    "zop": 'bar'
"int": 42
"str": 'I am a string.'
"true": 1
"undef": ~
"utf8": 'I ♥ Perl'
};

my $json_cont = q();

#### YAML ##

is( $app->str->ref_to_yaml($my_data), $yaml_cont, 'structure turns into expected YAML' );
is_deeply( $app->str->yaml_to_ref($yaml_cont), $my_data, 'YAML turns into expected structure' );

is( $app->str->ref_to_yaml( { 'unistr' => "I \x{2665} Unicode" } ), qq{--- \n"unistr": 'I \xe2\x99\xa5 Unicode'\n}, 'structure (w/ unicode str) turns into expected YAML' );

#### JSON ##

like( $app->str->ref_to_json($my_data), qr/"utf8"\s*:\s*"I \xe2\x99\xa5 Perl"/, 'structure turns into expected JSON' );
is_deeply( $app->str->json_to_ref(qq({"foo":42})), { foo => 42 }, 'JSON turns into expected structure' );

like( $app->str->ref_to_json( { 'unistr' => "I \x{2665} Unicode" } ), qr/"unistr"\s*:\s*"I \xe2\x99\xa5 Unicode"/, 'structure (w/ unicode str) turns into expected JSON' );

is( $app->str->ref_to_jsonp($my_data), 'jsonp_callback(' . $app->str->ref_to_json($my_data) . ');', 'JSONP w/ no callback arg' );
is( $app->str->ref_to_jsonp( $my_data, 'scotch' ), 'scotch(' . $app->str->ref_to_json($my_data) . ');', 'JSONP w/ callback arg' );
is( $app->str->ref_to_jsonp( $my_data, 'mord mord' ), undef, 'JSONP w/ invalid callback arg' );

#### trim() ##

my @strings = (
    [ "foo",                                     "foo",                    "foo",              "none" ],
    [ "  f  oo  ",                               "f  oo",                  "f oo",             "basic" ],
    [ "  f  \xe2\x99\xa5oo  ",                   "f  \xe2\x99\xa5oo",      "f \xe2\x99\xa5oo", "basic bytes" ],
    [ "  f  \x{2665}oo  ",                       "f  \x{2665}oo",          "f \x{2665}oo",     "basic unicode" ],
    [ "\xc2\xa0foo\xc2\xa0\xc2\xa0bar\xc2\xa0",  "foo\xc2\xa0\xc2\xa0bar", "foo bar",          "nbsp" ],
    [ "f\x00oo \xc2\xa0b\xe2\x80\x8ba\x09r",     "foo \xc2\xa0bar",        "foo bar",          "funky chunks-bytes" ],
    [ "f\x{0000}oo \x{00a0}b\x{200b}a\x{0009}r", "foo \x{00a0}bar",        "foo bar",          "funky chunks-unicode" ],
);

for my $str (@strings) {
    is $app->str->trim( $str->[0] ), $str->[1], "trim($str->[3])";
    is $app->str->trim( $str->[0], 1 ), $str->[2], "trim($str->[3],1)";
}

### sha512 ###

is( $app->str->sha512(42),     '39ca7ce9ecc69f696bf7d20bb23dd1521b641f806cc7a6b724aaa6cdbffb3a023ff98ae73225156b2c6c9ceddbfc16f5453e8fa49fc10e5d96a3885546a46ef4', 'sha512 number' );
is( $app->str->sha512("perl"), 'a07b1e41acd79ad0da14aff1835099132c30c27f6bfd726304ecd19c2d8aaee81691ed56ec15e4d73f1bb6408f11a4842d43070ce3e02364e94d61a89748b122', 'sha512 bytes string' );

#### epoch ##

my $time  = time;
my $epoch = $app->str->epoch;
cmp_ok( $epoch, '>=', $time, 'epoch() works like time' );    # if this fails due to a race your clock is busted

#### attrs ##

my $attrs = $app->str->attrs( { title => "hello & world", class => "foo bar" } );
like( $attrs, qr/^ \S/,                       'attrs begines witha space' );
like( $attrs, qr/ class="foo bar"/,           'basic attr formatted as expected' );
like( $attrs, qr/ title="hello &amp; world"/, 'attr values with HTML escaped' );

$attrs = $app->str->attrs( { title => "hello & world", class => "foo bar", required => undef, barf => "" } );
like( $attrs, qr/^ \S/,                       'attrs begines witha space' );
like( $attrs, qr/ class="foo bar"/,           'basic attr formatted as expected 2' );
like( $attrs, qr/ title="hello &amp; world"/, 'attr values with HTML escaped 2' );
like( $attrs, qr/ barf=""/,                   'attr empty formatted as expected (empty value)' );
like( $attrs, qr/ required(?!=)/,             'attr undef formatted as boolean (no value)' );

$attrs = $app->str->attrs( { title => "hello & world", class => "foo bar", required => undef, barf => "" }, { barf => 1, required => 1, title => 1 } );
like( $attrs, qr/^ \S/,             'attrs begines witha space' );
like( $attrs, qr/ class="foo bar"/, 'basic attr formatted as expected 3' );
unlike( $attrs, qr/ title="hello &amp; world"/, 'attr ignored (value)' );
unlike( $attrs, qr/ barf=""/,                   'attr ignored (empty)' );
unlike( $attrs, qr/ required/,                  'attr ignored (undef)' );

#### escape_html ##

is( $app->str->escape_html(qq{<b>hack's&reg</b>The "planet's'" `peril` &copy;}), '&lt;b&gt;hack&#39;s&amp;reg&lt;/b&gt;The &quot;planet&#39;s&#39;&quot; &#96;peril&#96; &amp;copy;', q{escape_html() does multiple <>"'`& characters} );

done_testing;
