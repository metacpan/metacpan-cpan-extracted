use strict;
use constant HAS_THREADS => eval{ require threads; threads->create(sub{return 1})->join };
use Test::More HAS_THREADS ? ('no_plan') : (skip_all => 'for threaded perls only');

{
    package Test;
    use Class::Accessor::Inherited::XS inherited => [qw/foo/];
}

{
    package Jopa;
    use parent qw/Class::Accessor::Inherited::XS/;
}

my @threads;

Test->foo(3);

sub same_name {
    my $val = $_;
    return sub {
        die if Test->foo($val) != $val;
        die if Test->foo != $val;
    };
}

sub same_name_recreate {
    my $val = $_;
    return sub {
        Jopa->mk_inherited_accessors(['foo', 'bar']);
        die if Jopa->foo($val) != $val;
        die if $Jopa::__cag_bar != $val;
        die if Jopa->foo != $val;

        undef *{Jopa::foo};
    };
}

sub diff_name_over {
    my $val = $_;
    return sub {
        Jopa->mk_inherited_accessors(["foo", "bar_$val"]);
        die if Jopa->foo($val) != $val;
        {
            no strict 'refs';
            die if ${"Jopa::__cag_bar_$val"} != $val;
        }
        die if Jopa->foo != $val;

        undef *{Jopa::foo};
    };
}

sub run_threaded {
    my $generator = shift;

    for my $code (map $generator->(), qw/17 42 80/) {
        push @threads, threads->create(sub {
            $code->() for (1..100_000);
        });
    }

    $_->join for splice @threads;

    ok 1;
}

run_threaded(\&same_name);
is(Test->foo, 3); #still in main thr

run_threaded(\&same_name_recreate);
run_threaded(\&diff_name_over);
