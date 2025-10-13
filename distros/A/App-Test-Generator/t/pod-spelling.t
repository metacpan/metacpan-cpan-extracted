#!perl

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Needs 'Test::Spelling';

Test::Spelling->import();

add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__END__
AnnoCPAN
CPAN
CPANTS
GPL
MetaCPAN
