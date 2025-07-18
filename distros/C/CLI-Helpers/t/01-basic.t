use strict;
use warnings;

package Foo {
    sub TO_JSON {
        my $self = shift;
        return { %{ $self } };
    }
}

use Capture::Tiny qw(capture);
use CLI::Helpers qw( :output delay_argv );
use Test::More qw( no_plan );


cli_helpers_initialize([]);
my ($stdout,$stderr) = capture { run(); };
ok($stdout eq "normal\n", "normal output");
ok($stderr eq "normal stderr\n", "normal stderr");

cli_helpers_initialize(['--verbose']);
($stdout,$stderr) = capture { run(); };
ok($stdout eq "normal\nverbose\n", "verbose output") or diag "GOT: $stdout";

cli_helpers_initialize(['-v','-v']);
($stdout,$stderr) = capture { run(); };
ok($stdout eq "normal\nverbose\nverbose2\n", "verbose output");

cli_helpers_initialize(['--debug']);
($stdout,$stderr) = capture { run(); };
ok($stdout eq "normal\nverbose\nverbose2\ndebug\n", "debug output");

cli_helpers_initialize([]);
($stdout,$stderr) = capture { run(); };
ok($stdout eq "normal\n", "normal after reinit output");

@ARGV = ( '--verbose' );
cli_helpers_initialize();
is( CLI::Helpers::def('VERBOSE'), 1, "ARGV first pass" );
cli_helpers_initialize();
is( CLI::Helpers::def('VERBOSE'), 1, "ARGV processing is idempotent" );

# JSON
check_output(
    name => "JSON Debug Output",
    init => ['--debug'],
    test => sub { debug_var({json => 1}, {foo => 1}) },
    stdout => sub { shift =~ s/\n//gr eq qq|{"foo":1}| },
);

# Single References
check_output(
    name   => "JSON Single Reference",
    test   => sub { output({foo => 1}) },
    stdout => sub { shift =~ s/\n//gr eq q|{"foo":1}| },
);

# Double References
check_output(
    name   => "JSON Multi Reference",
    test   => sub { output({foo=>1},{bar=>1}) },
    stdout => sub {  shift =~ s/\n//gr eq q|{"foo":1}{"bar":1}| }

);

# Options and a reference
check_output(
    name   => "Options and a Reference",
    test   => sub { output({clear => 1}, {bar => 1}) },
    stdout => sub { shift =~ s/\n//gr eq q|{"bar":1}| },
);

# Just Options?
check_output(
    name   => "Single Reference, all valid options",
    test   => sub { output( {clear => 1} ) },
    stdout => sub { shift =~ s/\n//gr eq q|{"clear":1}| },
);

# Check JSON encoder
check_output(
    name => "JSON Encoder",
    test => sub { my $x = bless {x => 1}, "Foo"; output($x) },
    stdout => sub { shift =~ s/\n//gr eq '{"x":1}'},
);

# Multiple fields, sorting
check_output(
    name   => "Multiple Fields, JSON Key Sorting",
    test   => sub { output( {z => 1, a => 2} ) },
    stdout => sub { shift =~ s/\n//gr eq q|{"a":2,"z":1}| },
);

done_testing;

sub check_output {
    my %opts = (
        init   => [],
        stdout => sub { length(shift)  > 0 },
        stderr => sub { length(shift) == 0 },
        @_,
    );

    cli_helpers_initialize($opts{init});
    my ($stdout,$stderr) = capture { $opts{test}->() };
    ok($opts{stdout}->($stdout),$opts{name}) or diag "GOT [stdout]: $stdout";
    ok($opts{stderr}->($stderr), "STDERR: $opts{name}") or diag "GOT [stderr]: $stderr";
}

sub run {
    output('normal');
    verbose('verbose');
    verbose({level=>2}, "verbose2");
    debug('debug');
    output({stderr=>1}, 'normal stderr');
}
