use strict;
use warnings;
use Test::More;
use Data::MuForm::Test;

{
    package MyApp::Form::Test;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'foo' => ( type => 'List', valid => ['one','bar','mix']);
    has_field 'bar' => ( type => 'List' );

}

my $form = MyApp::Form::Test->new;
ok( $form );
my $params = {
    foo => ['one', 'two', 'bar'],
    bar => ['fruit', 'vegetable', 'meat'],
};
$form->process( params => $params );
my $expected = q{
<div>
  <label for="bar">Bar</label>
  <div>
    <input type="text" name="bar" id="bar0" value="fruit"/>
  </div>
  <div>
    <input type="text" name="bar" id="bar1" value="vegetable"/>
  </div>
  <div>
    <input type="text" name="bar" id="bar2" value="meat"/>
  </div>
</div>
};
is_html( $form->field('bar')->render, $expected, 'bar field rendered ok' );

done_testing;
