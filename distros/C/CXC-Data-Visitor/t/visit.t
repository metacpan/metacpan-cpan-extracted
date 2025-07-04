#! perl

use v5.20;
use Test2::V0;

use CXC::Data::Visitor '-all';
use Ref::Util 'is_refref', 'is_arrayref';
use Scalar::Util 'refaddr';
use experimental 'signatures', 'postderef', 'lexical_subs';
use Data::Dump 'pp';

sub myhash {
    (
        a => 1,
        b => [ 2, 3, 4 ],
        c => {
            d => [ 5, 6, 7 ],
            e => 8,
        },
    );
}

sub lookup ( $container, $kydx ) {
    return is_arrayref( $container ) ? $container->[$kydx] : $container->{$kydx};
}

sub check_ancestors ( $element, $meta ) {

    my @nodes   = ( $meta->{ancestors}->@*, $element );
    my @indexes = $meta->{path}->@*;

    my $node = shift @nodes;
    while ( @nodes ) {
        my $next  = shift @nodes;
        my $index = shift @indexes;
        is( lookup( $node, $index ), $next, "lookup: $index" );
        $node = $next;
    }
}

subtest 'default' => sub {

    my %hash = myhash;

    my @traversed;

    # see if context works
    my %context = ( traversed => \@traversed );

    my ( $completed ) = visit(
        \%hash,
        sub ( $kydx, $vref, $context, $meta ) {

            subtest $kydx => sub {
                if ( is_refref( $vref ) ) {
                    my $container = lookup( $meta->{container}, $kydx );
                    is( refaddr( $container ), refaddr( $vref->$* ), 'container' );
                    push $context->{traversed}->@*, $kydx;
                }
                else {
                    subtest 'leaf' => sub {
                        my $element = lookup( $meta->{container}, $kydx );
                        is( $element, $vref->$*, "kydx: $kydx => $element" );

                        subtest 'ancestors' => sub {
                            check_ancestors( $element, $meta );
                        };
                    };

                    push $context->{traversed}->@*, [ $kydx, $vref->$* ];
                }
            };

            return RESULT_CONTINUE;
        },
        context => \%context,
    );

    is( $completed, T(), 'completed' );

    is(
        \@traversed,
        array {
            item [ a => 1 ];
            item 'b';
            item [ 0, 2 ];
            item [ 1, 3 ];
            item [ 2, 4 ];
            item 'c';
            item 'd';
            item [ 0, 5 ];
            item [ 1, 6 ];
            item [ 2, 7 ];
            item [ e => 8 ];
        },
        'scalars',
    );
};

subtest 'return' => sub {

    my %hash = myhash;

    my @kydx;

    my ( $completed ) = visit(
        \%hash,
        sub ( $kydx, $vref, $context, $meta ) {
            push @kydx, $kydx;
            return RESULT_RETURN if $kydx eq 'b';
            return RESULT_CONTINUE;
        },
    );

    is( $completed, F(), 'not completed' );
    is( \@kydx, [ 'a', 'b', ] );
};

subtest 'revisit container' => sub {

    my %hash = myhash;

    my @kydx;
    my @value;

    my $visited = 0;
    my ( $completed ) = visit(
        \%hash,
        sub ( $kydx, $vref, $context, $meta ) {
            push @kydx,  $kydx;
            push @value, is_refref( $vref ) ? 'ref' : $$vref;

            # manipulate container to test revisit
            if ( $kydx eq 'b' && !$visited ) {
                $visited = 1;
                $meta->{container}{c} = [ 8, 9, 10 ];
                return RESULT_REVISIT_CONTAINER;
            }
            return RESULT_CONTINUE;
        },
    );

    is( $completed, T(), 'completed' );
    is( \@kydx,     [ 'a', 'b', 'a', 'b', 0 .. 2, 'c', 0 .. 2 ] );
    is( \@value,    [qw( 1 ref 1 ref 2 3 4 ref 8 9 10 )] );
};

subtest 'revisit element' => sub {

    my %hash = myhash;

    my @kydx;
    my @value;

    my $visited = 0;
    my ( $completed ) = visit(
        \%hash,
        sub ( $kydx, $vref, $context, $meta ) {
            push @kydx,  $kydx;
            push @value, is_refref( $vref ) ? 'ref' : $$vref;

            # manipulate container to test revisit
            return $kydx eq 'b' && $meta->{pass} == PASS_VISIT_ELEMENT
              ? RESULT_REVISIT_ELEMENT
              : RESULT_CONTINUE;
        },
    );

    is( $completed, T(), 'completed' );

    is( \@kydx, [ ( 'a' ), ( ( 'b', 0 .. 2, 'b', ), ( 'c', ( 'd', 0 .. 2 ), ( 'e' ), ), ), ], );
    is( \@value,
        [ ( 1 ), ( ( ( 'ref', 2, 3, 4, 'ref', ), ( 'ref', ( 'ref', 5, 6, 7 ), ( 8 ), ), ), ), ],
    );
};

subtest 'stop descent' => sub {

    my %hash = myhash;

    my $visited = 0;
    my ( $completed ) = visit(
        \%hash,
        sub ( $kydx, $vref, $context, $meta ) {
            $$vref = [ @{$$vref}, ['XX'] ];
            RESULT_STOP_DESCENT;
        },
        visit => VISIT_ARRAY,
    );

    is( $completed, T(), 'completed' );

    is(
        \%hash,
        hash {
            field a => 1;
            field b => [ 2, 3, 4, ['XX'] ];
            field c => hash {
                field d => [ 5, 6, 7, ['XX'] ];
                field e => 8;
                end;
            };
            end;
        } );
};



subtest 'cycle' => sub {

    subtest 'two parents' => sub {
        my %hash = ( a => { b => [ 0, 1 ] }, );

        $hash{c} = $hash{a};

        ok(
            lives {
                visit( \%hash, sub { 1 } )
            },
        ) or note $@;
    };

    subtest 'die' => sub {

        my %hash = ( a => { b => [ 0, 1 ] }, );
        $hash{a}{b}[0] = $hash{a};

        like(
            dies {
                visit( \%hash, sub { 1; }, )
            },
            qr/ cycle /,
        );
    };

    subtest 'truncate' => sub {

        my %hash = ( a => { b => [ 0, 1 ] }, );
        $hash{a}{b}[0] = $hash{a};

        ok(
            lives {
                visit( \%hash, sub { 1; }, cycle => CYCLE_TRUNCATE )
            },
        ) or note $@;
    };

    subtest 'continue' => sub {

        my %hash = ( a => { b => [ 0, 1 ] }, );
        $hash{a}{b}[0] = $hash{a};

        my $seen = 0;
        ok(
            lives {
                visit(
                    \%hash,
                    sub ( $kydx, $vref, $context, $meta ) {
                        $seen++              if $kydx eq 'b';
                        return RESULT_RETURN if $seen == 10;
                        return RESULT_CONTINUE;
                    },
                    cycle => CYCLE_CONTINUE,
                )
            },
        ) or note $@;
    };

};

subtest 'visit' => sub {

    my $struct = { a => { b => 1, c => [ 2, 3 ] } };

    my sub callback ( $kydx, $vref, $context, $meta ) {
        push $context->{path}->@*, [ $meta->{path}->@* ];
        1;
    }

    subtest 'all' => sub {

        my @path;
        ok(
            lives {
                visit( $struct, \&callback, context => { path => \@path }, )
            },
        ) or note $@;

        is(
            \@path,
            array {
                item array {
                    item $_ for qw( a );
                    end;
                };
                item array {
                    item $_ for qw( a b );
                    end;
                };
                item array {
                    item $_ for qw( a c );
                    end;
                };

                item array {
                    item $_ for qw( a c 0 );
                    end;
                };

                item array {
                    item $_ for qw( a c 1 );
                    end;
                };

                end;
            },
        );

    };

    subtest 'container' => sub {

        my @path;
        ok(
            lives {
                visit(
                    $struct, \&callback,
                    context => { path => \@path },
                    visit   => VISIT_CONTAINER,
                )
            },
        ) or note $@;

        is(
            \@path,
            array {
                item array {
                    item $_ for qw( a );
                    end;
                };
                item array {
                    item $_ for qw( a c );
                    end;
                };

                end;
            },
        ) or do { require Data::Dump; note Data::Dump::pp( \@path ); };

    };

    subtest 'array' => sub {

        my @path;
        ok(
            lives {
                visit(
                    $struct, \&callback,
                    context => { path => \@path },
                    visit   => VISIT_ARRAY,
                )
            },
        ) or note $@;

        is(
            \@path,
            array {
                item array {
                    item $_ for qw( a c );
                    end;
                };

                end;
            },
        ) or do { require Data::Dump; note Data::Dump::pp( \@path ); };

    };


    subtest 'hash' => sub {

        my @path;
        ok(
            lives {
                visit(
                    $struct, \&callback,
                    context => { path => \@path },
                    visit   => VISIT_HASH,
                )
            },
        ) or note $@;

        is(
            \@path,
            array {
                item array {
                    item $_ for qw( a );
                    end;
                };

                end;
            },
        ) or do { require Data::Dump; note Data::Dump::pp( \@path ); };

    };


    subtest 'leaf' => sub {

        my @path;
        ok(
            lives {
                visit(
                    $struct, \&callback,
                    context => { path => \@path },
                    visit   => VISIT_LEAF,
                )
            },
        ) or note $@;

        is(
            \@path,
            array {
                item array {
                    item $_ for qw( a b );
                    end;
                };
                item array {
                    item $_ for qw( a c 0 );
                    end;
                };

                item array {
                    item $_ for qw( a c 1 );
                    end;
                };

                end;
            },
        );

    };

};

subtest 'sort' => sub {

    my %hash = myhash;

    my @order;

    visit(
        \%hash,
        sub ( $kydx, $vref, @ ) {
            push @order, $kydx;
            return RESULT_CONTINUE;
        },
        visit     => VISIT_ALL,
        sort_keys => sub { $_[1] cmp $_[0] },
    );

    is( \@order, [qw( c e d 0 1 2 b 0 1 2 a )] )
      or diag pp @order;

};

done_testing;
