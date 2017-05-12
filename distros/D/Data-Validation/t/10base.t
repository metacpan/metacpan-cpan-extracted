use t::boilerplate;

use Test::More;
use Class::Null;
use English qw( -no_match_vars );
use Unexpected;

use_ok 'Data::Validation';
use_ok 'Data::Validation::Constants';

sub new_e {
   my $config    = shift;
   my $validator = Data::Validation->new( %{ $config } );
   my $value     = eval { $validator->check_field( @_ ) };

   return $value, Data::Validation::Exception->caught();
}

sub test_val {
   my ($value, $e) = new_e( @_ );

   $e and $e->instance_of( 'Data::Validation::Exception' )
      and $e->class ne 'Data::Validation::Exception' and return $e->class;

   if ($e) { $e = $e->as_string; chomp $e; return $e }

   return $value;
}

my $f = {};

is test_val( $f, undef, 1 ), "Field '[?]' validation configuration not found",
   'No field def 1';
is test_val( $f, 'test', 1), "Field 'test' validation configuration not found",
   'No field def 2';

$f->{fields}->{test}->{validate} = q(isHexadecimal);
is test_val( $f, q(test), q(alive) ), q(Hexadecimal), 'Not hexadecimal';
is test_val( $f, q(test), q(dead) ),  q(dead),         'Is hexadecimal';

my ($value, $e) = new_e( $f, q(test), q(alive) );

like $e->explain, qr{ \Qcan only contain\E }imx, 'Explains error';

$f->{fields}->{test}->{validate} = q(isMandatory);
is test_val( $f, q(test), undef ), q(Mandatory), 'Missing field';
is test_val( $f, q(test), 1 ),     q(1),       'Mandatory field';

($value, $e) = new_e( $f, q(test), undef );
is $e->explain, q(), 'Default explain';

$f->{fields}->{test}->{validate} = q(isPrintable);
is test_val( $f, q(test), q() ),   q(Printable), 'Not printable';
is test_val( $f, q(test), q(q; *) ), q(q; *),          'Printable';

$f->{fields}->{test}->{validate} = q(isSimpleText);
is test_val( $f, q(test), q(*3$%^) ),        q(SimpleText), 'Not simple text';
is test_val( $f, q(test), q(this is text) ), q(this is text),   'Simple text';

SKIP: {
   $f->{fields}->{test}->{validate} = q(isValidHostname);

   (test_val( $f, q(test), q(example.com)        ) eq q(example.com)   and
    test_val( $f, q(test), q(google.com)         ) eq q(google.com)    and
    test_val( $f, q(test), q(does_not_exist)     ) eq q(ValidHostname) and
    test_val( $f, q(test), q(does_not_exist.com) ) eq q(ValidHostname) and
    test_val( $f, q(test), q(does.not.exist.com) ) eq q(ValidHostname) and
    test_val( $f, q(test), q(does.not.exist.example.com) ) eq q(ValidHostname))
      or skip 'valid hostname test - Broken resolver', 8;

   is test_val( $f, q(test), q(does_not_exist) ), q(ValidHostname),
      'Invalid hostname - does_not_exist';
   is test_val( $f, q(test), q(does_not_exist.com) ), q(ValidHostname),
      'Invalid hostname - does_not_exist.com';
   is test_val( $f, q(test), q(does.not.exist.com) ), q(ValidHostname),
      'Invalid hostname - does.not.exist.com';
   is test_val( $f, q(test), q(does.not.exist.example.com) ),
      q(ValidHostname), 'Invalid hostname - does.not.exist.example.com';
   is test_val( $f, q(test), q(127.0.0.1) ), q(127.0.0.1),
      'Valid hostname - 127.0.0.1';
   is test_val( $f, q(test), q(example.com) ), q(example.com),
      'Valid hostname - example.com';
   is test_val( $f, q(test), q(localhost) ), q(localhost),
      'Valid hostname - localhost';
   is test_val( $f, q(test), q(google.com) ), q(google.com),
      'Valid hostname - google.com';
}

$f->{fields}->{test}->{validate} = q(isValidIdentifier);
is test_val( $f, q(test), 1 ),     q(ValidIdentifier), 'Invalid Identifier';
is test_val( $f, q(test), q(x) ),  q(x),               'Valid Identifier';

$f->{fields}->{test}->{validate} = q(isValidNumber isValidInteger);
is test_val( $f, q(test), 1.1 ),   q(ValidInteger), 'Invalid Integer';
is test_val( $f, q(test), q(1a) ), q(ValidNumber),  'Invalid Number';
is test_val( $f, q(test), 1 ),     1,               'Valid Integer';

$f->{fields}->{test}->{validate}
   = q(isValidNumber isValidInteger isBetweenValues);
$f->{constraints}->{test} = { min_value => 2, max_value => 4 };
is test_val( $f, q(test), 5 ), q(BetweenValues), 'Out of range';
is test_val( $f, q(test), 3 ), 3,                'In range';

$f->{fields}->{test}->{validate} = q(isValidText);
is test_val( $f, q(test), q(*3$%^) ),        q(ValidText), 'Not valid text';
is test_val( $f, q(test), q(this/is/text) ), q(this/is/text),   'Valid text';

$f->{fields}->{test}->{validate} = 'isValidTime';
is test_val( $f, 'test', '0700'     ), 'ValidTime', 'Invalid Time';
is test_val( $f, 'test', '07:00'    ), '07:00',     'Valid Time - no secs';
is test_val( $f, 'test', '07:00:59' ), '07:00:59',  'Valid Time - with secs';
is test_val( $f, 'test', '07:00:60' ), 'ValidTime', 'Valid Time - bad secs';
is test_val( $f, 'test', '07:60'    ), 'ValidTime', 'Valid Time - bad mins';
is test_val( $f, 'test', '24:00'    ), 'ValidTime', 'Valid Time - bad hours';

$f->{fields}->{test}->{validate} = q(isEqualTo);
$f->{constraints}->{test} = { value => 4 };
is test_val( $f, q(test), 5 ), q(EqualTo), 'Not equal';
is test_val( $f, q(test), 4 ), 4,          'Is equal';
$f->{constraints}->{test} = { value => 'four' };
is test_val( $f, q(test), 'four' ), 'four', 'Is equal - string';

$f->{fields}->{test}->{validate} = q(isValidLength);
$f->{constraints}->{test} = { min_length => 2, max_length => 4 };
is test_val( $f, q(test), q(qwerty) ), q(ValidLength), 'Invalid length';
is test_val( $f, q(test), q(qwe) ),    q(qwe),         'Valid length';

($value, $e) = new_e( $f, q(test), q(qwerty) );
like $e->explain, qr{ \Qmust be greater\E }imx, 'Explains error with subs';

$f->{fields}->{test}->{validate} = q(isMatchingRegex);
$f->{constraints}->{test} = { pattern => q(...-...) };
is test_val( $f, q(test), q(123 456) ), q(MatchingRegex), 'Non Matching Regex';
is test_val( $f, q(test), q(123-456) ), q(123-456),       'Matching Regex';

$f->{fields}->{test}->{validate} = q(isAllowed);
$f->{constraints}->{test} = { allowed => [ 'a', 'b', 'c' ] };
is test_val( $f, q(test), q(x) ), q(Allowed), 'Is not allowed';
is test_val( $f, q(test), q(b) ), q(b),  'Is allowed';

SKIP: {
   $ENV{AUTHOR_TESTING} or skip 'valid date developers only', 1;

   $f->{fields}->{test}->{validate} = 'isValidDate';
   is test_val( $f, 'test', '9/13/2001' ), 'ValidDate', 'Invalid date';
   is test_val( $f, 'test', '9/11/2001' ), '9/11/2001', 'Valid date';
   is test_val( $f, 'test', '13/9/2001' ), '13/9/2001', 'Valid date - GB';
}

$f->{fields}->{test}->{validate} = q(isValidEmail);
is test_val( $f, q(test), q(fred) ),  q(ValidEmail), 'Invalid email';
is test_val( $f, q(test), q(a@b.c) ), q(a@b.c),      'Valid email';

$f->{fields}->{test}->{validate} = q(isValidPassword);
is test_val( $f, q(test), q(fred) ), q(ValidPassword), 'Invalid password 1';
is test_val( $f, q(test), q(freddyBoy) ), q(ValidPassword),
   'Invalid password 2';
is test_val( $f, q(test), q(qw3erty) ), q(qw3erty), 'Valid password';
$f->{constraints}->{test}->{min_length} = 8;
is test_val( $f, q(test), q(qw3erty) ), q(ValidPassword),
   'Invalid password 3';
is test_val( $f, q(test), q(123456789) ), q(ValidPassword),
   'Invalid password 4';

$f->{fields}->{test}->{validate} = q(isValidPath);
is test_val( $f, q(test), q(this is not ok;) ), q(ValidPath),
   'Invalid path';
is test_val( $f, q(test), q(/this/is/ok) ), q(/this/is/ok), 'Valid path';

$f->{fields}->{test}->{validate} = q(isValidPostcode);
is test_val( $f, q(test), q(CA123445) ), q(ValidPostcode), 'Invalid postcode';
is test_val( $f, q(test), q(SW1A 4WW) ), q(SW1A 4WW),      'Valid postcode';

SKIP: {
   $ENV{AUTHOR_TESTING} or skip 'valid URL developers only', 1;

   $f->{fields}->{test}->{validate} = 'isValidURL';
   is test_val( $f, 'test', 'http://notlikeky.nono' ), 'ValidURL',
      'Invalid URL - 1';
   is test_val( $f, 'test', 'notlikeky.nono' ), 'ValidURL',
      'Invalid URL - 2';
   is test_val( $f, 'test', 'http://google.com' ), 'http://google.com',
      'Valid URL';
}

$f->{fields}->{test}->{validate} = q(isHexadecimal|isValidNumber);
is test_val( $f, q(test), 1.2 ), 1.2, 'Is hexadecimal or a number - 1';
is test_val( $f, q(test), 'dead' ), 'dead', 'Is hexadecimal or a number - 2';
like test_val( $f, q(test), 'wrong' ), qr{ \Qis none of\E }mx,
   'Is not hexadecimal or a number';

{  package BadTestConstraint;

   sub _validate_typo {}

   $INC{ 'BadTestConstraint.pm' } = __FILE__;
}

$f->{fields}->{test}->{validate} = '+BadTestConstraint';
like test_val( $f, 'test', q(x) ), qr{ \Qlocate object\E }mx, 'Bad constraint';

$f->{fields}->{test}->{validate} = '+UnknownTestConstraint';
like test_val( $f, 'test', q(x) ), qr{ \Qlocate UnknownTestConstraint\E }mx,
   'Unknown constraint';

$f->{fields}->{subr_field_name }->{validate} = q(isValidPostcode);
$f->{fields}->{subr_field_name1}->{validate} = q(isValidPath);
$f->{fields}->{subr_field_name2}->{validate} = q(isValidPassword);
$f->{fields}->{subr_field_name3}->{validate} = q(isValidEmail);
$f->{fields}->{subr_field_name4}->{validate} = q(isValidLength);
$f->{fields}->{subr_field_name5}->{validate} = q(compare);
$f->{constraints}->{subr_field_name5} = { other_field => q(field_name4) };

my $validator = Data::Validation->new( %{ $f } );
my $vals = { field_name  => q(SW1A 4WW),
             field_name1 => q(/this/is/ok),
             field_name2 => q(qw3erty),
             field_name3 => q(a@b.c),
             field_name4 => q(qwe),
             field_name5 => q(qwe) };

eval { $validator->check_form( q(subr_), $vals ) };

$e = Unexpected->caught() || Class::Null->new();

ok !$e->error, 'Valid form';

$vals->{field_name5} = q(not_the_same_as_field4);
eval { $validator->check_form( q(subr_), $vals ) };
$e = Unexpected->caught() || Class::Null->new();
like $e->args->[0]->as_string, qr{ \Qdoes not 'eq' field\E }mx,
   'Non matching fields';

ok $e->args->[0]->args->[0] eq q(field_name5)
   && $e->args->[0]->args->[1] eq q(eq)
   && $e->args->[0]->args->[2] eq q(field_name4), 'Field comparison args';

$f->{constraints}->{subr_field_name5}->{operator} = q(ne);
eval { $validator->check_form( q(subr_), $vals ) };
$e = Unexpected->caught() || Class::Null->new();
ok !$e->as_string, 'Not equal field comparison';

$f->{constraints}->{subr_field_name5}->{operator} = q(eq);
$vals->{field_name5} = q(qwe);
delete $f->{constraints}->{subr_field_name5}->{other_field};
eval { $validator->check_form( q(subr_), $vals ) };
$e = Unexpected->caught() || Class::Null->new();
like $e->args->[0]->as_string, qr{ \Qhas no comparison field\E }mx,
   'No comparison field';

$f->{constraints}->{subr_field_name5}->{other_field} = q(field_name4);
$vals->{field_name2} = q(tooeasy);
eval { $validator->check_form( q(subr_), $vals ) };
$e = Unexpected->caught() || Class::Null->new();
like $e->args->[0]->as_string, qr{ \Qnot a valid password\E }mx, 'Invalid form';

eval { $validator->check_form( undef, [] ) };
$e = Unexpected->caught() || Class::Null->new();
like $e->error, qr{ \Qnot a hash\E }mx, 'Invalid form args';

$f->{fields}->{test}->{validate} = q(isMatchingType);
$f->{constraints}->{test} = { type => 'Int' };
is test_val( $f, 'test', 'abcdefg' ), 'MatchingType', 'Not matching int type';
is test_val( $f, 'test', '1234567' ), 1234567, 'Matching int type';

$f->{constraints}->{test} = { type => 'PositiveInt' };
is test_val( $f, 'test', -1 ), 'MatchingType',
   'Not matching positive int type';
is test_val( $f, 'test', 1234567 ), 1234567, 'Matching positive int type';

$f->{constraints}->{test} = { type => 'NotLikely' };
is test_val( $f, 'test', 0 ), 'KnownType', 'Unknown type exception';

$f->{fields}->{test}->{validate} = q(isMatchingRegex);
$f->{constraints}->{test} = { pattern => q(\A \d+ \z) };
is test_val( $f, q(test), q(123 456) ), q(MatchingRegex),
   'Non Matching Regex 1';

$f->{fields}->{test}->{filters} = q(filterEscapeHTML);
$f->{constraints}->{test} = { pattern => q(\A .+ \z) };
is test_val( $f, q(test), q(&amp;"&<>") ),
   q(&amp;&quot;&amp;&lt;&gt;&quot;), 'Filter EscapeHTML';

$f->{fields}->{test}->{filters} = q(filterLowerCase);
$f->{constraints}->{test} = { pattern => q(\A [a-z ]+ \z) };
is test_val( $f, q(test), q(HELLO WORLD) ), q(hello world), 'Filter LowerCase';

$f->{fields}->{test}->{filters} = q(filterNonNumeric);
$f->{constraints}->{test} = { pattern => q(\A \d+ \z) };
is test_val( $f, q(test), q(1a2b3c) ), q(123), 'Filter NonNumeric';

$f->{fields}->{test}->{filters} = q(filterReplaceRegex);
$f->{constraints}->{test} = { pattern => q(\A \d+ \z) };
$f->{filters}->{test} = { pattern => q(\-), replace => q(0) };
is test_val( $f, q(test), q(1-2-3) ), q(10203), 'Filter RegexReplace';

$f->{fields}->{test}->{filters} = q(filterTitleCase);
$f->{constraints}->{test} = { pattern => q(\A [a-zA-Z ]+ \z) };
is test_val( $f, q(test), q(hello world) ), q(Hello World), 'Filter TitleCase';

$f->{fields}->{test}->{filters} = q(filterTrimBoth);
$f->{constraints}->{test} = { pattern => q(\A \d+ \z) };
is test_val( $f, q(test), q( 123456 ) ), 123456, 'Filter TrimBoth';

$f->{fields}->{test}->{filters} = q(filterUpperCase);
$f->{constraints}->{test} = { pattern => q(\A [A-Z ]+ \z) };
is test_val( $f, q(test), q(hello world) ), q(HELLO WORLD), 'Filter UpperCase';

$f->{fields}->{test}->{filters} = q(filterUCFirst);
$f->{constraints}->{test} = { pattern => q(\A [A-Z][a-z ]+ \z) };
is test_val( $f, q(test), q(hello world) ), q(Hello world), 'Filter UCFirst';

$f->{fields}->{test}->{filters} = q(filterWhiteSpace);
$f->{constraints}->{test} = { pattern => q(\A \d+ \z) };
is test_val( $f, q(test), q(123 456) ), 123456, 'Filter WhiteSpace';

$f->{constraints}->{test} = { pattern => q(\A \z) };
delete $f->{fields}->{test}->{filters};
is test_val( $f, 'test', q() ), q(), 'Filter ZeroLength - negative';
$f->{fields}->{test}->{filters} = 'filterZeroLength';
delete $f->{fields}->{test}->{validate};
is test_val( $f, 'test', q() ), undef, 'Filter ZeroLength - positive';
is test_val( $f, 'test', 'x' ), 'x', 'Filter ZeroLength - negative with val';

$f->{fields}->{test}->{filters}
   = 'filterUpperCase filterNonNumeric filterTrimBoth';
$f->{constraints}->{test} = { pattern => q(\A [A-Z ]+ \z) };
is test_val( $f, q(test), q( hello world2 ) ), q(2),
   'Filter UpperCase NonNumeric and TrimBoth';

{  package BadTestFilter;

   sub _filter_typo {
   }

   $INC{ 'BadTestFilter.pm' } = __FILE__;
}

delete $f->{constraints}->{test};
$f->{fields}->{test}->{filters} = '+BadTestFilter';
like test_val( $f, 'test', q() ), qr{ \Qlocate object\E }mx, 'Bad filter';

eval { Data::Validation::Constants->Exception_Class( 'BadExceptionClass' ) };
like $EVAL_ERROR, qr{ \Qnot loaded\E }mx, 'Exception class must throw';
is Data::Validation::Constants->Exception_Class( 'Unexpected' ), 'Unexpected',
   'Unexpected can throw';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
