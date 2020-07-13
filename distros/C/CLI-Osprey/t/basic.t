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

    subtest "default options" => sub {
	local @ARGV = qw ( yell );
	my ( $stdout, $stderr, @result ) =
	   capture { MyTest::Class::Basic->new_with_options->run };

	is ( $stdout, "HELLO WORLD!\n", "message sent to stdout" );
	is ( $stderr, '', "empty stderr" );
    };

    subtest "hyphenated options" => sub {
	local @ARGV = qw ( yell --excitement-level 2 );
	my ( $stdout, $stderr, @result ) =
	   capture { MyTest::Class::Basic->new_with_options->run };

	is ( $stdout, "HELLO WORLD!!!\n", "message sent to stdout" );
	is ( $stderr, '', "empty stderr" );
    };

    subtest "inline" => sub {
	local @ARGV = qw ( whisper );
	my ( $stdout, $stderr, @result ) =
	   capture { MyTest::Class::Basic->new_with_options->run };

	is ( $stdout, "hello world!\n", "message sent to stdout" );
	is ( $stderr, '', "empty stderr" );
    };

};

done_testing;
