#! perl

use Test2::V0;
use Const::Fast;

use App::mkpkgconfig::PkgConfig;
use constant PkgConfig => 'App::mkpkgconfig::PkgConfig';
use Capture::Tiny 'capture';

subtest 'exists' => sub {

    my $pkg = PkgConfig->new;

    subtest Variables => sub {

        $pkg->add_variables( {
            prefix      => 'root',
            exec_prefix => '${prefix}/exec',
            foo         => '${prefix}',
            bar         => '${prefix}/${exec_prefix}'
        } );


        is(
            [ map { $_->name } $pkg->variables ],
            bag {
                item 'foo';
                item 'bar';
                item 'prefix';
                item 'exec_prefix';
                end;
            },
            "inserted variables"
        );

        subtest 'prefix' => sub {

            is(
                $pkg->variable( 'prefix' ),
                object {
                    call name         => 'prefix';
                    call value        => 'root';
                    call_list depends => [];
                },
                'object'
            );

            is(
                $pkg,
                object {
                    call_list [
                        resolve_dependencies => $pkg->variable( 'prefix' )
                    ] => bag {
                        item 'prefix';
                        end;
                    };
                },
                'dependencies'
            );
        };

        subtest 'exec_prefix' => sub {

            is(
                $pkg->variable( 'exec_prefix' ),
                object {
                    call name         => 'exec_prefix';
                    call value        => '${prefix}/exec';
                    call_list depends => bag {
                        item 'prefix';
                        end;
                    };
                },
                'object'
            );

            is(
                $pkg,
                object {
                    call_list [
                        resolve_dependencies => $pkg->variable( 'exec_prefix' )
                    ] => bag {
                        item 'exec_prefix';
                        item 'prefix';
                        end;
                    };
                },
                'dependencies'
            );
        };

        subtest 'foo' => sub {
            is(
                $pkg->variable( 'foo' ),
                object {
                    call name         => 'foo';
                    call value        => '${prefix}';
                    call_list depends => bag {
                        item 'prefix';
                        end;
                    };
                },
                'object'
            );

            is(
                $pkg,
                object {
                    call_list [
                        resolve_dependencies => $pkg->variable( 'foo' )
                    ] => bag {
                        item 'foo';
                        item 'prefix';
                        end;
                    };
                },
                'dependencies'
            );
        };

        subtest 'bar' => sub {
            is(
                $pkg->variable( 'bar' ),
                object {
                    call name         => 'bar';
                    call value        => '${prefix}/${exec_prefix}';
                    call_list depends => bag {
                        item 'prefix';
                        item 'exec_prefix';
                        end;
                    };
                },
                'object'
            );

            is(
                $pkg,
                object {
                    call_list [
                        resolve_dependencies => $pkg->variable( 'bar' )
                    ] => bag {
                        item 'bar';
                        item 'prefix';
                        item 'exec_prefix';
                        end;
                    };
                },
                'dependencies'
            );
        };

    };

    subtest 'Keywords' => sub {

        $pkg->add_keywords( {
            Pfx => '${prefix}/${exec_prefix}'
        } );


        is(
            [ map { $_->name } $pkg->keywords ],
            bag {
                item 'Pfx';
                end;
            },
            "inserted keywords"
        );

        subtest 'Pfx' => sub {
            is(
                $pkg->keyword( 'Pfx' ),
                object {
                    call name         => 'Pfx';
                    call value        => '${prefix}/${exec_prefix}';
                    call_list depends => bag {
                        item 'prefix';
                        item 'exec_prefix';
                        end;
                    };
                },
                'object'
            );

            is(
                $pkg,
                object {
                    call_list [
                        resolve_dependencies => $pkg->keyword( 'Pfx' )
                    ] => bag {
                        item 'prefix';
                        item 'exec_prefix';
                        end;
                    };
                },
                'dependencies'
            );
        };

    };


};

subtest "doesn't exist" => sub {

    my $pkg = PkgConfig->new;

    $pkg->add_variables( {
        exec_prefix => '${prefix}/exec',
        bar         => '${exec_prefix}'
    } );


    is(
        [ map { $_->name } $pkg->variables ],
        bag {
            item 'bar';
            item 'exec_prefix';
            end;
        },
        "inserted variables"
    );

    is(
        $pkg->variable( 'bar' ),
        object {
            call name         => 'bar';
            call value        => '${exec_prefix}';
            call_list depends => bag {
                item 'exec_prefix';
                end;
            };
        },
        'object'
    );

    like(
        dies { $pkg->resolve_dependencies( $pkg->variable( 'bar' ) ) },
        qr/bar->exec_prefix->prefix->undef/,
        'dependencies'
    );
};

subtest 'loops' => sub {

    my $pkg = PkgConfig->new;

    $pkg->add_variables( {
        exec_prefix => '${bar}',
        bar         => '${exec_prefix}',
        foo         => '${bar}',
        a           => '${b}',
        b           => '${c}',
        c           => '${d}',
        d           => '${a}',
    } );


    is(
        [ map { $_->name } $pkg->variables ],
        bag {
            item 'foo';
            item 'bar';
            item 'exec_prefix';
            item 'a';
            item 'b';
            item 'c';
            item 'd';
            end;
        },
        "inserted variables"
    );

    like( dies { $pkg->resolve_dependencies( $pkg->variable( 'bar' ) ) },
        qr/bar->exec_prefix->bar/, 'direct inner loop' );

    like(
        dies { $pkg->resolve_dependencies( $pkg->variable( 'foo' ) ) },
        qr/foo->bar->exec_prefix->bar/,
        'indirect inner loop'
    );

    like( dies { $pkg->resolve_dependencies( $pkg->variable( 'a' ) ) },
        qr/a->b->c->d->a/, 'indirect outer loop' );
};

subtest 'order variables' => sub {

    my $pkg = PkgConfig->new;

    $pkg->add_variables( {
        v0 => '${v1}',
        v1 => '${v2} ${v3}',
        v2 => '',
        v3 => '${v4}',
        v4 => '',
    } );

    my @order;
    ok(
        lives {
            @order = $pkg->order_variables( qw[ v0 v1 v2 v3 v4 ] )
        },
        'create order'
    ) or diag $@;

    # items without dependencies (but which are themselves
    # dependencies) come first and may arrive in any order
    is(
        [ $order[0], $order[1] ],
        bag {
            item 'v2';
            item 'v4';
            end;
        },
        'entries without dependencies'
    );

    # the rest must come in this order, by design of the input set
    is(
        [ @order[ 2 .. 4 ] ],
        array {
            item 'v3';
            item 'v1';
            item 'v0';
            end;
        },
        'entries with dependencies'
    );

};

subtest 'order keywords' => sub {

    *order_keywords = \&App::mkpkgconfig::PkgConfig::order_keywords;

    const my @keywords => qw( A Version B Description C Name );

    my @ordered = order_keywords( @keywords );
    is(
        [ @ordered[ 0 .. 2 ] ],
        array {
            item 'Name';
            item 'Description';
            item 'Version';
            end;
        },
        'first'
    );

    is(
        [ @ordered[ 3 .. 5 ] ],
        bag {
            item 'A';
            item 'B';
            item 'C';
            end;
        },
        'last'
    );

};

subtest 'read' => sub {

    my $meta = <<'END';
       # This is a comment
       prefix=/home/hp/unst   # this defines a variable
       exec_prefix=${prefix}  # defining another variable in terms of the first
       libdir=${exec_prefix}/lib
       includedir=${prefix}/include

       Name: GObject                            # human-readable name
       Description: Object/type system for GLib # human-readable description
       Version: 1.3.1
       URL: http://www.gtk.org
       Requires: glib-2.0 = 1.3.1
       Conflicts: foobar <= 4.5
       Libs: -L${libdir} -lgobject-1.3
       Libs.private: -lm
       Cflags: -I${includedir}/glib-2.0 -I${libdir}/glib/include
END

    my $pkg = PkgConfig->new_from( \$meta );

    is ( $pkg,
         object {
             call_list variables => bag {
                 item object {
                     call name => 'prefix';
                     call value => '/home/hp/unst';
                 };
                 item object {
                     call name => 'exec_prefix';
                     call value => '${prefix}';
                 };
                 item object {
                     call name => 'libdir';
                     call value => '${exec_prefix}/lib';
                 };
                 item object {
                     call name => 'includedir';
                     call value => '${prefix}/include';
                 };
                 end;
             };

             call_list keywords => bag {
                 item object {
                     call name => 'Name';
                     call value => 'GObject';
                 };
                 item object {
                     call name => 'Description';
                     call value => 'Object/type system for GLib';
                 };
                 item object {
                     call name => 'Version';
                     call value => '1.3.1';
                 };
                 item object {
                     call name => 'URL';
                     call value => 'http://www.gtk.org';
                 };
                 item object {
                     call name => 'Requires';
                     call value => 'glib-2.0 = 1.3.1';
                 };
                 item object {
                     call name => 'Conflicts';
                     call value => 'foobar <= 4.5';
                 };
                 item object {
                     call name => 'Libs';
                     call value => '-L${libdir} -lgobject-1.3';
                 };
                 item object {
                     call name => 'Libs.private';
                     call value => '-lm';
                 };
                 item object {
                     call name => 'Cflags';
                     call value => '-I${includedir}/glib-2.0 -I${libdir}/glib/include';
                 };
                 end;
             };

         }
       );

};

subtest 'write' => sub {

    my $pkg = PkgConfig->new;

    $pkg->add_variables( {
        prefix      => 'root',
        exec_prefix => '${prefix}/exec',
        foo         => '${prefix}',
        bar         => '${exec_prefix}',
        version     => 1
    } );

    $pkg->add_keywords( {
        Version => '${version}',
        Libs    => '-L${exec_prefix}/lib -lfoo'
    } );

    my $stdout;

    subtest 'all variables' => sub {

        ok(
            lives {
                $stdout = capture { $pkg->write }
            },
            "write"
        ) or diag $@;

        my @lines = split( "\n", $stdout );

        subtest 'variables' => sub {

            is(
                [ splice @lines, 0, 2 ],
                bag {
                    item 'prefix = root';
                    item 'version = 1';
                    end;
                },
                "constant",
            );

            is(
                [ splice @lines, 0, 2 ],
                bag {
                    item 'exec_prefix = ${prefix}/exec';
                    item 'foo = ${prefix}';
                    end;
                },
                'depends on ${prefix}',
            );

            is(
                [ splice @lines, 0, 1 ],
                bag {
                    item 'bar = ${exec_prefix}';
                    end;
                },
                'depends on ${exec_prefix}',
            );

        };

        is( shift( @lines ), "", "separator" );

        subtest 'keywords' => sub {

            is(
                \@lines,
                bag {
                    item 'Version: ${version}';
                    item 'Libs: -L${exec_prefix}/lib -lfoo';
                    end;
                } );

        };

    };

    subtest 'requested, extras' => sub {

        ok(
            lives {
                $stdout = capture {
                    $pkg->write( undef, write => 'req', vars => ['bar'] )
                }
            },
            "write"
        ) or diag $@;

        my @lines = split( "\n", $stdout );

        subtest 'variables' => sub {

            is(
                [ splice @lines, 0, 2 ],
                bag {
                    item 'prefix = root';
                    item 'version = 1';
                    end;
                },
                "constant",
            );

            is(
                [ splice @lines, 0, 1 ],
                bag {
                    item 'exec_prefix = ${prefix}/exec';
                    end;
                },
                'depends on ${prefix}',
            );

            is(
                [ splice @lines, 0, 1 ],
                bag {
                    item 'bar = ${exec_prefix}';
                    end;
                },
                'depends on ${exec_prefix}',
            );

        };

        is( shift( @lines ), "", "separator" );

        subtest 'keywords' => sub {

            is(
                \@lines,
                bag {
                    item 'Version: ${version}';
                    item 'Libs: -L${exec_prefix}/lib -lfoo';
                    end;
                } );

        };

    };

    subtest 'requested, no extras' => sub {

        ok(
            lives {
                $stdout = capture { $pkg->write( undef, write => 'req' ) }
            },
            "write"
        ) or diag $@;

        my @lines = split( "\n", $stdout );

        subtest 'variables' => sub {

            is(
                [ splice @lines, 0, 2 ],
                bag {
                    item 'prefix = root';
                    item 'version = 1';
                    end;
                },
                "constant",
            );

            is(
                [ splice @lines, 0, 1 ],
                bag {
                    item 'exec_prefix = ${prefix}/exec';
                    end;
                },
                'depends on ${prefix}',
            );

        };

        is( shift( @lines ), "", "separator" );

        subtest 'keywords' => sub {

            is(
                \@lines,
                bag {
                    item 'Version: ${version}';
                    item 'Libs: -L${exec_prefix}/lib -lfoo';
                    end;
                } );

        };

    };

};

done_testing;
