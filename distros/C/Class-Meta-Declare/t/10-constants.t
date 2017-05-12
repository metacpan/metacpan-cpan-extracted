#!perl

use strict;
use warnings;

#use Test::More qw/no_plan/;
use Test::More tests => 35;

BEGIN {
    chdir 't' if -d 't';
    use lib '../lib';
    use_ok('Class::Meta::Declare');
}

{

    package TestACC;
    use Class::Meta::Declare qw(:acc);

    my @acc = (
        [ PERL            => $ACC_PERL            => '' ],
        [ AFFORDANCE      => $ACC_AFFORDANCE      => 'affordance' ],
        [ SEMI_AFFORDANCE => $ACC_SEMI_AFFORDANCE => 'semi-affordance' ],
    );

    foreach my $acc (@acc) {
        main::is $acc->[1], $acc->[2], "acc $acc->[0] should be correct";
    }
}

{

    package TestAUTHZ;
    use Class::Meta::Declare qw(:authz);

    my @authz = (
        [ READ  => $AUTHZ_READ  => Class::Meta::READ ],
        [ WRITE => $AUTHZ_WRITE => Class::Meta::WRITE ],
        [ RDWR  => $AUTHZ_RDWR  => Class::Meta::RDWR ],
        [ NONE  => $AUTHZ_NONE  => Class::Meta::NONE ],
    );

    foreach my $authz (@authz) {
        main::is $authz->[1], $authz->[2],
          "authz $authz->[0] should be correct";
    }
}

{

    package TestVIEW;
    use Class::Meta::Declare qw(:view);

    my @view = (
        [ PUBLIC    => $VIEW_PUBLIC    => Class::Meta::PUBLIC ],
        [ PRIVATE   => $VIEW_PRIVATE   => Class::Meta::PRIVATE ],
        [ TRUSTED   => $VIEW_TRUSTED   => Class::Meta::TRUSTED ],
        [ PROTECTED => $VIEW_PROTECTED => Class::Meta::PROTECTED ],
    );

    foreach my $view (@view) {
        main::is $view->[1], $view->[2], "view $view->[0] should be correct";
    }
}

{

    package TestCONTEXT;
    use Class::Meta::Declare qw(:ctxt);

    my @context = (
        [ CLASS  => $CTXT_CLASS  => Class::Meta::CLASS ],
        [ OBJECT => $CTXT_OBJECT => Class::Meta::OBJECT ],
    );

    foreach my $context (@context) {
        main::is $context->[1], $context->[2],
          "context $context->[0] should be correct";
    }
}

{

    package TestCREATE;
    use Class::Meta::Declare qw(:create);

    my @create = (
        [ GET    => $CREATE_GET    => Class::Meta::GET ],
        [ SET    => $CREATE_SET    => Class::Meta::SET ],
        [ GETSET => $CREATE_GETSET => Class::Meta::GETSET ],
        [ NONE   => $CREATE_NONE   => Class::Meta::NONE ],
    );

    foreach my $create (@create) {
        main::is $create->[1], $create->[2],
          "create $create->[0] should be correct";
    }
}

{

    package TestTYPE;
    use Class::Meta::Declare qw(:type);

    my @type = (
        [ scalar    => $TYPE_SCALAR    => 'scalar' ],
        [ scalarref => $TYPE_SCALARREF => 'scalarref' ],
        [ array     => $TYPE_ARRAY     => 'array' ],
        [ arrayref  => $TYPE_ARRAYREF  => 'arrayref' ],
        [ hash      => $TYPE_HASH      => 'hash' ],
        [ hashref   => $TYPE_HASHREF   => 'hashref' ],
        [ code      => $TYPE_CODE      => 'code' ],
        [ coderef   => $TYPE_CODEREF   => 'coderef' ],
        [ closure   => $TYPE_CLOSURE   => 'closure' ],
        [ string    => $TYPE_STRING    => 'string' ],
        [ boolean   => $TYPE_BOOLEAN   => 'boolean' ],
        [ bool      => $TYPE_BOOL      => 'bool' ],
        [ whole     => $TYPE_WHOLE     => 'whole' ],
        [ integer   => $TYPE_INTEGER   => 'integer' ],
        [ decimal   => $TYPE_DECIMAL   => 'decimal' ],
        [ real      => $TYPE_REAL      => 'real' ],
        [ float     => $TYPE_FLOAT     => 'float' ],
    );

    foreach my $type (@type) {
        main::is $type->[1], $type->[2], "type '$type->[0]' should be correct";
    }
}
