use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'DBD::AnyData',
    license           => 'perl',
    dist_author       => q{Jens Rehsack <rehsack@cpan.org>},
    dist_version_from => 'lib/DBD/AnyData.pm',
    resources         => {
                   repository  => 'https://svn.perl.org/modules/DBD-AnyData/branches/0.1x-SqlEngine',
                   MailingList => 'mailto:dbi-dev@perl.org',
                   license     => 'http://dev.perl.org/licenses/',
                 },
    build_requires => { 'Test::More' => 0.90, },
    requires       => {
                  'AnyData'        => '0.07',
                  'DBI'            => '1.611_93',
                  'SQL::Statement' => '1.27_02',
                  'Params::Util'   => '1.00',
                },
    recommends => {
                    'AnyData'        => '0.10',
                    'DBI'            => '1.612',
                    'SQL::Statement' => '1.28',
                    'Params::Util'   => '1.01',
                  },
    # from doc, until AnyData has been converted
    auto_features => {
                       remote_files => {
                                         description => "Remote file access",
                                         requires    => { 'LWP' => 0, },
                                         recommends  => { 'LWP' => '5.836', },
                                       },
                       xml_access => {
                                       description => "XML access",
                                       requires    => {
                                                     'XML::Parser' => 0,
                                                     'XML::Twig'   => 0,
                                                   },
                                       recommends => {
                                                       'XML::Parser' => '2.36',
                                                       'XML::Twig'   => '3.35',
                                                     },
                                     },
                       html_tables => {
                                        description => "HTML Table acess",
                                        requires    => {
                                                      'HTML::Parser'       => 0,
                                                      'HTML::TableExtract' => 0,
                                                    },
                                        recommends => {
                                                        'HTML::Parser'       => '3.65',
                                                        'HTML::TableExtract' => '2.10',
                                                      },
                                      },
                       html_table_writing => {
                                               description => "Write HTML Tables",
                                               requires    => { 'CGI' => 0, },
                                               recommends  => { 'CGI' => '3.49', },
                                             },
                     },
    CONFLICTS => {
                   'SQL::Statement' => '1.27',
                   'DBI'            => '1.611',
                 },
    add_to_cleanup     => ['DBD-AnyData-*'],
    create_makefile_pl => 'traditional',
                                );

$builder->create_build_script();
