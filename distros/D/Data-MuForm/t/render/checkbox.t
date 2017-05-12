use strict;
use warnings;
use Test::More;
use Data::MuForm::Test;


{
   package Test::Form;
   use Moo;
   use Data::MuForm::Meta;
   extends 'Data::MuForm';

   has_field 'option1' => ( type => 'Checkbox', render_args => { cb_layout => 'cbwrlr' });
   has_field 'option2' => ( type => 'Checkbox', render_args => { cb_layout => 'cbwrll' });
   has_field 'option3' => ( type => 'Checkbox', render_args => { cb_layout => 'cb2l', option_label => 'Try this one' });
   has_field 'option4' => ( type => 'Checkbox', render_args => { cb_layout => 'cbnowrll' });
   has_field 'option5' => ( type => 'Checkbox' );
   has_field 'option6' => ( type => 'Checkbox', label => 'Simple Checkbox', render_args => { layout => 'standard', cb_layout => 'cbwrlr', wrapper => 'none' } );

   sub render_hook {
       my ( $self, $renderer, $rargs ) = @_;
       return if $rargs->{name} eq 'option4';
       if ( $rargs->{type} = 'Checkbox' && $rargs->{rendering} eq 'label' ) {
           push @{$rargs->{label_attr}->{class}}, 'checkbox';
       }
   }
}
my $form = Test::Form->new;
$form->process;

my $expected = q{
    <input id="option1" name="option1" type="checkbox" value="1" class="cbox" />
};
my $rendered = $form->field('option1')->render_element({ class=> ["cbox"] });
is_html( $rendered, $expected, 'element rendered correctly' );

   # single_label: label wraps input, label to right
$expected =
'<div>
  <label class="checkbox" for="option1"><input id="option1" name="option1" type="checkbox" value="1" />Option1</label>
</div>';
$rendered = $form->field('option1')->render;
is_html( $rendered, $expected, 'standard Checkbox render ok' );

   # single_label: label wraps input, label to left
 $expected =
'<div>
  <label class="checkbox" for="option2">Option2<input id="option2" name="option2" type="checkbox" value="1" /></label>
</div>';
$rendered = $form->field('option2')->render;
is_html( $rendered, $expected, 'Checkbox with label to left' );


   # standard: checkbox with additional label (like Bootstrap)
$expected =
'<div>
  <label class="checkbox" for="option3">Option3</label>
    <label for="option3"><input id="option3" name="option3" type="checkbox" value="1" />Try this one</label>
</div>';
$rendered = $form->field('option3')->render;
is_html( $rendered, $expected, 'Checkbox with two labels' );


# no wrapped label
$expected =
'<div>
  <label for="option4">Option4</label>
  <input id="option4" name="option4" type="checkbox" value="1" />
</div>';
$rendered = $form->field('option4')->render;
is_html( $rendered, $expected, 'Checkbox with no wrapped label');


# wrapper = 'None', input element only
$expected = q{
  <input id="option5" name="option5" type="checkbox" value="1" />
};
$rendered = $form->field('option5')->render_element;
is_html( $rendered, $expected, 'Checkbox with no wrapper and no label' );

# no wrapper
$expected =
'<label class="checkbox" for="option6">
  <input id="option6" name="option6" type="checkbox" value="1" />Simple Checkbox</label>';
$rendered = $form->field('option6')->render;
is_html( $rendered, $expected, 'checkbox with no wrapper, wrapped label' );


done_testing;
