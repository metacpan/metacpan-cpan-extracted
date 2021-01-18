use strict;
use warnings;

use Test::More tests => 20;
BEGIN { use_ok('Algorithm::CP::IZ') };

my $iz = Algorithm::CP::IZ->new();
my $v1 = $iz->create_int(0, 10);


# save_context - restore_context pair works
# too many restore_context
{
    my $a = $iz->save_context;
    $v1->Le(5);
    my $b = $iz->save_context;
    $v1->Le(3);

    $iz->restore_context;
    is($v1->max, 5);
    $iz->restore_context;
    is($v1->max, 10);

    my $err = 1;
    eval {
        $iz->restore_context;
	$err = 0;
    };

    is($err, 1);
}

# save_context - restore_context_util works
{
    my $a = $iz->save_context;
    $v1->Le(5);
    my $b = $iz->save_context;
    $v1->Le(3);
    my $c = $iz->save_context;
    $v1->Le(2);

    $iz->restore_context_until($b); # state to before $b
    is($v1->max, 5);
    $iz->restore_context;
    is($v1->max, 10);

    my $err = 1;
    eval {
        $iz->restore_context;
	$err = 0;
    };

    is($err, 1);
}

# restore_all works
# invalid restore_context after restore_all
{
    my $a = $iz->save_context;
    $v1->Le(5);
    my $b = $iz->save_context;
    $v1->Le(3);

    $iz->restore_all;
    is($v1->max, 10);

    my $err = 1;
    eval {
        $iz->restore_context;
	$err = 0;
    };

    is($err, 1);
}

# save_context - accept_context pair works
# invalid accept_context
{
    my $va = $iz->create_int(0, 10);

    my $a = $iz->save_context;
    $va->Le(5);
    my $b = $iz->save_context;
    $va->Le(3);

    $iz->accept_context; # Le(3) is accepted
    is($va->max, 3);

    $iz->restore_context;
    is($va->max, 10);

    my $err = 1;
    eval {
        $iz->accept_context;
	$err = 0;
    };

    is($err, 1);
}

# save_context - accept_context_util works
{
    my $va = $iz->create_int(0, 10);

    my $a = $iz->save_context;
    $va->Le(5);
    my $b = $iz->save_context;
    $va->Le(3);
    my $c = $iz->save_context;
    $va->Le(2);

    $iz->accept_context_until($b); # 2 is accepted, $b, $c is wasted.
    is($va->max, 2);
    $iz->restore_context; # restore to context $a
    is($va->max, 10);

    my $err = 1;
    eval {
        $iz->accept_context;
	$err = 0;
    };

    is($err, 1);
}

# accept_all works
{
    my $va = $iz->create_int(0, 10);

    my $a = $iz->save_context;
    $va->Le(5);
    my $b = $iz->save_context;
    $va->Le(3);

    $iz->accept_all; # Le(3)
    is($va->max, 3);

    my $err = 1;
    eval {
        $iz->accept_context;
	$err = 0;
    };

    is($err, 1);
}

# version
{
    my $version = $iz->get_version;
    if (defined($version)) {
	ok($version =~ /^[0-9]+\.[0-9]+\.[0-9]+$/);
    }
    else {
	ok(1);
    }
}

# duplicated instance
{
    my $err = 1;

    eval {
	my $iz2 = Algorithm::CP::IZ->new;
	$err = 0;
    };

    is($err, 1);
}

# destroy and invalidated
{
    $iz = undef;
    is(ref $v1, "Algorithm::CP::IZ::Int::InvalidInt");
}
