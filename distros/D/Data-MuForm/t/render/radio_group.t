use strict;
use warnings;
use Test::More;
use Data::MuForm::Test;

{
    package Test::Form;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'opt_in'     => (
        type    => 'Select',
        'ra.layout_type'  => 'radiogroup',
        'ra.ewa.class' => 'my_radio',
        options => [
            { value => 'no & never', label => 'No & Never', id => 'opt1' },
            { value => 'yes', label => 'Yes', id => 'opt2' },
        ]
    );

=comment
    has_field 'option_group' => (
        type    => 'Select',
        widget  => 'RadioGroup',
        options => [
            {
                group            => 'First Group',
                options          => [ { value => 1, label => 'Yes'}, {value => 2, label => 'No' } ],
                attributes       => { class => 'firstgroup' },
                label_attributes => { class => 'group1' },
            }
        ]
    );
=cut
}

my $form = Test::Form->new;
$form->process;
=comment
# not yet handling calsses etc on radios
my $expected =
'<div>
  <label for="opt_in">Opt in</label>
  <label class="radio" for="opt_in.0">
    <input type="radio" value="no &amp; never" name="opt_in" id="opt_in.0" />
    No &amp; Never
   </label>
  <label class="radio" for="opt_in.1">
    <input type="radio" value="&quot;yes&quot;" name="opt_in" id="opt_in.1" />
    Yes
  </label>
</div>';
=cut
my $expected = q{
<div>
  <label for="opt_in">Opt in</label>
  <div class="my_radio">
    <label class="radio" for="opt1">
      <input name="opt_in" id="opt1" type="radio" value="no &amp; never" />
      No &amp; Never
    </label>
  </div>
  <div class="my_radio">
    <label class="radio" for="opt2"><input name="opt_in" id="opt2" type="radio" value="yes" />
      Yes
    </label>
  </div>
</div>
};
my $rendered = $form->field('opt_in')->render;
is_html( $rendered, $expected, 'radio group rendered ok' );

=comment
my $params = {
    opt_in             => 'no & never',
};
$form->process( update_field_list => { opt_in => { tags => { 'radio_br_after' => 1 }}}, params => $params);
$rendered = $form->field('opt_in')->render;
$expected =
'<div>
  <label for="opt_in">Opt in</label><br />
  <label class="radio" for="opt_in.0">
    <input type="radio" value="no &amp; never" name="opt_in" id="opt_in.0" checked="checked" />
    No &amp; Never
  </label><br />
  <label class="radio" for="opt_in.1"><input type="radio" value="&quot;yes&quot;" name="opt_in" id="opt_in.1" />
    Yes
  </label><br />
</div>';

is_html( $rendered, $expected, 'output from radio group');

# option group attributes
$rendered = $form->field('option_group')->render;
$expected =
'<div>
  <label for="option_group">Option group</label>
  <div class="firstgroup">
    <label class="group1">First Group</label>
    <label class="radio" for="option_group.0">
      <input type="radio" value="1" name="option_group" id="option_group.0" />
      Yes
    </label>
    <label class="radio" for="option_group.1">
      <input type="radio" value="2" name="option_group" id="option_group.1" />
      No
    </label>
  </div>
</div>';

is_html( $rendered, $expected, 'output from ragio group with option group and label attributes');

# create form with no label rendering for opt_in
$form = Test::Form->new( field_list => [ '+opt_in' => { do_label => 0 } ] );
$form->process;
# first individually rendered option
$rendered = $form->field('opt_in')->render_option({ value => 'test', label => 'Test'});
$expected = '<label class="radio" for="opt_in.0"><input id="opt_in.0" name="opt_in" type="radio" value="test" /> Test </label>';
is_html( $rendered, $expected, 'individual option rendered ok' );
# second rendered option is wrapped
$rendered = $form->field('opt_in')->render_wrapped_option({ value => 'abcde', label => 'Abcde' });
$expected = '<div><label class="radio" for="opt_in.1"><input id="opt_in.1" name="opt_in" type="radio" value="abcde" /> Abcde </label></div>';
is_html( $rendered, $expected, 'indvidual wrapped option rendered ok' );
=cut

done_testing;
