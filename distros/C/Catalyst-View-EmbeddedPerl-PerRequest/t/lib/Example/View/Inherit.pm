package Example::View::Inherit;

use Moose;
use MooseX::MethodAttributes;
extends 'Example::View::Base';

has 'name' => (is => 'ro', isa => 'Str', default => 'world', export=>1);

sub title :Helper  { 'Inherited Title' }
sub bbb :Helper { 'bbb1' }

around 'helpers', sub {
  my ($orig, $class) = @_;
  return (
    test_name2 => sub { 'joe2' },
    $class->$orig,
  );
};

__PACKAGE__->meta->make_immutable;
__PACKAGE__->config(helpers => {
  test_name4 => sub { 'joe4' }
});

__DATA__
# Style content
% content_for('css', sub {\
      p { color: red; }
% });
# Main content
  %= &test_name1
  %= test_name2()
  %= test_name3()
  %= test_name4()
  %= $aaa
  %= bbb()
  %= ccc()
  <p>hello <%= $name %></p>\
