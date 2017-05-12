#
# $Id: 01-RoundTrip.t,v 0.1 2005/08/30 01:32:11 dankogai Exp $
#
use strict;
use Test::More tests => 27;
require Acme::Bleach::Numerically;
Acme::Bleach::Numerically->import(qw/num2str str2num/);

is(str2num(''),  0, qq(str2num('') is 0));
is(num2str(0),  '', qq(num2str(0) is ''));

my $ascii = join '', map {chr} (0..255);
is(num2str(str2num($ascii)), $ascii, "ascii table");

open my $fh, "<:raw", $0 or die "$0 : $!";
my @lines = <$fh>;
my $file = join '', @lines;
close $fh; chomp @lines;
for my $line (@lines){
    is(num2str(str2num($line)), $line, $line);
}
is(num2str(str2num($file)), $file, "Whole File");
__END__
