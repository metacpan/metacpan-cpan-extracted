#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use open ':std' => ':utf8';
    use DateTime;
    use Test::More qw( no_plan );
    use Module::Generic::File qw( file );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Changes' ) || BAIL_OUT( "Failed to load Changes" );;
};

use strict;
use warnings;
use utf8;

my $raw_data = <<EOT;
0.02 令和４年１２月７日１７時１２分
 ① 新バージョン
 ② 追加機能

0.01 令和４年１２月５日９時３５分
 ー　最初リリース
EOT
my $c = Changes->load_data( $raw_data, debug => $DEBUG );
isa_ok( $c, 'Changes' );
is( $c->preamble, undef, 'no preamble' );
is( $c->releases->length, 2, 'No of releases' );
my $rel = $c->releases->first;
isa_ok( $rel, 'Changes::Release' );
my $changes_data = $c->as_string;
is( "$changes_data", $raw_data, 'as_string reproduces same original data' );
SKIP:
{
    skip( 'No release object found.', 5 ) if( !$rel );
    isa_ok( $rel->version, 'Changes::Version' );
    is( $rel->version->as_string, '0.02', 'version is 0.02' );
    is( $rel->datetime, '令和４年１２月７日１７時１２分', 'datetime' );
    is( $rel->changes->length, 2, 'release has 2 change' );
    skip( "No release change found.", 2 ) if( $rel->changes->is_empty );
    my $ch = $rel->changes->first;
    isa_ok( $ch => 'Changes::Change', 'change object is a Changes::Change' );
    is( $ch->text, '新バージョン', 'change text' );
    is( $ch->marker, '①', 'marker' ); 
    is( $rel->changes->second->text, '追加機能', 'change text' );
    is( $rel->changes->second->marker, '②', 'marker' );
};

my $rel2 = $c->releases->second;
isa_ok( $rel2, 'Changes::Release' );
SKIP:
{
    skip( 'No release object found.', 5 ) if( !$rel2 );
    isa_ok( $rel2->version, 'Changes::Version' );
    is( $rel2->version, '0.01', 'version is 0.01' );
    is( $rel2->datetime, '令和４年１２月５日９時３５分', 'datetime' );
    is( $rel2->changes->length, 1, 'release has 1 change' );
    skip( "No release change found.", 2 ) if( $rel2->changes->is_empty );
    my $ch = $rel2->changes->first;
    isa_ok( $ch => 'Changes::Change', 'change object is a Changes::Change' );
    is( $ch->text, '最初リリース', 'change text' );
};

done_testing();

__END__

