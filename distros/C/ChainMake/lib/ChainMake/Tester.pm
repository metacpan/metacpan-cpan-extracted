#!/usr/bin/perl

package ChainMake::Tester;

use Test::More;
use Exporter 'import';
use ChainMake::Functions ':all';

our $VERSION = $ChainMake::VERSION;

our @EXPORT_OK = qw(have_made my_ok my_nok);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);
 
my $made;

unlink_timestamps();

sub have_made { $made.=shift }
sub my_ok {
    my ($cmd,$result,$comment)=@_;
    ok( chainmake($cmd) && ($made eq $result),
        "$comment; make $cmd should '$result', did '$made'" );
    $made='';
}
sub my_nok {
    my ($cmd,$result,$comment)=@_;
    ok( !chainmake($cmd) && ($made eq $result),
        "$comment; make $cmd should return false and give '$result', did '$made'" );
    $made='';
}

1;
