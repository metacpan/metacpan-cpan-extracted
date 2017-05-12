use strict;
use warnings;
use Test::More;

{
    package MyApp::Form::Test;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    sub build_renderer_args {{ is_html5 => 1 }}

    has_field 'foo_date' => (
      type => 'Date',
    );
    has_field 'email' => ( type => 'Email' );
    has_field 'some_link' => ( type => 'URL' );
    has_field 'bar' => ( type => 'Integer' );
    has_field 'phone' => ( type => 'Text', html5_input_type => 'tel' );

}

my $form = MyApp::Form::Test->new;
ok( $form );
$form->process( params => {} );
like( $form->field('foo_date')->render, qr/type="date"/, 'has date input type' );
like( $form->field('email')->render, qr/type="email"/, 'has email input type' );
like( $form->field('bar')->render, qr/type="number"/, 'has number input type' );
like( $form->field('phone')->render, qr/type="tel"/, 'has tel input type' );

done_testing;
