### figure out if we can run tests
BEGIN {
    use strict;
    use Test::More;
    use CPANPLUS::Backend;
    use CPANPLUS::Dist::Deb;
    use File::Spec;
    use Config;
    use IPC::Cmd    qw[can_run];
    
    use vars qw[$CLASS $DIST $CONST $CB $FAKEMOD $DEBMOD $DPKG $CPANDEB
                $CONTENTS $DO_META];
    $DIST       = 'CPANPLUS::Dist';
    $CLASS      = 'CPANPLUS::Dist::Deb';
    $CONST      = 'CPANPLUS::Dist::Deb::Constants';
    $DPKG       = can_run('dpkg');
    $DO_META    = can_run('apt-ftparchive');  # XXX use the constant?
    
    ### can we even run this tests?
    plan (  $CLASS->format_available
                ? 'no_plan'
                : (skip_all => "$CLASS is not available") );


    $CB         = CPANPLUS::Backend->new or die "CPANPLUS not available";

    ### write things to our local test dir
    $CB->configure_object->set_conf( base => File::Spec->rel2abs('dist') );
    $CB->configure_object->set_conf( verbose => ($ARGV[0] ? 1 : 0) );

    ### makes sure the nested 'make test' doesn't screw up our test
    ### counters
    $CB->configure_object->set_conf( allow_build_interactivity => 0 );

    ### dont try to report tests!
    $CB->configure_object->set_conf( cpantest => 0 );

    ### disable sig tests
    $CB->configure_object->set_conf( signature => 0 );
    
    ### a fake module object to play with
    $FAKEMOD    = CPANPLUS::Module::Fake->new(
                    module      => 'Foo::Bar',
                    version     => '0.01',
                    path        => 'foo',
                    package     => 'Foo-Bar-0.01.tar.gz',
                    author      => CPANPLUS::Module::Author::Fake->new(),
                );                
    $DEBMOD     = 'libfoo-bar-perl';
    $CPANDEB    = 'cpan-libfoo-bar-perl';
    
    ### install prefixes for files -- do not hardcode, as we may not be
    ### working with debians stock perl
    my $pref = $Config{'installsitelib'};
    my $arch = $Config{'installsitearch'};
    my $man3 = $Config{'installsiteman3dir'};
    my $bin  = $Config{'installsitescript'};
    
    $CONTENTS = {
        xs  => 
            [       # ones we need
                [   $man3 . q[/Foo::Bar.3pm],
                    $arch . q[/Foo/Bar.pm],
                    $arch . q[/auto/Foo/Bar/Bar.bs],
                    $arch . q[/auto/Foo/Bar/Bar.so],
                    $bin  . q[/foobar.pl],
                ],
                    # ones that definately shouldn't be there
                [   #qw[perllocal.pod]  # we abandoned pure_install due
                                        # to M::B issues with it :(
                ]
            ],
        noxs => 
            [       # ones we need
                [   $man3 . q[/Foo::Bar.3pm],
                    $pref . q[/Foo/Bar.pm],
                    $bin  . q[/foobar.pl],
                ],
                    # ones that definately shouldn't be there
                [   #qw[perllocal.pod]  # we abandoned pure_install due
                                        # to M::B issues with it :(
                ]
            ]
    };

    
    
}    

1;
