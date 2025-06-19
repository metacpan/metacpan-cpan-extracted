use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'AsposeCellsCloud::CellsApi',
    license             => 'MIT',
    dist_abstract       => 'Aspose.Cells Cloud SDK for Perl',
    dist_author         => 'Aspose.Cells',
    dist_version => '25.6.1',
    requires => {
                        'perl'           => '5.6.0',
                        'strict' => 0,
                                        'warnings' => 0,
                                        'utf8' => 0,
                                        'Log::Any' => 0,
                                        'Carp' => 0,
                                        'utf8' => 0,
                                        'MIME::Base64' => 0,
                                        'LWP::UserAgent' => 0,
                                        'HTTP::Headers' => 0,
                                        'HTTP::Response' => 0,
                                        'HTTP::Request::Common' => 0,
                                        'HTTP::Status' => 0,
                                        'URI::Query' => 0,
                                        'JSON' => 0,
                                        'URI::Escape' => 0,
                                        'Scalar::Util' => 0,
                                        'Module::Runtime' => 0,
                                        'Digest::HMAC_SHA1' => 0,
                                        'Exporter' => 0,
                                        'Carp' => 0,
                                        'File::Slurp' => 0,
                                        'Date::Parse' => 0,
                                        'DateTime' => 0,
                                        'Data::Dumper' => 0,
                                        'Test::Exception' => 0

                 },
    build_requires => {
        'Test::More' => '0.10',
    },
    create_makefile_pl => 'traditional'
);

$builder->create_build_script();
