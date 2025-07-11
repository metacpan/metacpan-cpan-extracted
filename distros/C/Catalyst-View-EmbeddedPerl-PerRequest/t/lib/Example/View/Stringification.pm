package Example::View::Stringification;

use Moose;
use MooseX::MethodAttributes;

extends 'Catalyst::View::EmbeddedPerl::PerRequest';

has object => (is=>'ro', required=>1, export=>1);

__PACKAGE__->meta->make_immutable;
__PACKAGE__->config(
  auto_escape => 1,
);

__DATA__
<p><%= $object->method1("John")->method2("Doe") =%></p>
<p>
  %= $object->clear->method1(sub {\
    <div>John</div>
  % })->method2(sub {\
    <div>Doe</div>
  % })\
</p>\
