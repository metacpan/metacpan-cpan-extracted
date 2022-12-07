use strict;
use Test::More 0.98;
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
use Dyn::Call qw[:aggr :sigchar];
use Affix     qw[:all];
$|++;
#
use t::lib::nativecall;
#
compile_test_lib('65_dyn_call_aggregate');
#
sub offset : Native('t/65_dyn_call_aggregate') : Signature([Char]=>Int);
#
subtest 'simple' => sub {
    my $aggr = dcNewAggr( 5, 5 );
    isa_ok $aggr, 'Dyn::Call::Aggregate', 'dcNewAggr(5, 5)';
    is $aggr->size,      5, '->size == 5';
    is $aggr->n_fields,  0, '->n_fields == 0';
    is $aggr->alignment, 0, '->alignment == 0';
    subtest 'add fields' => sub {
        subtest 'add int' => sub {
            dcAggrField( $aggr, DC_SIGCHAR_INT, offset('i'), 1 );
            is $aggr->n_fields,  1, '->n_fields == 1';
            is $aggr->alignment, 4, '->alignment == 4';
        };
        subtest 'add float' => sub {
            dcAggrField( $aggr, DC_SIGCHAR_FLOAT, offset('f'), 1 );
            is $aggr->n_fields,  2, '->n_fields == 2';
            is $aggr->alignment, 4, '->alignment == 4';
        };
        subtest 'add double' => sub {
            dcAggrField( $aggr, DC_SIGCHAR_DOUBLE, offset('d'), 1 );
            is $aggr->n_fields,  3, '->n_fields == 3';
            is $aggr->alignment, 8, '->alignment == 8';
        };
        subtest 'add char' => sub {
            dcAggrField( $aggr, DC_SIGCHAR_CHAR, offset('c'), 1 );
            is $aggr->n_fields,  4, '->n_fields == 4';
            is $aggr->alignment, 8, '->alignment == 8';
        };
        subtest 'add long' => sub {
            dcAggrField( $aggr, DC_SIGCHAR_LONG, offset('j'), 1 );
            is $aggr->n_fields,  5, '->n_fields == 5';
            is $aggr->alignment, 8, '->alignment == 8';
        };
    };
    subtest 'check fields' => sub {
        my @fields = $aggr->fields;
        is $fields[4]->offset,    offset('j'), '$fields[4]->offset == ' . offset('j');
        is $fields[3]->alignment, 1,           '$fields[2]->alignment == 1';
        for my $i ( 0 .. $#fields ) {
            diag sprintf '[%d] size: %d, type: %s, alignment: %d, offset: %d, array_len: %d', $i,
                $fields[$i]->size, $fields[$i]->type, $fields[$i]->alignment, $fields[$i]->offset,
                $fields[$i]->array_len;
        }
    }
};
#
done_testing;
