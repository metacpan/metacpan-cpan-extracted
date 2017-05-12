use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Amazon::SQS::ProducerConsumer',
    license             => 'perl',
    dist_author         => q{Nic Wolff <nic@angel.net>},
    dist_version_from   => 'lib/Amazon/SQS/ProducerConsumer/Base.pm',
    configure_requires => { 'Module::Build' => 0.40 },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
				'XML::Simple' => 0,
				'LWP::UserAgent' => 0,
				'Digest::HMAC_SHA1' => 0,
				'URI::Escape' => 0,
				'MIME::Base64' => 0,
				'JSON::XS' => 0,
    },
    add_to_cleanup      => [ 'Amazon-SQS-ProducerConsumer-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
