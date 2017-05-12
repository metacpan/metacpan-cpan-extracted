use strict;
use warnings;
use Test::More;
use Try::Tiny;

# this is an example of a validation that should live outside of the
# form, yet needs to be called in the form's validate routine

{

    package SignupForm;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has check_name_availability => ( is => 'ro', required => 1 );

    has_field 'name';
    has_field 'email';

    sub validate {
        my $self = shift;
        my $name = $self->value->{name};
        my $meth = $self->check_name_availability;
        if ( defined $name && length $name && !$meth->($name) ) {
            $self->field('name')->add_error('That name is taken already');
        }
    }

}

{
    package MyApp::Signup;
    use Moo;

    has 'form' => ( is => 'ro', builder => 'build_form' );
    sub build_form {
        my $self = shift;
        return SignupForm->new(
            {
                check_name_availability => sub {
                    my $name = shift;
                    return $self->username_available($name);
                },
            }
        );

    }
    sub username_available {
        my ( $self, $name ) = @_;
        return $name eq 'Sam' ? 1 : 0;
    }

}

my $obj = MyApp::Signup->new;

ok( $obj->form, 'form built' );

my $params = { name => 'Sam', email => 'sam@gmail.com' };

$obj->form->process( params => $params );
ok( $obj->form->validated, 'form validated' );

$params->{name} = 'Jane';
$obj->form->process( params => $params );
ok( !$obj->form->validated, 'form did not validate' );

done_testing;
