# 1234
use strict;
use warnings;
use Test::More;

BEGIN {
    eval 'require URI::file;';
    plan skip_all => 'URI::file module not available' if $@;
    eval 'require File::Spec;';
    plan skip_all => 'File::Spec module not available' if $@;
}

use ARGV::URL ();

plan tests => 6;

my @a = @ARGV = ( URI::file->new(File::Spec->rel2abs(__FILE__)) );
like $ARGV[0], qr|\Afile://|, "\$ARGV[0] is a file:// URL";

ARGV::URL->import;

is scalar(@ARGV), 1, "Array size preserved";
isnt $ARGV[0], $a[0], "\$ARGV[0] has been modified";
like $ARGV[0], qr|file://|, "\$ARGV[0] still contains a file:// URL";
like $ARGV[0], qr/|\z/, "Is a pipe";

my $line = <>;
chomp $line;
is $line, '# 1234', "Read line works";
