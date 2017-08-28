use strict;
use warnings;

package CMGITtests;

use Config;
use Test::More tests => 27;
use Capture::Tiny qw(capture);
use Class::Mock::Generic::InterfaceTester;

# Basics: if we mock a method call fixture, it works.
correct_method_call_gets_correct_results();

# Check that we can set_name
set_name_not_mocked();
set_name_mocked();

# mock _ok in C::M::G::IT so any reported failure is considered a success.
# That only applies to this version of the Perl interpreter; shelling out
# and calling C::M::G::IT with bad fixtures still results in a failure.
with_mocked_ok( sub {
    # check that the mock works!
    default_ok();

    # Now that we've done that, we can test all sorts of ways that things can
    # go wrong, and consider C::M::G::IT complaining about something as a
    # test success. We list the expected test failures in the plan above,
    # so just saying Test::More::done_testing at the end is insufficient:
    # that wouldn't distinguish between (a) a test ran and did nothing, and
    # (b) a test produced an error, which we turned into a test success,
    # and counted.
    run_out_of_tests();
    wrong_method();
    wrong_args_structure();
    wrong_args_subref();
    magic_for_new();
    didnt_run_all_tests();
});

# The various ways we have of adding fixtures work fine.
add_fixtures_method_not_mocked();
add_fixtures_arrayref();
add_fixtures_list();
add_fixtures_ordered_hash();
add_fixtures_input_omitted();

sub with_mocked_ok {
    Class::Mock::Generic::InterfaceTester->_ok(sub { Test::More::ok(!shift(), shift()); });
    shift->();
    Class::Mock::Generic::InterfaceTester->_reset_ok();
}

sub set_name_not_mocked {
    my $interface_tester = Class::Mock::Generic::InterfaceTester->new();
    $interface_tester->set_name('Harland & Wolff, Belfast');
    ok($interface_tester->{called_from} =~ /Harland/, "name was stored in 'called_from' attrib");

    $interface_tester->add_fixtures(
        set_name => { input  => ['Titanic'], output => "I name this ship 'Titanic'", }
    );
    # now that fixtures have been added this should blow up (wrong args)
    with_mocked_ok(sub { $interface_tester->set_name('Lusitania'); });
    # and this should blow up (run out of mocks)
    with_mocked_ok(sub { $interface_tester->set_name('Titanic'); });
}

sub set_name_mocked {
    # first test when we set mocks in the constructor
    my $interface_tester = Class::Mock::Generic::InterfaceTester->new(
        set_name => { input  => ['Titanic'], output => "I name this ship 'Titanic'", }
    );
    is(
        $interface_tester->set_name('Titanic'),
        "I name this ship 'Titanic'",
        "The method set_name isn't magical if you supplied a list of fixtures to the constructor"
    );
    # this should blow up (run out of tests)
    with_mocked_ok(sub { $interface_tester->set_name('Lusitania'); });

    # now test when we set mocks using add_fixtures
    $interface_tester = Class::Mock::Generic::InterfaceTester->new();
    $interface_tester->add_fixtures(
        set_name => { input  => ['Titanic'], output => "I name this ship 'Titanic'", }
    );
    is(
        $interface_tester->set_name('Titanic'),
        "I name this ship 'Titanic'",
        "The method set_name isn't magical if you supplied a list of fixtures using add_fixtures"
    );
    # this should blow up (run out of tests)
    with_mocked_ok(sub { $interface_tester->set_name('Lusitania'); });
}

sub default_ok {
    my $perl = $Config{perlpath};

    my $result;
    {
      local $ENV{PERL5LIB} = join($Config{path_sep}, @INC);
      $result = (capture {
        system(
            $perl, qw( -MClass::Mock::Generic::InterfaceTester -e ),
            " Class::Mock::Generic::InterfaceTester->new([
                { method => 'wibble', input => ['wobble'], output => 'jelly' }
              ]) "
        )
      })[0];
    }
    ok($result =~ /^not ok.*didn't run all tests/, "normal 'ok' works")
        || diag($result);
}

sub didnt_run_all_tests {
    { 
        Class::Mock::Generic::InterfaceTester->new([
            { method => 'foo', input => ['foo'], output => 'foo' },
        ]);
    }
}

sub correct_method_call_gets_correct_results {
    my $interface = Class::Mock::Generic::InterfaceTester->new([
        { method => 'foo', input => ['foo'], output => 'foo' },
    ]);

    ok($interface->foo('foo') eq 'foo', "correct method call gets right result back");
}

sub run_out_of_tests {
    my $interface = Class::Mock::Generic::InterfaceTester->new([
        { method => 'foo', input => ['foo'], output => 'foo' },
    ]);

    $interface->foo('foo'); # eat the first test
    $interface->foo('bar'); # should emit an ok(1, "run out of tests ...")
}

sub wrong_method {
    my $interface = Class::Mock::Generic::InterfaceTester->new([
        { method => 'foo', input => ['foo'], output => 'foo' },
    ]);

    $interface->bar('foo'); # should emit an ok(1, "wrong method ...");
}

sub wrong_args_structure {
    my $interface = Class::Mock::Generic::InterfaceTester->new([
        { method => 'foo', input => ['foo'], output => 'foo' },
    ]);

    $interface->foo('bar'); # should emit an ok(1, "wrong args to method ...");
}

sub wrong_args_subref {
    my $interface = Class::Mock::Generic::InterfaceTester->new([
        { method => 'foo', input => sub { shift() eq 'foo' }, output => 'bar' },
        { method => 'foo', input => sub { shift() eq 'foo' }, output => 'foo' },
    ]);

    ok($interface->foo('foo') eq 'bar', "subref as input can pass");
    $interface->foo('bar'); # should emit an ok(1, "wrong args to method ...");
}

sub magic_for_new {
    my $interface = Class::Mock::Generic::InterfaceTester->new([
        { method => 'new', input => ['foo'], output => 'foo' },
        { method => 'new', input => ['foo'], output => 'foo' },
    ]);

    ok($interface->new('foo') eq 'foo', "\$mockobject->new() returns right data");
    $interface->new('bar'); # should emit an ok(1, "wrong args to method ...");
}

sub add_fixtures_method_not_mocked {
    my $interface_tester = Class::Mock::Generic::InterfaceTester->new(
        [
            {
                method => 'add_fixtures',
                input  => ['curtain rail', 'picture hook'],
                output => 'Picture hung!',
            }
        ]
    );
    is(
        $interface_tester->add_fixtures('curtain rail', 'picture hook'),
        'Picture hung!',
        q{The method add_fixtures isn't magical if you supplied}
            . ' a list of fixtures to the constructor'
    );
}

sub add_fixtures_arrayref {
    my $interface_tester = Class::Mock::Generic::InterfaceTester->new;
    $interface_tester->add_fixtures(
        [
            {
                method => 'frolic',
                input  => ['joyously'],
                output => 'yay!',
            },
            {
                method => 'celebrate',
                input  => sub { 1 },
                output => q{It's your birthday!},
            }
        ]
    );
    is($interface_tester->frolic('joyously'), 'yay!',
        'You can add a method fixture as an arrayref');
    is($interface_tester->celebrate, q{It's your birthday!},
        'More than one');
}

sub add_fixtures_list {
    my $interface_tester = Class::Mock::Generic::InterfaceTester->new;
    $interface_tester->add_fixtures(
        {
            method => 'brood',
            input  => [{ style => 'teenager', glower => 'yes', }],
            output => 'Excellent gloom',
        },
        {
            method => 'sulk',
            input  => ['endlessly'],
            output => 'Woe!',
        }
    );
    is(
        $interface_tester->brood({ glower => 'yes', style => 'teenager' }),
        'Excellent gloom',
        'You can add a method fixture as a list'
    );
    is($interface_tester->sulk('endlessly'), 'Woe!',
        'And another');
}

sub add_fixtures_ordered_hash {
    my $interface_tester = Class::Mock::Generic::InterfaceTester->new;
    $interface_tester->add_fixtures(
        rock => {
            input  => ['horns'],
            output => 'metal AF',
        },
        paper => {
            input  => [{ over => 'cracks' }],
            output => 'Totally covered',
        },
        scissors => {
            input  => ['Attractive woman', 'Other attractive woman'],
            output => 'Not going to happen',
        }
    );
    is($interface_tester->rock('horns'), 'metal AF',
        'One call to our mocked interface');
    is(
        $interface_tester->paper({ over => 'cracks' }),
        'Totally covered',
        'And another with slightly fancy arguments'
    );
    is(
        $interface_tester->scissors(
            'Attractive woman',
            'Other attractive woman'
        ),
        'Not going to happen',
        'Arrayref arguments work as well'
    );
}

sub add_fixtures_input_omitted {
    my $interface_tester = Class::Mock::Generic::InterfaceTester->new;
    $interface_tester->add_fixtures(
        [
            {
                method => 'blow_things_up',
                output => 'Boom!',
            }
        ]
    );
    is(
        $interface_tester->blow_things_up(
            q{It doesn't matter what I want to blow up}
        ),
        'Boom!',
        'If you omit input, its exact value is ignored'
    );
    $interface_tester->add_fixtures(
        blow_things_up_again => {
            output => 'Boom! Boom! Boom for everyone!',
        }
    );
    like(
        $interface_tester->blow_things_up_again(
            qw(tinky-winky laa-laa dipsy po )),
        qr/Boom/,
        'This works for shorthand fixtures as well'
    );
}
