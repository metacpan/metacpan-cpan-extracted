#!perl

use Test::More tests => 2;

use lib 't';

use File::Temp;
use File::Spec::Functions qw[ catfile ];

#############################################################


my $exe = catfile( qw[ blib script appexec ] );
my $script = catfile( qw [ t appexec.pl ] );

{
    my $fh = File::Temp->new;

    system( $^X, '-Mblib', '-It', $exe, 'App1', $^X, $script, $fh->filename ) == 0
      or die( "error running appexec\n" );

    chomp(my $res = <$fh>);
    is( $res, '1', 'direct' );
}

{
    my $fh = File::Temp->new;

    system( $^X, '-Mblib', '-It', $exe, 'App3', $^X, $script, $fh->filename ) == 0
      or die( "error running appexec\n" );

    chomp(my $res = <$fh>);
    is( $res, '1', 'alias' );
}
