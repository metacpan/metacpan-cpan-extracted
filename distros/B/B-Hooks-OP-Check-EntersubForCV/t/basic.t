use strict;
use warnings;
use Test::More tests => 20;

BEGIN { use_ok('B::Hooks::OP::Check::EntersubForCV') }

sub foo { 'affe'  }
sub bar { 'birne' }

my ($i, $cv);
BEGIN {
    $i = 0;
    $cv = \&foo;
}

sub entersub_cb {
    my ($code) = @_;
    $i++;
    is($code->(), 'affe', 'got the right coderef');
}

foo();

my @id;

BEGIN {
    is($i, 0, 'no callback yet');

    push @id, B::Hooks::OP::Check::EntersubForCV::register($cv, \&entersub_cb);
    is($i, 0, 'no callback after registration');
}

foo();
bar();

BEGIN {
    is($i, 1, 'simple callback');
    $i = 0;
}

my $x = \&foo;

BEGIN {
    is($i, 0, '\&foo does not issue a callback');
    $i = 0;
}

&foo;
&foo();

BEGIN {
    TODO: {
        local $TODO = 'TODO';
        is($i, 2, '&foo and &foo() issue a callback');
    }

    $i = 0;
}

foo();
bar();
foo();

BEGIN {
    is($i, 2, 'multiple callbacks');

    push @id, B::Hooks::OP::Check::EntersubForCV::register($cv, \&entersub_cb);
    is($i, 2, 'no callback after multiple registrations');

    $i = 0;
}

foo();
bar();
foo();

BEGIN {
    is($i, 4, 'multiple callbacks for multiple entersubs');

    B::Hooks::OP::Check::EntersubForCV::unregister(pop @id);

    $i = 0;
}

foo();
bar();
foo();

BEGIN {
    is($i, 2, 'deregistration');

    B::Hooks::OP::Check::EntersubForCV::unregister(pop @id);

    $i = 0;
}

foo();
bar();
foo();

BEGIN {
    is($i, 0, 'no callbacks after removing all registers');
}
