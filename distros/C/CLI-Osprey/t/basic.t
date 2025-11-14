#! perl

use Test::More;
use Capture::Tiny qw( capture );

use Test::Lib;
use MyTest::Class::Basic;

subtest 'command' => sub {

    subtest "default options" => sub {
        local @ARGV = ();
        my ( $stdout, $stderr, @result ) =
           capture { MyTest::Class::Basic->new_with_options->run };

        is ( $stdout, "Hello world!\n", "message sent to stdout" );
        is ( $stderr, '', "empty stderr" );

    };

    subtest "command line options" => sub {
        local @ARGV = ( '--message', 'Hello Cleveland!' );
        my ( $stdout, $stderr, @result ) =
           capture { MyTest::Class::Basic->new_with_options->run };

        is ( $stdout, "Hello Cleveland!\n", "message sent to stdout" );
        is ( $stderr, '', "empty stderr" );

    };

};

subtest 'subcommand' => sub {
    subtest 'yell class subcommand' => sub {
        require CLI::Osprey::Role;
        require MyTest::Class::Basic::Yell;
        my %options = MyTest::Class::Basic::Yell->_osprey_options();

        # Helper function: get getopt string for an option
        my $get_getopt_string = sub {
            my ($option_name) = @_;
            my %attrs = %{ $options{$option_name} };
            my $getopt = CLI::Osprey::Role::_osprey_option_to_getopt($option_name, %attrs);
            note("$option_name getopt string: $getopt");
            return $getopt;
        };

        # Helper function: run yell command and capture output
        my $run_yell_command = sub {
            my (@args) = @_;
            local @ARGV = ('yell', @args);
            local *CORE::exit = sub { };  # Prevent exit() from terminating test process
            my ($stdout, $stderr, @result) = capture { MyTest::Class::Basic->new_with_options->run };
            return ($stdout, $stderr);
        };

        # Helper function: run yell command and test output
        my $test_yell_command = sub {
            my ($args, $stdout_pattern, $description) = @_;
            my ($stdout, $stderr) = $run_yell_command->(@$args);
            like($stdout, $stdout_pattern, $description);
            is($stderr, '', "empty stderr");
            return ($stdout, $stderr);
        };

        subtest "default options" => sub {
            $test_yell_command->([], qr{^\QHELLO WORLD!\E\n$}, "message sent to stdout");
        };

        subtest "output_format option" => sub {
            subtest "internal: generates hyphenated getopt string" => sub {
                my $getopt = $get_getopt_string->('output_format');
                like($getopt, qr{\Qoutput-format\E}, "generates hyphenated getopt string");
                unlike($getopt, qr{\Qoutput_format\E}, "does not generate underscored getopt string");
            };

            subtest "functional: --output-format long option" => sub {
                $test_yell_command->([qw(--output-format xml)], qr{\Q<yell>HELLO WORLD!</yell>\E},
                                 "XML format output");
            };

            subtest "functional: -f short option" => sub {
                $test_yell_command->([qw(-f json)], qr{\Q"yell": "HELLO WORLD!"\E},
                                 "JSON format output");
            };
        };

        subtest "excitement_level option" => sub {
            subtest "internal: generates hyphenated getopt string" => sub {
                my $getopt = $get_getopt_string->('excitement_level');
                like($getopt, qr{\Qexcitement-level\E}, "generates hyphenated getopt string");
                unlike($getopt, qr{\Qexcitement_level\E}, "does not generate underscored getopt string");
            };

            subtest "functional: --excitement-level" => sub {
                $test_yell_command->([qw(--excitement-level 2)], qr{^\QHELLO WORLD!!!\E\n$},
                                 "excitement level adds exclamation marks");
            };
        };

        subtest "repeat_count option" => sub {
            subtest "functional: -r short option" => sub {
                my ($stdout, $stderr) = $run_yell_command->(qw(-r 3));
                my @lines = split /\n/, $stdout;
                is ( scalar(@lines), 3, "repeated 3 times" );
                is ( $lines[0], "HELLO WORLD!", "first line correct" );
                is ( $stderr, '', "empty stderr" );
            };
        };

        subtest "custom_suffix option (custom option name)" => sub {
            subtest "internal: generates custom option name getopt string" => sub {
                my $getopt = $get_getopt_string->('custom_suffix');
                like($getopt, qr{\Qadd-suffix\E}, "generates custom 'add-suffix' getopt string");
                unlike($getopt, qr{custom[_-]suffix}, "does not generate attribute name in getopt string");
                is($getopt, 'add-suffix|s=s', "complete getopt string uses custom option name");
            };

            subtest "functional: -s short option" => sub {
                $test_yell_command->([qw(-s), '[BOOM]'], qr{\QHELLO WORLD![BOOM]\E},
                                 "custom suffix added via -s");
            };

            subtest "functional: --add-suffix long option" => sub {
                $test_yell_command->([qw(--add-suffix), '[POW]'], qr{\QHELLO WORLD![POW]\E},
                                 "custom suffix added via --add-suffix");
            };
        };

        subtest "add_tag option (negatable)" => sub {
            subtest "internal: generates hyphenated negatable getopt string" => sub {
                my $getopt = $get_getopt_string->('add_tag');
                like($getopt, qr{\Qadd-tag!\E}, "generates hyphenated negatable getopt string");
                unlike($getopt, qr{\Qadd_tag\E}, "does not generate underscored getopt string");
            };

            subtest "functional: --add-tag" => sub {
                $test_yell_command->([qw(--add-tag)], qr{\Q[TAG] HELLO WORLD!\E},
                                 "tag added via --add-tag");
            };

            subtest "functional: --no-add-tag" => sub {
                my ($stdout, $stderr) = $run_yell_command->(qw(--no-add-tag));
                unlike($stdout, qr{\Q[TAG]\E}, "no tag when disabled via --no-add-tag");
                like($stdout, qr{^\QHELLO WORLD!\E$}, "plain output");
                is($stderr, '', "empty stderr");
            };
        };

        subtest "abbreviate feature" => sub {
            subtest "--out abbreviates --output-format" => sub {
                $test_yell_command->([qw(--out xml)], qr{\Q<yell>HELLO WORLD!</yell>\E},
                                 "abbreviated --out works for --output-format");
            };

            subtest "--output-form abbreviates --output-format" => sub {
                $test_yell_command->([qw(--output-form xml)], qr{\Q<yell>HELLO WORLD!</yell>\E},
                                 "abbreviated --output-form works for --output-format");
            };
        };

        subtest "combinations" => sub {
            subtest "minimum failing case: short + hyphenated long" => sub {
                $test_yell_command->([qw(-f xml --excitement-level 2)],
                                 qr{\Q<yell>HELLO WORLD!!!</yell>\E},
                                 "XML format via -f with excitement-level 2");
            };

            subtest "multiple hyphenated long options" => sub {
                my ($stdout, $stderr) = $run_yell_command->(qw(--excitement-level 2 --output-format xml --repeat-count 2));
                my @lines = split /\n/, $stdout;
                is ( scalar(@lines), 2, "repeated 2 times" );
                like ( $lines[0], qr{\Q<yell>HELLO WORLD!!!</yell>\E}, "XML with excitement-level 2" );
                is ( $stderr, '', "empty stderr" );
            };

            subtest "custom option + other options" => sub {
                $test_yell_command->([qw(-f xml --add-suffix), '[ZAP]', qw(--excitement-level 1)],
                                 qr{\Q<yell>HELLO WORLD!![ZAP]</yell>\E},
                                 "custom suffix combined with format and excitement");
            };
        };
    };

    subtest "inline subcommand" => sub {
        local @ARGV = qw ( whisper );
        local *CORE::exit = sub { };
        my ($stdout, $stderr) = capture { MyTest::Class::Basic->new_with_options->run };
        is ( $stdout, "hello world!\n", "message sent to stdout" );
        is ( $stderr, '', "empty stderr" );
    };

};

done_testing;
