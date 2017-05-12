package MadeUp::Class::Singleton;
use Moo;
with 'MooX::Singleton';
has qw( foo is rw );
1;
