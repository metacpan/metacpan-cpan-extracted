#!/usr/bin/perl

use strict;
use warnings;
use warnings qw(FATAL utf8);
use utf8;

use Test::More;

use Catmandu::Importer::PICA;
use Catmandu::Fix;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::Bind::pica_each';
    use_ok $pkg;
}
require_ok $pkg;

{
    my $fixer = Catmandu::Fix->new(
        fixes => [q|
    do pica_each()
        if pica_match("010@a",'ger')
            add_field(is_ger,true)
        end
        if pica_match("001U0")
            add_field(has_encoding,true)
        end
        if pica_match("001Ua")
            add_field(is_bogus,true)
        end
    end
    do pica_each('010@')
        copy_field(record.0,foo)
        if all_match(record.0.0,'010@')
          add_field(from_var,true)
        end
    end
    do pica_each('010@')
        if all_match(record.0.0,'010U')
          add_field(from_var2,true)
        end
    end
    |]);

    my $importer = Catmandu::Importer::PICA->new(
        file => './t/files/picaplus.dat',
        type => "PLUS"
    );
    my $record = $fixer->fix( $importer->first );

    ok exists $record->{record}, 'created a PICA record';
    is $record->{is_ger},       'true', 'created is_ger tag';
    is $record->{has_encoding}, 'true', 'created has_encoding tag';
    isnt $record->{is_bogus},   'true', 'not created is_bogus tag';
    is $record->{from_var},     'true', 'created from_var tag';
    isnt $record->{from_var2},  'true', 'not created from_var tag';
}

{
    my $fixer = Catmandu::Fix->new(
        fixes => [q|
    add_field(counter,'')
    do pica_each('2...')
        unless pica_match($t)
            append(counter,'+')
        end
    end
    |]);
    my $importer = Catmandu::Importer::PICA->new(
        file => './t/files/plain.pica',
        type => "Plain"
    );
    my $record = $fixer->fix( $importer->first );
    is $record->{counter}, '+++++', 'iterated over all 2...fields';
    is @{$record->{record}}, 16, 'does not remove fields (#84)';
}

done_testing;
