#! perl

use Test2::V0;
use Test::Lib;
use My::Test::Utils 'export_from';

# make sure we don't mess up exports from a Type::Library

package My::Library {

    use CXC::Exporter::Util ':all';
    use Type::Tiny::Class;
    use Type::Utils -all;
    use Type::Library -base,
      -extends => ['Types::Standard'],
      -declare => qw( Foo );

    sub Bar { }
    install_EXPORTS( { misc => ['Bar'] } );

    declare Foo, as Str;

    __PACKAGE__->meta->add_type(
        Type::Tiny->new(
            name                 => 'NewInstanceOf',
            constraint_generator => sub {
                my $class = shift;
                die( "too many parameters" ) if @_;
                Type::Tiny::Class::->new( class => $class )->plus_constructors;
            },
        ) );
}

use constant class => 'My::Library';

ok( export_from( class, '-all' )->can( $_ ), $_ )
  for 'Foo', 'NewInstanceOf', 'Bar';

done_testing;
