#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Cookie::Jar;
    use Scalar::Util qw( refaddr weaken );
};

use strict;
use warnings;

{
    # Hide from CPAN
    package
        Cookie::Jar::AutosaveEndProbe;
    use parent -norequire, 'Cookie::Jar';

    sub file { return( shift->{file} ); }
    sub autosave { return( shift->{autosave} ); }
    sub encrypt { return(0); }
    sub type { return( 'json' ); }
    sub _warnings_is_enabled { return(0); }
    sub error { return( 'Simulated failure' ); }
}

our $JAR;
my( $mode, $output ) = @ARGV;
die( "Unknown test mode\n" ) unless( $mode =~ /\A(?:success|disabled|failure|not_ready)\z/ );

{
    no warnings 'redefine';
    *Cookie::Jar::save = sub
    {
        return if( $mode eq 'failure' );
        open( my $fh, '>>', $output ) or die( "Cannot write $output: $!" );
        print( $fh "saved\n" );
        close( $fh ) or die( "Cannot close $output: $!" );
        return(1);
    };
}

$JAR = bless( {
    file => $output,
    autosave => ( $mode ne 'disabled' ),
    _autosave_ready => ( $mode ne 'not_ready' ),
    _autosaved => 0,
}, 'Cookie::Jar::AutosaveEndProbe' );
my $addr = refaddr( $JAR );
$Cookie::Jar::LIVE_JARS->{ $addr } = $JAR;
weaken( $Cookie::Jar::LIVE_JARS->{ $addr } );

exit(0);

__END__
