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

package    # no CPAN index
  My::SubForm0 {

    use Form::Tiny plugins => ['+CXC::Form::Tiny::Plugin::OptArgs2'];

    use Types::Standard qw( Any );

    form_field 'subfield0' => ( type => Any );
    option(
        isa     => 'Str',
        comment => 'subfield0',
        default => sub { 'subvalue0' },
    );
}

package    # no CPAN index
  My::SubForm1 {

    use Form::Tiny plugins => ['+CXC::Form::Tiny::Plugin::OptArgs2'];
    use Types::Standard qw( Any );

    extends 'My::SubForm0';

    form_field 'subfield1' => ( type => Any );
    option(
        isa     => 'Str',
        comment => 'subfield1',
        default => sub { 'subvalue1' },
    );
}

package    # no CPAN index
  My::Form0 {

    use Form::Tiny plugins => ['+CXC::Form::Tiny::Plugin::OptArgs2'];
    use Types::Standard 'Any';
    form_field 'field0' => ( type => Any, );
    option(
        isa     => 'Str',
        comment => 'field0',
        default => sub { 'value0' },
    );

    form_field 'nested0' => ( type => My::SubForm1->new );
}

package    # no CPAN index
  My::Form1 {

    use Form::Tiny plugins => ['+CXC::Form::Tiny::Plugin::OptArgs2'];
    use Types::Standard 'Any';

    extends 'My::Form0';

    form_field 'field1' => ( type => Any, );
    option(
        isa     => 'Str',
        comment => 'field1',
        default => sub { 'value1' },
    );

    form_field 'nested1' => ( type => My::SubForm1->new );

}

package    # no CPAN index
  My::Form2 {

    use Form::Tiny plugins => ['+CXC::Form::Tiny::Plugin::OptArgs2'];
    use Types::Standard 'Any';

    extends 'My::Form1';

    form_field 'field2' => ( type => Any, );
    option(
        isa     => 'Str',
        comment => 'field2',
        default => sub { 'value2' },
    );

    form_field 'nested2' => ( type => My::SubForm1->new );

}

package    #
  My::Variant {

    use Package::Variant
      importing => [ 'Form::Tiny', [ plugins => ['+CXC::Form::Tiny::Plugin::OptArgs2'] ] ],
      subs      => [qw( extends optargs_opts )],
      ;

    sub make_variant ( $class, $target_package, %arguments ) {
        extends delete $arguments{parent};
        optargs_opts( inherit_optargs => 1, %arguments, );
        $target_package->form_meta;
    }
}


# no inheritance
subtest 'no inheritance' => sub {
    is(
        My::Form2->optargs,
        array {
            item 'field2';
            item hash { field comment => 'field2'; etc; };
            item 'nested2_subfield1';
            item hash { field comment => 'subfield1'; etc; };
            end;
        },
        'Form2',
    );

    is(
        My::Form1->optargs,
        array {
            item 'field1';
            item hash { field comment => 'field1'; etc; };
            item 'nested1_subfield1';
            item hash { field comment => 'subfield1'; etc; };
            end;
        },
        'Form1',
    );

    is(
        My::Form0->optargs,
        array {
            item 'field0';
            item hash { field comment => 'field0'; etc; };
            item 'nested0_subfield1';
            item hash { field comment => 'subfield1'; etc; };
            end;
        },
        'Form0',
    );

};

subtest 'inheritance' => sub {

    subtest 'Form2' => sub {
        my @fields = pairmap { [ $a, $b ] }
        Package::Variant->build_variant_of( 'My::Variant', parent => 'My::Form2', )->optargs->@*;

        is(
            \@fields,
            bag {
                item array {
                    item 'field2';
                    item hash { field comment => 'field2'; etc; };
                    end;
                };
                item array {
                    item 'nested2_subfield1';
                    item hash { field comment => 'subfield1'; etc; };
                    end;
                };
                item array {
                    item 'field1';
                    item hash { field comment => 'field1'; etc; };
                    end;
                };

                item array {
                    item 'nested1_subfield1';
                    item hash { field comment => 'subfield1'; etc; };
                    end;
                };

                item array {
                    item 'field0';
                    item hash { field comment => 'field0'; etc; };
                    end;
                };

                item array {
                    item 'nested0_subfield1';
                    item hash { field comment => 'subfield1'; etc; };
                    end;
                };
                end;
            },
        );
    };

    subtest 'Form2 included' => sub {

        my @fields = pairmap { [ $a, $b ] }
        Package::Variant->build_variant_of(
            'My::Variant',
            parent                => 'My::Form2',
            inherit_optargs_match => [ qr/Form0/, qr/Form2/ ],
        )->optargs->@*;

        is(
            \@fields,
            bag {

                item array {
                    item 'field2';
                    item hash { field comment => 'field2'; etc; };
                    end;
                };

                item array {
                    item 'nested2_subfield1';
                    item hash { field comment => 'subfield1'; etc; };
                    end;
                };

                item array {
                    item 'field0';
                    item hash { field comment => 'field0'; etc; };
                    end;
                };

                item array {
                    item 'nested0_subfield1';
                    item hash { field comment => 'subfield1'; etc; };
                    end;
                };
                end;
            },
        );

    };

    subtest 'Form2 excluded' => sub {

        my @fields = pairmap { [ $a, $b ] }
        Package::Variant->build_variant_of(
            'My::Variant',
            parent                => 'My::Form2',
            inherit_optargs_match => [ q{-}, qr/Form2/ ],
        )->optargs->@*;

        is(
            \@fields,
            bag {

                item array {
                    item 'field1';
                    item hash { field comment => 'field1'; etc; };
                    end;
                };

                item array {
                    item 'nested1_subfield1';
                    item hash { field comment => 'subfield1'; etc; };
                    end;
                };

                item array {
                    item 'field0';
                    item hash { field comment => 'field0'; etc; };
                    end;
                };

                item array {
                    item 'nested0_subfield1';
                    item hash { field comment => 'subfield1'; etc; };
                    end;
                };
                end;
            },
        );

    };

    subtest 'Form2 excluded & included' => sub {

        my @fields = pairmap { [ $a, $b ] }
        Package::Variant->build_variant_of(
            'My::Variant',
            parent                => 'My::Form2',
            inherit_optargs_match => [ qr/Form1/, q{-}, qr/Form0/ ],
        )->optargs->@*;

        is(
            \@fields,
            bag {

                item array {
                    item 'field1';
                    item hash { field comment => 'field1'; etc; };
                    end;
                };

                item array {
                    item 'nested1_subfield1';
                    item hash { field comment => 'subfield1'; etc; };
                    end;
                };

                item array {
                    item 'field2';
                    item hash { field comment => 'field2'; etc; };
                    end;
                };

                item array {
                    item 'nested2_subfield1';
                    item hash { field comment => 'subfield1'; etc; };
                    end;
                };
                end;
            },
        );

    };
};


done_testing;
