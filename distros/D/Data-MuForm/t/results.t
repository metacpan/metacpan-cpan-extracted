use strict;
use warnings;
use Test::More;

{
    package MyApp::Form::Test;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'foo';
    has_field 'bar';

}

my $form = MyApp::Form::Test->new;
ok( $form );

my $expected =  {
    name => 'Test',
    id => 'Test',
    method => 'post',
    action => undef,
    submitted => undef,
    validated => 0,
    fields => [
        { name => 'foo', id => 'foo', full_name => 'foo', fif => '', label => 'Foo', render_args => {} },
        { name => 'bar', id => 'bar', full_name => 'bar', fif => '', label => 'Bar', render_args => {} },
    ]
};

my $results = $form->results;
is_deeply( $results, $expected, 'got right results' );


done_testing;
