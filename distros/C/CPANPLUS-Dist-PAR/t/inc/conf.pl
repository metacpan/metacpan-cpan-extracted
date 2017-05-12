### figure out if we can run tests
BEGIN {
    use strict;
    use Test::More;
    use CPANPLUS::Backend;
    use CPANPLUS::Dist::PAR;
    use File::Spec;
    use Config;
    use IPC::Cmd    qw[can_run];
    
    use vars qw[$CLASS $DIST $CB $FAKEMOD $DEBMOD $DPKG];
    $DIST       = 'CPANPLUS::Dist';
    $CLASS      = 'CPANPLUS::Dist::PAR';
    
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
}    

1;
