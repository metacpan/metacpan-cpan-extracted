use strict;
use warnings;
use Test::More;

{
    package MyApp::Form::Test;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has '+field_prefix' => ( default => 'mxx' );

    has_field 'foo';
    has_field 'bar';
    has_field 'max';

}

my $form = MyApp::Form::Test->new;
ok( $form );

is_deeply( $form->fif, { 'mxx.foo' => '', 'mxx.bar' => '', 'mxx.max' => '' }, 'right fif for field_prefix' );

done_testing;
