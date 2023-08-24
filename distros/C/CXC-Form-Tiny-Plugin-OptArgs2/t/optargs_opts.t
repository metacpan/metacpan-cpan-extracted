#! perl

use v5.20;

use Test2::V0;
use Test::Lib;

use My::Test::AutoCleanHash;
use OptArgs2;
use Ref::Util 'is_regexpref';
use List::Util 'pairmap';

use experimental 'signatures', 'postderef';

##no critic (Modules::ProhibitMultiplePackages)

package My::Variant {

    use Package::Variant
      importing => [
        'Form::Tiny',      [ plugins => [ '+CXC::Form::Tiny::Plugin::OptArgs2', '+My::Test::Plugin' ] ],
        'Types::Standard', ['Any'],
      ],
      subs => [qw( optargs_opts option form_field Any )],
      ;


    sub make_variant ( $class, $target_package, %arguments ) {
        optargs_opts( %arguments );

        form_field 'field0' => ( type => Any );
        option(
            isa     => 'Str',
            comment => 'field0',
        );


        $target_package->form_meta;
    }
}

## no critic ( ValuesAndExpressions::ProhibitLongChainsOfMethodCalls )

# default value for inherit_optargs is false, but My::Test::Plugin flips it
is( Package::Variant->build_variant_of( 'My::Variant' )->new->form_meta->inherit_optargs,
    T(), 'Plugin overrides default' );

# and now we flip it back
is(
    Package::Variant->build_variant_of( 'My::Variant', inherit_optargs => !!0 )
      ->new->form_meta->inherit_optargs,
    F(),
    'class options overrides Plugin'
);

done_testing;
