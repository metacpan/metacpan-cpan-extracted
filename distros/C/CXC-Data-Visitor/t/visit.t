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
                return RESULT_REVISIT_CONTENTS;
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
                visit( \%hash, sub { RESULT_CONTINUE } )
            },
        ) or note $@;
    };

    subtest 'die' => sub {

        my %hash = ( a => { b => [ 0, 1 ] }, );
        $hash{a}{b}[0] = $hash{a};

        like(
            dies {
                visit( \%hash, sub { RESULT_CONTINUE }, )
            },
            qr/ cycle /,
        );
    };

    subtest 'truncate' => sub {

        my %hash = ( a => { b => [ 0, 1 ] }, );
        $hash{a}{b}[0] = $hash{a};

        ok(
            lives {
                visit( \%hash, sub { RESULT_CONTINUE }, cycle => CYCLE_TRUNCATE )
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
        return RESULT_CONTINUE;
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

subtest 'stop_descent | revisit_contents' => sub {

    my %hash = myhash;

    my @path;
    my sub callback ( $kydx, $vref, $context, $meta ) {
        push @path, [ $meta->{path}->@* ];

        return
          join( q{,}, $meta->{path}->@* ) eq 'c,d' && $meta->{visit} == 1
          ? RESULT_STOP_DESCENT | RESULT_REVISIT_CONTENTS
          : RESULT_CONTINUE;
    }

    ok(
        lives {
            visit( \%hash, \&callback )
        },
    ) or note $@;

    is(
        \@path,
        [
            ['a'],
            ['b'],
            [ 'b', 0 ],
            [ 'b', 1 ],
            [ 'b', 2 ],
            ['c'],
            [ 'c', 'd', ],
            [ 'c', 'e', ],
            [ 'c', 'd', ],
            [ 'c', 'd', 0 ],
            [ 'c', 'd', 1 ],
            [ 'c', 'd', 2 ],
            [ 'c', 'e', ],
        ],
    ) or note pp( \@path );


};

subtest 'continue | revisit_contents' => sub {

    my %hash = myhash;

    my @path;
    my sub callback ( $kydx, $vref, $context, $meta ) {
        push @path, [ $meta->{path}->@* ];

        return join( q{,}, $meta->{path}->@* ) eq 'c,d,2' && $meta->{visit} == 1
          ? RESULT_REVISIT_CONTENTS
          : RESULT_CONTINUE;
    }

    ok(
        lives {
            visit( \%hash, \&callback )
        },
    ) or note $@;

    is(
        \@path,
        [
            ['a'],
            ['b'],
            [ 'b', 0 ],
            [ 'b', 1 ],
            [ 'b', 2 ],
            ['c'],
            [ 'c', 'd', ],
            [ 'c', 'd', 0 ],
            [ 'c', 'd', 1 ],
            [ 'c', 'd', 2 ],
            [ 'c', 'd', 0 ],
            [ 'c', 'd', 1 ],
            [ 'c', 'd', 2 ],
            [ 'c', 'e', ],
        ],
    ) or note pp( \@path );


};

subtest 'revisit root' => sub {

    my %hash = myhash;

    my @path;
    my $revisit;

    my sub callback ( $kydx, $vref, $context, $meta ) {
        push @path, [ $meta->{path}->@* ];

        # after this is defined, won't toggle
        $revisit //= !!1
          if join( q{,}, $meta->{path}->@* ) eq 'c,d' && $meta->{visit} == 1;

        if ( $revisit ) {
            $revisit = !!0;    # one shot.
            return RESULT_REVISIT_ROOT;
        }

        return RESULT_CONTINUE;
    }

    ok(
        lives {
            visit( \%hash, \&callback )
        },
    ) or note $@;

    is(
        \@path,
        [
            ['a'],
            ['b'],
            [ 'b', 0 ],
            [ 'b', 1 ],
            [ 'b', 2 ],
            ['c'],
            [ 'c', 'd', ],
            ['a'],
            ['b'],
            [ 'b', 0 ],
            [ 'b', 1 ],
            [ 'b', 2 ],
            ['c'],
            [ 'c', 'd', ],
            [ 'c', 'd', 0 ],
            [ 'c', 'd', 1 ],
            [ 'c', 'd', 2 ],
            [ 'c', 'e', ],
        ],
    ) or note pp( \@path );


};

subtest 'visit root' => sub {


    subtest 'continue' => sub {

        my %hash = myhash;

        my @path;
        my sub callback ( $kydx, $vref, $context, $meta ) {
            push @path, defined $kydx ? [ $meta->{path}->@* ] : ['root'];
            return RESULT_CONTINUE;
        }

        ok(
            lives {
                visit( \%hash, \&callback, visit => VISIT_ROOT )
            },
        ) or note $@;

        is(
            \@path,
            [
                ['root'],
                ['a'],
                ['b'],
                [ 'b', 0 ],
                [ 'b', 1 ],
                [ 'b', 2 ],
                ['c'],
                [ 'c', 'd', ],
                [ 'c', 'd', 0 ],
                [ 'c', 'd', 1 ],
                [ 'c', 'd', 2 ],
                [ 'c', 'e', ],
            ],
        ) or note pp( \@path );

    };

    subtest 'revisit element' => sub {

        my %hash = myhash;

        my @path;
        my sub callback ( $kydx, $vref, $context, $meta ) {
            push @path, [ $meta->{pass}, defined $kydx ? $meta->{path}->@* : 'root', ];

            return
              defined( $kydx )
              || $meta->{visit} > 1 || $meta->{pass} == PASS_REVISIT_ELEMENT
              ? RESULT_CONTINUE
              : RESULT_REVISIT_ELEMENT;
        }

        my $completed;
        ok(
            lives {
                $completed = visit( \%hash, \&callback, visit => VISIT_ROOT )
            },
        ) or note $@;

        is(
            \@path,
            [
                [ PASS_VISIT_ELEMENT,   'root' ],
                [ PASS_VISIT_ELEMENT,   'a' ],
                [ PASS_VISIT_ELEMENT,   'b' ],
                [ PASS_VISIT_ELEMENT,   'b', 0 ],
                [ PASS_VISIT_ELEMENT,   'b', 1 ],
                [ PASS_VISIT_ELEMENT,   'b', 2 ],
                [ PASS_VISIT_ELEMENT,   'c' ],
                [ PASS_VISIT_ELEMENT,   'c', 'd', ],
                [ PASS_VISIT_ELEMENT,   'c', 'd', 0 ],
                [ PASS_VISIT_ELEMENT,   'c', 'd', 1 ],
                [ PASS_VISIT_ELEMENT,   'c', 'd', 2 ],
                [ PASS_VISIT_ELEMENT,   'c', 'e', ],
                [ PASS_REVISIT_ELEMENT, 'root' ],
            ],
        ) or note pp( \@path );

    };

    subtest 'revisit root' => sub {

        my %hash = myhash;

        my @path;
        my sub callback ( $kydx, $vref, $context, $meta ) {
            push @path, [ $meta->{visit}, defined $kydx ? $meta->{path}->@* : 'root', ];

            return defined( $kydx ) || $meta->{visit} == 2
              ? RESULT_CONTINUE
              : RESULT_REVISIT_ROOT;
        }

        my $completed;
        ok(
            lives {
                $completed = visit( \%hash, \&callback, visit => VISIT_ROOT )
            },
        ) or note $@;

        is(
            \@path,
            [
                [ 1, 'root' ],
                [ 2, 'root' ],
                [ 1, 'a' ],
                [ 1, 'b' ],
                [ 1, 'b', 0 ],
                [ 1, 'b', 1 ],
                [ 1, 'b', 2 ],
                [ 1, 'c' ],
                [ 1, 'c', 'd', ],
                [ 1, 'c', 'd', 0 ],
                [ 1, 'c', 'd', 1 ],
                [ 1, 'c', 'd', 2 ],
                [ 1, 'c', 'e', ],

            ],
        ) or note pp( \@path );

    };

    subtest 'return/abort' => sub {

        my %hash = myhash;

        my @path;
        my sub callback ( $kydx, $vref, $context, $meta ) {
            push @path, [ $meta->{pass}, defined $kydx ? $meta->{path}->@* : 'root' ];

            return defined( $kydx )
              ? RESULT_CONTINUE
              : $context->{retval};
        }

        my $subtest = sub ( $retval, $expected ) {
            @path = ();
            my $got;
            ok(
                lives {
                    ( $got ) = visit(
                        \%hash, \&callback,
                        visit   => VISIT_ROOT,
                        context => { retval => $retval },
                    );
                },
            ) or note $@;

            is( $got, $expected, 'visit return value' );
            is( \@path, [ [ PASS_VISIT_ELEMENT, 'root' ] ], ) or note pp( \@path );
        };

        subtest( 'return',       $subtest, RESULT_RETURN,       !!0 );
        subtest( 'stop descent', $subtest, RESULT_STOP_DESCENT, !!1 );

    };


};


done_testing;
