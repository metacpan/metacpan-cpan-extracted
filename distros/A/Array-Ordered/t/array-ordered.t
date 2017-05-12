#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
#use Test::More;
use Test::Simple tests => 20;

use Array::Ordered;

init ();

ok( test_size(),            'size'            );
ok( test_clear(),           'clear'           );
ok( test_first(),           'first'           );
ok( test_last(),            'last'            );
ok( test_unshift(),         'unshift'         );
ok( test_push(),            'push'            );
ok( test_shift(),           'shift'           );
ok( test_pop(),             'pop'             );
ok( test_find_or_insert(),  'find_or_insert'  );
ok( test_occurrences(),     'occurrences'     );
ok( test_is_reduced(),      'is_reduced'      );
ok( test_reduce(),          'reduce'          );
ok( test_is_sorted(),       'is_reduced'      );
ok( test_sort(),            'reduce'          );
ok( test_find_all(),        'find_all'        );
ok( test_heads(),           'heads'           );
ok( test_tails(),           'tails'           );
ok( test_remove_all(),      'remove_all'      );
ok( test_shift_heads(),     'shift_heads'     );
ok( test_pop_tails(),       'pop_tails'       );

# Testing data

my @random;   # Seed array
my @cmpsubs;  # Array of comparison subroutine references
my @recipes;  # Map of elements of form [SOURCE, COMPARISON]
my @sorts;    # Arrays ordered via single and combined comparison subroutines
my @splits;   # Arrays of equivalency sequences
my @heads;    # Arrays of first elements of '@splits'
my @tails;    # Arrays of last elements of '@splits'
my @firsts;   # Arrays of indices of '@heads' in '@sorts'
my @lasts;    # Arrays of indices of '@tails' in '@sorts'
my @objects;  # Array of Array::Ordered::Object objects
my $arg;      # A place to put a value for testing 'find_or_insert' variations

# Testing subroutines

sub test_size {
    my $array = order [@random], $cmpsubs[0];
    return $array->size == 17;
}

sub test_clear {
    my @test_sorts;

    foreach my $i (0 .. $#recipes) {
        my ($cmpsub, $src, $dst) = recipe( $i );
        my $array = order [@{$dst}], $cmpsub;
        push @test_sorts, [$array->clear];
        (@{$array}) and return 0;
    }

    return array_cmp( \@test_sorts,  \@sorts ) == 0;
}

sub test_first {
    my @test_heads;
    my @test_firsts;
    
    foreach my $i (0 .. $#recipes) {
        my @finds = map { [$sorts[$i]->first( $_ )] } @{$tails[$i]};
        push @test_heads,   [map { $_->[0] } @finds];
        push @test_firsts,  [map { $_->[1] } @finds];
    }

    return (array_cmp( \@test_heads,  \@heads ) ||
            array_cmp( \@test_firsts, \@firsts )) == 0;
}

sub test_last {
    my @test_tails;
    my @test_lasts;
    
    foreach my $i (0 .. $#recipes) {
        my @finds = map { [$sorts[$i]->last( $_ )] } @{$heads[$i]};
        push @test_tails,   [map { $_->[0] } @finds];
        push @test_lasts,  [map { $_->[1] } @finds];
    }

    return (array_cmp( \@test_tails, \@tails ) ||
            array_cmp( \@test_lasts, \@lasts )) == 0;
}

sub test_unshift {
    my @test_splits;

    foreach my $i (0 .. $#recipes) {
        my ($cmpsub, $src) = recipe( $i );
        my $cmp = $recipes[$i]->[1];
        my $array = order [], $cmpsub;
        $array->unshift( @{$src} );
        my @split;
        foreach my $item (@{$array}) {
            ((@split) ?
              $cmp == 2 ? length( $item ) - length( $split[-1]->[0] ) :
              $cmp == 1 ? lc( $item ) cmp lc( $split[-1]->[0] ) :
              $item cmp $split[-1]->[0] : 1 ) and push @split, [];
            unshift @{$split[-1]}, $item;
        }
        push @test_splits, [@split];
    }

    return array_cmp( \@test_splits, \@splits ) == 0;
}

sub test_push {
    my @test_sorts;

    foreach my $i (0 .. $#recipes) {
        my ($cmpsub, $src) = recipe( $i );
        my $array = order [], $cmpsub;
        $array->push( @{$src} );
        push @test_sorts, $array;
    }

    return array_cmp( \@test_sorts, \@sorts ) == 0;
}

sub test_shift {
    my @test_splits;

    foreach my $i (0 .. $#recipes) {
        my ($cmpsub, $src, $dst) = recipe( $i );
#         print STDERR "\$sorts[$i]: [", join( ', ', @{$dst} ), "]\n";
        my $array = order [@{$src}], $cmpsub;
#         print STDERR "\$array: [", join( ', ', @{$array} ), "]\n";
#         ($array eq $src) and die "Oops!";
        my @split = map { [] } @{$tails[$i]};
        while (@{$array}) {
            foreach my $j (0 .. $#{$tails[$i]}) {
                my $item = $array->shift( $tails[$i]->[$j] );
                push @{$split[$j]}, $item if (defined $item);
            }
        }
        push @test_splits, [@split];
    }

    return array_cmp( \@test_splits, \@splits ) == 0;
}

sub test_pop {
    my @test_splits;

    foreach my $i (0 .. $#recipes) {
        my ($cmpsub, $src) = recipe( $i );
        my $array = order [@{$src}], $cmpsub;
        my @split = map { [] } @{$heads[$i]};
        while (@{$array}) {
            foreach my $j (0 .. $#{$heads[$i]}) {
                my $item = $array->pop( $heads[$i]->[$j] );
                unshift @{$split[$j]}, $item if (defined $item);
            }
        }
        push @test_splits, [@split];
    }

    return array_cmp( \@test_splits, \@splits ) == 0;
}

sub test_find_or_insert {
    my @test_heads;
    my @test_heads_default;
    my @test_heads_constructor;

    foreach my $i (0 .. $#recipes) {
        my ($cmpsub, $src)    = recipe( $i );
        my $array             = order [], $cmpsub;
        my $array_default     = order [], $cmpsub;
        my $array_constructor = order [], $cmpsub;
        foreach (@{$src}) {
            $arg = $_;
            $array->find_or_insert( $_ );
            $array_default->find_or_insert( $_, $arg );
            $array_constructor->find_or_insert( $_, \&test_constructor );
        }
        push @test_heads,              $array;
        push @test_heads_default,      $array_default;
        push @test_heads_constructor,  $array_constructor;
    }

    return (array_cmp( \@test_heads,             \@heads ) ||
            array_cmp( \@test_heads_default,     \@heads ) ||
            array_cmp( \@test_heads_constructor, \@heads )) == 0;
}

sub test_constructor {
    return $arg;
}

sub test_occurrences {
    my @occurrences;
    my @test_head_occurrences;
    my @test_tail_occurrences;

    foreach my $split (@splits) {
        push @occurrences, [map { scalar( @{$_} ) } @{$split}];
    }

    foreach my $i (0 .. $#recipes) {
        my ($cmpsub, $src, $dst) = recipe( $i );
        my $array = order [@{$dst}], $cmpsub;
        push @test_head_occurrences,
            [map { $array->occurrences( $_ ) } @{$heads[$i]}];
        push @test_tail_occurrences,
            [map { $array->occurrences( $_ ) } @{$tails[$i]}];
    }

    return (array_cmp( \@test_head_occurrences, \@occurrences ) ||
            array_cmp( \@test_tail_occurrences, \@occurrences )) == 0;
}

sub test_is_reduced  {
    my $reduced_ok    = 1;

    foreach my $i (0 .. $#recipes) {
        my ($cmpsub, $src, $dst) = recipe( $i );
        my $array = order [@{$dst}], $cmpsub;
        my $heads = order [@{$heads[$i]}], $cmpsub;
        my $tails = order [@{$tails[$i]}], $cmpsub;
        $reduced_ok &&=
           !$array->is_reduced &&
            $heads->is_reduced &&
            $tails->is_reduced;
        $reduced_ok or last;
    }

    return $reduced_ok;
}

sub test_reduce  {
    my @test_heads;
    my @test_tails;

    foreach my $i (0 .. $#recipes) {
        my ($cmpsub, $src, $dst) = recipe( $i );
        my $heads = order [@{$dst}], $cmpsub;
        my $tails = order [@{$dst}], $cmpsub;
        $heads->reduce( 1 );
        push @test_heads, $heads;
        $tails->reduce;
        push @test_tails, $tails;
    }

    return (array_cmp( \@test_heads, \@heads ) ||
            array_cmp( \@test_tails, \@tails )) == 0;
}

sub test_is_sorted  {
    my $sorted_ok = 1;

    foreach (0 .. 2) {
        my $array = order [], $cmpsubs[$_];
        splice( @{$array}, 0, 0, @random);
        unless ($array->is_sorted) {
            $array->sort;
        }
        $sorted_ok &&= $array->is_sorted;
        last unless ($sorted_ok);
    }
    
    return $sorted_ok;
}

sub test_sort {
    my @test_sorts;

    foreach my $i (0 .. $#recipes) {
        my ($cmpsub, $src) = recipe( $i );
        my $array = order [], $cmpsub;
        splice( @{$array}, 0, 0, @{$src});
        unless ($array->is_sorted) {
            $array->sort;
        }
        push @test_sorts, $array;
    }
    
    return array_cmp( \@test_sorts, \@sorts ) == 0;
}

sub test_find_all {
    my @test_head_splits;
    my @test_tail_splits;
    
    foreach my $i (0 .. $#recipes) {
        my ($cmpsub, $src, $dst) = recipe( $i );
        my $array = order [@{$dst}], $cmpsub;
        push @test_head_splits,
            [map { [$array->find_all( $_ ) ] } @{$heads[$i]}];
        push @test_tail_splits,
            [map { [$array->find_all( $_ ) ] } @{$tails[$i]}];
    }

    return (array_cmp( \@test_head_splits, \@splits ) ||
            array_cmp( \@test_tail_splits, \@splits )) == 0;
}

sub test_heads {
    my @test_heads;
    
    foreach my $i (0 .. $#recipes) {
        my ($cmpsub, $src, $dst) = recipe( $i );
        my $array = order [@{$dst}], $cmpsub;
        push @test_heads, [$array->heads];
    }

    return array_cmp( \@test_heads, \@heads ) == 0;
}

sub test_tails {
    my @test_tails;
    
    foreach my $i (0 .. $#recipes) {
        my ($cmpsub, $src, $dst) = recipe( $i );
        my $array = order [@{$dst}], $cmpsub;
        push @test_tails, [$array->tails];
    }

    return array_cmp( \@test_tails, \@tails ) == 0;
}

sub test_remove_all {
    my @test_head_splits;
    my @test_tail_splits;
    
    foreach my $i (0 .. $#recipes) {
        my ($cmpsub, $src, $dst) = recipe( $i );
        my $heads = order [@{$dst}], $cmpsub;
        my $tails = order [@{$dst}], $cmpsub;
        push @test_head_splits,
            [map { [$heads->remove_all( $_ ) ] } @{$heads[$i]}];
        push @test_tail_splits,
            [map { [$tails->remove_all( $_ ) ] } @{$tails[$i]}];
    }

    return (array_cmp( \@test_head_splits, \@splits ) ||
            array_cmp( \@test_tail_splits, \@splits )) == 0;
}

sub test_shift_heads {
    my @test_heads;
    
    foreach my $i (0 .. $#recipes) {
        my ($cmpsub, $src, $dst) = recipe( $i );
        my $array = order [@{$dst}], $cmpsub;
        push @test_heads, [$array->shift_heads];
    }

    return array_cmp( \@test_heads, \@heads ) == 0;
}

sub test_pop_tails {
    my @test_tails;
    
    foreach my $i (0 .. $#recipes) {
        my ($cmpsub, $src, $dst) = recipe( $i );
        my $array = order [@{$dst}], $cmpsub;
        push @test_tails, [$array->pop_tails];
    }

    return array_cmp( \@test_tails, \@tails ) == 0;
}

# Comparison subroutines

sub strcmp {
    $_[0] cmp $_[1]
}

sub strlccmp {
    lc( $_[0] ) cmp lc( $_[1] )
}

sub strlencmp {
    length( $_[0] ) - length( $_[1] )
}

# Recursive array comparison subroutine wrapping 'cmp'

sub array_cmp {
    my @sizes = map { scalar @{$_} } @_;
    my $cmp   = $sizes[0] - $sizes[1];

    unless ($cmp || !$sizes[0]) {
        if (ref $_[0]->[0]) {
            for (my $i = 0; $i < $sizes[0]; $i++) {
                $cmp  = ( ref $_[0]->[$i] cmp 'ARRAY' &&
                          ref $_[0]->[$i] cmp 'Array::Ordered' ) ||
                        ( ref $_[1]->[$i] cmp 'ARRAY' &&
                          ref $_[1]->[$i] cmp 'Array::Ordered' );
                last if ($cmp);
            }
            unless ($cmp) {
                for (my $i = 0; $i < $sizes[0]; $i++) {
                    $cmp ||= array_cmp( $_[0]->[$i], $_[1]->[$i] );
                    last if ($cmp);
                }
            }
        }
        else {
            for (my $i = 0; $i < $sizes[0]; $i++) {
                $cmp = ref $_[0]->[$i] cmp '' ||
                       ref $_[1]->[$i] cmp '';
                last if ($cmp);
            }
            unless ($cmp) {
                my @strings = map { join( '', @{$_} ) } @_;
                $cmp = $strings[0] cmp $strings[1];
            }
        }
    }
    
    return $cmp;
}

# Initialize testing data

sub init {
    my @fodder  = qw( APPLE Apple BOY Boy CUP Cup DOG Dog ELEPHANT ELEPHANT
                      Elephant apple boy boy cup dog elephant );
    for (my $size = scalar( @fodder ); $size; $size--) {
        push @random, splice( @fodder, int( rand( $size ) ), 1);
    }

    @cmpsubs = ( \&strcmp, \&strlccmp, \&strlencmp );

    my ($from, $to) = (-1, 0);
    while (1) {
        last unless ($from < $to);
        my $added = 0;
        for (my $i = $from; $i < $to; $i++) {
            my $src = ($i < 0) ? \@random : $sorts[$i];
            for (my $j = 0; $j < 3; $j++) {
                next if ( defined( $recipes[$i] ) && ($recipes[$i]->[1] == $j) );
                my @array =
                    ($j == 2) ? sort { length( $a ) - length( $b ) } @{$src} :
                    ($j == 1) ? sort { lc( $a ) cmp lc( $b ) } @{$src} :
                    sort { $a cmp $b } @{$src};
                my $k;
                for ($k = 0; $k < $to + $added; $k++) {
                    array_cmp( \@array, $sorts[$k] ) or last;
                }
                next if ($k < $to + $added);
                my @split;
                foreach my $item (@array) {
                    ((@split) ?
                    $j == 2 ? length( $item ) - length( $split[-1]->[-1] ) :
                    $j == 1 ? lc( $item ) cmp lc( $split[-1]->[-1] ) :
                    $item cmp $split[-1]->[-1] : 1 ) and push @split, [];
                    push @{$split[-1]}, $item;
                }
                my @sizes = map { scalar( @{$_} ) } @split;
                my @first = (0);
                my @last  = (-1);
                foreach my $size (@sizes) {
                    push @first, $first[-1] + $size;
                    push @last,  $last[-1] + $size;
                }
                pop   @first;
                shift @last;

                push  @recipes, [$i, $j];
                push  @sorts,   order [@array], $cmpsubs[$j];
                push  @splits,  [@split];
                push  @heads,   [map { $_->[ 0] } @split];
                push  @tails,   [map { $_->[-1] } @split];
                push  @firsts,  [@first];
                push  @lasts,   [@last];

                $added++;
            }
        }
        $from = $to;
        $to += $added;
    }
}

# Subroutine identifying comparison, input array and output array per index

sub recipe {
    my $i = shift;
    return ($cmpsubs[$recipes[$i]->[1]],
            $recipes[$i]->[0] < 0 ? \@random : $sorts[$recipes[$i]->[0]],
            $sorts[$i]);
}
