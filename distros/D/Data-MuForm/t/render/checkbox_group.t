use strict;
use warnings;
use Test::More;
use Data::MuForm::Test;

{
    package Test::Form;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'comedians' => (
        type => 'Multiple',
        'ra.layout_type' => 'checkboxgroup',
        options => [
            { value => 'keaton', label => 'Buster Keaton'},
            { value => 'chaplin', label => 'Charly Chaplin'},
            { value => 'laurel & hardy', label => 'Stan Laurel & Oliver Hardy' },
        ],
    );
    has_field 'fruit' => (
        type => 'Multiple',
        widget => 'CheckboxGroup',
#       tags => { inline => 1 },
        options => [
            { value => 1, label => 'Apples' },
            { value => 2, label => 'Oranges' },
            { value => 3, label => 'Pears' },
        ],
    );

=comment
# options groups...sigh
    has_field 'optgroup' => (
        type => 'Multiple',
        'ra.layout_type' => 'checkboxgroup',
    );

    sub options_optgroup { (
        {
            group => 'First Group',
            options => [
                { value => 1, label => 'One' },
                { value => 2, label => 'Two' },
                { value => 3, label => 'Three' },
            ],
            attributes => { class => 'group1' },
        },
        {
            group => 'Second Group',
            options => [
                { value => 4, label => 'Four' },
                { value => 5, label => 'Five' },
                { value => 6, label => 'Six' },
            ],
            label_attributes => { class => 'group2' },
        },
    ) }
=cut

}
my $form = Test::Form->new;
$form->process;

my $expected = q{
<div>
  <label for="comedians">Comedians</label>
  <div>
    <label class="checkbox" for="comedians0">
    <input name="comedians" type="checkbox" value="keaton" id="comedians0" />
      Buster Keaton
    </label>
  </div>
  <div>
    <label class="checkbox" for="comedians1">
    <input name="comedians" type="checkbox" value="chaplin" id="comedians1" />
      Charly Chaplin
    </label>
  </div>
  <div>
    <label class="checkbox" for="comedians2">
    <input name="comedians" type="checkbox" value="laurel &amp; hardy" id="comedians2" />
      Stan Laurel &amp; Oliver Hardy
    </label>
  </div>
</div>
};
my $rendered = $form->field('comedians')->render;
is_html( $rendered, $expected, 'output from checkbox group');

=comment
$expected = q{
<div>
  <label for="fruit">Fruit</label>
  <label class="checkbox inline" for="fruit.0">
    <input type="checkbox" value="1" name="fruit" id="fruit.0" />
    Apples
  </label>
  <label class="checkbox inline" for="fruit.1">
    <input type="checkbox" value="2" name="fruit" id="fruit.1" />
    Oranges
  </label>
  <label class="checkbox inline" for="fruit.2">
    <input type="checkbox" value="3" name="fruit" id="fruit.2" />
    Pears
  </label>
</div>
};
$rendered = $form->field('fruit')->render;
is_html( $rendered, $expected, 'output from inline checkbox group' );

my $params = {
    comedians          => [ 'chaplin', 'laurel & hardy' ],
};
$form->process($params);
$rendered = $form->field('comedians')->render;
$expected =
'<div>
  <label for="comedians">Comedians</label>
  <label class="checkbox" for="comedians.0">
    <input type="checkbox" value="keaton" name="comedians" id="comedians.0" />
    Buster Keaton
  </label>
  <label class="checkbox" for="comedians.1">
    <input type="checkbox" value="chaplin" name="comedians" id="comedians.1" checked="checked" />
    Charly Chaplin
  </label>
  <label class="checkbox" for="comedians.2">
    <input type="checkbox" value="laurel &amp; hardy" name="comedians" id="comedians.2" checked="checked" />
    Stan Laurel &amp; Oliver Hardy
  </label>
</div>';
is_html( $rendered, $expected, 'output from checkbox group' );

=comment
$rendered = $form->field('optgroup')->render;
$expected =
'<div>
  <label for="optgroup">Optgroup</label>
  <div class="group1">
    <label>First Group</label>
    <label class="checkbox" for="optgroup.0">
      <input type="checkbox" value="1" name="optgroup" id="optgroup.0" />
      One
    </label>
    <label class="checkbox" for="optgroup.1">
      <input type="checkbox" value="2" name="optgroup" id="optgroup.1" />
      Two
    </label>
    <label class="checkbox" for="optgroup.2">
      <input type="checkbox" value="3" name="optgroup" id="optgroup.2" />
      Three
    </label>
  </div>
  <div>
    <label class="group2">Second Group</label>
    <label class="checkbox" for="optgroup.3">
      <input type="checkbox" value="4" name="optgroup" id="optgroup.3" />
      Four
    </label>
    <label class="checkbox" for="optgroup.4">
      <input type="checkbox" value="5" name="optgroup" id="optgroup.4" />
      Five
    </label>
    <label class="checkbox" for="optgroup.5">
      <input type="checkbox" value="6" name="optgroup" id="optgroup.5" />
      Six
    </label>
  </div>
</div>';

is_html( $rendered, $expected,
    'output from checkbox group with option group attributes' );
=cut

done_testing;
