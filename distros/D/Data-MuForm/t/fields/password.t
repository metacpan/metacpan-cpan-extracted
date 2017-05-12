use strict;
use warnings;
use Test::More;
use lib 't/lib';

=comment
use Data::MuForm::Field::Text;

my $field = Data::MuForm::Field::Text->new(
   name => 'password',
   type => 'Text',
   required => 1,
   password => 1,
);
is( $field->password, 1, 'password is set');
$field->value('abcdef');
is( $field->fif, '', 'no fif for password');

{
   package My::Form;
   use Moo;
   extends 'Data::MuForm';

   sub field_list {
       return [
               login       => 'Text',
               username    => 'Text',
               password    => { type => 'Password',
                                minlength => 6,
                              },
          ];
   }

}


my $form = My::Form->new;
my $params = {
   username => 'my4username',
   password => 'something'
};
$form->process( $params );

$field = $form->field('password');
ok( $field,  'got password field' );

$field->input( '2192ab201def' );
$field->field_validate;
ok( !$field->has_errors, 'Test for errors 1' );

$field->input( 'ab1' );
$field->field_validate;
ok( $field->has_errors, 'too short' );
$field->clear_errors;

$field->input( '' );
$field->field_validate;
ok( !$field->has_errors, 'empty password accepted' );
is($field->no_update, 1, 'noupdate has been set on password field' );

my $pass = 'my4user5name';
$field->input( $pass );
$field->field_validate;
ok( !$field->has_errors, 'just right' );
is ( $field->value, $pass, 'Input and value match' );

=cut


{
   package Password::Form;
   use Moo;
   use Data::MuForm::Meta;
   extends 'Data::MuForm';

   has '+field_namespace' => ( default => 'Field' );
   has_field 'password' => ( type => 'Password', required => 1 );
   has_field '_password' => ( type => 'Password', required => 1,
        'msg.required' => 'You must enter the password a second time',
   );

   sub validate {
       my $self = shift;
       unless ( ($self->field('password')->value || '' ) eq ($self->field('_password')->value || '') ) {
           $self->field('_password')->add_error('Your password confirmation did not match the password');
       }
   }

}

my $form = Password::Form->new;
ok( $form, 'form created' );

my $params = {
   password => '',
   _password => '',
};

$form->process( params => $params );
ok( !$form->validated, 'form validated' );
ok( !$form->field('password')->no_update, q{no_update is 'false' on password field} );
ok( $form->field('_password')->has_errors, 'Password confirmation has errors' );
is( $form->field('_password')->errors->[0], 'You must enter the password a second time', 'correct error message' );

$form->process( params => { password => 'aaaaaa', _password => 'bbbb' } );
ok( $form->field('_password')->has_errors, 'Password confirmation has errors' );

$form->process( params => { password => 'aaaaaa', _password => 'aaaaaa' } );
ok( $form->validated, 'password confirmation validated' );

done_testing;
