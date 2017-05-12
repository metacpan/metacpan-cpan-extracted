use strict;
use warnings;
use Test::More;

{
    package MyApp::Form::Test;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'foo' => (
        type => 'Repeatable',
    );
    has_field 'foo.pk' => (
        type => 'PrimaryKey',
    );
    has_field 'foo.name' => (
        type => 'Text',
    );
    has_field 'foo.number' => (
        type => 'Text',
    );
    has_field 'bar' => (
        type => 'Repeatable',
    );
    has_field 'bar.pk' => (
        type => 'PrimaryKey',
    );
    has_field 'bar.name' => (
        type => 'Text',
    );
    has_field 'bar.number' => (
        type => 'Text',
    );

    sub validate {
        my $self = shift;
        unless ( $self->field('foo')->has_input || $self->field('bar')->has_input ) {
            $self->add_form_error('You must have either a foo or a bar');
        }
    }
}

my $form = MyApp::Form::Test->new;
ok( $form );

done_testing;
