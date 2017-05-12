use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Apache2::AuthenNTLM::Cookie',
    license             => 'perl',
    dist_author         => 'Laurent Dami <la_____.da__@etat.ge.ch>',
    dist_version_from   => 'lib/Apache2/AuthenNTLM/Cookie.pm',
    requires            => {
      'Apache2::RequestRec' => 0,
      'Apache2::Request'    => 0,
      'Apache2::Cookie'     => 0,
      'Apache2::AuthenNTLM' => 0,
      'Apache2::Directive'  => 0,
      'Digest::SHA1'        => 0,
      'MIME::Base64'        => 0,
     },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Apache2-AuthenNTLM-Cookie-*' ],
);

$builder->create_build_script();
