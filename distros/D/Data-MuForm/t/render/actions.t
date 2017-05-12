use strict;
use warnings;
use Test::More;
use Data::MuForm::Test;

{
    package Test::Form;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has '+name' => ( default => 'action_form' );
    has_field 'foo';
    has_field 'actions' => ( type => 'Compound', 'ra.wa.class' => 'form-actions', 'ra.wrapper' => 'simple', 'ra.no_label' => 1 );
    has_field 'actions.save' => ( type => 'Submit' );
    has_field 'actions.cancel' => ( type => 'Reset' );
}

my $form = Test::Form->new;
$form->process;
my $rendered = $form->render;
my $expected =
'<form id="action_form" method="post">
  <div>
    <label for="foo">Foo</label>
    <input id="foo" name="foo" type="text" value="" />
  </div>
  <div class="form-actions">
    <input id="actions.save" name="actions.save" type="submit" value="Save" />
    <input id="actions.cancel" name="actions.cancel" type="reset" value="Reset" />
  </div>
</form>';
is_html($rendered, $expected, 'actions render ok' );

done_testing;
