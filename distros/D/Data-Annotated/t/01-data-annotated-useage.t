use Test::More;
use Data::Annotated;

plan tests =>   11
            ;
our $test;
our $struct = {foo => 'bar'};
our $struct2 = {baz => 'boff'};
our $struct3 = {foo => 'bar', baz => 'boff'};
our $anno1 =  {desc => 'standard foo var', 
               runif => sub {$test = 'the first one worked'}, 
               name => 'fooname',
              };
our $anno2 =  {desc => 'non-standard baz var', 
               runif => sub {$test = 'the second one worked'}, 
               name => 'bazname',
              };

our $da = Data::Annotated->new();

{
    isa_ok($da, 'Data::Annotated');
}

{
    can_ok($da, 'annotate');
    $da->annotate('/foo',$anno1);
    is_deeply($da->{'/foo'}, $anno1, '/foo path has an annotation');
}

$anno1->{path} = '/foo';
$anno2->{path} = '/baz';
{
   can_ok($da, 'cat_annotation');
   is_deeply($da->cat_annotation($struct), ($anno1), 'got annotation for the struct1'); 
   ok(!$da->cat_annotation($struct2), 'got no annotation for struct2'); 
   $da->annotate('/baz',$anno2);
   is_deeply($da->cat_annotation($struct2), ($anno2), 'got annotation for the struct2 after adding'); 
   is_deeply([sort {$a->{path} cmp $b->{path}} ($da->cat_annotation($struct3))],
             [sort {$a->{path} cmp $b->{path}} ($anno1, $anno2)], 
           'got annotations for the struct3 after adding');
   is_deeply($da->get_annotation('/baz'), $anno2, 'retrieved annotation for /baz path'); 
}

{
    ok(!$da->_validate_path('foo/bar'), 'Missing root slash does not validate');
    ok(!$da->_validate_path('/foo/bar/'), 'slash on the end does not validate');
}

