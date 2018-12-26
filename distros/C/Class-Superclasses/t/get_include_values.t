#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use FindBin ();
use Class::Superclasses;
use PPI;

my @tests = (
    [ 'use base("test","hallo")',                 [qw/test hallo/] ],
    [ "use parent('test','hallo')",               [qw/test hallo/] ],
    [ 'use base("test",@{["hallo"]})',            [qw/test/] ],
    [ 'use base(@{["hallo"]})',                   [] ],
    [ 'use base(sub {"hallo"})',                  [] ],
    [ "use parent('test',-norequire => 'hallo')", [qw/test hallo/] ],
    [ "use parent('test','-norequire', 'hallo')", [qw/test hallo/] ],
);

my $parser = Class::Superclasses->new;

for my $test ( @tests ) {
    my ($doc, $expected) = @{$test};

    my $ppi          = PPI::Document->new( \$doc );
    my $baseref      = $ppi->find('PPI::Statement::Include');
    my @superclasses = $parser->_get_include_values( $baseref );

    is_deeply \@superclasses, $expected, $doc;
}

done_testing();
