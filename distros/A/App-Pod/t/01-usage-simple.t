#!perl
use v5.24;    # Postfix defef.
use strict;
use warnings;
use Test::More;
use Term::ANSIColor       qw( colorstrip );
use File::Spec::Functions qw( catfile );

#TODO: Remove this debug code !!!
use feature    qw(say);
use Mojo::Util qw(dumper);

BEGIN {
    use_ok( 'App::Pod' ) || print "Bail out!\n";
}

diag( "Testing App::Pod $App::Pod::VERSION, Perl $], $^X" );

{
    no warnings qw( redefine once );

    # Make sure this is already defined a a number.
    like( Pod::Query::get_term_width(),
        qr/^\d+$/, "get_term_width returns a number" );

    *Pod::Query::get_term_width = sub { 56 };    # Match android.
}

my $sample_pod = catfile( qw( t ex_Mojo_UserAgent.pm ) );

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
          "class_options - Mojo::UserAgent (flush to avoid last run cache)",
        input           => [qw( Mojo::UserAgent --class_options --flush )],
        expected_output => [
            qw{
              BEGIN
              DEBUG
              DESTROY
              ISA
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
        name            => "class_options - Mojo::UserAgent2",
        input           => [qw( Mojo::UserAgent2 --class_options )],
        expected_output => [ "", "Class not found: Mojo::UserAgent2" ],
    },

    # --class_options --tool_options
    {
        name            => "class_options, tool_options - No class",
        input           => [qw( --class_options --tool_options )],
        expected_output => [
            "--all",          "--class_options",
            "--co",           "--dd",
            "--doc",          "--dump",
            "--edit",         "--flush_cache",
            "--help",         "--no_error",
            "--query",        "--to",
            "--tool_options", "--version",
            "-a",             "-d",
            "-e",             "-f",
            "-h",             "-q",
            "-v",             "",
            "Class name not provided!"
        ],
    },
    {
        name            => "class_options, tool_options - No class, no_error",
        input           => [qw( --class_options --tool_options --no_error )],
        expected_output => [
            "--all",          "--class_options",
            "--co",           "--dd",
            "--doc",          "--dump",
            "--edit",         "--flush_cache",
            "--help",         "--no_error",
            "--query",        "--to",
            "--tool_options", "--version",
            "-a",             "-d",
            "-e",             "-f",
            "-h",             "-q",
            "-v",
        ],
    },
    {
        name  => "class_options, tool_options - Mojo::UserAgent",
        input => [qw( Mojo::UserAgent --class_options --tool_options )],
        expected_output => [
            "--all",              "--class_options",
            "--co",               "--dd",
            "--doc",              "--dump",
            "--edit",             "--flush_cache",
            "--help",             "--no_error",
            "--query",            "--to",
            "--tool_options",     "--version",
            "-a",                 "-d",
            "-e",                 "-f",
            "-h",                 "-q",
            "-v",                 "BEGIN",
            "DEBUG",              "DESTROY",
            "ISA",                "__ANON__",
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
        name  => "class_options, tool_options - Mojo::UserAgent2",
        input => [qw( Mojo::UserAgent2 --class_options --tool_options )],
        expected_output => [
            "--all",          "--class_options",
            "--co",           "--dd",
            "--doc",          "--dump",
            "--edit",         "--flush_cache",
            "--help",         "--no_error",
            "--query",        "--to",
            "--tool_options", "--version",
            "-a",             "-d",
            "-e",             "-f",
            "-h",             "-q",
            "-v",             "",
            'Class not found: Mojo::UserAgent2'
        ],
    },
    {
        name  => "class_options, tool_options - Mojo::UserAgent2, no_error",
        input =>
          [qw( Mojo::UserAgent2 --class_options --tool_options --no_error )],
        expected_output => [
            "--all",          "--class_options",
            "--co",           "--dd",
            "--doc",          "--dump",
            "--edit",         "--flush_cache",
            "--help",         "--no_error",
            "--query",        "--to",
            "--tool_options", "--version",
            "-a",             "-d",
            "-e",             "-f",
            "-h",             "-q",
            "-v",
        ],
    },

    # class
    {
        name            => "Module - ojo",
        input           => [qw( ojo )],
        expected_output => [
            "",
            "Package: ojo",
            "Path:    <PATH>",
            "",
            "ojo - Fun one-liners with Mojo",
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
        input           => [qw( Mojo::UserAgent )],
        expected_output => [
            "",
            "Package: Mojo::UserAgent",
            "Path:    <PATH>",
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
        input           => [qw( Mojo::UserAgent --query head1[0]/Para )],
        expected_output =>
          ["Mojo::UserAgent - Non-blocking I/O HTTP and WebSocket user agent"],
    },
    {
        name            => "query TOC",
        input           => [qw( Mojo::UserAgent --query head1 )],
        expected_output => [
            "NAME",       "SYNOPSIS", "DESCRIPTION", "EVENTS",
            "ATTRIBUTES", "METHODS",  "DEBUGGING",   "SEE ALSO"
        ]
    },
    {
        name            => "query with class at end",
        input           => [qw( --query head1[0]/Para Mojo::UserAgent )],
        expected_output =>
          ["Mojo::UserAgent - Non-blocking I/O HTTP and WebSocket user agent"],
    },
    {
        name            => "query with class at end and method",
        input           => [qw( --query head1[0]/Para Mojo::UserAgent get )],
        expected_output =>
          ["Mojo::UserAgent - Non-blocking I/O HTTP and WebSocket user agent"],
    },
    {
        name            => "query_dump",
        input           => [qw( Mojo::UserAgent --query head1[0]/Para --dump )],
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
            "  \"args\" => [],",
            "  \"cache_path\" => \"PATH\",",
            "  \"class\" => \"Mojo::UserAgent\",",
            "  \"core_flags\" => [],",
            "  \"method\" => undef,",
            "  \"non_main_flags\" => [",
            "    {",
            "      \"description\" => \"Run a pod query.\",",
            "      \"handler\" => \"query_class\",",
            "      \"name\" => \"query\",",
            "      \"spec\" => \"query|q=s\"",
            "    }",
            "  ],",
            "  \"opts\" => {",
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
            "  \"args\" => [],",
            "  \"cache_path\" => \"PATH\",",
            "  \"class\" => \"$sample_pod\",",
            "  \"core_flags\" => [],",
            "  \"method\" => undef,",
            "  \"non_main_flags\" => [",
            "    {",
            "      \"description\" => \"Run a pod query.\",",
            "      \"handler\" => \"query_class\",",
            "      \"name\" => \"query\",",
            "      \"spec\" => \"query|q=s\"",
            "    }",
            "  ],",
            "  \"opts\" => {",
            "    \"dump\" => 1,",
            "    \"query\" => \"head1[0]/Para\"",
            "  }",
            "}"
        ],
    },

    # Specific modules.
    {
        name            => "Module - Mojo::File",
        input           => [qw( Mojo::File )],
        expected_output => [
            "",
            "Package: Mojo::File",
            "Path:    <PATH>",
            "",
            "Mojo::File - File system paths",
            "",
            "Methods (32):",
            " basename    - Return the last level of the path wit ...",
            " child       - Return a new Mojo::File object relati ...",
            " chmod       - Change file permissions.",
            " copy_to     - Copy file with File::Copy and return  ...",
            " curfile     - Construct a new scalar-based Mojo::Fi ...",
            " dirname     - Return all but the last level of the  ...",
            " extname     - Return file extension of the path.",
            " is_abs      - Check if the path is absolute.",
            " list        - List all files in the directory and r ...",
            " list_tree   - List all files recursively in the dir ...",
            " lstat       - Return a File::stat object for the sy ...",
            " make_path   - Create the directories if they don't  ...",
            " move_to     - Move file with File::Copy and return  ...",
            " new         - Construct a new Mojo::File object, de ...",
            " open        - Open file with IO::File.",
            " path        - Construct a new scalar-based Mojo::Fi ...",
            " realpath    - Resolve the path with Cwd and return  ...",
            " remove      - Delete file.",
            " remove_tree - Delete this directory and any files a ...",
            " sibling     - Return a new Mojo::File object relati ...",
            " slurp       - Read all data at once from the file.",
            " spurt       - Write all data at once to the file.",
            " stat        - Return a File::stat object for the path.",
            " tap         - Alias for \"tap\" in Mojo::Base.",
            " tempdir     - Construct a new scalar-based Mojo::Fi ...",
            " tempfile    - Construct a new scalar-based Mojo::Fi ...",
            " to_abs      - Return absolute path as a Mojo::File  ...",
            " to_array    - Split the path on directory separators.",
            " to_rel      - Return a relative path from the origi ...",
            " to_string   - Stringify the path.",
            " touch       - Create file if it does not exist or c ...",
            " with_roles  - Alias for \"with_roles\" in Mojo::Base.",
            "",
            "Use --all (or -a) to see all methods.",
        ],
    },
    {
        name            => "Module - Mojo::File --all",
        input           => [qw( Mojo::File --all )],
        expected_output => [
            "",
            "Package: Mojo::File",
            "Path:    <PATH>",
            "",
            "Mojo::File - File system paths",
            "",
            "Methods (57):",
            " (\"\"                  ",
            " ((                   ",
            " ()                   ",
            " (\@{}                 ",
            " (bool                ",
            " AUTOLOAD             ",
            " BEGIN                ",
            " EXPORT               ",
            " EXPORT_OK            ",
            " ISA                  ",
            " VERSION              ",
            " __ANON__             ",
            " abs2rel              ",
            " basename              - Return the last level of th ...",
            " can                  ",
            " canonpath            ",
            " catfile              ",
            " child                 - Return a new Mojo::File obj ...",
            " chmod                 - Change file permissions.",
            " copy                 ",
            " copy_to               - Copy file with File::Copy a ...",
            " croak                ",
            " curfile               - Construct a new scalar-base ...",
            " dirname               - Return all but the last lev ...",
            " extname               - Return file extension of th ...",
            " file_name_is_absolute",
            " find                 ",
            " getcwd               ",
            " import               ",
            " is_abs                - Check if the path is absolute.",
            " list                  - List all files in the direc ...",
            " list_tree             - List all files recursively  ...",
            " lstat                 - Return a File::stat object  ...",
            " make_path             - Create the directories if t ...",
            " move                 ",
            " move_to               - Move file with File::Copy a ...",
            " new                   - Construct a new Mojo::File  ...",
            " open                  - Open file with IO::File.",
            " path                  - Construct a new scalar-base ...",
            " realpath              - Resolve the path with Cwd a ...",
            " rel2abs              ",
            " remove                - Delete file.",
            " remove_tree           - Delete this directory and a ...",
            " sibling               - Return a new Mojo::File obj ...",
            " slurp                 - Read all data at once from  ...",
            " splitdir             ",
            " spurt                 - Write all data at once to t ...",
            " stat                  - Return a File::stat object  ...",
            " tap                   - Alias for \"tap\" in Mojo::Base.",
            " tempdir               - Construct a new scalar-base ...",
            " tempfile              - Construct a new scalar-base ...",
            " to_abs                - Return absolute path as a M ...",
            " to_array              - Split the path on directory ...",
            " to_rel                - Return a relative path from ...",
            " to_string             - Stringify the path.",
            " touch                 - Create file if it does not  ...",
            " with_roles            - Alias for \"with_roles\" in M ...",
        ],
    },
);

my $is_path       = qr/ ^ Path: \s* \K (.*) $ /x;
my $is_version    = qr/ \b \d+\.\d+  $ /x;
my $is_cache_path = qr/ "cache_path" \s+ => \K \s+ ".*" /x;

for my $case ( @cases ) {
    my $input = join( "", $case->{input}->@* ) // "";
    local @ARGV = ( $case->{input}->@* );
    my $out = "";

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

    my $need = $case->{expected_output};
    my $name = $case->{name};

    # Version check
    if ( "$input" eq "--version" ) {
        $lines[0] =~ s/$is_version/<VERSION>/;
    }

    say dumper \@lines
      unless is_deeply \@lines, $need, "$name";
}

done_testing( 32 );

