#!perl
#!perl -T # TODO - figure out why File::Find won't pass taint checks

use strict;
use warnings;
use Test::More tests => 1;

use FindBin qw($Bin);
use File::Spec;
use Cwd;

( my $test_dir ) = ( $Bin =~ m:^(.*?/t)$: );
( my $dist_dir ) = Cwd::realpath( File::Spec->catfile( $test_dir, '..' ) );

use File::Find;

sub not_in_file_ok {
    my ( $filename, %regex ) = @_;
    open( my $fh, '<', $filename )
      or die "couldn't open $filename for reading: $!";

    my %violated;

    while ( my $line = <$fh> ) {
        while ( my ( $desc, $regex ) = each %regex ) {
            if ( $line =~ $regex ) {
                push @{ $violated{$desc} ||= [] }, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains TODO text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    }
    else {
        pass("$filename contains no TODO items");
    }
}

TODO: {
    local $TODO = "Need to finish TODO items";

    find(
        sub {
					return if -d $File::Find::name;
            return unless /\.pm$/;
            diag($File::Find::name);
            not_in_file_ok( $File::Find::name, "TODO" => qr/TODO/, );
        },
        File::Spec->catfile( $dist_dir, 'lib' )
    );

}
