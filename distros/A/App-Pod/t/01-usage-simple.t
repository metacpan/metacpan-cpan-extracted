#!perl
use v5.24;    # Postfix defef.
use strict;
use warnings;
use Test::More;
use Term::ANSIColor qw( colorstrip );

#TODO: Remove this debug code !!!
use feature qw(say);
use Mojo::Util qw(dumper);

BEGIN {
   use_ok( 'App::Pod' ) || print "Bail out!\n";
}

diag( "Testing App::Pod $App::Pod::VERSION, Perl $], $^X" );

{
   no warnings qw( redefine once );

   # Make sure this is already defined a a number.
   like( Pod::Query::get_term_width(),
      qr/^\d+$/, "get_term_width eturns a number" );

   *Pod::Query::get_term_width = sub { 56 };    # Match android.
}

my @cases = (
   {
      name            => "No Input - Help",
      input           => ["--help"],
      expected_output => [
         "",
         "Shows available class methods and documentation",
         "",
         "Syntax:",
         "   pod module_name [method_name]",
         "",
         "Options::",
         "   --all, -a            - Show all class functions.",
         "   --doc, -d            - View the class documentation.",
         "   --edit, -e           - Edit the source code.",
         "   --help, -h           - Show this help section.",
         "   --list_tool_options  - List tool options.",
         "   --list_class_options - List class events and methods.",
         "",
         "Examples:",
         "   # Methods",
         "   pod Mojo::UserAgent",
         "   pod Mojo::UserAgent -a",
         "",
         "   # Method",
         "   pod Mojo::UserAgent prepare",
         "",
         "   # Documentation",
         "   pod Mojo::UserAgent -d",
         "",
         "   # Edit",
         "   pod Mojo::UserAgent -e",
         "   pod Mojo::UserAgent prepare -e",
         "",
         "   # List all methods",
         "   pod Mojo::UserAgent --list_class_options",
      ],
   },
   {
      name            => "Module - ojo",
      input           => ["ojo"],
      expected_output => [
         "",
         "Package: ojo",
         "Path:    PATH",
         "",
         "ojo - Fun one-liners with Mojo",
         "",
         "Inheritance (4):",
         " ojo",
         " Mojolicious",
         " Mojolicious::_Dynamic",
         " Mojo::Base",
         "",
         "Methods (16):",
         " a - Create a route with \"any\" in Mojolicious::Lite  ...",
         " b - Turn string into a Mojo::ByteStream object.",
         " c - Turn list into a Mojo::Collection object.",
         " d - Perform DELETE request with \"delete\" in Mojo::U ...",
         " f - Turn string into a Mojo::File object.",
         " g - Perform GET request with \"get\" in Mojo::UserAge ...",
         " h - Perform HEAD request with \"head\" in Mojo::UserA ...",
         " j - Encode Perl data structure or decode JSON with  ...",
         " l - Turn a string into a Mojo::URL object.",
         " n - Benchmark block and print the results to STDERR ...",
         " o - Perform OPTIONS request with \"options\" in Mojo: ...",
         " p - Perform POST request with \"post\" in Mojo::UserA ...",
         " r - Dump a Perl data structure with \"dumper\" in Moj ...",
         " t - Perform PATCH request with \"patch\" in Mojo::Use ...",
         " u - Perform PUT request with \"put\" in Mojo::UserAge ...",
         " x - Turn HTML/XML input into Mojo::DOM object.",
         "",
         "Use --all (or -a) to see all methods.",
      ],
   },
   {
      name            => "Module - Mojo::UserAgent",
      input           => ["Mojo::UserAgent"],
      expected_output => [
         "",
         "Package: Mojo::UserAgent",
         "Path:    PATH",
         "",
         "Mojo::UserAgent - Non-blocking I/O HTTP and WebSocke ...",
         "",
         "Inheritance (3):",
         " Mojo::UserAgent",
         " Mojo::EventEmitter",
         " Mojo::Base",
         "",
         "Events (2):",
         " prepare - Emitted whenever a new transaction is bei ...",
         " start   - Emitted whenever a new transaction is abo ...",
         "",
         "Methods (36):",
         " build_tx           - Generate Mojo::Transaction::HT ...",
         " build_websocket_tx - Generate Mojo::Transaction::HT ...",
         " ca                 - Path to TLS certificate author ...",
         " cert               - Path to TLS certificate file,  ...",
         " connect_timeout    - Maximum amount of time in seco ...",
         " cookie_jar         - Cookie jar to use for requests ...",
         " delete             - Perform blocking DELETE reques ...",
         " delete_p           - Same as \"delete\", but performs ...",
         " get                - Perform blocking GET request a ...",
         " get_p              - Same as \"get\", but performs al ...",
         " head               - Perform blocking HEAD request  ...",
         " head_p             - Same as \"head\", but performs a ...",
         " inactivity_timeout - Maximum amount of time in seco ...",
         " insecure           - Do not require a valid TLS cer ...",
         " ioloop             - Event loop object to use for b ...",
         " key                - Path to TLS key file, defaults ...",
         " max_connections    - Maximum number of keep-alive c ...",
         " max_redirects      - Maximum number of redirects th ...",
         " max_response_size  - Maximum response size in bytes ...",
         " options            - Perform blocking OPTIONS reque ...",
         " options_p          - Same as \"options\", but perform ...",
         " patch              - Perform blocking PATCH request ...",
         " patch_p            - Same as \"patch\", but performs  ...",
         " post               - Perform blocking POST request  ...",
         " post_p             - Same as \"post\", but performs a ...",
         " proxy              - Proxy manager, defaults to a M ...",
         " put                - Perform blocking PUT request a ...",
         " put_p              - Same as \"put\", but performs al ...",
         " request_timeout    - Maximum amount of time in seco ...",
         " server             - Application server relative UR ...",
         " socket_options     - Additional options for IO::Soc ...",
         " start              - Emitted whenever a new transac ...",
         " start_p            - Same as \"start\", but performs  ...",
         " transactor         - Transaction builder, defaults  ...",
         " websocket          - Open a non-blocking WebSocket  ...",
         " websocket_p        - Same as \"websocket\", but retur ...",
         "",
         "Use --all (or -a) to see all methods.",
      ],
   },
);

my $is_path = qr/ ^ Path: \s* \K (.*) $ /x;

for my $case ( @cases ) {
   local @ARGV = ( $case->{input}->@* );
   my $output;

   # Capture STDOUT.
   {
      local *STDOUT;
      open STDOUT, ">", \$output or die $!;
      App::Pod->run;
   }

   my @lines = split /\n/, colorstrip( $output );

   # Normalize Path.
   for ( @lines ) {
      last if s/$is_path/PATH/;
   }

   say dumper \@lines
     unless is_deeply( \@lines, $case->{expected_output}, $case->{name} );
}

done_testing();    # TODO: add the total

