package Foo;

use Elastic::Model;

#===================================
has_namespace 'foo' => {
#===================================
    user => 'Foo::User'
};

1;