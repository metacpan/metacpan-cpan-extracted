use strict;
use warnings;
use Test::More;
use Data::MuForm::Test;

# tests rendering an optgroup
{
    package MyApp::Form::Test;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'foo';
    has_field 'testop' => ( type => 'Select', multiple => 1, empty_select => '-- Choose --' );
    sub options_testop { (
        {
            group => 'First Group',
            options => [
                { value => 1, label => 'One' },
                { value => 2, label => 'Two' },
                { value => 3, label => 'Three' },
            ],
        },
        {
            group => 'Second Group',
            options => [
                { value => 4, label => 'Four' },
                { value => 5, label => 'Five' },
                { value => 6, label => 'Six' },
            ],
        },
        { value => '6a', label => 'SixA' },
        {
            group => 'Third Group',
            options => [
                { value => 7, label => 'Seven' },
                { value => 8, label => 'Eight' },
                { value => 9, label => 'Nine' },
            ],
        },

    ) }
}

my $form = MyApp::Form::Test->new;
ok( $form, 'form built' );
$form->process ( { foo => 'my_foo', testop => 12 } );
ok( ! $form->validated, 'form validated' );
my $params = { foo => 'my_foo', testop => 8 };

$form->process( $params );
ok( $form->validated, 'form validated' );
my $rendered = $form->field('testop')->render;
my $expected = q{
<div>
  <label for="testop">Testop</label>
  <select name="testop" multiple="multiple" id="testop">
    <option value="">-- Choose --</option>
    <optgroup label="First Group">
      <option value="1">One</option>
      <option value="2">Two</option>
      <option value="3">Three</option>
    </optgroup>
    <optgroup label="Second Group">
      <option value="4">Four</option>
      <option value="5">Five</option>
      <option value="6">Six</option>
    </optgroup>
    <option value="6a">SixA</option>
    <optgroup label="Third Group">
      <option value="7">Seven</option>
      <option value="8" selected="selected">Eight</option>
      <option value="9">Nine</option>
    </optgroup>
  </select>
</div>
};


is_html( $rendered, $expected, 'select rendered ok' );

done_testing;
