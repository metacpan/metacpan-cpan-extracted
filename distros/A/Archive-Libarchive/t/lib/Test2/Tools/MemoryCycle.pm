package Test2::Tools::MemoryCycle;

use strict;
use warnings;
use Devel::Cycle qw( find_cycle find_weakened_cycle );
use Test2::API qw( context );
use Exporter qw( import );

our @EXPORT = qw( memory_cycle_ok );

# Adapted from Test::Memory::Cycle for Test2::API
sub memory_cycle_ok {
    my $ref = shift;
    my $msg = shift;

    $msg ||= 'no memory cycle';

    my $cycle_no = 0;
    my @diags;

    # Callback function that is called once for each memory cycle found.
    my $callback = sub {
        my $path = shift;
        $cycle_no++;
        push( @diags, "Cycle #$cycle_no" );
        foreach (@$path) {
            my ($type,$index,$ref,$value) = @$_;

            my $str = 'Unknown! This should never happen!';
            my $refdisp = _ref_shortname( $ref );
            my $valuedisp = _ref_shortname( $value );

            $str = sprintf( '    %s => %s', $refdisp, $valuedisp )               if $type eq 'SCALAR';
            $str = sprintf( '    %s => %s', "${refdisp}->[$index]", $valuedisp ) if $type eq 'ARRAY';
            $str = sprintf( '    %s => %s', "${refdisp}->{$index}", $valuedisp ) if $type eq 'HASH';
            $str = sprintf( '    closure %s => %s', "${refdisp}, $index", $valuedisp ) if $type eq 'CODE';

            push( @diags, $str );
        }
    };

    find_cycle( $ref, $callback );
    my $ok = !$cycle_no;

    my $ctx = context();
    if($ok) {
        $ctx->pass_and_release($msg);
    } else {
        $ctx->fail_and_release($msg, @diags);
    }

    return $ok;
} # memory_cycle_ok

my %shortnames;
my $new_shortname = "A";

sub _ref_shortname {
    my $ref = shift;
    my $refstr = "$ref";
    my $refdisp = $shortnames{ $refstr };
    if ( !$refdisp ) {
        my $sigil = ref($ref) . " ";
        $sigil = '%' if $sigil eq "HASH ";
        $sigil = '@' if $sigil eq "ARRAY ";
        $sigil = '$' if $sigil eq "REF ";
        $sigil = '&' if $sigil eq "CODE ";
        $refdisp = $shortnames{ $refstr } = $sigil . $new_shortname++;
    }

    return $refdisp;
}

1;
