use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    package Test::Form;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'bar';
    has_field 'foo' => ( inactive => 1 );
    has_field 'foo_checkbox' => ( type => 'Checkbox', inactive => 1 );
}

my $form = Test::Form->new;
ok( $form, 'form builds' );
$form->process;

is( $form->num_fields, 3, 'right number of fields' );
is( scalar @{$form->sorted_fields}, 1, 'right number of sorted fields' );


$form->field('foo')->clear_inactive;
is( scalar @{$form->sorted_fields}, 2, 'right number of sorted fields after clear_inactive' );

my $fif = {
   bar => 'bar_test',
   foo => 'foo_test',
};
$form->process($fif);
ok( $form->validated, 'form validated' );
is_deeply( $form->fif, $fif, 'fif is correct' );
is_deeply( $form->value, $fif, 'value is correct' );

$form = Test::Form->new;
my $active = ['foo'];
$form->process( active => [@{$active}], params => $fif );
is_deeply( $active, ['foo'], 'active hashref still there' );
ok( $form->validated, 'form validated' );
is_deeply( $form->fif, $fif, 'fif is correct' );
is_deeply( $form->value, $fif, 'value is correct' );


# tests for setting active fields inactive
{
    package Test::Another;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'foo';
    has_field 'bar';
    has_field 'gaz';
}

$form = Test::Another->new( inactive => ['bar'] );
$form->process;
ok( $form->field('bar')->is_inactive, 'field is inactive' );
ok( $form->field('foo')->is_active, 'field is active' );

$form = Test::Another->new;
$form->process( inactive => ['gaz'], params => {} );
ok( $form->field('gaz')->is_inactive, 'field is inactive' );
ok( $form->field('foo')->is_active, 'field is active' );

done_testing;
