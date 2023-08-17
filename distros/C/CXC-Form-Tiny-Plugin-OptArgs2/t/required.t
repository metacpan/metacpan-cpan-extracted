#! perl

use v5.20;

use Test2::V0;
use Test::Lib;

use My::Test::AutoCleanHash;
use Data::Dumper;
use OptArgs2;

use experimental 'signatures', 'postderef';

package My::Form {

    use Form::Tiny plugins => ['+CXC::Form::Tiny::Plugin::OptArgs2'];
    use Types::Common::String qw( NonEmptyStr );

    form_field 'file' => (
        type     => NonEmptyStr,
        required => 1,
    );

    option(
        comment  => 'Query in a file',
        isa_name => 'ADQL in a file',
    );
}

my $form = My::Form->new;

subtest 'present' => sub {

    local @ARGV = qw( --file foo );

    my $optargs = $form->optargs;
    is(
        $optargs,
        array {
            item 'file';
            item hash {
                field comment  => 'Query in a file';
                field required => 1;
                field isa      => '--Str';
                field isa_name => 'ADQL in a file';
                end;
            };
            end;
        },
        'correct optargs output',
    );

};


done_testing;
