#! perl

use Test2::V0;
use FindBin;
use Capture::Tiny 'capture';

require "$FindBin::Bin/../script/mkpkgconfig";

use App::mkpkgconfig::PkgConfig;
use constant PkgConfig => 'App::mkpkgconfig::PkgConfig';

subtest 'default' => sub {

    my $stdout;
    ok(
        lives {
            $stdout = capture {
                main( qw( --name foo --description foodesc --Cflags foo --modversion 1 ) )
            };
        } ) or diag $@;


    my $pkg;
    ok( lives { $pkg = PkgConfig->new_from( \$stdout ) } )
      or diag $@;

    is(
        $pkg,
        object {
            call_list variables => bag {
                item object {
                    call name  => 'version';
                    call value => '1';
                };
                end;
            };

            call_list keywords => bag {
                item object {
                    call name  => 'Name';
                    call value => 'foo';
                };
                item object {
                    call name  => 'Description';
                    call value => 'foodesc';
                };

                item object {
                    call name  => 'Version';
                    call value => '${version}';
                };

                item object {
                    call name  => 'Cflags';
                    call value => 'foo';
                };

                end;
            };
        },
    );
};

subtest 'requested' => sub {

    my $stdout;
    ok(
        lives {
            $stdout = capture {
                main(
                    '--name'        => 'foo',
                    '--description' => 'foodesc',
                    '--modversion'  => 1,
                    '--var'         => 'bar=2',
                    '--usevars'     => 'requested',
                  )
            }
        },
    ) or diag $@;

    my $pkg;
    ok( lives { $pkg = PkgConfig->new_from( \$stdout ) } )
      or diag $@;

    is(
        $pkg,
        object {
            call_list variables => bag {
                item object {
                    call name  => 'version';
                    call value => '1';
                };
                item object {
                    call name  => 'bar';
                    call value => '2';
                };
                end;
            };

            call_list keywords => bag {
                item object {
                    call name  => 'Name';
                    call value => 'foo';
                };
                item object {
                    call name  => 'Description';
                    call value => 'foodesc';
                };

                item object {
                    call name  => 'Version';
                    call value => '${version}';
                };

            };
        },
    );
};

subtest 'needed' => sub {

    my $stdout;
    ok(
        lives {
            $stdout = capture {
                main(
                    '--name'        => 'foo',
                    '--description' => 'foodesc',
                    '--modversion'  => 1,
                    '--var'         => 'bar=2',
                    '--usevars'     => 'needed',
                  )
            }
        },
    ) or diag $@;

    my $pkg;
    ok( lives { $pkg = PkgConfig->new_from( \$stdout ) } )
      or diag $@;

    is(
        $pkg,
        object {
            call_list variables => bag {
                item object {
                    call name  => 'version';
                    call value => '1';
                };
                end;
            };

            call_list keywords => bag {
                item object {
                    call name  => 'Name';
                    call value => 'foo';
                };
                item object {
                    call name  => 'Description';
                    call value => 'foodesc';
                };

                item object {
                    call name  => 'Version';
                    call value => '${version}';
                };

            };
        },
    );
};

subtest 'auto' => sub {

    subtest 'usevars => all' => sub {

        my $stdout;
        ok(
            lives {
                $stdout = capture {
                    main(
                        '--name'        => 'foo',
                        '--description' => 'foodesc',
                        '--modversion'  => 1,
                        '--auto',
                        '--prefix'  => 'root',
                        '--package' => 'mypkg',
                        '--usevars' => 'all',
                      )
                }
            },
        ) or diag $@;

        my $pkg;
        ok( lives { $pkg = PkgConfig->new_from( \$stdout ) } )
          or diag $@;

        is(
            $pkg,
            object {
                call_list variables => bag {
                    item object {
                        call name  => 'prefix';
                        call value => 'root';
                    };

                    item object {
                        call name  => 'version';
                        call value => 1;
                    };

                    item object {
                        call name  => 'package';
                        call value => 'mypkg';
                    };

                    for ( keys %::VarsAuto ) {
                        item object {
                            call name  => $_;
                            call value => $::VarsAuto{$_};
                        };
                    }
                    end;
                };

                call_list keywords => bag {
                    item object {
                        call name  => 'Name';
                        call value => 'foo';
                    };
                    item object {
                        call name  => 'Description';
                        call value => 'foodesc';
                    };

                    item object {
                        call name  => 'Version';
                        call value => '${version}';
                    };

                };
            },
        );
    };

    subtest 'usevars => requested' => sub {

        my $stdout;
        ok(
            lives {
                $stdout = capture {
                    main(
                        '--name'        => 'foo',
                        '--description' => 'foodesc',
                        '--modversion'  => 1,
                        '--auto'     => 'libdir',
                        '--prefix'  => 'root',
                        '--package' => 'mypkg',
                        '--usevars' => 'requested',
                      )
                }
            },
        ) or diag $@;

        my $pkg;
        ok( lives { $pkg = PkgConfig->new_from( \$stdout ) } )
          or diag $@;

        is(
            $pkg,
            object {
                call_list variables => bag {
                    item object {
                        call name  => 'prefix';
                        call value => 'root';
                    };

                    item object {
                        call name  => 'exec_prefix';
                        call value => '${prefix}';
                    };

                    item object {
                        call name  => 'libdir';
                        call value => '${exec_prefix}/lib';
                    };

                    item object {
                        call name  => 'version';
                        call value => 1;
                    };

                    end;
                };

                call_list keywords => bag {
                    item object {
                        call name  => 'Name';
                        call value => 'foo';
                    };
                    item object {
                        call name  => 'Description';
                        call value => 'foodesc';
                    };

                    item object {
                        call name  => 'Version';
                        call value => '${version}';
                    };

                };
            },
        );
    };

    subtest 'usevars => needed' => sub {

        my $stdout;
        ok(
            lives {
                $stdout = capture {
                    main(
                        '--name'        => 'foo',
                        '--description' => 'foodesc',
                        '--modversion'  => 1,
                        '--auto'     => 'libdir',
                        '--prefix'  => 'root',
                        '--package' => 'mypkg',
                        '--usevars' => 'needed',
                      )
                }
            },
        ) or diag $@;

        my $pkg;
        ok( lives { $pkg = PkgConfig->new_from( \$stdout ) } )
          or diag $@;

        is(
            $pkg,
            object {
                call_list variables => bag {
                    item object {
                        call name  => 'version';
                        call value => 1;
                    };

                    end;
                };

                call_list keywords => bag {
                    item object {
                        call name  => 'Name';
                        call value => 'foo';
                    };
                    item object {
                        call name  => 'Description';
                        call value => 'foodesc';
                    };

                    item object {
                        call name  => 'Version';
                        call value => '${version}';
                    };

                };
            },
        );
    };

};

done_testing;
