use strict;
use warnings;
use utf8;

use FindBin '$Bin';

use Test::More;
use App::Aphra;

# Easy way to bail out if the pandoc executable isn't installed
use Pandoc;
plan skip_all => "pandoc isn't installed; this module won't work"
  unless pandoc;

chdir("$Bin/data4");

@ARGV = ('build');

my $outfile = 'docs/index.html';

unlink $outfile if -r $outfile;

App::Aphra->new->run;

ok(-e $outfile, 'Got an output file');
ok(-f $outfile, "... and it's a real file");

open my $out_fh, '<:utf8', $outfile or die $!;
my $contents = do { local $/; <$out_fh> };

ok($contents, 'Got some contents');
like($contents, qr/\x{2019}/, 'Right single quotation mark is not double-encoded');
like($contents, qr/\x{201c}/, 'Left double quotation mark is not double-encoded');
like($contents, qr/\x{201d}/, 'Right double quotation mark is not double-encoded');
like($contents, qr/\x{2014}/, 'Em dash is not double-encoded');

unlink $outfile if -r $outfile;

done_testing;
