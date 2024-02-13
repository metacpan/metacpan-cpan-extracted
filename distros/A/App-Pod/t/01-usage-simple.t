#!perl
use v5.24;    # Postfix defef.
use strict;
use warnings;
use Test::More tests => 35;
use Term::ANSIColor       qw( colorstrip );
use File::Spec::Functions qw( catfile catdir );
use open                  qw( :std :utf8 );
use FindBin               qw( $RealDir );
use lib catdir( $RealDir, "cpan" );

sub _dumper {
    require Data::Dumper;
    my $data = Data::Dumper
      ->new( [@_] )
      ->Indent( 1 )
      ->Sortkeys( 1 )
      ->Terse( 1 )
      ->Useqq( 1 )
      ->Dump;
    return $data if defined wantarray;
    say $data;
}

BEGIN {
    use_ok( 'App::Pod' ) || print "Bail out!\n";
}

diag( "Testing App::Pod $App::Pod::VERSION, Perl $], $^X" );

{
    no warnings qw( redefine once );

    # Make sure this is already defined a a number.
    like( Pod::Query::get_term_width(),
        qr/^\d+$/, "get_term_width returns a number" );

    *Pod::Query::get_term_width = sub { 55 };    # Match android.
}


my $sample_pod        = catfile( $RealDir, qw( cpan Mojo2 UserAgent.pm ) );
my $windows_safe_path = $sample_pod =~ s&(\\)&\\$1&gr;

ok( -f $sample_pod, "pod file exists: $sample_pod" );

my @cases = (

    # --help
    {
        name            => "No Input shows help",
        input           => [],
        expected_output => [
            "",
            "Syntax:",
            "  pod module_name [method_name] [options]",
            "",
            "Options:",
            "  --help, -h            - Show this help section.",
            "  --version, -v         - Show this tool version.",
            "  --tool_options, --to  - List tool options.",
            "  --class_options, --co - Class events and methods.",
            "  --doc, -d             - View class documentation.",
            "  --edit, -e            - Edit the source code.",
            "  --query, -q           - Run a pod query.",
            "  --dump, --dd          - Dump extra info (adds up).",
            "  --all, -a             - Show all class functions.",
            "  --no_colors           - Do not output colors.",
            '  --no_error            - Suppress some error message.',
            "  --flush_cache, -f     - Flush cache file(s).",
            "",
            "Examples:",
            "  # All or a method",
            "  pod Mojo::UserAgent",
            "  pod Mojo::UserAgent prepare",
            "",
            "  # Documentation",
            "  pod Mojo::UserAgent -d",
            "",
            "  # Edit class or method",
            "  pod Mojo::UserAgent -e",
            "  pod Mojo::UserAgent prepare -e",
            "",
            "  # List all methods",
            "  pod Mojo::UserAgent --class_options",
            "",
            "  # List all Module::Build actions.",
            "  pod Module::Build --query head1=ACTIONS/item-text"
        ],
    },
    {
        name            => "help",
        input           => [qw( --help )],
        expected_output => [
            "",
            "Syntax:",
            "  pod module_name [method_name] [options]",
            "",
            "Options:",
            "  --help, -h            - Show this help section.",
            "  --version, -v         - Show this tool version.",
            "  --tool_options, --to  - List tool options.",
            "  --class_options, --co - Class events and methods.",
            "  --doc, -d             - View class documentation.",
            "  --edit, -e            - Edit the source code.",
            "  --query, -q           - Run a pod query.",
            "  --dump, --dd          - Dump extra info (adds up).",
            "  --all, -a             - Show all class functions.",
            "  --no_colors           - Do not output colors.",
            '  --no_error            - Suppress some error message.',
            "  --flush_cache, -f     - Flush cache file(s).",
            "",
            "Examples:",
            "  # All or a method",
            "  pod Mojo::UserAgent",
            "  pod Mojo::UserAgent prepare",
            "",
            "  # Documentation",
            "  pod Mojo::UserAgent -d",
            "",
            "  # Edit class or method",
            "  pod Mojo::UserAgent -e",
            "  pod Mojo::UserAgent prepare -e",
            "",
            "  # List all methods",
            "  pod Mojo::UserAgent --class_options",
            "",
            "  # List all Module::Build actions.",
            "  pod Module::Build --query head1=ACTIONS/item-text"
        ],
    },

    # --version
    {
        name            => "version",
        input           => [qw( --version )],
        expected_output => [ "pod (App::Pod) <VERSION>", ],
    },

    # --tool_options
    {
        name            => "tool_options",
        input           => [qw( --tool_options )],
        expected_output => [
            qw {
              --all
              --class_options
              --co
              --dd
              --doc
              --dump
              --edit
              --flush_cache
              --help
              --no_colors
              --no_error
              --query
              --to
              --tool_options
              --version
              -a
              -d
              -e
              -f
              -h
              -q
              -v
            }
        ],
    },

    # --class_options
    {
        name            => "class_options - No class",
        input           => [qw( --class_options )],
        expected_output => [ "", "Class name not provided!", ],
    },
    {
        name            => "class_options - No class, no_error",
        input           => [qw( --class_options --no_error )],
        expected_output => [],
    },
    {
        name =>
          "class_options - Mojo2::UserAgent (flush to avoid last run cache)",
        input           => [qw( Mojo2::UserAgent --class_options --flush )],
        expected_output => [
            qw{
              BEGIN
              DEBUG
              DESTROY
              ISA
              VERSION
              __ANON__
              _cleanup
              _connect
              _connect_proxy
              _connection
              _dequeue
              _error
              _finish
              _process
              _read
              _redirect
              _remove
              _reuse
              _start
              _url
              _write
              build_tx
              build_websocket_tx
              ca
              cert
              connect_timeout
              cookie_jar
              delete
              delete_p
              get
              get_p
              has
              head
              head_p
              import
              inactivity_timeout
              insecure
              ioloop
              key
              max_connections
              max_redirects
              max_response_size
              monkey_patch
              options
              options_p
              patch
              patch_p
              post
              post_p
              prepare
              proxy
              put
              put_p
              request_timeout
              server
              socket_options
              start
              start
              start_p
              term_escape
              transactor
              weaken
              websocket
              websocket_p
            }
        ],
    },
    {
        name            => "class_options - Mojo2::UserAgent2",
        input           => [qw( Mojo2::UserAgent2 --class_options )],
        expected_output => [ "", "Class not found: Mojo2::UserAgent2" ],
    },

    # --class_options --tool_options
    {
        name            => "class_options, tool_options - No class",
        input           => [qw( --class_options --tool_options )],
        expected_output => [
            "--all",      "--class_options",
            "--co",       "--dd",
            "--doc",      "--dump",
            "--edit",     "--flush_cache",
            "--help",     "--no_colors",
            "--no_error", "--query",
            "--to",       "--tool_options",
            "--version",  "-a",
            "-d",         "-e",
            "-f",         "-h",
            "-q",         "-v",
            "",           "Class name not provided!"
        ],
    },
    {
        name            => "class_options, tool_options - No class, no_error",
        input           => [qw( --class_options --tool_options --no_error )],
        expected_output => [
            "--all",  "--class_options", "--co",       "--dd",
            "--doc",  "--dump",          "--edit",     "--flush_cache",
            "--help", "--no_colors",     "--no_error", "--query",
            "--to",   "--tool_options",  "--version",  "-a",
            "-d",     "-e",              "-f",         "-h",
            "-q",     "-v",
        ],
    },
    {
        name  => "class_options, tool_options - Mojo2::UserAgent",
        input => [qw( Mojo2::UserAgent --class_options --tool_options )],
        expected_output => [
            "--all",              "--class_options",
            "--co",               "--dd",
            "--doc",              "--dump",
            "--edit",             "--flush_cache",
            "--help",             "--no_colors",
            "--no_error",         "--query",
            "--to",               "--tool_options",
            "--version",          "-a",
            "-d",                 "-e",
            "-f",                 "-h",
            "-q",                 "-v",
            "BEGIN",              "DEBUG",
            "DESTROY",            "ISA",
            "VERSION",            "__ANON__",
            "_cleanup",           "_connect",
            "_connect_proxy",     "_connection",
            "_dequeue",           "_error",
            "_finish",            "_process",
            "_read",              "_redirect",
            "_remove",            "_reuse",
            "_start",             "_url",
            "_write",             "build_tx",
            "build_websocket_tx", "ca",
            "cert",               "connect_timeout",
            "cookie_jar",         "delete",
            "delete_p",           "get",
            "get_p",              "has",
            "head",               "head_p",
            "import",             "inactivity_timeout",
            "insecure",           "ioloop",
            "key",                "max_connections",
            "max_redirects",      "max_response_size",
            "monkey_patch",       "options",
            "options_p",          "patch",
            "patch_p",            "post",
            "post_p",             "prepare",
            "proxy",              "put",
            "put_p",              "request_timeout",
            "server",             "socket_options",
            "start",              "start",
            "start_p",            "term_escape",
            "transactor",         "weaken",
            "websocket",          "websocket_p"
        ],
    },
    {
        name  => "class_options, tool_options - Mojo2::UserAgent2",
        input => [qw( Mojo2::UserAgent2 --class_options --tool_options )],
        expected_output => [
            "--all",      "--class_options",
            "--co",       "--dd",
            "--doc",      "--dump",
            "--edit",     "--flush_cache",
            "--help",     "--no_colors",
            "--no_error", "--query",
            "--to",       "--tool_options",
            "--version",  "-a",
            "-d",         "-e",
            "-f",         "-h",
            "-q",         "-v",
            "",           'Class not found: Mojo2::UserAgent2'
        ],
    },
    {
        name  => "class_options, tool_options - Mojo2::UserAgent2, no_error",
        input =>
          [qw( Mojo2::UserAgent2 --class_options --tool_options --no_error )],
        expected_output => [
            "--all",  "--class_options", "--co",       "--dd",
            "--doc",  "--dump",          "--edit",     "--flush_cache",
            "--help", "--no_colors",     "--no_error", "--query",
            "--to",   "--tool_options",  "--version",  "-a",
            "-d",     "-e",              "-f",         "-h",
            "-q",     "-v",
        ],
    },

    # class
    {
        name            => "Module - ojo",
        input           => [qw( ojo )],
        expected_output => [
            '',
            'Package: ojo',
            'Path:    <PATH>',
            '',
            'ojo - Fun one-liners with Mojo',
            '',
            'Methods (16):',
            ' a - Create a route with "any" in Mojolicious::Lite ...',
            ' b - Turn string into a Mojo::ByteStream object.',
            ' c - Turn list into a Mojo::Collection object.',
            ' d - Perform DELETE request with "delete" in Mojo:: ...',
            ' f - Turn string into a Mojo::File object.',
            ' g - Perform GET request with "get" in Mojo::UserAg ...',
            ' h - Perform HEAD request with "head" in Mojo::User ...',
            ' j - Encode Perl data structure or decode JSON with ...',
            ' l - Turn a string into a Mojo::URL object.',
            ' n - Benchmark block and print the results to STDER ...',
            ' o - Perform OPTIONS request with "options" in Mojo ...',
            ' p - Perform POST request with "post" in Mojo::User ...',
            ' r - Dump a Perl data structure with "dumper" in Mo ...',
            ' t - Perform PATCH request with "patch" in Mojo::Us ...',
            ' u - Perform PUT request with "put" in Mojo::UserAg ...',
            ' x - Turn HTML/XML input into Mojo::DOM object.',
            '',
            'Use --all (or -a) to see all methods.',
        ],
    },
    {
        name            => "Module - ojo, no_color",
        input           => [qw( ojo --no_color )],
        expected_output => [
            '',
            'Package: ojo',
            'Path:    <PATH>',
            '',
            'ojo - Fun one-liners with Mojo',
            '',
            'Methods (16):',
            ' a - Create a route with "any" in Mojolicious::Lite ...',
            ' b - Turn string into a Mojo::ByteStream object.',
            ' c - Turn list into a Mojo::Collection object.',
            ' d - Perform DELETE request with "delete" in Mojo:: ...',
            ' f - Turn string into a Mojo::File object.',
            ' g - Perform GET request with "get" in Mojo::UserAg ...',
            ' h - Perform HEAD request with "head" in Mojo::User ...',
            ' j - Encode Perl data structure or decode JSON with ...',
            ' l - Turn a string into a Mojo::URL object.',
            ' n - Benchmark block and print the results to STDER ...',
            ' o - Perform OPTIONS request with "options" in Mojo ...',
            ' p - Perform POST request with "post" in Mojo::User ...',
            ' r - Dump a Perl data structure with "dumper" in Mo ...',
            ' t - Perform PATCH request with "patch" in Mojo::Us ...',
            ' u - Perform PUT request with "put" in Mojo::UserAg ...',
            ' x - Turn HTML/XML input into Mojo::DOM object.',
            '',
            'Use --all (or -a) to see all methods.',
        ],
    },
    {
        name            => "Module - Mojo2::UserAgent",
        input           => [qw( Mojo2::UserAgent )],
        expected_output => [
            '',
            'Package: Mojo2::UserAgent',
            'Path:    <PATH>',
            '',
            'Mojo::UserAgent - Non-blocking I/O HTTP and WebSock ...',
            '',
            'Inheritance (3):',
            ' Mojo2::UserAgent',
            ' Mojo::EventEmitter',
            ' Mojo::Base',
            '',
            'Events (2):',
            ' prepare - Emitted whenever a new transaction is be ...',
            ' start   - Emitted whenever a new transaction is ab ...',
            '',
            'Methods (36):',
            ' build_tx           - Generate Mojo::Transaction::H ...',
            ' build_websocket_tx - Generate Mojo::Transaction::H ...',
            ' ca                 - Path to TLS certificate autho ...',
            ' cert               - Path to TLS certificate file, ...',
            ' connect_timeout    - Maximum amount of time in sec ...',
            ' cookie_jar         - Cookie jar to use for request ...',
            ' delete             - Perform blocking DELETE reque ...',
            ' delete_p           - Same as "delete", but perform ...',
            ' get                - Perform blocking GET request  ...',
            ' get_p              - Same as "get", but performs a ...',
            ' head               - Perform blocking HEAD request ...',
            ' head_p             - Same as "head", but performs  ...',
            ' inactivity_timeout - Maximum amount of time in sec ...',
            ' insecure           - Do not require a valid TLS ce ...',
            ' ioloop             - Event loop object to use for  ...',
            ' key                - Path to TLS key file, default ...',
            ' max_connections    - Maximum number of keep-alive  ...',
            ' max_redirects      - Maximum number of redirects t ...',
            ' max_response_size  - Maximum response size in byte ...',
            ' options            - Perform blocking OPTIONS requ ...',
            ' options_p          - Same as "options", but perfor ...',
            ' patch              - Perform blocking PATCH reques ...',
            ' patch_p            - Same as "patch", but performs ...',
            ' post               - Perform blocking POST request ...',
            ' post_p             - Same as "post", but performs  ...',
            ' proxy              - Proxy manager, defaults to a  ...',
            ' put                - Perform blocking PUT request  ...',
            ' put_p              - Same as "put", but performs a ...',
            ' request_timeout    - Maximum amount of time in sec ...',
            ' server             - Application server relative U ...',
            ' socket_options     - Additional options for IO::So ...',
            ' start              - Emitted whenever a new transa ...',
            ' start_p            - Same as "start", but performs ...',
            ' transactor         - Transaction builder, defaults ...',
            ' websocket          - Open a non-blocking WebSocket ...',
            ' websocket_p        - Same as "websocket", but retu ...',
            '',
            'Use --all (or -a) to see all methods.',
        ],
    },

    # Class method.
    {
        name            => "Module - ojo x",
        input           => [qw( ojo x )],
        expected_output => [
            "",
            "Package: ojo",
            "Path:    <PATH>",
            "",
            "ojo - Fun one-liners with Mojo",
            "",
            "x:",
            "",
            "  my \$dom = x('<div>Hello!</div>');",
            "",
            "  Turn HTML/XML input into Mojo::DOM object.",
            "",
"  \$ perl -Mojo -E 'say x(f(\"test.html\")->slurp)->at(\"title\")->text'",
            "",
            "  [UnicodeTest: I ♥ Mojolicious!]",
        ]
    },

    # --query bad
    {
        name            => "query with no class",
        input           => [qw( --query head1[0]/Para )],
        expected_output => [ "", "Class name not provided!" ],
    },
    {
        name            => "query with no class",
        input           => [qw( --query head1[0]/Para )],
        expected_output => [ "", "Class name not provided!" ],
    },
    {
        name            => "query with bad class",
        input           => [qw( ojo2 --query head1[0]/Para )],
        expected_output => [ "", "Class not found: ojo2" ],
    },

    # --query good
    {
        name            => "query",
        input           => [qw( Mojo2::UserAgent --query head1[0]/Para )],
        expected_output =>
          ["Mojo::UserAgent - Non-blocking I/O HTTP and WebSocket user agent"],
    },
    {
        name            => "query TOC",
        input           => [qw( Mojo2::UserAgent --query head1 )],
        expected_output => [
            "NAME",       "SYNOPSIS", "DESCRIPTION", "EVENTS",
            "ATTRIBUTES", "METHODS",  "DEBUGGING",   "SEE ALSO"
        ]
    },
    {
        name            => "query with class at end",
        input           => [qw( --query head1[0]/Para Mojo2::UserAgent )],
        expected_output =>
          ["Mojo::UserAgent - Non-blocking I/O HTTP and WebSocket user agent"],
    },
    {
        name            => "query with class at end and method",
        input           => [qw( --query head1[0]/Para Mojo2::UserAgent get )],
        expected_output =>
          ["Mojo::UserAgent - Non-blocking I/O HTTP and WebSocket user agent"],
    },
    {
        name  => "query_dump",
        input => [qw( Mojo2::UserAgent --query head1[0]/Para --dump )],
        expected_output => [
            "_process_non_main()",
            "Processing: query",
            "DEBUG_FIND_DUMP: [",
            "  {",
            "    \"keep\" => 1,",
            "    \"prev\" => [],",
            "    \"tag\" => \"Para\",",
"    \"text\" => \"Mojo::UserAgent - Non-blocking I/O HTTP and WebSocket user agent\"",
            "  }",
            "]",
            "",
            "Mojo::UserAgent - Non-blocking I/O HTTP and WebSocket user agent",
            "self={",
            "  \"_args\" => [],",
            "  \"_cache_path\" => \"PATH\",",
            "  \"_class\" => \"Mojo2::UserAgent\",",
            "  \"_core_flags\" => [],",
            "  \"_method\" => undef,",
            "  \"_non_main_flags\" => [",
            "    {",
            "      \"description\" => \"Run a pod query.\",",
            "      \"handler\" => \"query_class\",",
            "      \"name\" => \"query\",",
            "      \"spec\" => \"query|q=s\"",
            "    }",
            "  ],",
            "  \"_opts\" => {",
            "    \"dump\" => 1,",
            "    \"query\" => \"head1[0]/Para\"",
            "  }",
            "}"
        ],
    },

    # --query good - using a file.
    {
        name            => "query file",
        input           => [ $sample_pod, qw( --query head1[0]/Para ) ],
        expected_output =>
          ["Mojo::UserAgent - Non-blocking I/O HTTP and WebSocket user agent"],
    },
    {
        name            => "query TOC file",
        input           => [ $sample_pod, qw( --query head1 ) ],
        expected_output => [
            "NAME",       "SYNOPSIS", "DESCRIPTION", "EVENTS",
            "ATTRIBUTES", "METHODS",  "DEBUGGING",   "SEE ALSO"
        ]
    },
    {
        name            => "query with file at end",
        input           => [ qw( --query head1[0]/Para ), $sample_pod ],
        expected_output =>
          ["Mojo::UserAgent - Non-blocking I/O HTTP and WebSocket user agent"],
    },
    {
        name  => "query with file at end and method",
        input => [ qw( --query head1[0]/Para ), $sample_pod, qw( get ) ],
        expected_output =>
          ["Mojo::UserAgent - Non-blocking I/O HTTP and WebSocket user agent"],
    },
    {
        name            => "query_dump file",
        input           => [ $sample_pod, qw( --query head1[0]/Para --dump ) ],
        expected_output => [
            "_process_non_main()",
            "Processing: query",
            "DEBUG_FIND_DUMP: [",
            "  {",
            "    \"keep\" => 1,",
            "    \"prev\" => [],",
            "    \"tag\" => \"Para\",",
"    \"text\" => \"Mojo::UserAgent - Non-blocking I/O HTTP and WebSocket user agent\"",
            "  }",
            "]",
            "",
            "Mojo::UserAgent - Non-blocking I/O HTTP and WebSocket user agent",
            "self={",
            "  \"_args\" => [],",
            "  \"_cache_path\" => \"PATH\",",
            "  \"_class\" => \"$windows_safe_path\",",
            "  \"_core_flags\" => [],",
            "  \"_method\" => undef,",
            "  \"_non_main_flags\" => [",
            "    {",
            "      \"description\" => \"Run a pod query.\",",
            "      \"handler\" => \"query_class\",",
            "      \"name\" => \"query\",",
            "      \"spec\" => \"query|q=s\"",
            "    }",
            "  ],",
            "  \"_opts\" => {",
            "    \"dump\" => 1,",
            "    \"query\" => \"head1[0]/Para\"",
            "  }",
            "}"
        ],
    },

    # Specific modules.
    {
        name            => "Module - Mojo:2:File",
        input           => [qw( Mojo2::File )],
        expected_output => [
            q(),
            q(Package: Mojo2::File),
            q(Path:    <PATH>),
            q(),
            q(Mojo::File - File system paths),
            q(),
            q(Methods (32):),
            q( basename    - Return the last level of the path wi ...),
            q( child       - Return a new Mojo::File object relat ...),
            q( chmod       - Change file permissions.),
            q( copy_to     - Copy file with File::Copy and return ...),
            q( curfile     - Construct a new scalar-based Mojo::F ...),
            q( dirname     - Return all but the last level of the ...),
            q( extname     - Return file extension of the path.),
            q( is_abs      - Check if the path is absolute.),
            q( list        - List all files in the directory and  ...),
            q( list_tree   - List all files recursively in the di ...),
            q( lstat       - Return a File::stat object for the s ...),
            q( make_path   - Create the directories if they don't ...),
            q( move_to     - Move file with File::Copy and return ...),
            q( new         - Construct a new Mojo::File object, d ...),
            q( open        - Open file with IO::File.),
            q( path        - Construct a new scalar-based Mojo::F ...),
            q( realpath    - Resolve the path with Cwd and return ...),
            q( remove      - Delete file.),
            q( remove_tree - Delete this directory and any files  ...),
            q( sibling     - Return a new Mojo::File object relat ...),
            q( slurp       - Read all data at once from the file.),
            q( spurt       - Write all data at once to the file.),
            q( stat        - Return a File::stat object for the path.),
            q( tap         - Alias for "tap" in Mojo::Base.),
            q( tempdir     - Construct a new scalar-based Mojo::F ...),
            q( tempfile    - Construct a new scalar-based Mojo::F ...),
            q( to_abs      - Return absolute path as a Mojo::File ...),
            q( to_array    - Split the path on directory separators.),
            q( to_rel      - Return a relative path from the orig ...),
            q( to_string   - Stringify the path.),
            q( touch       - Create file if it does not exist or  ...),
            q( with_roles  - Alias for "with_roles" in Mojo::Base.),
            q(),
            q(Use --all (or -a) to see all methods.),
        ],
    },
    {
        name            => "Module - Mojo2::File --all",
        input           => [qw( Mojo2::File --all )],
        expected_output => [
            q(),
            q(Package: Mojo2::File),
            q(Path:    <PATH>),
            q(),
            q(Mojo::File - File system paths),
            q(),
            q(Methods (55):),
            q{ (""},
            q{ ((},
            q{ ()},
            q{ (@{}},
            q{ (bool},
            q( BEGIN),
            q( EXPORT),
            q( EXPORT_OK),
            q( ISA),
            q( VERSION),
            q( __ANON__),
            q( abs2rel),
            q( basename              - Return the last level of t ...),
            q( canonpath),
            q( catfile),
            q( child                 - Return a new Mojo::File ob ...),
            q( chmod                 - Change file permissions.),
            q( copy),
            q( copy_to               - Copy file with File::Copy  ...),
            q( croak),
            q( curfile               - Construct a new scalar-bas ...),
            q( dirname               - Return all but the last le ...),
            q( extname               - Return file extension of t ...),
            q( file_name_is_absolute),
            q( find),
            q( getcwd),
            q( import),
            q( is_abs                - Check if the path is absolute.),
            q( list                  - List all files in the dire ...),
            q( list_tree             - List all files recursively ...),
            q( lstat                 - Return a File::stat object ...),
            q( make_path             - Create the directories if  ...),
            q( move),
            q( move_to               - Move file with File::Copy  ...),
            q( new                   - Construct a new Mojo::File ...),
            q( open                  - Open file with IO::File.),
            q( path                  - Construct a new scalar-bas ...),
            q( realpath              - Resolve the path with Cwd  ...),
            q( rel2abs),
            q( remove                - Delete file.),
            q( remove_tree           - Delete this directory and  ...),
            q( sibling               - Return a new Mojo::File ob ...),
            q( slurp                 - Read all data at once from ...),
            q( splitdir),
            q( spurt                 - Write all data at once to  ...),
            q( stat                  - Return a File::stat object ...),
            q( tap                   - Alias for "tap" in Mojo::Base.),
            q( tempdir               - Construct a new scalar-bas ...),
            q( tempfile              - Construct a new scalar-bas ...),
            q( to_abs                - Return absolute path as a  ...),
            q( to_array              - Split the path on director ...),
            q( to_rel                - Return a relative path fro ...),
            q( to_string             - Stringify the path.),
            q( touch                 - Create file if it does not ...),
            q( with_roles            - Alias for "with_roles" in  ...),
        ],
    },
);

my $is_path       = qr/ ^ Path: \s* \K (.*) $ /x;
my $is_version    = qr/ \b \d+\.\d+  $ /x;
my $is_cache_path = qr/ "_cache_path" \s+ => \K \s+ ".*" /x;

for my $case ( @cases ) {
    local @ARGV = ( $case->{input}->@* );
    my $input = "@ARGV";
    my $out   = "";

    # Capture output.
    {
        local *STDOUT;
        local *STDERR;
        open STDOUT, ">",  \$out or die $!;
        open STDERR, ">>", \$out or die $!;
        eval { App::Pod->run };
        if ( $@ ) {
            $out = $@;
            chomp $out;
        }
    }

    my @lines = split /\n/, colorstrip( $out // '' );

    # Normalize PATHs
    for ( @lines ) {
        s/$is_path/<PATH>/;
        s/$is_cache_path/ "PATH"/g;
    }

    # Normalize Version
    if ( "$input" eq "--version" ) {
        $lines[0] =~ s/$is_version/<VERSION>/;
    }

    say STDERR _dumper \@lines
      and last
      unless is_deeply( \@lines, $case->{expected_output}, $case->{name} );
}

