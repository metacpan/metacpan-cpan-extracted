use strict;
use warnings;
use Test::More;
use Data::MuForm::Test;

use lib 't/lib';

{

    package Test::Form;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

#   sub build_do_form_wrapper {1}
#   sub build_update_subfields {{
#       by_flag => { compound => { do_wrapper => 1, do_label => 1 },
#           repeatable => { do_wrapper => 1, do_label => 1 },
#       },
#   }}
#   sub build_form_wrapper_class { 'form_wrapper' }

    sub build_renderer_args { { cb_layout => 'cbwrll' } }
    has '+name' => ( default => 'testform' );
    has_field 'test_field' => (
        size  => 20,
        label => 'TEST',
        id    => 'f99',
        'ra.ea.class' => 'test123',
    );
    has_field 'number';
    has_field hobbies => (
        type => 'Repeatable',
        'ra.wrapper' => 'fieldset',
        num_when_empty => 1,
    );
    has_field 'hobbies.contains' => (
        type => 'Text',
        tabindex => 2,
    );

    has_field 'active'     => ( type => 'Checkbox' );
    has_field 'comments'   => ( type => 'Textarea', cols => 40, rows => 3 );
    has_field 'hidden'     => ( type => 'Hidden' );
    has_field 'selected'   => ( type => 'Boolean' );
    has_field 'start_date' => ( type => 'Compound', 'ra.wrapper' => 'fieldset' );
    has_field 'start_date.month' => (
        type        => 'Integer',
        range_start => 1,
        range_end   => 12
    );
    has_field 'start_date.day' => (
        type        => 'Integer',
        range_start => 1,
        range_end   => 31
    );
    has_field 'start_date.year' => (
        type        => 'Integer',
        range_start => 2000,
        range_end   => 2020
    );

    has_field 'two_errors' => (
        apply => [
            { check => [], message => 'First constraint error' },
            { check => [], message => 'Second constraint error' }
        ]
    );

    has_field 'submit' => ( type => 'Submit', value => '>>> Update' );
    has_field 'reset' => ( type => 'Reset', value => '<<< Reset' );

    has_field 'plain' => ( 'ra.wrapper' => 'none', 'ra.layout' => 'no_label' );
    has_field 'boxed' => ( 'ra.wrapper' => 'fieldset', 'ra.wa.class' => 'boxed' );
    has_field 'element_wrapper_field' => ( element_wrapper_class => 'large' );

}

my $form = Test::Form->new;
ok( $form, 'create form' );

# repeatable with 'contains'
my $expected = q{
<fieldset id="hobbies"><legend class="label">Hobbies</legend>
  <div>
    <input id="hobbies.0" name="hobbies.0" type="text" value="" />
  </div>
</fieldset>
};
is_html( $form->field('hobbies')->render, $expected, 'output from repeatable with num_when_empty == 1'
);

my $params = {
    test_field         => 'something',
    number             => 0,
    active             => 'now',
    comments           => 'Four score and seven years ago...</textarea>',
    hidden             => '1234',
    selected           => '1',
    'start_date.month' => '7',
    'start_date.day'   => '14',
    'start_date.year'  => '2006',
    two_errors         => 'aaa',
    plain              => 'No divs!!',
    hobbies            => [ 'eating', 'sleeping', 'not chasing mice' ],
    boxed              => 'Testing single fieldset',
};

$form->process($params);

is_html(
    $form->field('number')->render,
'<div>
  <label for="number">Number</label>
  <input type="text" name="number" id="number" value="0" />
</div>',
    "value '0' is rendered"
);

is ( $form->field('test_field')->id, 'f99', 'right id');
my $rendered = $form->field('test_field')->render;
is_html( $rendered,
'<div>
  <label for="f99">TEST</label>
  <input type="text" name="test_field" id="f99" size="20" value="something" class="test123" />
</div>',
    'output from text field'
);


$rendered = $form->field('test_field')->render_element;
is_html( $rendered,
    '<input type="text" name="test_field" id="f99" size="20" value="something" class="test123" />',
    'output from render_element is correct'
);

$expected = q{
<div>
  <label for="active">Active<input id="active" name="active" type="checkbox" value="1" /></label>
</div>
};
is_html( $form->field('active')->render, $expected, 'output from checkbox field');


$rendered = $form->field('comments')->render;
is_html( $rendered,
'<div>
  <label for="comments">Comments</label>
  <textarea name="comments" id="comments" rows="3" cols="40">Four score and seven years ago...&lt;/textarea&gt;</textarea>
</div>',
    'output from textarea'
);


$rendered = $form->field('hidden')->render;
is_html( $rendered,
  '<input type="hidden" name="hidden" id="hidden" value="1234" />',
  'output from hidden field'
);


$rendered = $form->field('selected')->render;
$expected = q{
<div>
  <label for="selected">Selected<input checked="checked" id="selected" name="selected" type="checkbox" value="1" /></label>
</div>
};
is_html( $rendered, $expected, 'output from boolean'
);

$rendered = $form->field('start_date')->render;
$expected = q{
<fieldset id="start_date"><legend class="label">Start date</legend>
  <div>
    <label for="start_date.month">Month</label>
    <input type="text" name="start_date.month" id="start_date.month" size="8" value="7" />
  </div>
  <div>
    <label for="start_date.day">Day</label>
    <input type="text" name="start_date.day" id="start_date.day" size="8" value="14" />
  </div>
  <div>
    <label for="start_date.year">Year</label>
    <input type="text" name="start_date.year" id="start_date.year" size="8" value="2006" />
  </div>
</fieldset>
};
is_html( $rendered, $expected, 'output from Compound start_date field');


$rendered = $form->field('submit')->render;
is_html( $rendered,
  '<input type="submit" name="submit" id="submit" value="&gt;&gt;&gt; Update" />',
  'output from Submit' );

$rendered = $form->field('reset')->render;
is_html( $rendered,
  '<input type="reset" name="reset" id="reset" value="&lt;&lt;&lt; Reset" />',
  'output from Reset'
);

$rendered = $form->render_start;
is_html( $rendered,
'<form id="testform" method="post">',
'Form start OK'
);


$rendered = $form->field('hobbies')->render;

$expected = q{
<fieldset id="hobbies"><legend class="label">Hobbies</legend>
  <div>
    <input id="hobbies.0" name="hobbies.0" type="text" value="eating" />
  </div>
  <div>
    <input id="hobbies.1" name="hobbies.1" type="text" value="sleeping" />
  </div>
  <div>
    <input id="hobbies.2" name="hobbies.2" type="text" value="not chasing mice" />
  </div>
</fieldset>
};

is_html($rendered, $expected, 'hobbies compound field render ok');

is_html( $form->field('plain')->render, '<input type="text" name="plain" id="plain" value="No divs!!" />', 'renders without wrapper');


is_html( $form->field('boxed')->render,
'<fieldset class="boxed"><legend class="label">Boxed</legend>
  <input type="text" name="boxed" id="boxed" value="Testing single fieldset" />
</fieldset>', 'fieldset wrapper renders' );

=comment
# TODO - element_wrapper... sigh
is_html( $form->field('element_wrapper_field')->render,
'<div>
  <label for="element_wrapper_field">Element wrapper field</label>
  <div class="large">
    <input id="element_wrapper_field" name="element_wrapper_field" type="text" value="" />
  </div>
</div>',
   'element wrapper renders ok' );
=cut

done_testing;
