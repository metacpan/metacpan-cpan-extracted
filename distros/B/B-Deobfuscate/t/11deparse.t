use strict;
use warnings;
use Test::More;

BEGIN {
    my @missing;
    for (
        [qw[ File::Basename dirname ]],
        [qw[ File::Spec::Functions catfile catfile devnull ]],
        [qw[ IPC::Run run ]],
        [qw[ YAML Dump ]],
        [qw[ File::Temp tempfile ]]
        )
    {
        my ( $mod, @import ) = @$_;
        eval "use $mod qw( @import )";
        push @missing, $mod if $@;
    }

    if (@missing) {
        plan( skip_all => "Missing modules @missing" );
        exit 0;
    }
    else {
        plan( tests => 5 * 5 + 3 * 5 );
    }
}

my $test_dir = dirname($0);

my @scripts = map catfile( $test_dir, "${_}_t" ),
    qw(scalar array hash code glob);

my $syntax_checker = catfile( $test_dir, 'syntax.pl' );

my ( $tmp_fh, $tmp_nm ) = tempfile( UNLINK => 1 );
for my $test (
    {   cmd => [ [ $^X, $syntax_checker, 'HERE' ] ],
        nm => 'basic syntax'
    },
    {   cmd => [ [ $^X, '-Mblib', '-MO=Deobfuscate', 'HERE' ] ],
        nm => 'basic deobfuscation'
    },
    {   cmd => [ [ $^X, '-Mblib', '-MO=Deobfuscate,-y', 'HERE' ] ],
        nm => 'yaml output'
    },
    {   cmd => [
            [ $^X, '-Mblib', '-MO=Deobfuscate,-y', 'HERE' ],
            '|',
            [ $^X, '-000', '-MYAML', '-e', 'Load(scalar <STDIN>)' ]
        ],
        nm => 'yaml syntax'
    },
    {   cmd => [
            [ $^X, '-Mblib', '-MO=Deobfuscate', 'HERE' ],
            '|', [ $^X, $syntax_checker ]
        ],
        nm => 'deobfuscation syntax check'
    },
    )
{

    for my $script (@scripts) {

        seek $tmp_fh, 0, 0;
        truncate $tmp_fh, 0;

        my @command = map {
            ref()
                ? [ map { /^HERE\z/ ? $script : $_ } @$_ ]
                : $_
        } @{ $test->{cmd} };

        local ( $@, $? );

        my $ok = run( @command, '2>&1', '>', $tmp_nm );
        ok( $ok, $test->{nm} );
        if ( not $ok ) {
            local $/;
            diag( \@command, scalar <$tmp_fh> );
        }
    }
}

my $canonizer = catfile( $test_dir, 'canon.pl' );
for my $script (@scripts) {
    my @normal = (
        [ $^X, '-MO=Concise', $script ],
        '|', [ $^X, $canonizer ],
        '>', $tmp_nm
    );
    my @deob = (
        [ $^X, '-Mblib', '-MO=Deobfuscate', $script ],
        '|', [ $^X, '-MO=Concise' ],
        '|', [ $^X, $canonizer ],
        '>', $tmp_nm
    );

    seek $tmp_fh, 0, 0;
    truncate $tmp_fh, 0;
    ok( run(@normal), "Normal $script" );
    my $normal = do {
        local $/;
        <$tmp_fh>;
    };

    seek $tmp_fh, 0, 0;
    truncate $tmp_fh, 0;
    ok( run(@deob), "Deobfuscate $script" );
    my $deob = do {
        local $/;
        <$tmp_fh>;
    };

    is( "$normal", "$deob", "Comparing optrees: $script" );
}
