#!/usr/bin/perl
use strict; use warnings FATAL => 'all';
use Test::More;

use DTL::Fast::Expression;
use DTL::Fast::Context;
use Data::Dumper;

my $exp;

# @todo Tests for hash values
# @todo Tests for array values
# @todo Tests for objecs with methods: div, mul, plus, minus, not, compare

my $COMPARE_NUM_SET = [ # compare numeric values
    {'val1' => 3.14, 'val2' => 3.14 },
    {'val1' => 3.14, 'val2' => 3.15 },
    {'val1' => 3.15, 'val2' => 3.14 },
    {'val1' => -3.14, 'val2' => 3.14 },
    {'val1' => -3.14, 'val2' => 3.15 },
    {'val1' => -3.15, 'val2' => 3.14 },
    {'val1' => 3.14, 'val2' => -3.14 },
    {'val1' => 3.14, 'val2' => -3.15 },
    {'val1' => 3.15, 'val2' => -3.14 },
    {'val1' => -3.14, 'val2' => -3.14 },
    {'val1' => -3.14, 'val2' => -3.15 },
    {'val1' => -3.15, 'val2' => -3.14 },
    
    # auhtor tests, issue #93
    #{'val1' => undef, 'val2' => -3.14 },
    #{'val1' => -3.15, 'val2' => undef },
    #{'val1' => undef, 'val2' => undef },
    
];

my $STRING_SET = [ # compare and operate string and mixed values
    {'val1' => 'abc', 'val2' => 'def' },
    {'val1' => 'def', 'val2' => 'abc' },
    {'val1' => '', 'val2' => 'def' },
    {'val1' => 'def', 'val2' => '' },
    {'val1' => 'abc', 'val2' => 3.14 },
    {'val1' => 3.14, 'val2' => 'abc' },
    
    # auhtor tests, issue #93
    #{'val1' => undef, 'val2' => 'abc' },
    #{'val1' => 'abc', 'val2' => undef },
    #{'val1' => undef, 'val2' => undef },
];

my $LOGICAL_SET = [ # logical operations
    {'val1' => 0, 'val2' => 0 },
    {'val1' => 0, 'val2' => 1 },
    {'val1' => 1, 'val2' => 0 },
    {'val1' => 1, 'val2' => 1 },
    {'val1' => '', 'val2' => '' },
    {'val1' => '', 'val2' => 'bingo' },
    {'val1' => 'bingo', 'val2' => '' },
    {'val1' => 'bingo', 'val2' => 'bingo' },
    {'val1' => 0, 'val2' => '' },
    {'val1' => 0, 'val2' => 'bingo' },
    {'val1' => 1, 'val2' => '' },
    {'val1' => 1, 'val2' => 'bingo' },
    {'val1' => '', 'val2' => 0 },
    {'val1' => '', 'val2' => 1 },
    {'val1' => 'bingo', 'val2' => 0 },

    # auhtor tests, issue #93
    #{'val1' => undef, 'val2' => 1 },
    #{'val1' => 1, 'val2' => undef },
    #{'val1' => undef, 'val2' => undef },
];

my $NUMERIC_SET = [    # math operations
    {'val1' => 3.14, 'val2' => 15.92},
    {'val1' => -3.14, 'val2' => 15.92},
    {'val1' => 3.14, 'val2' => -15.92},
    {'val1' => -3.14, 'val2' => -15.92},
    {'val1' => 0, 'val2' => 15.92},
    {'val1' => 0, 'val2' => -15.92},
    {'val1' => 3.14, 'val2' => 0},
    {'val1' => -3.14, 'val2' => 0},
    {'val1' => 0, 'val2' => 0},

    # auhtor tests, issue #93
    #{'val1' => undef, 'val2' => 0},
    #{'val1' => 0, 'val2' => undef},
    #{'val1' => undef, 'val2' => undef},
];

my $NUMERIC_SET_DIV = [    # math operations without division by zero
    {'val1' => 3.14, 'val2' => 15.92},
    {'val1' => -3.14, 'val2' => 15.92},
    {'val1' => 3.14, 'val2' => -15.92},
    {'val1' => -3.14, 'val2' => -15.92},
    {'val1' => 0, 'val2' => 15.92},
    {'val1' => 0, 'val2' => -15.92},
    # modulus
    {'val1' => 42, 'val2' => 15},
    {'val1' => 0, 'val2' => 15},
    {'val1' => 0, 'val2' => -15},
    {'val1' => -42, 'val2' => 15},
    {'val1' => 42, 'val2' => -15},

    # auhtor tests, issue #93
    #{'val1' => undef, 'val2' => -15},
    #{'val1' => 42, 'val2' => undef},
    #{'val1' => undef, 'val2' => undef},
];
        
my $samples = [
################################################################################
    {
        'template' => 'val1 ** val2'
        , 'context' => $NUMERIC_SET
        , 'control' => sub{
            my $c = shift;
            return( $c->{'val1'} ** $c->{'val2'});
        }
    },
################################################################################
    {
        'template' => 'not val1'
        , 'context' => $LOGICAL_SET
        , 'control' => sub{
            my $c = shift;
            return( not $c->{'val1'});
        }
    },
################################################################################
    {
        'template' => 'val1 / val2'
        , 'context' => $NUMERIC_SET_DIV
        , 'control' => sub{
            my $c = shift;
            return( $c->{'val1'} / $c->{'val2'});
        }
    },
################################################################################
    {
        'template' => 'val1 * val2'
        , 'context' => $NUMERIC_SET
        , 'control' => sub{
            my $c = shift;
            return( $c->{'val1'} * $c->{'val2'});
        }
    },
################################################################################
    {
        'template' => 'val1 * val2'
        , 'context' => {
            'val1' => 'repeat'
            , 'val2' => '5'
        }
        , 'control' => sub{
            my $c = shift;
            return( $c->{'val1'} x $c->{'val2'});
        }
    },
################################################################################
    {
        'template' => 'val1 % val2'
        , 'context' => $NUMERIC_SET_DIV
        , 'control' => sub{
            my $c = shift;
            return( $c->{'val1'} % $c->{'val2'});
        }
    },
################################################################################
    {
        'template' => 'val1 + val2'
        , 'context' => $NUMERIC_SET
        , 'control' => sub{
            my $c = shift;
            return( $c->{'val1'} + $c->{'val2'});
        }
    },
################################################################################
    {
        'template' => 'val1 + val2'
        , 'context' => $STRING_SET
        , 'control' => sub{
            my $c = shift;
            return( $c->{'val1'}.$c->{'val2'});
        }
    },
################################################################################
    {
        'template' => 'val1 - val2'
        , 'context' => $NUMERIC_SET
        , 'control' => sub{
            my $c = shift;
            return( $c->{'val1'} - $c->{'val2'});
        }
    },
################################################################################
    {
        'template' => 'val1 == val2'
        , 'context' => $COMPARE_NUM_SET
        , 'control' => sub{
            my $c = shift;
            return( $c->{'val1'} == $c->{'val2'});
        }
    },
################################################################################
    {
        'template' => 'val1 == val2'
        , 'context' => $STRING_SET
        , 'control' => sub{
            my $c = shift;
            return( $c->{'val1'} eq $c->{'val2'});
        }
    },
################################################################################
    {
        'template' => 'val1 != val2'
        , 'context' => $COMPARE_NUM_SET
        , 'control' => sub{
            my $c = shift;
            return( $c->{'val1'} != $c->{'val2'});
        }
    },
################################################################################
    {
        'template' => 'val1 != val2'
        , 'context' => $STRING_SET
        , 'control' => sub{
            my $c = shift;
            return( $c->{'val1'} ne $c->{'val2'});
        }
    },
################################################################################
    {
        'template' => 'val1 <> val2'
        , 'context' => $COMPARE_NUM_SET
        , 'control' => sub{
            my $c = shift;
            return( $c->{'val1'} != $c->{'val2'});
        }
    },
################################################################################
    {
        'template' => 'val1 > val2'
        , 'context' => $COMPARE_NUM_SET
        , 'control' => sub{
            my $c = shift;
            return( $c->{'val1'} > $c->{'val2'});
        }
    },
################################################################################
    {
        'template' => 'val1 > val2'
        , 'context' => $STRING_SET
        , 'control' => sub{
            my $c = shift;
            return( $c->{'val1'} gt $c->{'val2'});
        }
    },
################################################################################
    {
        'template' => 'val1 < val2'
        , 'context' => $COMPARE_NUM_SET
        , 'control' => sub{
            my $c = shift;
            return( $c->{'val1'} < $c->{'val2'});
        }
    },
################################################################################
    {
        'template' => 'val1 < val2'
        , 'context' => $STRING_SET
        , 'control' => sub{
            my $c = shift;
            return( $c->{'val1'} lt $c->{'val2'});
        }
    },
################################################################################
    {
        'template' => 'val1 >= val2'
        , 'context' => $COMPARE_NUM_SET
        , 'control' => sub{
            my $c = shift;
            return( $c->{'val1'} >= $c->{'val2'});
        }
    },
################################################################################
    {
        'template' => 'val1 >= val2'
        , 'context' => $STRING_SET
        , 'control' => sub{
            my $c = shift;
            return( $c->{'val1'} ge $c->{'val2'});
        }
    },
################################################################################
    {
        'template' => 'val1 <= val2'
        , 'context' => $COMPARE_NUM_SET
        , 'control' => sub{
            my $c = shift;
            return( $c->{'val1'} <= $c->{'val2'});
        }
    },
################################################################################
    {
        'template' => 'val1 <= val2'
        , 'context' => $STRING_SET
        , 'control' => sub{
            my $c = shift;
            return( $c->{'val1'} le $c->{'val2'});
        }
    },
################################################################################
    {
        'template' => 'val1 or val2'
        , 'context' => $LOGICAL_SET
        , 'control' => sub{
            my $c = shift;
            return( $c->{'val1'} || $c->{'val2'});
        }
    },
################################################################################
    {
        'template' => 'val1 and val2'
        , 'context' => $LOGICAL_SET
        , 'control' => sub{
            my $c = shift;
            return( $c->{'val1'} && $c->{'val2'});
        }
    },
################################################################################
    {
        'template' => 'val1 + val2 * val1 - val1 % val2 + val1 / val2'
        , 'context' => $NUMERIC_SET_DIV
        , 'control' => sub{
            my $c = shift;
            my( $val1, $val2 ) = @$c{'val1', 'val2'};
            return( $val1 + $val2 * $val1 - $val1 % $val2 + $val1 / $val2);
        }
    },
################################################################################
    {
        'template' => '(val1 + val2) * val1 - val1 % (val2 + val1) / val2'
        , 'context' => $NUMERIC_SET_DIV
        , 'control' => sub{
            my $c = shift;
            my( $val1, $val2 ) = @$c{'val1', 'val2'};
            return( ($val1 + $val2) * $val1 - $val1 % ($val2 + $val1) / $val2);
        }
    },
################################################################################
    {
        'template' => '((val1 + val2) * (val1 - val2 )) % (val2 + val1) / val2'
        , 'context' => $NUMERIC_SET_DIV
        , 'control' => sub{
            my $c = shift;
            my( $val1, $val2 ) = @$c{'val1', 'val2'};
            return( (($val1 + $val2) * ($val1 - $val2)) % ($val2 + $val1) / $val2);
        }
    },
];

foreach my $sample (@$samples)
{
    $exp = new DTL::Fast::Expression($sample->{'template'});

    if( ref $sample->{'context'} eq 'HASH' )
    {
        $sample->{'context'} = [$sample->{'context'}];
    }

    subtest $sample->{'template'} => sub
    {
    
        foreach my $context (@{$sample->{'context'}})
        {
            my @context = ();
            
            foreach my $key (keys %$context)
            {
                push @context, sprintf( '%s = %s', $key // 'undef', $context->{$key} // 'undef');
            }
            my $title = '';
            if( scalar @context )
            {
                $title = join('; ', @context);
            }

            my $result;
            eval{ $result = $exp->render(new DTL::Fast::Context($context)) };
            
            if ( $@ )
            {
                print STDERR $@;   
            }
            else
            {
                is( 
                    $result
                    , $sample->{'control'}->($context)
                    , $title
                );
            }
        }
    }
}

#use Data::Dumper;print Dumper($exp);

done_testing();
