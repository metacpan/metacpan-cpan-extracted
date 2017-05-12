use strict;
use warnings;
use Test::More;

use Data::MuForm;

{
    package MyApp::Form::Test;
    use Moo;
    extends 'Data::MuForm';
    use Data::MuForm::Meta;

    has '+name' => ( default => 'test' );
    has_field 'foo' => (
        methods => { build_id => sub { my $self = shift; return $self->name . "-id"; } }
    );
    has_field 'bar' => ( type => 'Select', label => 'BarNone' );;
    sub options_bar {
        my $self = shift;
        return $self->some_options;
    }
    sub some_options {
        (
           1 => 'apples',
           2 => 'oranges',
           3 => 'kiwi',
        )
    }

}

my $form = MyApp::Form::Test->new;
ok( $form );
is( $form->field('foo')->id, 'foo-id', 'id is correct' );

$form->process( params => {} );

my $options = $form->field('bar')->options;

is_deeply( $options, [ { value => 1 => label => 'apples', order => 0 }, { value => 2, label => 'oranges', order => 1 }, { value => 3, label => 'kiwi', order => 2 } ], 'right options' );

{
    package MyApp::Form::Test2;
    use Moo;
    use Data::MuForm::Meta;
    extends 'MyApp::Form::Test';

    has_field '+foo' => (
        'meth.build_id' => \&my_build_id,
        'meth.build_label' => \&my_build_label,
    );

    sub my_build_id {
        my $self = shift; # field
        return $self->name . ".myid";
    }
    sub my_build_label {
        my $self = shift; # field
        return uc($self->name) . ":";
    }
}

$form = MyApp::Form::Test2->new;
ok( $form, 'form built' );
is( $form->field('foo')->id, 'foo.myid', 'id is correct' );
is( $form->field('foo')->label, 'FOO:', 'label is correct' );

done_testing;
