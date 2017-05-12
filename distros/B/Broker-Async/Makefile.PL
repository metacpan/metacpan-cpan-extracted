use strict;
use warnings;
use ExtUtils::MakeMaker;

my $main = 'lib/Broker/Async.pm';
WriteMakefile(
    NAME          => 'Broker::Async',
    AUTHOR        => [ 'Mark Flickinger <maf@cpan.org>' ],
    ABSTRACT_FROM => $main,
    VERSION_FROM  => $main,
    test          => { RECURSIVE_TEST_FILES => 1 },
    META_MERGE    => {
        'meta-spec'      => { version => 2 },
        'license'        => [ 'perl_5' ],
        'dynamic_config' => 0,
        'prereqs' => {
            'runtime' => {
                'requires' => {
                    'perl'         => '5.008',
                    'Carp'         => 0,
                    'Class::Tiny'  => 0,
                    'Exporter'     => 0,
                    'Scalar::Util' => 0,
                },
            },
            'test' => {
                'requires' => {
                    'parent'          => 0,
                    'Future'          => '0.26',
                    'List::Util'      => 0,
                    'Test::Fatal'     => 0,
                    'Test::LeakTrace' => 0,
                    'Test::More'      => 0,
                },
            },
            'develop' => {
                'requires' => {
                    'AnyEvent::Future' => 0,
                    'AnyEvent::HTTP'   => 0,
                    'CPAN::Meta'       => 0,
                    'Future::HTTP'     => 0,
                    'Future::Mojo'     => 0,
                    'IO::Async'        => 0,
                    'Module::CPANfile' => 0,
                    'Mojolicious'      => 0,
                    'Pod::Markdown'    => 0,
                    'POE::Future'      => 0,
                    'Test::Pod'        => '1.00',
                    'Test::Strict'     => 0,
                },
            },
        },
        'resources' => {
            'bugtracker' => {'web' => 'https://github.com/mark-5/p5-broker-async/issues'},
            'homepage'   => 'https://github.com/mark-5/p5-broker-async',
            'repository' => {
                'type' => 'git',
                'url'  => 'https://github.com/mark-5/p5-broker-async.git',
            },
        },
    },
);


sub MY::postamble {
    return 'include Makefile.author' if -d '.git';
}

sub MY::test_via_harness {
    my ($self, $perl, @tests) = @_;
    return $self->MM::test_via_harness("$perl -It/lib", @tests);
}
