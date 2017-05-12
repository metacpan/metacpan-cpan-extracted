use Test::More;
use Test::Exception;
my $obj;
my $aref = [qw|baz boz|];
my $struct = {foo => {bar => $aref}};
my $path = '/foo/bar';
my $annotation = 'this is a test annotation';

BEGIN: {
    plan tests => 12
                  ;
    
    use_ok('Class::Data::Annotated');
}

{
    isa_ok($obj = Class::Data::Annotated->new($struct), 'Class::Data::Annotated');
    dies_ok( sub {Class::Data::Annotated->new()}, 'I just gotta have data');
    can_ok($obj, 'annotate');
    $obj->annotate($path, $annotation);
    is($obj->{Annotations}{$path}, $annotation, 'Annotation for data matches expected');
    ok(!$obj->annotate('/foo/baz', $annotation), 'Failed to add annotation for nonmatching path in data');
}

{
    can_ok($obj, '_validate_path');
    dies_ok(sub {$obj->_validate_path('foo/bar')}, 'Missing root slash does not validate');
    dies_ok(sub {$obj->_validate_path('/foo/bar/')}, 'slash on the end does validate');
}

{
    can_ok($obj, 'get');
    is_deeply($obj->get($path), $aref, 'got correct data from object with path'); 
    is($obj->get_annotation($path), $annotation, 'Retrieved annotation for a path');
}
