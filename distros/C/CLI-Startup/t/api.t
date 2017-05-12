# Basic API tests

use Test::More;
use Test::Trap;
use Test::Exception;

use CLI::Startup;

my $app = CLI::Startup->new;

# Some calls aren't allowed AT ALL
ok !$app->can('set_config'),     "<config> attribute not settable";
ok !$app->can('set_options'),    "<options> attribute not settable";
ok !$app->can('set_initalized'), "<initialized> attribute not settable";

# Some calls aren't allowed /before/ init
throws_ok { $app->get_config       } qr/before init/,
    "get_config() before init()";
throws_ok { $app->get_options      } qr/before init/,
    "get_options() before init()";
throws_ok { $app->get_raw_options  } qr/before init/,
    "get_raw_options() before init()";
throws_ok { $app->write_rcfile     } qr/before init/,
    "write_rcfile() before init()";

# This call should fail because options weren't defined yet.
throws_ok { $app->die_usage } qr/FATAL/, "die_usage() with no options";

# These calls should fail due to incorrect arguments
throws_ok { $app->init(1) } qr/no arguments/,
    "init() dies when called with args";
throws_ok { $app->set_write_rcfile(1) } qr/requires a coderef/,
    "set_write_rcfile() requires a coderef";
throws_ok { $app->set_optspec } qr/requires a hashref/,
    "set_optspec() requires a hashref";
throws_ok { $app->set_default_settings    } qr/requires a hashref/,
    "set_default_settings() requires an argument";
throws_ok { $app->set_default_settings(1) } qr/requires a hashref/,
    "set_default_settings() requires a hashref";

# These calls should all live
lives_ok { $app->set_usage('')             } "set_usage() lives";
lives_ok { $app->set_rcfile('')            } "set_rcfile() lives";
lives_ok { $app->set_default_settings({})  } "set_default_settings() lives";
lives_ok { $app->set_write_rcfile('')      } "set_write_rcfile() lives";
lives_ok { $app->set_write_rcfile(undef)   } "set_write_rcfile(undef) lives";
lives_ok { $app->set_write_rcfile(sub{})   } "set_write_rcfile(sub{}) lives";

# This call should live, but the "help" option should be overridden
lives_ok { $app->set_optspec({foo=>'bar', help=>0}) } "set_optspec() lives";
like $app->get_optspec->{help}, qr/help message/, "Could not delete --help option";

# Now call init()
lives_ok { $app->init } "init() lives the first time";

# Now that options were set, die_usage() should succeed--which means
# that it should die with a usage message.
trap { $app->die_usage };
like $trap->stderr, qr/usage:/, "die_usage() succeeds";
ok $trap->stdout eq '', "Nothing printed to stdout";
ok $trap->exit == 1, "Correct exit status";

# Caling die_usage() with a message should cause it
# to be printed.
trap { $app->die_usage("rutabaga") };
like $trap->stderr, qr/usage:/, "die_usage() succeeds";
like $trap->stderr, qr/rutabaga/, "die_usage() message is printed";
ok $trap->stdout eq '', "Nothing printed to stdout";
ok $trap->exit == 1, "Correct exit status";

# Some calls aren't allowed /after/ init
my $die = "dies after init()";
my $err = qr/after init/;
throws_ok { $app->init                     } qr/second time/, "init() $die";
throws_ok { $app->set_usage                } $err, "set_usage() $die";
throws_ok { $app->set_rcfile               } $err, "set_rcfile() $die";
throws_ok { $app->set_optspec({})          } $err, "set_optspec() $die";
throws_ok { $app->set_write_rcfile         } $err, "set_write_rcfile() $die";
throws_ok { $app->set_default_settings({}) } $err, "set_default_settings() $die";

# Print warning messages, nicely formatted
trap { $app->warn("scary warning") };
like $trap->stderr, qr/WARNING/, "Printed a warning";
like $trap->stderr, qr/scary warning/,  "Printed the correct message";

done_testing();
