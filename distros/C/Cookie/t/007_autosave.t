#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
    use File::Temp qw( tempdir );
    use File::Spec;
    use Scalar::Util qw( refaddr weaken );
    use Cookie::Jar;
}

use strict;
use warnings;

{
    package Cookie::Jar::AutosaveProbe;
    use parent -norequire, 'Cookie::Jar';

    sub file { return( shift->{file} ); }
    sub autosave { return( shift->{autosave} ); }
    sub encrypt { return( shift->{encrypt} ); }
    sub type { return( shift->{type} ); }
    sub algo { return( shift->{algo} ); }
    sub secret { return( shift->{secret} ); }
    sub _warnings_is_enabled { return(0); }
    sub error { return( 'Simulated save failure' ); }
}

sub make_probe
{
    my %opts = @_;
    return( bless( {
        file => 'test-cookie-file',
        autosave => 1,
        encrypt => 0,
        type => 'json',
        _autosave_ready => 1,
        _autosaved => 0,
        %opts,
    }, 'Cookie::Jar::AutosaveProbe' ) );
}

subtest 'Successful save is performed once' => sub
{
    my $calls = 0;
    no warnings 'redefine';
    local *Cookie::Jar::save = sub { $calls++; return(1); };
    my $jar = make_probe();
    ok( $jar->_autosave, 'Autosave succeeds' );
    is( $jar->{_autosaved}, 1, 'Successful save is recorded' );
    ok( !$jar->_autosave, 'Repeated autosave is skipped' );
    is( $calls, 1, 'The save handler is called only once' );
};

subtest 'Failed save can be retried' => sub
{
    my $calls = 0;
    no warnings 'redefine';
    local *Cookie::Jar::save = sub { $calls++; return( $calls > 1 ? 1 : undef ); };
    my $jar = make_probe();
    ok( !$jar->_autosave, 'First autosave fails' );
    ok( !$jar->{_autosaved}, 'Failure is not marked as saved' );
    ok( $jar->_autosave, 'Second autosave succeeds' );
    is( $jar->{_autosaved}, 1, 'Success is recorded after retry' );
    is( $calls, 2, 'Save handler is called twice' );
};

subtest 'No save for a jar not ready for autosave' => sub
{
    my $calls = 0;
    no warnings 'redefine';
    local *Cookie::Jar::save = sub { $calls++; return(1); };
    my $jar = make_probe( _autosave_ready => 0 );
    ok( !$jar->_autosave, 'Autosave is skipped' );
    is( $calls, 0, 'The file is not overwritten' );
    ok( !$jar->{_autosaved}, 'The jar remains unsaved' );
};

subtest 'Autosave disabled or missing filename' => sub
{
    my $calls = 0;
    no warnings 'redefine';
    local *Cookie::Jar::save = sub { $calls++; return(1); };
    my $disabled = make_probe( autosave => 0 );
    my $no_file = make_probe( file => '' );
    $disabled->_autosave;
    $no_file->_autosave;
    is( $calls, 0, 'Neither jar invokes the save handler' );
    ok( !$disabled->{_autosaved} && !$no_file->{_autosaved}, 'Neither jar is marked as saved' );
};

subtest 'Encrypted autosave passes existing options' => sub
{
    my( $calls, @args ) = ( 0 );
    no warnings 'redefine';
    local *Cookie::Jar::save = sub { $calls++; @args = @_; return(1); };
    my $jar = make_probe( encrypt => 1, algo => 'AES', secret => 'secret' );
    ok( $jar->_autosave, 'Encrypted autosave succeeds' );
    is( $calls, 1, 'Save handler is invoked' );
    is_deeply( [ @args[2..$#args] ], [ algo => 'AES', key => 'secret' ], 'Encryption options are preserved' );
};

subtest 'Normal destruction cleans up the weak registry' => sub
{
    my $calls = 0;
    no warnings 'redefine';
    local *Cookie::Jar::save = sub { $calls++; return(1); };
    my $jar = make_probe();
    my $addr = refaddr( $jar );
    $Cookie::Jar::LIVE_JARS->{ $addr } = $jar;
    weaken( $Cookie::Jar::LIVE_JARS->{ $addr } );
    undef( $jar );
    is( $calls, 1, 'Normal destruction performs autosave' );
    ok( !exists( $Cookie::Jar::LIVE_JARS->{ $addr } ), 'Registry entry was deleted' );
};

subtest 'END saves live jars in an isolated Perl interpreter' => sub
{
    my $directory = tempdir( CLEANUP => 1 );
    my $child = File::Spec->catfile( 't', 'autosave_end_child.pl' );
    for my $case (
        [ success => "saved\n" ],
        [ disabled => '' ],
        [ failure => '' ],
        [ not_ready => '' ],
    )
    {
        my( $mode, $expected ) = @$case;
        my $output = File::Spec->catfile( $directory, "$mode.txt" );
        my $status = system( $^X, '-Ilib', $child, $mode, $output );
        is( $status, 0, "$mode child exits successfully" );
        my $actual = '';
        if( -e( $output ) )
        {
            open( my $fh, '<', $output ) or die( "Cannot read $output: $!" );
            local $/;
            $actual = <$fh>;
            close( $fh );
        }
        is( $actual, $expected, "$mode invokes exactly the expected save operations" );
    }
};

done_testing();
