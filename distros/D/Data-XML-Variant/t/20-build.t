#!perl -w

use strict;

use Test::More tests => 56;
#use Test::More qw/no_plan/;
use Test::XML;

my $Build;

BEGIN {
    chdir 't' if -d 't';
    unshift @INC => '../lib';
    $Build = 'Data::XML::Variant::Build';
    use_ok($Build) or die;
}

can_ok $Build, 'Add';
my $build = bless {}, $Build;

# invalid method names should throw an exception

eval { $build->Add('Foo') };
ok $@, 'Trying to add a method starting with an upper-case letter should croak';
like $@, qr/^\QAdded methods must begin with a lower-case letter (Foo)\E/,
  '... with an appropriate error message';
eval { $build->Add('_foo') };
ok $@,   'You cannot add methods that do not begin with a lower-case letter';
like $@, qr/^\QAdded methods must begin with a lower-case letter (_foo)\E/,
  '... and I really, really mean it';

eval { $build->Add('can') };
ok $@,   'Adding methods UNIVERSAL:: supplied should fail';
like $@, qr/^\QCannot override UNIVERSAL methods\E/,
  '... with an appropriate error message';

# foo()

ok !$build->can('foo'), 'foo() should not be an available method';
ok $build->Add('foo'),       '... but we should be able to add it';
ok $build->can('foo'),       '... and foo() should now be available';
ok $build->can('start_foo'), '... and start_foo() should now be available';
ok $build->can('end_foo'),   '... and end_foo() should now be available';
is_xml $build->foo, '<foo/>', '... and foo() should build an empty tag';

# start_foo

is $build->start_foo, '<foo>', 'start_foo() should return the start tag';
is $build->start_foo( [ this => 1, that => 2 ] ), '<foo this="1" that="2">',
  '... and passing attributes as an array reference should work';
is_xml $build->start_foo( { this => 1, that => 2 } ) . '</foo>',
  '<foo this="1" that="2"/>',
  '... and passing attributes as a hash reference should work';

# end foo

is $build->end_foo, '</foo>', 'end_foo() should return the end tag';
eval { $build->end_foo('data') };
ok $@,   '... but passing arguments to an end tag should fail';
like $@, qr/^\Qend_foo does not take any arguments\E/,
  '... with an appropriate error message';

eval { $build->Add('foo') };
ok $@,   'Attempting to re-add a method should fail';
like $@, qr/^\QMethod (foo) already added\E/,
  '... with an appropriate error message';

is_xml $build->foo('message'), '<foo>message</foo>',
  'We should be able to build tags with data';

my $result = $build->foo('message');

is $build->foo( [ 'ns:id' => 3 ], 'something' ),
  '<foo ns:id="3">something</foo>',
  '... and attributes should be handled correctly';

is $build->foo( { 'ns:id' => 3 }, 'something' ),
  '<foo ns:id="3">something</foo>', '... even if they are passed in a hashref';

$build->Add( 'ns:bar', 'bar' );
is $build->bar, '<ns:bar/>', 'We should be able to add arbitrary namespaces';

is $build->foo( $build->bar('something') ),
  '<foo><ns:bar>something</ns:bar></foo>', 'We should be able to nest calls';

can_ok $build, 'Cdata';
is $build->Cdata('<some tag>'), '<![CDATA[<some tag>]]>',
  '... and we should be able to build CDATA sections';

can_ok $build, 'Decl';
is $build->Decl, '<?xml version="1.0"?>',
  '... and it should return a valid XML declaration';
is $build->Decl([version => '1.1', standalone => 'no']),
    '<?xml version="1.1" standalone="no"?>',
    '... but we should be able to speficy our own attributes';

can_ok $build, 'Quote';
is $build->Quote, '"', '... and the default quote should be double quotes';
$build->Quote("'");
is $build->foo( [ 'ns:id' => 3 ], 'something' ),
  q{<foo ns:id='3'>something</foo>},
  '... and setting the attribute quote should change how they are quoted';

$build->Quote('"');
is $build->foo( [ key => '&' ], '<this>' ),
  '<foo key="&amp;">&lt;this&gt;</foo>',
  'Attributes and character data should be properly encoded';

my $attributes = '&& -- ??';
is $build->foo( \$attributes ), '<foo && -- ??/>',
'Passing a scalar reference for attributes should return the exact string for attributes';

can_ok $build, 'Methods';
my @expected = qw/
  start_bar
  bar
  end_bar
  start_foo
  foo
  end_foo
  /;
is_deeply [ $build->Methods ], \@expected,
  '... and it should list the tag methods';

can_ok $build, 'Remove';
ok $build->Remove('foo'), '... and we should be able to delete a method';
ok !$build->can('foo'),       '... and it should be gone from our namespace';
ok !$build->can('start_foo'), '... as should its start method';
ok !$build->can('end_foo'),   '... and its end method';
@expected = qw/start_bar bar end_bar/;
is_deeply [ $build->Methods ], \@expected,
  '... and Methods() should no longer return them';

ok $build->Remove, 'We should be able to remove all tag methods';
ok !$build->can('bar'),       '... and the remaining tag methods should be gone from our namespace';
ok !$build->can('start_bar'), '... as should their start methods';
ok !$build->can('end_bar'),   '... and end methods';
ok !$build->Methods, '... and Methods() should return no methods';

can_ok $build, 'Closing';
ok $build->Closing(' /'), '... and calling it should succeed';
$build->Add('foo');
is $build->foo, '<foo />', '... and use the new closing characters';

can_ok $build, 'Raw';
my $raw = '.. > & ..';
is $build->Raw($raw), $raw, '... and it should return strings unchanged';
is $build->foo($build->Raw($raw)), "<foo>$raw</foo>",
    '... even when embedded in other tags';
