use Test::More;
use Data::Dumper;

use strict;
use warnings;
use File::Temp qw( tempfile );

require_ok( 'App::Automaton::Plugin::Source::File');

#my $filename = File::Temp::tempnam();
my ($fh, $filename) = tempfile();

my $conf = {
    type => 'File',
	path => $filename,
    delete => 0
};

my @queue = qw(
	https://tr.im/429e1
	http://ow.ly/Gc7RI
	http://bit.ly/1sHi667
	http://bit.do/VGZZ
	http://goo.gl/IGBHwm
	http://t.ted.com/Pa5p9zX]
	http://youtu.be/KVFkWWvMIpM
	https://www.youtube.com/watch?v=KVFkWWvMIpM
);

#open(my $fh, '>', $filename) or die $!;
print $fh join("\n", @queue);
close($fh);

my $f1 = App::Automaton::Plugin::Source::File->new();
my @r = $f1->go($conf);

is_deeply(\@r, \@queue, 'Read input file');

ok(-e $filename, 'File not deleted');

$conf->{delete} = 1;
my $f2 = App::Automaton::Plugin::Source::File->new();
$f2->go($conf);
ok(!(-e $filename), 'File deleted');

done_testing();
