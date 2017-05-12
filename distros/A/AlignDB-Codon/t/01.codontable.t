use strict;
use warnings;

use Test::More;

use AlignDB::Codon;

{    # id <=> name

    # all translation tables in Bio::Tools::CodonTable
    my @NAMES =    #id
        (
        'Standard',                      # 1
        'Vertebrate Mitochondrial',      # 2
        'Yeast Mitochondrial',           # 3
        '',
        'Invertebrate Mitochondrial',    # 5
        '', '', '', '', '',
        'Bacterial, Archaeal and Plant Plastid',    # 11
        );

    for ( 0 .. $#NAMES ) {
        my $table_id   = $_ + 1;
        my $table_name = $NAMES[$_];
        next if length $table_name < 1;
        my $codon_obj = AlignDB::Codon->new( table_id => $table_id );
        ok( defined $codon_obj,                "Init object $table_id" );
        ok( $codon_obj->isa('AlignDB::Codon'), "ISA $table_id" );
        is( $codon_obj->table_id,   $table_id,   "table_id $table_id" );
        is( $codon_obj->table_name, $table_name, "table_name $table_id" );
    }

    print "\n";
}

{    # wrong codon table id

    {    # not a number
        my @ids = qw{ a b c };
        for my $table_id (@ids) {
            eval { AlignDB::Codon->new( table_id => $table_id ); };
            like( $@, qr{Int}, "not a number" );
        }
    }

    {    # out of range
        my @ids = qw{ 55 100 };
        for my $table_id (@ids) {
            eval { AlignDB::Codon->new( table_id => $table_id ); };
            like( $@, qr{range}, "out of range" );
        }
    }

    {    # not defined
        my @ids = (undef);
        for my $table_id (@ids) {
            eval { AlignDB::Codon->new->change_codon_table($table_id); };
            like( $@, qr{not defined}, "not defined" );
        }
    }
}

done_testing();
