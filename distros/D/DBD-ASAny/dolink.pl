use strict;
my $dll = shift;
if( !defined( $dll ) ) {
    die( "Use: %s target [link_args]*\n" );
}
my $cmd = 'link ';
my $arg;
foreach $arg ( @ARGV ) {
    &add_arg( \$cmd, $arg );
}
&run( $cmd );

my $manifest = "$dll.manifest";
if( -e $manifest ) {
    $cmd = "mt.exe ";
    &add_arg( \$cmd, "-outputresource:$dll;2" );
    &add_arg( \$cmd, "-manifest" );
    &add_arg( \$cmd, $manifest );
    &run( $cmd );
}

sub add_arg
{
    my( $dest, $arg ) = @_;
    if( $arg =~ /\s/ ) {
	$$dest .= "\"$arg\" ";
    } else {
	$$dest .= "$arg ";
    }
}
sub run
{
    my( $cmd ) = @_;
    my $status;

    printf( "%s\n", $cmd );
    $status = system( $cmd ) >> 8;
    if( $status != 0 ) {
	printf( STDERR "Command failed with status %d.\n", $status );
	exit( $status );
    }
}

