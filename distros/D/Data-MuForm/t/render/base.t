use strict;
use warnings;
use Test::More;
use Data::MuForm::Test;

use_ok('Data::MuForm::Renderer::Base');

{
    package MyApp::Form::Test;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    sub build_renderer_args {{ render_element_errors => 1 }}

    has_field 'foo' => ( required => 1, maxlength => 10 );
    has_field 'bar' => (
        type => 'Select',
        empty_select => '-- Choose --',
        options => [
            1 => 'one',
            2 => 'two',
        ],
    );
    has_field 'jax' => ( type => 'Checkbox', checkbox_value => 'yes', 'ra.cb_layout' => 'cbwrll' );
    has_field 'sol' => ( type => 'Textarea', cols => 50, rows => 3 );

    has_field 'submitted' => ( type => 'Submit', value => 'Save' );
}

my $form = MyApp::Form::Test->new;
ok( $form, 'form built' );

# text field
my $rendered = $form->field('foo')->render_element({ placeholder => 'Type...', class => 'mb10 x322' });
my $expected = q{
  <input type="text" id="foo" name="foo" class="mb10 x322" placeholder="Type..." maxlength="10" value="">
};
is_html( $rendered, $expected, 'got expected output for text element');

# text label
$rendered = $form->field('foo')->render_label;
$expected = q{
  <label for="foo">Foo</label>
};
is_html( $rendered, $expected, 'label rendered okay');

$form->process( params => { foo => '', bar => 1, sol => 'Some text' } );

# text field render_element
$rendered = $form->field('foo')->render_element({ class => 'bm10 x333' });
$expected = q{
  <input type="text" id="foo" name="foo" class="bm10 x333 error" maxlength="10" value="">
  <span class="error_message">&apos;Foo&apos; field is required</span>
};
is_html( $rendered, $expected, 'got expected output for text element with error');


# text field errors
$rendered = $form->field('foo')->render_errors;
$expected  = q{
  <span class="error_message">'Foo' field is required</span>
};
is_html( $rendered, $expected, 'rendered errors okay');

# text field render
$rendered = $form->field('foo')->render({ 'ea.class' => 'fftt' });
$expected = q{
<div>
  <label for="foo">Foo</label>
  <input class="fftt error" id="foo" maxlength="10" name="foo" type="text" value="" />
  <span class="error_message">&apos;Foo&apos; field is required</span>
</div>
};
is_html( $rendered, $expected, 'rendered field with ra changes ok');

# select field
$rendered = $form->field('bar')->render_element({ class => 'select 666' });
$expected = q{
  <select id="bar" name="bar" class="select 666">
    <option value="">-- Choose --</option>
    <option value="1" selected="selected">one</option>
    <option value="2">two</option>
  </select>
};
is_html( $rendered, $expected, 'got expected output for select element' );

# checkbox field
$rendered = $form->field('jax')->render_element({ class => 'hhh yyy' });
$expected = q{
  <input type="checkbox" id="jax" name="jax" value="yes" class="hhh yyy">
};
is_html( $rendered, $expected, 'got expected output for checkbox element' );


# textarea field
$rendered = $form->field('sol')->render_element({ class => 'the end' });
$expected = q{
  <textarea id="sol" name="sol" class="the end" cols="50" rows="3">Some text</textarea>
};
is_html( $rendered, $expected, 'got expected output for textarea element' );

# submit field
$rendered = $form->field('submitted')->render_element({ class => ['h23', 'bye' ] });
$expected = q{
  <input type="submit" name="submitted" id="submitted" class="h23 bye" value="Save">
};
is_html( $rendered, $expected, 'got expected output for submit element' );


# render simple div wrapper around label, input and errors
$rendered = $form->field('foo')->render({ layout => 'lbl_ele_err', wrapper_attr => { class => 'tpt'} });
$expected = q{
  <div class="tpt">
  <label for="foo">Foo</label>
  <input class="error" id="foo" maxlength="10" name="foo" type="text" value="" />
  <span class="error_message">'Foo' field is required</span>
  </div>
};
is_html( $rendered, $expected, 'foo field rendered correctly' );

$rendered = $form->render;
$expected = q{
<form id="Test" method="post">
  <div>
    <label for="foo">Foo</label>
    <input class="error" id="foo" maxlength="10" name="foo" type="text" value="" /> <span class="error_message">&apos;Foo&apos; field is required</span>
  </div>
  <div>
    <label for="bar">Bar</label>
    <select id="bar" name="bar">
      <option value="">-- Choose --</option>
      <option value="1" selected="selected">one</option>
      <option value="2">two</option>
    </select>
  </div>
  <div>
    <label for="jax">Jax<input id="jax" name="jax" type="checkbox" value="yes" /></label>
  </div>
  <div>
    <label for="sol">Sol</label>
    <textarea cols="50" id="sol" name="sol" rows="3">Some text</textarea>
  </div>
  <input id="submitted" name="submitted" type="submit" value="Save" />
</form>
};
is_html( $rendered, $expected, 'form rendered correctly' );

done_testing;
