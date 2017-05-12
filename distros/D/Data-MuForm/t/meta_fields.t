use strict;
use warnings;
use Test::More;

use lib 't/lib';

use_ok( 'Test::Form' );

my $form = Test::Form->new;
ok($form, 'form built');

my @meta_fields = $form->_meta_fields;
is( scalar @meta_fields, 5, 'there are 5 meta fields in the form' );

is( $form->num_fields, 5, 'five fields built' );

my $expected =  [
   { 'name' => 'foo', source => 'Test::Form' },
   { 'name' => 'bar', source => 'Test::Form' },
   { 'type' => 'Submit', source => 'Test::Form',
     'name' => 'submit_btn'
   },
   { 'name' => 'flotsam', source => 'Test::FormRole' },
   { 'name' => 'jetsam', source => 'Test::FormRole' },
];

note(explain(\@meta_fields));

is_deeply( \@meta_fields, $expected, 'got the meta fields we expected' );

done_testing;
