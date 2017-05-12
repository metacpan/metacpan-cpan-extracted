#-*-Perl-*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use ExtUtils::MakeMaker;
use File::Temp qw(tempfile);
use FindBin '$Bin';
use constant TEST_COUNT => 11;

use lib "$Bin/../lib","$Bin/../blib/lib","$Bin/../blib/arch";
use Test::More tests => TEST_COUNT;

use File::Temp 'tempdir';
use Bio::Graphics::Wiggle::Loader;

my $source = "$Bin/data/wig_data.wig";
my $tmpdir = tempdir(CLEANUP=>1);

my $loader = Bio::Graphics::Wiggle::Loader->new($tmpdir,'mywibfile');
ok($loader);
my $fh = IO::File->new($source);
ok($loader->load($fh));
my $gff3 = $loader->featurefile('gff3');
undef $loader; # force a flush

ok($gff3);
my ($wibfile) = $gff3 =~ m!wigfile=(.+\.wib)!;
ok($wibfile);
ok($wibfile =~ /mywibfile/);

my $wig = Bio::Graphics::Wiggle->new($wibfile);
ok($wig);
is($wig->seqid,'I');
ok(abs($wig->values(87=>87)->[0]-0.22) < 0.01);
ok(abs($wig->values(173=>173)->[0]-0.52) < 0.01);
my $h = $wig->values(101=>300);
is(@$h,200);

my $result = $wig->export_to_bedgraph(1,5000);
my @lines  = split "\n",$result;
is(@lines,57);

exit 0;



