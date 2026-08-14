use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Cwd qw( abs_path getcwd );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );

# Regression test: the COMMANDS block of `karr --help` must line its
# descriptions up in one column.
#
# App::karr::_print_help used to render each row with
#
#     sprintf "  %-*s  %s\n", $max, colored($cmd->[0], 'cyan'), $cmd->[1]
#
# and %-*s pads to the length of the string it is handed -- which for a
# coloured name includes the ANSI escapes Term::ANSIColor wrapped around it.
# Those escapes are ~9 characters on their own, so every argument was already
# wider than $max and the field never padded at all: the descriptions came out
# ragged, one space after each command name.
#
# The catch for a test is that Term::ANSIColor's colored() returns the text
# UNCHANGED when NO_COLOR / ANSI_COLORS_DISABLED is set, so a help test that
# only ever runs with colour off sees perfectly aligned output and cannot fail.
# This test therefore renders the help twice -- once forced plain, once with
# colour forced on -- and pins:
#
#   * both renderings align their descriptions on a single column, and
#   * the coloured rendering, once the escapes are stripped, is byte-identical
#     to the plain one (colour must change nothing about the layout).
#
# RED before the visible-width padding fix (coloured rendering ragged), GREEN
# after.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

# --help needs no board and no repo; run it from a throwaway cwd anyway so
# nothing can reach the developer's real board.
my $TMP = tempdir( CLEANUP => 1 );

sub _help {
    my (%env) = @_;
    my $old = getcwd();
    chdir $TMP or die "chdir $TMP: $!";

    # %env values of undef mean "unset for this run".
    my %saved;
    for my $k ( keys %env ) {
        $saved{$k} = $ENV{$k};
        if ( defined $env{$k} ) { $ENV{$k} = $env{$k} }
        else                    { delete $ENV{$k} }
    }

    my $stderr = gensym;
    my $pid = open3( undef, my $stdout_fh, $stderr,
        $^X, "-I$ROOT/lib", $BIN, '--help' );
    my $stdout      = do { local $/; <$stdout_fh> };
    my $stderr_text = do { local $/; <$stderr> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;

    for my $k ( keys %saved ) {
        if ( defined $saved{$k} ) { $ENV{$k} = $saved{$k} }
        else                      { delete $ENV{$k} }
    }
    chdir $old or die "chdir $old: $!";

    return {
        exit   => $exit,
        stdout => defined $stdout      ? $stdout      : '',
        stderr => defined $stderr_text ? $stderr_text : '',
    };
}

sub _strip { my ($s) = @_; $s =~ s/\x1b\[[0-9;]*m//g; return $s }

# Pull the "  <command>  <description>" rows out of the COMMANDS section of an
# already-uncoloured help text. Returns a list of [ name, description-column ].
sub _command_rows {
    my ($plain) = @_;
    my @rows;
    my $in;
    for my $line ( split /\n/, $plain ) {
        if ( $line =~ /^COMMANDS:/ ) { $in = 1; next }
        next unless $in;
        last if $line =~ /^\S/ || $line eq '';
        if ( $line =~ /^(\s+)(\S+)(\s+)(\S.*)$/ ) {
            push @rows, [ $2, length($1) + length($2) + length($3) ];
        }
    }
    return @rows;
}

sub _assert_aligned {
    my ( $plain, $label ) = @_;
    my @rows = _command_rows($plain);

    cmp_ok( scalar @rows, '>=', 20,
        "$label: COMMANDS block parsed (found " . scalar(@rows) . " commands)" );

    my %cols;
    $cols{ $_->[1] }++ for @rows;
    is( scalar keys %cols, 1,
        "$label: every description starts on the same column" )
        or diag(
        "description columns seen: "
            . join( ', ', map { "$_ (x$cols{$_})" } sort { $a <=> $b } keys %cols )
            . "\nrows: "
            . join( ', ', map { "$_->[0]=>$_->[1]" } @rows ) );

    # And the column is the one the dynamic $max in _print_help implies:
    # two spaces of indent + longest command name + two spaces of gutter.
    my $longest = 0;
    for (@rows) { $longest = length $_->[0] if length $_->[0] > $longest }
    my ($col) = keys %cols;
    is( $col, 2 + $longest + 2,
        "$label: column derives from the longest command name (no magic width)" );

    return;
}

subtest 'help aligns with colour disabled' => sub {
    my $rv = _help( NO_COLOR => 1, ANSI_COLORS_DISABLED => 1 );
    is( $rv->{exit}, 0, 'karr --help exits 0' ) or diag $rv->{stderr};
    unlike( $rv->{stdout}, qr/\x1b\[/,
        'no ANSI escapes emitted under NO_COLOR' );
    _assert_aligned( $rv->{stdout}, 'plain' );
};

subtest 'help aligns with colour enabled (the case the old %-*s got wrong)' => sub {
    my $rv = _help( NO_COLOR => undef, ANSI_COLORS_DISABLED => undef );
    is( $rv->{exit}, 0, 'karr --help exits 0' ) or diag $rv->{stderr};

    # If this fails the rest of the subtest is vacuous -- the whole point is to
    # measure a rendering that actually carries escapes.
    like( $rv->{stdout}, qr/\x1b\[36m/,
        'command names really are coloured (test is not silently plain)' );

    _assert_aligned( _strip( $rv->{stdout} ), 'coloured' );
};

subtest 'colour changes nothing but the escapes' => sub {
    my $plain   = _help( NO_COLOR => 1, ANSI_COLORS_DISABLED => 1 )->{stdout};
    my $colored = _help( NO_COLOR => undef, ANSI_COLORS_DISABLED => undef )->{stdout};

    isnt( $plain, $colored, 'the two renderings do differ before stripping' );
    is( _strip($colored), $plain,
        'stripped coloured help is byte-identical to the plain help' );
};

done_testing;
