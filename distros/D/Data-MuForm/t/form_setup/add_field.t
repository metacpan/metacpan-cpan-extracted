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
is( $form->num_fields, 2, 'right number of fields');
$form->add_field(
   name => 'my_cb',
   type => 'Checkbox',
);
is( $form->num_fields, 3, 'right number of fields');
is( scalar(keys(%{$form->index})), 3, 'right number of fields in index');
my $field = $form->field('my_cb');
ok( $field, 'we have a field' );
is( $field->order, 15, 'right order');

$field = $form->add_field(
   name => 'fax',
   order => ( $form->field('foo')->order + 1 ),
);
ok( $field, 'got another field added' );
is( $field->order, 6, 'right order' );

done_testing;
