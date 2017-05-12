use inc::Module::Install 0.75;

name        'Catalyst-View-Graphics-Primitive';
all_from    'lib/Catalyst/View/Graphics/Primitive.pm';

requires    'Catalyst::Runtime' => 5.7014;
requires    'Graphics::Primitive' => 0.29;
requires    'Moose' => 0.57;
requires    'Scalar::Util' => 1.19;
requires    'Class::Load' => 0.22;

WriteAll;
