use strict;
use warnings;
use Module::Build;

my $mb_subclass = Module::Build->subclass(
    class => 'Async::Microservice::MB_Builder',
    code  => q{
        eval q|
            use Path::Class qw(file);
            use Pod::Simple::Text;
        |;
        my $skip_readme = $@;

        sub create_readme {
            die 'unable to create readme: '.$skip_readme
                if $skip_readme;
            my @readmes;
            my @lib_files = qw(
                lib/Async/Microservice.pm
                lib/Async/MicroserviceReq.pm
                lib/Async/Microservice/Time.pm
            );
            foreach my $file (@lib_files) {
                my $pst = Pod::Simple::Text->new;
                my $readme = '';
                $pst->output_string(\$readme);
                $pst->parse_file($file);
                push(@readmes, $readme);
            }
            file('README')->spew(join("\n".('-'x76)."\n", @readmes));

            return;
        }
    },
);

my $builder = $mb_subclass->new(
    module_name        => 'Async-Microservice',
    license            => 'perl',
    dist_author        => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from  => 'lib/Async/Microservice.pm',
    configure_requires => {'Module::Build' => '0.36',},
    build_requires     => {
        'Test::Most'           => 0,
        'Path::Class'          => 0,
        'Pod::Simple::Text'    => 0,
        'Test::WWW::Mechanize' => 0,
    },
    requires => {
        'perl'                       => 5.010,
        'Twiggy'                     => 0,
        'Plack::Request'             => 0,
        'Try::Tiny'                  => 0,
        'Path::Class'                => 0,
        'Moose'                      => 0,
        'URI'                        => 0,
        'AnyEvent::IO'               => 0,
        'MooseX::Types::Path::Class' => 0,
        'Path::Router'               => 0,
        'JSON::XS'                   => 0,
        'Plack::MIME'                => 0,
        'DateTime'                   => 0,
        'Time::HiRes'                => 0,
        'AnyEvent'                   => 0,
        'namespace::autoclean'       => 0,
    },
    script_files   => [qw(
        bin/async-microservice-time.psgi
    )],
    add_to_cleanup => ['Async-Microservice-*'],
    create_readme  => 1,
    meta_merge     => {
        resources => {
            repository => 'https://github.com/meon/Async-Microservice.git',
            bugtracker => 'https://github.com/meon/Async-Microservice/issues',
        },
        keywords => [qw/ async asynchronous micro service http plack /],
    },
);

$builder->create_build_script();
