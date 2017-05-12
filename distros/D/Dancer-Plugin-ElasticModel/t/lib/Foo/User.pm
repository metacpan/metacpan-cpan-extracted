package Foo::User;

use Elastic::Doc;

#===================================
has 'name' => (
#===================================
    is => 'ro',
    isa => 'Str',
);
1;