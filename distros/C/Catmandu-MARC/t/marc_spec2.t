#!perl

use strict;
use warnings;
use Test::More;
use Catmandu;

note "
---
".'blahmarc_spec(...{^1=\1}{^2=\0}     indicators10: "Cross-platform Perl /Eric F. Johnson."';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => 't/camel9.mrc',
        type => 'ISO',
        fix  => 'marc_spec("...{^1=\1}{^2=\0}", indicators10.$append); retain_field(indicators10)'
    );
    my $record = $importer->first;
    is_deeply $record->{indicators10}, ['Cross-platform Perl /Eric F. Johnson.'], q|fix: marc_spec('...{^1=\1}{^2=\0}', indicators10.$append);|;
}


done_testing;
