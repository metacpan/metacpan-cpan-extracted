use v5.10;
use strict;
use Test::More;
use File::Temp qw(tempfile);
use File::Basename qw(dirname);
use Config::Reload;

my ($fh,$file) = tempfile( SUFFIX => '.pl' );
say $fh '{ hello => "world!" }';
close $fh;

my $c = Config::Reload->new( file => $file );
is $c->loaded, undef, 'not loaded yet';

is_deeply $c->load, { hello => "world!" }, 'loaded';
ok $c->loaded, 'loaded';

open $fh, '>', $file;
say $fh '{ hi => "world!" }';
close $fh;

is_deeply $c->load, { hello => "world!" }, 'not loaded again';

$c->checked( time - $c->wait - 1 );
is_deeply $c->load, { hi => "world!" }, 'loaded again';

done_testing;
