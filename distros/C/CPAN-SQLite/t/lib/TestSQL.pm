# $Id: TestSQL.pm 31 2011-06-12 22:56:18Z stro $

package TestSQL;
use strict;
use warnings;

use base qw(Exporter);
our (@EXPORT_OK, $dists, $mods, $auths);
@EXPORT_OK = qw($dists $mods $auths has_hash_data vcmp);

$dists = {
          'CPAN-Test-Dummy-Perl5-Make' => {
                                            'modules' => {
                                                           'CPAN::Test::Dummy::Perl5::Make' => 1,
                                                           'Bundle::CpanTestDummies' => 1
                                                         },
                                            'dist_vers' => '1.05',
                                            'cpanid' => 'ANDK',
                                            'dist_file' => 'CPAN-Test-Dummy-Perl5-Make-1.05.tar.gz'
                                          },
          'Apache-MP3' => {
                            'modules' => {
                                           'Apache::MP3::L10N::sh' => 1,
                                           'Apache::MP3::L10N::ms' => 1,
                                           'Apache::MP3::L10N::nl_be' => 1,
                                           'Apache::MP3::L10N::no' => 1,
                                           'Apache::MP3' => 1,
                                           'Apache::MP3::L10N::en' => 1,
                                           'Apache::MP3::L10N::uk' => 1,
                                           'Apache::MP3::L10N::nn' => 1,
                                           'Apache::MP3::L10N::sr' => 1,
                                           'Apache::MP3::L10N::hr' => 1,
                                           'Apache::MP3::L10N::zh_tw' => 1,
                                           'Apache::MP3::L10N::ga' => 1,
                                           'Apache::MP3::L10N::tr' => 1,
                                           'Apache::MP3::L10N::nl' => 1,
                                           'Apache::MP3::L10N::sl' => 1,
                                           'Apache::MP3::L10N::ru' => 1,
                                           'Apache::MP3::L10N::fa' => 1,
                                           'Apache::MP3::L10N::ko' => 1,
                                           'Apache::MP3::L10N::is' => 1,
                                           'Apache::MP3::L10N::ca' => 1,
                                           'Apache::MP3::L10N::cs' => 1,
                                           'Apache::MP3::L10N::he' => 1,
                                           'Apache::MP3::Playlist' => 1,
                                           'Apache::MP3::L10N::pl' => 1,
                                           'Apache::MP3::L10N::nb' => 1,
                                           'Apache::MP3::L10N::RightToLeft' => 1,
                                           'Apache::MP3::L10N::fr' => 1,
                                           'Apache::MP3::L10N::nb_no' => 1,
                                           'Apache::MP3::L10N::zh_cn' => 1,
                                           'Apache::MP3::L10N::x_marklar' => 1,
                                           'Apache::MP3::L10N::fi' => 1,
                                           'Apache::MP3::Sorted' => 1,
                                           'Apache::MP3::L10N::nn_no' => 1,
                                           'Apache::MP3::L10N::sk' => 1,
                                           'Apache::MP3::L10N::nl_nl' => 1,
                                           'Apache::MP3::L10N::es' => 1,
                                           'Apache::MP3::L10N::ja' => 1,
                                           'Apache::MP3::L10N' => 1,
                                           'Apache::MP3::L10N::ar' => 1,
                                           'Apache::MP3::L10N::Aliases' => 1,
                                           'Apache::MP3::L10N::it' => 1,
                                           'Apache::MP3::L10N::de' => 1,
                                           'Apache::MP3::L10N::no_no' => 1
                                         },
                            'dist_vers' => '4.00',
                            'cpanid' => 'LDS',
                            'dist_file' => 'Apache-MP3-4.00.tar.gz'
                          },
          'Devel-Symdump' => {
                               'modules' => {
                                              'Devel::Symdump::Export' => 1,
                                              'Devel::Symdump' => 1
                                            },
                               'dist_vers' => '2.0604',
                               'cpanid' => 'ANDK',
                               'dist_file' => 'Devel-Symdump-2.0604.tar.gz'
                             },
          'CPAN-Test-Dummy-Perl5-Make-Zip' => {
                                                'modules' => {
                                                               'CPAN::Test::Dummy::Perl5::Make::Zip' => 1
                                                             },
                                                'dist_vers' => '1.03',
                                                'cpanid' => 'ANDK',
                                                'dist_file' => 'CPAN-Test-Dummy-Perl5-Make-Zip-1.03.zip'
                                              },
          'Convert-ASN1' => {
                              'modules' => {
                                             'Convert::ASN1' => 1,
                                             'Convert::ASN1::parser' => 1
                                           },
                              'dist_vers' => '0.20',
                              'cpanid' => 'GBARR',
                              'dist_file' => 'Convert-ASN1-0.20.tar.gz'
                            },
          'Tie-DBI' => {
                         'modules' => {
                                        'Tie::DBI' => 1,
                                        'Tie::RDBM' => 1
                                      },
                         'dist_vers' => '1.02',
                         'cpanid' => 'LDS',
                         'dist_file' => 'Tie-DBI-1.02.tar.gz'
                       },
          'CPAN-Test-Dummy-Perl5-Make-CircDepeThree' => {
                                                          'modules' => {
                                                                         'CPAN::Test::Dummy::Perl5::Make::CircDepeThree' => 1
                                                                       },
                                                          'dist_vers' => '1.00',
                                                          'cpanid' => 'ANDK',
                                                          'dist_file' => 'CPAN-Test-Dummy-Perl5-Make-CircDepeThree-1.00.tar.gz'
                                                        },
          'GD' => {
                    'modules' => {
                                   'GD::Polyline' => 1,
                                   'GD' => 1,
                                   'GD::Simple' => 1
                                 },
                    'dist_vers' => '2.35',
                    'cpanid' => 'LDS',
                    'dist_file' => 'GD-2.35.tar.gz'
                  },
          'Errno' => {
                       'modules' => {
                                      'Errno' => 1
                                    },
                       'dist_vers' => '1.09',
                       'cpanid' => 'GBARR',
                       'dist_file' => 'Errno-1.09.tar.gz'
                     },
          'SHA' => {
                     'modules' => {
                                    'SHA' => 1
                                  },
                     'dist_vers' => '2.01',
                     'cpanid' => 'GAAS',
                     'dist_file' => 'SHA-2.01.tar.gz'
                   },
          'Tkx' => {
                     'modules' => {
                                    'Tkx::MegaConfig' => 1,
                                    'Tkx' => 1,
                                    'Tkx::LabEntry' => 1
                                  },
                     'dist_vers' => '1.04',
                     'cpanid' => 'GAAS',
                     'dist_file' => 'Tkx-1.04.tar.gz'
                   },
          'Apache-GzipChain' => {
                                  'modules' => {
                                                 'Apache::PassFile' => 1,
                                                 'Apache::GzipChain' => 1
                                               },
                                  'dist_vers' => '1.14',
                                  'cpanid' => 'ANDK',
                                  'dist_file' => 'Apache-GzipChain-1.14.tar.gz'
                                },
          'TimeDate' => {
                          'modules' => {
                                         'Date::Language::Dutch' => 1,
                                         'Date::Language' => 1,
                                         'Date::Language::Afar' => 1,
                                         'Date::Language::Sidama' => 1,
                                         'Date::Language::Amharic' => 1,
                                         'Date::Language::TigrinyaEritrean' => 1,
                                         'Date::Format' => 1,
                                         'Date::Language::Danish' => 1,
                                         'Time::Zone' => 1,
                                         'Date::Language::English' => 1,
                                         'Date::Language::Swedish' => 1,
                                         'Date::Language::Norwegian' => 1,
                                         'Date::Language::Tigrinya' => 1,
                                         'Date::Language::Gedeo' => 1,
                                         'Date::Language::TigrinyaEthiopian' => 1,
                                         'Date::Language::Austrian' => 1,
                                         'Date::Parse' => 1,
                                         'Date::Language::Chinese_GB' => 1,
                                         'Date::Language::French' => 1,
                                         'Date::Language::Brazilian' => 1,
                                         'Date::Language::Somali' => 1,
                                         'Date::Language::Czech' => 1,
                                         'Date::Language::Oromo' => 1,
                                         'Date::Language::German' => 1,
                                         'Date::Language::Italian' => 1,
                                         'Date::Language::Greek' => 1,
                                         'Date::Language::Finnish' => 1
                                       },
                          'dist_vers' => '1.16',
                          'cpanid' => 'GBARR',
                          'dist_file' => 'TimeDate-1.16.tar.gz'
                        },
          'IPC-SysV' => {
                          'modules' => {
                                         'IPC::Semaphore' => 1,
                                         'IPC::Msg' => 1,
                                         'IPC::SysV' => 1
                                       },
                          'dist_vers' => '1.03',
                          'cpanid' => 'GBARR',
                          'dist_file' => 'IPC-SysV-1.03.tar.gz'
                        },
          'Devel-Cycle' => {
                             'modules' => {
                                            'Devel::Cycle' => 1
                                          },
                             'dist_vers' => '1.07',
                             'cpanid' => 'LDS',
                             'dist_file' => 'Devel-Cycle-1.07.tar.gz'
                           },
          'CPAN-Test-Dummy-Perl5-Make-CircDepeTwo' => {
                                                        'modules' => {
                                                                       'CPAN::Test::Dummy::Perl5::Make::CircDepeTwo' => 1
                                                                     },
                                                        'dist_vers' => '1.00',
                                                        'cpanid' => 'ANDK',
                                                        'dist_file' => 'CPAN-Test-Dummy-Perl5-Make-CircDepeTwo-1.00.tar.gz'
                                                      },
          'HTML-Parser' => {
                             'modules' => {
                                            'HTML::LinkExtor' => 1,
                                            'HTML::TokeParser' => 1,
                                            'HTML::HeadParser' => 1,
                                            'HTML::Entities' => 1,
                                            'HTML::Parser' => 1,
                                            'HTML::PullParser' => 1,
                                            'HTML::Filter' => 1
                                          },
                             'dist_vers' => '3.55',
                             'cpanid' => 'GAAS',
                             'dist_file' => 'HTML-Parser-3.55.tar.gz'
                           },
          'Crypt-CBC' => {
                           'modules' => {
                                          'Crypt::CBC' => 1
                                        },
                           'dist_vers' => '2.22',
                           'cpanid' => 'LDS',
                           'dist_file' => 'Crypt-CBC-2.22.tar.gz'
                         },
          'webchat' => {
                         'modules' => {
                                        'WWW::Chat' => 1
                                      },
                         'dist_vers' => '0.05',
                         'cpanid' => 'GAAS',
                         'dist_file' => 'webchat-0.05.tar.gz'
                       },
          'Font-AFM' => {
                          'modules' => {
                                         'Font::Metrics::TimesRoman' => 1,
                                         'Font::Metrics::CourierOblique' => 1,
                                         'Font::Metrics::HelveticaBoldOblique' => 1,
                                         'Font::Metrics::HelveticaBold' => 1,
                                         'Font::Metrics::CourierBold' => 1,
                                         'Font::Metrics::Helvetica' => 1,
                                         'Font::Metrics::HelveticaOblique' => 1,
                                         'Font::Metrics::TimesBoldItalic' => 1,
                                         'Font::Metrics::TimesItalic' => 1,
                                         'Font::AFM' => 1,
                                         'Font::Metrics::CourierBoldOblique' => 1,
                                         'Font::Metrics::TimesBold' => 1,
                                         'Font::Metrics::Courier' => 1
                                       },
                          'dist_vers' => '1.19',
                          'cpanid' => 'GAAS',
                          'dist_file' => 'Font-AFM-1.19.tar.gz'
                        },
          'pyperl' => {
                        'modules' => {
                                       'Python::Object' => 1
                                     },
                        'dist_vers' => '1.0',
                        'cpanid' => 'GAAS',
                        'dist_file' => 'pyperl-1.0.tar.gz'
                      },
          'Convert-BER' => {
                             'modules' => {
                                            'Convert::BER' => 1,
                                            'Convert::BER::BER' => 1
                                          },
                             'dist_vers' => '1.3101',
                             'cpanid' => 'GBARR',
                             'dist_file' => 'Convert-BER-1.3101.tar.gz'
                           },
          'MAB2' => {
                      'modules' => {
                                     'MAB2::Record::pnd' => 1,
                                     'MAB2::Record::swd' => 1,
                                     'Tie::MAB2::Dualdb' => 1,
                                     'MAB2::Record::lokal' => 1,
                                     'MAB2::Record::titel' => 1,
                                     'MAB2::Record::gkd' => 1,
                                     'Tie::MAB2::RecnoViaId' => 1,
                                     'Encode::MAB2table' => 1,
                                     'Tie::MAB2::Dualdb::Recno' => 1,
                                     'Encode::MAB2' => 1,
                                     'Tie::MAB2::Id' => 1,
                                     'Tie::MAB2::Dualdb::Id' => 1,
                                     'MAB2::Record::Base' => 1,
                                     'Tie::MAB2::Recno' => 1
                                   },
                      'dist_vers' => '0.06',
                      'cpanid' => 'ANDK',
                      'dist_file' => 'MAB2-0.06.tar.gz'
                    },
          'Digest-SHA1' => {
                             'modules' => {
                                            'Digest::SHA1' => 1
                                          },
                             'dist_vers' => '2.11',
                             'cpanid' => 'GAAS',
                             'dist_file' => 'Digest-SHA1-2.11.tar.gz'
                           },
          'Perl-Repository-APC' => {
                                     'modules' => {
                                                    'Perl::Repository::APC' => 1,
                                                    'Perl::Repository::APC::BAP' => 1,
                                                    'Perl::Repository::APC2SVN' => 1
                                                  },
                                     'dist_vers' => '1.220',
                                     'cpanid' => 'ANDK',
                                     'dist_file' => 'Perl-Repository-APC-1.220.tar.gz'
                                   },
          'UDDI' => {
                      'modules' => {
                                     'UDDI::SOAP' => 1,
                                     'UDDI' => 1
                                   },
                      'dist_vers' => '0.03',
                      'cpanid' => 'GAAS',
                      'dist_file' => 'UDDI-0.03.tar.gz'
                    },
          'Data-DumpXML' => {
                              'modules' => {
                                             'Data::DumpXML' => 1,
                                             'Data::DumpXML::Parser' => 1
                                           },
                              'dist_vers' => '1.06',
                              'cpanid' => 'GAAS',
                              'dist_file' => 'Data-DumpXML-1.06.tar.gz'
                            },
          'LWPng-alpha' => {
                             'modules' => {
                                            'LWP::Dump' => 1,
                                            'LWP::Conn::HTTP' => 1,
                                            'LWP::Authen::digest' => 1,
                                            'LWP::Sink::Tee' => 1,
                                            'LWP::UA::Cookies' => 1,
                                            'LWP::MainLoop' => 1,
                                            'LWP::Sink::rot13' => 1,
                                            'LWP::Sink::identity' => 1,
                                            'LWP::StdSched' => 1,
                                            'LWP::Version' => 1,
                                            'LWP::Sink::Monitor' => 1,
                                            'LWP::Sink::base64' => 1,
                                            'LWP::Conn::FILE' => 1,
                                            'LWP::UA' => 1,
                                            'LWP::Conn::FTP' => 1,
                                            'LWP::EventLoop' => 1,
                                            'LWP::Sink::Buffer' => 1,
                                            'LWP::Authen::basic' => 1,
                                            'LWP::Sink::HTML' => 1,
                                            'LWP::Authen' => 1,
                                            'LWP::Sink::_Pipe' => 1,
                                            'LWP::Redirect' => 1,
                                            'URI::Attr' => 1,
                                            'LWP::Conn' => 1,
                                            'LWP::Sink::deflate' => 1,
                                            'LWP::UA::Proxy' => 1,
                                            'LWP::Sink::qp' => 1,
                                            'LWP::Conn::_Cmd' => 1,
                                            'LWP::Sink::IO' => 1,
                                            'LWP::Sink' => 1,
                                            'LWP::Hooks' => 1,
                                            'LWP::Request' => 1,
                                            'LWP::Conn::_Connect' => 1,
                                            'LWP::Server' => 1
                                          },
                             'dist_vers' => '0.24',
                             'cpanid' => 'GAAS',
                             'dist_file' => 'LWPng-alpha-0.24.tar.gz'
                           },
          'CPAN-Test-Dummy-Perl5-Build-DepeFails' => {
                                                       'modules' => {
                                                                      'CPAN::Test::Dummy::Perl5::Build::DepeFails' => 1
                                                                    },
                                                       'dist_vers' => '1.02',
                                                       'cpanid' => 'ANDK',
                                                       'dist_file' => 'CPAN-Test-Dummy-Perl5-Build-DepeFails-1.02.tar.gz'
                                                     },
          'Text-Shellwords' => {
                                 'modules' => {
                                                'Text::Shellwords' => 1
                                              },
                                 'dist_vers' => '1.08',
                                 'cpanid' => 'LDS',
                                 'dist_file' => 'Text-Shellwords-1.08.tar.gz'
                               },
          'Apache-Session-Counted' => {
                                        'modules' => {
                                                       'Apache::Session::Counted' => 1
                                                     },
                                        'dist_vers' => '1.118',
                                        'cpanid' => 'ANDK',
                                        'dist_file' => 'Apache-Session-Counted-1.118.tar.gz'
                                      },
          'Regexp' => {
                        'modules' => {
                                       'Regexp' => 1
                                     },
                        'dist_vers' => '0.004',
                        'cpanid' => 'GBARR',
                        'dist_file' => 'Regexp-0.004.tar.gz'
                      },
          'URI' => {
                     'modules' => {
                                    'URI::mailto' => 1,
                                    'URI::QueryParam' => 1,
                                    'URI::file::Mac' => 1,
                                    'URI::rtsp' => 1,
                                    'URI::urn::oid' => 1,
                                    'URI::file' => 1,
                                    'URI::https' => 1,
                                    'URI::sips' => 1,
                                    'URI::file::Base' => 1,
                                    'URI::_generic' => 1,
                                    'URI::rtspu' => 1,
                                    'URI::tn3270' => 1,
                                    'URI::urn::isbn' => 1,
                                    'URI::_login' => 1,
                                    'URI::gopher' => 1,
                                    'URI::rlogin' => 1,
                                    'URI::mms' => 1,
                                    'URI::ldap' => 1,
                                    'URI::Split' => 1,
                                    'URI::data' => 1,
                                    'URI::_server' => 1,
                                    'URI::ldaps' => 1,
                                    'URI::ssh' => 1,
                                    'URI::file::OS2' => 1,
                                    'URI::ftp' => 1,
                                    'URI::WithBase' => 1,
                                    'URI::Escape' => 1,
                                    'URI::file::Win32' => 1,
                                    'URI::_segment' => 1,
                                    'URI::_query' => 1,
                                    'URI::Heuristic' => 1,
                                    'URI::file::QNX' => 1,
                                    'URI::urn' => 1,
                                    'URI::sip' => 1,
                                    'URI::nntp' => 1,
                                    'URI' => 1,
                                    'URI::file::Unix' => 1,
                                    'URI::http' => 1,
                                    'URI::telnet' => 1,
                                    'URI::file::FAT' => 1,
                                    'URI::rsync' => 1,
                                    'URI::ldapi' => 1,
                                    'URI::_ldap' => 1,
                                    'URI::snews' => 1,
                                    'URI::URL' => 1,
                                    'URI::_userpass' => 1,
                                    'URI::pop' => 1,
                                    'URI::news' => 1
                                  },
                     'dist_vers' => '1.35',
                     'cpanid' => 'GAAS',
                     'dist_file' => 'URI-1.35.tar.gz'
                   },
          'Tie-Dir' => {
                         'modules' => {
                                        'Tie::Dir' => 1
                                      },
                         'dist_vers' => '1.02',
                         'cpanid' => 'GBARR',
                         'dist_file' => 'Tie-Dir-1.02.tar.gz'
                       },
          'Bio-SCF' => {
                         'modules' => {
                                        'Bio::SCF::Arrays' => 1,
                                        'Bio::SCF' => 1
                                      },
                         'dist_vers' => '1.01',
                         'cpanid' => 'LDS',
                         'dist_file' => 'Bio-SCF-1.01.tar.gz'
                       },
          'Digest-MD2' => {
                            'modules' => {
                                           'Digest::MD2' => 1
                                         },
                            'dist_vers' => '2.03',
                            'cpanid' => 'GAAS',
                            'dist_file' => 'Digest-MD2-2.03.tar.gz'
                          },
          'CPAN-Test-Dummy-Perl5-Make-Failearly' => {
                                                      'modules' => {
                                                                     'CPAN::Test::Dummy::Perl5::Make::Failearly' => 1
                                                                   },
                                                      'dist_vers' => '1.02',
                                                      'cpanid' => 'ANDK',
                                                      'dist_file' => 'CPAN-Test-Dummy-Perl5-Make-Failearly-1.02.tar.gz'
                                                    },
          'Net-TFTP' => {
                          'modules' => {
                                         'Net::TFTP' => 1
                                       },
                          'dist_vers' => '0.16',
                          'cpanid' => 'GBARR',
                          'dist_file' => 'Net-TFTP-0.16.tar.gz'
                        },
          'Digest-HMAC' => {
                             'modules' => {
                                            'Digest::HMAC_SHA1' => 1,
                                            'Digest::HMAC' => 1,
                                            'Digest::HMAC_MD5' => 1
                                          },
                             'dist_vers' => '1.01',
                             'cpanid' => 'GAAS',
                             'dist_file' => 'Digest-HMAC-1.01.tar.gz'
                           },
          'Bundle-CPAN' => {
                             'modules' => {
                                            'Bundle::CPANxxl' => 1,
                                            'Bundle::CPAN' => 1
                                          },
                             'dist_vers' => '1.854',
                             'cpanid' => 'ANDK',
                             'dist_file' => 'Bundle-CPAN-1.854.tar.gz'
                           },
          'Apache-Stage' => {
                              'modules' => {
                                             'Apache::Stage' => 1
                                           },
                              'dist_vers' => '1.20',
                              'cpanid' => 'ANDK',
                              'dist_file' => 'Apache-Stage-1.20.tar.gz'
                            },
          'AcePerl' => {
                         'modules' => {
                                        'Ace' => 1,
                                        'Ace::Browser::GeneSubs' => 1,
                                        'Ace::Sequence::Multi' => 1,
                                        'Ace::Graphics::Glyph::dot' => 1,
                                        'Ace::Graphics::GlyphFactory' => 1,
                                        'Ace::Graphics::Glyph::anchored_arrow' => 1,
                                        'Ace::Freesubs' => 1,
                                        'Ace::Sequence::Gene' => 1,
                                        'Ace::Sequence::Transcript' => 1,
                                        'Ace::Object::Wormbase' => 1,
                                        'Ace::Graphics::Glyph::primers' => 1,
                                        'Ace::Graphics::Glyph::ex' => 1,
                                        'Ace::Graphics::Glyph::transcript' => 1,
                                        'Ace::Graphics::Glyph::group' => 1,
                                        'Ace::Graphics::Glyph::arrow' => 1,
                                        'Ace::Graphics::Glyph::crossbox' => 1,
                                        'Ace::Sequence::FeatureList' => 1,
                                        'Ace::Model' => 1,
                                        'Ace::Browser::SiteDefs' => 1,
                                        'Ace::Graphics::Glyph::triangle' => 1,
                                        'Ace::Graphics::Glyph::graded_segments' => 1,
                                        'Ace::Sequence' => 1,
                                        'Ace::Sequence::Feature' => 1,
                                        'Ace::Graphics::Glyph::box' => 1,
                                        'Ace::Graphics::Track' => 1,
                                        'Ace::Graphics::Glyph::line' => 1,
                                        'Ace::Browser::SearchSubs' => 1,
                                        'Ace::Object' => 1,
                                        'Ace::Sequence::GappedAlignment' => 1,
                                        'Ace::Graphics::Glyph::span' => 1,
                                        'Ace::Sequence::Homol' => 1,
                                        'Ace::SocketServer' => 1,
                                        'Ace::Graphics::Glyph' => 1,
                                        'Ace::Local' => 1,
                                        'Ace::Graphics::Glyph::toomany' => 1,
                                        'GFF::Filehandle' => 1,
                                        'Ace::Graphics::Glyph::segments' => 1,
                                        'Ace::Graphics::Panel' => 1,
                                        'Ace::Graphics::Fk' => 1,
                                        'Ace::Iterator' => 1,
                                        'Ace::Browser::TreeSubs' => 1,
                                        'Ace::RPC' => 1,
                                        'Ace::Browser::AceSubs' => 1
                                      },
                         'dist_vers' => '1.89',
                         'cpanid' => 'LDS',
                         'dist_file' => 'AcePerl-1.89.tar.gz'
                       },
          'perlbench' => {
                           'modules' => {
                                          'PerlBench::Results' => 1,
                                          'MyPodHtml' => 1,
                                          'PerlBench' => 1,
                                          'PerlBench::Stats' => 1
                                        },
                           'dist_vers' => '0.93',
                           'cpanid' => 'GAAS',
                           'dist_file' => 'perlbench-0.93.tar.gz'
                         },
          'Apache-HeavyCGI' => {
                                 'modules' => {
                                                'Apache::HeavyCGI::Layout' => 1,
                                                'Apache::HeavyCGI::Debug' => 1,
                                                'Apache::HeavyCGI::IfModified' => 1,
                                                'Apache::HeavyCGI::SquidRemoteAddr' => 1,
                                                'Apache::HeavyCGI::Date' => 1,
                                                'Apache::HeavyCGI' => 1,
                                                'Apache::HeavyCGI::Exception' => 1,
                                                'Apache::HeavyCGI::ExePlan' => 1,
                                                'Apache::HeavyCGI::UnmaskQuery' => 1
                                              },
                                 'dist_vers' => '0.013302',
                                 'cpanid' => 'ANDK',
                                 'dist_file' => 'Apache-HeavyCGI-0.013302.tar.gz'
                               },
          'PostScript-EPSF' => {
                                 'modules' => {
                                                'PostScript::EPSF' => 1
                                              },
                                 'dist_vers' => '0.01',
                                 'cpanid' => 'GAAS',
                                 'dist_file' => 'PostScript-EPSF-0.01.tar.gz'
                               },
          'CPAN-Test-Dummy-Perl5-Build-Fails' => {
                                                   'modules' => {
                                                                  'CPAN::Test::Dummy::Perl5::Build::Fails' => 1
                                                                },
                                                   'dist_vers' => '1.03',
                                                   'cpanid' => 'ANDK',
                                                   'dist_file' => 'CPAN-Test-Dummy-Perl5-Build-Fails-1.03.tar.gz'
                                                 },
          'IO-Socket-Multicast' => {
                                     'modules' => {
                                                    'IO::Socket::Multicast' => 1
                                                  },
                                     'dist_vers' => '1.05',
                                     'cpanid' => 'LDS',
                                     'dist_file' => 'IO-Socket-Multicast-1.05.tar.gz'
                                   },
          'IO' => {
                    'modules' => {
                                   'IO::Seekable' => 1,
                                   'IO::File' => 1,
                                   'IO::Pipe' => 1,
                                   'IO::Handle' => 1,
                                   'IO::Socket::UNIX' => 1,
                                   'IO::Socket::INET' => 1,
                                   'IO' => 1,
                                   'IO::Socket' => 1,
                                   'IO::Select' => 1,
                                   'IO::Poll' => 1,
                                   'IO::Dir' => 1
                                 },
                    'dist_vers' => '1.2301',
                    'cpanid' => 'GBARR',
                    'dist_file' => 'IO-1.2301.tar.gz'
                  },
          'libwww-perl' => {
                             'modules' => {
                                            'LWP::Protocol::cpan' => 1,
                                            'LWP::Protocol::ftp' => 1,
                                            'HTTP::Status' => 1,
                                            'File::Listing' => 1,
                                            'LWP::Protocol::http10' => 1,
                                            'HTTP::Cookies::Microsoft' => 1,
                                            'HTTP::Headers' => 1,
                                            'LWP::Protocol::nogo' => 1,
                                            'LWP::Protocol::nntp' => 1,
                                            'HTTP::Daemon' => 1,
                                            'LWP::Protocol::mailto' => 1,
                                            'HTML::Form' => 1,
                                            'LWP::Protocol::gopher' => 1,
                                            'LWP::ConnCache' => 1,
                                            'Net::HTTPS' => 1,
                                            'HTTP::Cookies' => 1,
                                            'HTTP::Message' => 1,
                                            'HTTP::Request::Common' => 1,
                                            'HTTP::Headers::Auth' => 1,
                                            'LWP::Protocol::loopback' => 1,
                                            'HTTP::Response' => 1,
                                            'HTTP::Cookies::Netscape' => 1,
                                            'LWP::Authen::Ntlm' => 1,
                                            'LWP::Authen::Basic' => 1,
                                            'WWW::RobotRules' => 1,
                                            'LWP::Protocol' => 1,
                                            'HTTP::Request' => 1,
                                            'LWP' => 1,
                                            'LWP::MediaTypes' => 1,
                                            'LWP::Protocol::data' => 1,
                                            'HTTP::Negotiate' => 1,
                                            'LWP::Protocol::https' => 1,
                                            'Net::HTTP::NB' => 1,
                                            'LWP::Simple' => 1,
                                            'LWP::DebugFile' => 1,
                                            'Net::HTTP' => 1,
                                            'LWP::RobotUA' => 1,
                                            'LWP::Protocol::file' => 1,
                                            'HTTP::Headers::Util' => 1,
                                            'HTTP::Headers::ETag' => 1,
                                            'LWP::Authen::Digest' => 1,
                                            'LWP::Protocol::http' => 1,
                                            'HTTP::Date' => 1,
                                            'LWP::MemberMixin' => 1,
                                            'LWP::Protocol::GHTTP' => 1,
                                            'LWP::UserAgent' => 1,
                                            'Bundle::LWP' => 1,
                                            'LWP::Debug' => 1,
                                            'LWP::Protocol::https10' => 1,
                                            'WWW::RobotRules::AnyDBM_File' => 1,
                                            'Net::HTTP::Methods' => 1
                                          },
                             'dist_vers' => '5.805',
                             'cpanid' => 'GAAS',
                             'dist_file' => 'libwww-perl-5.805.tar.gz'
                           },
          'CPAN-Checksums' => {
                                'modules' => {
                                               'CPAN::Checksums' => 1
                                             },
                                'dist_vers' => '1.050',
                                'cpanid' => 'ANDK',
                                'dist_file' => 'CPAN-Checksums-1.050.tar.gz'
                              },
          'libnet' => {
                        'modules' => {
                                       'Net::FTP::dataconn' => 1,
                                       'Net::FTP' => 1,
                                       'Net::FTP::A' => 1,
                                       'Net::POP3' => 1,
                                       'Net::NNTP' => 1,
                                       'Net::Netrc' => 1,
                                       'Net::Cmd' => 1,
                                       'Net::Config' => 1,
                                       'Net::Time' => 1,
                                       'Net::SMTP' => 1,
                                       'Net::FTP::E' => 1,
                                       'Net::FTP::L' => 1,
                                       'Net::FTP::I' => 1,
                                       'Net::Domain' => 1
                                     },
                        'dist_vers' => '1.19',
                        'cpanid' => 'GBARR',
                        'dist_file' => 'libnet-1.19.tar.gz'
                      },
          'CPAN-DistnameInfo' => {
                                   'modules' => {
                                                  'CPAN::DistnameInfo' => 1
                                                },
                                   'dist_vers' => '0.06',
                                   'cpanid' => 'GBARR',
                                   'dist_file' => 'CPAN-DistnameInfo-0.06.tar.gz'
                                 },
          'MIME-Base64' => {
                             'modules' => {
                                            'MIME::Base64' => 1,
                                            'MIME::QuotedPrint' => 1
                                          },
                             'dist_vers' => '3.07',
                             'cpanid' => 'GAAS',
                             'dist_file' => 'MIME-Base64-3.07.tar.gz'
                           },
          'IO-String' => {
                           'modules' => {
                                          'IO::String' => 1
                                        },
                           'dist_vers' => '1.08',
                           'cpanid' => 'GAAS',
                           'dist_file' => 'IO-String-1.08.tar.gz'
                         },
          'perl-lisp' => {
                           'modules' => {
                                          'Lisp::Localize' => 1,
                                          'Lisp::Vector' => 1,
                                          'Lisp::Subr::Perl' => 1,
                                          'Lisp::Printer' => 1,
                                          'Lisp::Subr::All' => 1,
                                          'Lisp::Cons' => 1,
                                          'Lisp::Special' => 1,
                                          'Lisp::String' => 1,
                                          'Lisp::List' => 1,
                                          'Gnus::Newsrc' => 1,
                                          'Lisp::Interpreter' => 1,
                                          'Lisp::Reader' => 1,
                                          'Lisp::Symbol' => 1,
                                          'Lisp::Subr::Core' => 1
                                        },
                           'dist_vers' => '0.06',
                           'cpanid' => 'GAAS',
                           'dist_file' => 'perl-lisp-0.06.tar.gz'
                         },
          'MD5' => {
                     'modules' => {
                                    'MD5' => 1
                                  },
                     'dist_vers' => '2.03',
                     'cpanid' => 'GAAS',
                     'dist_file' => 'MD5-2.03.tar.gz'
                   },
          'MIME-Base64-Perl' => {
                                  'modules' => {
                                                 'MIME::Base64::Perl' => 1,
                                                 'MIME::QuotedPrint::Perl' => 1
                                               },
                                  'dist_vers' => '1.00',
                                  'cpanid' => 'GAAS',
                                  'dist_file' => 'MIME-Base64-Perl-1.00.tar.gz'
                                },
          'File-CounterFile' => {
                                  'modules' => {
                                                 'File::CounterFile' => 1
                                               },
                                  'dist_vers' => '1.04',
                                  'cpanid' => 'GAAS',
                                  'dist_file' => 'File-CounterFile-1.04.tar.gz'
                                },
          'Devel-SawAmpersand' => {
                                    'modules' => {
                                                   'Devel::SawAmpersand' => 1,
                                                   'B::FindAmpersand' => 1,
                                                   'Devel::FindAmpersand' => 1
                                                 },
                                    'dist_vers' => '0.30',
                                    'cpanid' => 'ANDK',
                                    'dist_file' => 'Devel-SawAmpersand-0.30.tar.gz'
                                  },
          'IO-Interface' => {
                              'modules' => {
                                             'IO::Interface::Simple' => 1,
                                             'IO::Interface' => 1
                                           },
                              'dist_vers' => '1.02',
                              'cpanid' => 'LDS',
                              'dist_file' => 'IO-Interface-1.02.tar.gz'
                            },
          'Bundle-libnet' => {
                               'modules' => {
                                              'Bundle::libnet' => 1
                                            },
                               'dist_vers' => '1.00',
                               'cpanid' => 'GBARR',
                               'dist_file' => 'Bundle-libnet-1.00.tar.gz'
                             },
          'Net-PH' => {
                        'modules' => {
                                       'Net::PH' => 1
                                     },
                        'dist_vers' => '2.21',
                        'cpanid' => 'GBARR',
                        'dist_file' => 'Net-PH-2.21.tar.gz'
                      },
          'Unicode-String' => {
                                'modules' => {
                                               'Unicode::String' => 1,
                                               'Unicode::CharName' => 1
                                             },
                                'dist_vers' => '2.09',
                                'cpanid' => 'GAAS',
                                'dist_file' => 'Unicode-String-2.09.tar.gz'
                              },
          'HTTPD-User-Manage' => {
                                   'modules' => {
                                                  'HTTPD::GroupAdmin' => 1,
                                                  'HTTPD::UserAdmin::Text' => 1,
                                                  'HTTPD::RealmManager' => 1,
                                                  'HTTPD::GroupAdmin::Text' => 1,
                                                  'HTTPD::Realm' => 1,
                                                  'HTTPD::UserAdmin::SQL' => 1,
                                                  'HTTPD::UserAdmin' => 1
                                                },
                                   'dist_vers' => '1.65',
                                   'cpanid' => 'LDS',
                                   'dist_file' => 'HTTPD-User-Manage-1.65.tar.gz'
                                 },
          'Unicode-Map8' => {
                              'modules' => {
                                             'Unicode::Map8' => 1
                                           },
                              'dist_vers' => '0.12',
                              'cpanid' => 'GAAS',
                              'dist_file' => 'Unicode-Map8-0.12.tar.gz'
                            },
          'Convert-Recode' => {
                                'modules' => {
                                               'Convert::Recode' => 1
                                             },
                                'dist_vers' => '1.04',
                                'cpanid' => 'GAAS',
                                'dist_file' => 'Convert-Recode-1.04.tar.gz'
                              },
          'Apache-UploadSvr' => {
                                  'modules' => {
                                                 'Apache::UploadSvr::Directory' => 1,
                                                 'Apache::UploadSvr::Dictionary' => 1,
                                                 'Apache::UploadSvr::User' => 1,
                                                 'Apache::UploadSvr' => 1
                                               },
                                  'dist_vers' => '1.024',
                                  'cpanid' => 'ANDK',
                                  'dist_file' => 'Apache-UploadSvr-1.024.tar.gz'
                                },
          'IO-Sockatmark' => {
                               'modules' => {
                                              'IO::Sockatmark' => 1
                                            },
                               'dist_vers' => '1.00',
                               'cpanid' => 'LDS',
                               'dist_file' => 'IO-Sockatmark-1.00.tar.gz'
                             },
          'perl-ldap' => {
                           'modules' => {
                                          'Net::LDAP::LDIF' => 1,
                                          'Net::LDAP::Control::ProxyAuth' => 1,
                                          'Net::LDAP::Filter' => 1,
                                          'Net::LDAP::Control::Paged' => 1,
                                          'Net::LDAP::Message' => 1,
                                          'Net::LDAP::Control::ManageDsaIT' => 1,
                                          'Net::LDAPI' => 1,
                                          'Net::LDAP::Control::PersistentSearch' => 1,
                                          'Net::LDAP::Search' => 1,
                                          'Net::LDAP::Control::SortResult' => 1,
                                          'Net::LDAP::Control' => 1,
                                          'Net::LDAP::Util' => 1,
                                          'LWP::Protocol::ldap' => 1,
                                          'Net::LDAP::Control::VLVResponse' => 1,
                                          'Net::LDAPS' => 1,
                                          'Net::LDAP::Control::EntryChange' => 1,
                                          'Net::LDAP::Constant' => 1,
                                          'Net::LDAP::Entry' => 1,
                                          'Net::LDAP::Control::VLV' => 1,
                                          'Net::LDAP::Schema' => 1,
                                          'Bundle::Net::LDAP' => 1,
                                          'Net::LDAP::Extra' => 1,
                                          'Net::LDAP::ASN' => 1,
                                          'Net::LDAP::Extension::WhoAmI' => 1,
                                          'Net::LDAP::Extension::SetPassword' => 1,
                                          'Net::LDAP::RootDSE' => 1,
                                          'Net::LDAP::Extension' => 1,
                                          'Net::LDAP::Bind' => 1,
                                          'Net::LDAP' => 1,
                                          'Net::LDAP::Control::Sort' => 1,
                                          'Net::LDAP::DSML' => 1
                                        },
                           'dist_vers' => '0.33',
                           'cpanid' => 'GBARR',
                           'dist_file' => 'perl-ldap-0.33.tar.gz'
                         },
          'Scalar-List-Utils' => {
                                   'modules' => {
                                                  'Scalar::Util' => 1,
                                                  'List::Util' => 1
                                                },
                                   'dist_vers' => '1.18',
                                   'cpanid' => 'GBARR',
                                   'dist_file' => 'Scalar-List-Utils-1.18.tar.gz'
                                 },
          'Lingua-Shakespeare' => {
                                    'modules' => {
                                                   'Lingua::Shakespeare::Play' => 1,
                                                   'Lingua::Shakespeare::Character' => 1,
                                                   'Lingua::Shakespeare' => 1
                                                 },
                                    'dist_vers' => '1.00',
                                    'cpanid' => 'GBARR',
                                    'dist_file' => 'Lingua-Shakespeare-1.00.tar.gz'
                                  },
          'Digest-Adler32' => {
                                'modules' => {
                                               'Digest::Adler32' => 1
                                             },
                                'dist_vers' => '0.03',
                                'cpanid' => 'GAAS',
                                'dist_file' => 'Digest-Adler32-0.03.tar.gz'
                              },
          'CPAN-Test-Dummy-Perl5-BuildOrMake' => {
                                                   'modules' => {
                                                                  'CPAN::Test::Dummy::Perl5::BuildOrMake' => 1
                                                                },
                                                   'dist_vers' => '1.02',
                                                   'cpanid' => 'ANDK',
                                                   'dist_file' => 'CPAN-Test-Dummy-Perl5-BuildOrMake-1.02.tar.gz'
                                                 },
          'Digest-MD5' => {
                            'modules' => {
                                           'Digest::MD5' => 1
                                         },
                            'dist_vers' => '2.36',
                            'cpanid' => 'GAAS',
                            'dist_file' => 'Digest-MD5-2.36.tar.gz'
                          },
          'Array-RefElem' => {
                               'modules' => {
                                              'Array::RefElem' => 1
                                            },
                               'dist_vers' => '1.00',
                               'cpanid' => 'GAAS',
                               'dist_file' => 'Array-RefElem-1.00.tar.gz'
                             },
          'Digest' => {
                        'modules' => {
                                       'Digest' => 1,
                                       'Digest::file' => 1,
                                       'Digest::base' => 1
                                     },
                        'dist_vers' => '1.15',
                        'cpanid' => 'GAAS',
                        'dist_file' => 'Digest-1.15.tar.gz'
                      },
          'Module-Install-InstallDirs' => {
                                            'modules' => {
                                                           'Module::Install::InstallDirs' => 1
                                                         },
                                            'dist_vers' => '0.01',
                                            'cpanid' => 'GBARR',
                                            'dist_file' => 'Module-Install-InstallDirs-0.01.tar.gz'
                                          },
          'Convert-UU' => {
                            'modules' => {
                                           'Convert::UU' => 1
                                         },
                            'dist_vers' => '0.52',
                            'cpanid' => 'ANDK',
                            'dist_file' => 'Convert-UU-0.52.tar.gz'
                          },
          'CPAN-Test-Dummy-Perl5-Make-CircDepeOne' => {
                                                        'modules' => {
                                                                       'CPAN::Test::Dummy::Perl5::Make::CircDepeOne' => 1
                                                                     },
                                                        'dist_vers' => '1.00',
                                                        'cpanid' => 'ANDK',
                                                        'dist_file' => 'CPAN-Test-Dummy-Perl5-Make-CircDepeOne-1.00.tar.gz'
                                                      },
          'CPAN-Test-Dummy-Perl5-Build' => {
                                             'modules' => {
                                                            'CPAN::Test::Dummy::Perl5::Build' => 1
                                                          },
                                             'dist_vers' => '1.03',
                                             'cpanid' => 'ANDK',
                                             'dist_file' => 'CPAN-Test-Dummy-Perl5-Build-1.03.tar.gz'
                                           },
          'Norge' => {
                       'modules' => {
                                      'No::KontoNr' => 1,
                                      'No::PersonNr' => 1,
                                      'No::Sort' => 1,
                                      'No::Dato' => 1
                                    },
                       'dist_vers' => '1.08',
                       'cpanid' => 'GAAS',
                       'dist_file' => 'Norge-1.08.tar.gz'
                     },
          'rlib' => {
                      'modules' => {
                                     'rlib' => 1
                                   },
                      'dist_vers' => '0.02',
                      'cpanid' => 'GBARR',
                      'dist_file' => 'rlib-0.02.tar.gz'
                    },
          'LWP-attic' => {
                           'modules' => {
                                          'LWP::Socket' => 1,
                                          'LWP::SecureSocket' => 1
                                        },
                           'dist_vers' => '1.00',
                           'cpanid' => 'GAAS',
                           'dist_file' => 'LWP-attic-1.00.tar.gz'
                         },
          'Authen-SASL' => {
                             'modules' => {
                                            'Authen::SASL::Perl::DIGEST_MD5' => 1,
                                            'Authen::SASL::Perl::CRAM_MD5' => 1,
                                            'Authen::SASL::Perl' => 1,
                                            'Authen::SASL' => 1,
                                            'Authen::SASL::Perl::GSSAPI' => 1,
                                            'Authen::SASL::Perl::ANONYMOUS' => 1,
                                            'Authen::SASL::EXTERNAL' => 1,
                                            'Authen::SASL::CRAM_MD5' => 1,
                                            'Authen::SASL::Perl::PLAIN' => 1,
                                            'Authen::SASL::Perl::LOGIN' => 1,
                                            'Authen::SASL::Perl::EXTERNAL' => 1
                                          },
                             'dist_vers' => '2.10',
                             'cpanid' => 'GBARR',
                             'dist_file' => 'Authen-SASL-2.10.tar.gz'
                           },
          'Bio-Das' => {
                         'modules' => {
                                        'Bio::Das' => 1,
                                        'Bio::Das::Request::Dsn' => 1,
                                        'Bio::Das::AGPServer::Daemon' => 1,
                                        'Bio::Das::TypeHandler' => 1,
                                        'Bio::Das::HTTP::Fetch' => 1,
                                        'Bio::Das::AGPServer::SQLStorage::MySQL::DB' => 1,
                                        'Bio::Das::Request::Types' => 1,
                                        'Bio::Das::Request' => 1,
                                        'Bio::Das::Request::Dnas' => 1,
                                        'Bio::Das::DSN' => 1,
                                        'Bio::Das::Stylesheet' => 1,
                                        'Bio::Das::AGPServer::Parser' => 1,
                                        'Bio::Das::Util' => 1,
                                        'Bio::Das::FeatureIterator' => 1,
                                        'Bio::Das::Map' => 1,
                                        'Bio::Das::AGPServer::Config' => 1,
                                        'Bio::Das::Request::Stylesheet' => 1,
                                        'Bio::Das::Request::Entry_points' => 1,
                                        'Bio::Das::Request::Features' => 1,
                                        'Bio::Das::Type' => 1,
                                        'Bio::Das::Request::Sequences' => 1,
                                        'Bio::Das::Segment' => 1,
                                        'Bio::Das::AGPServer::SQLStorage' => 1,
                                        'Bio::Das::Feature' => 1,
                                        'Bio::Das::AGPServer::SQLStorage::CSV::DB' => 1,
                                        'Bio::Das::Request::Feature2Segments' => 1
                                      },
                         'dist_vers' => '1.03',
                         'cpanid' => 'LDS',
                         'dist_file' => 'Bio-Das-1.03.tar.gz'
                       },
          'Include' => {
                         'modules' => {
                                        'Include' => 1
                                      },
                         'dist_vers' => '1.02a',
                         'cpanid' => 'GBARR',
                         'dist_file' => 'Include-1.02a.tar.gz'
                       },
          'Boulder' => {
                         'modules' => {
                                        'Boulder::Genbank' => 1,
                                        'Boulder::LocusLink' => 1,
                                        'Boulder::Medline' => 1,
                                        'Stone' => 1,
                                        'Boulder::Stream' => 1,
                                        'Boulder::Swissprot' => 1,
                                        'Boulder::String' => 1,
                                        'Boulder::Blast::WU' => 1,
                                        'Stone::Cursor' => 1,
                                        'Stone::GB_Sequence' => 1,
                                        'Boulder::Blast::NCBI' => 1,
                                        'Boulder::Store' => 1,
                                        'Boulder::Blast' => 1
                                      },
                         'dist_vers' => '1.30',
                         'cpanid' => 'LDS',
                         'dist_file' => 'Boulder-1.30.tar.gz'
                       },
          'Bundle-MP3' => {
                            'modules' => {
                                           'Bundle::MP3' => 1
                                         },
                            'dist_vers' => '1.00',
                            'cpanid' => 'LDS',
                            'dist_file' => 'Bundle-MP3-1.00.tar.gz'
                          },
          'CPAN' => {
                      'modules' => {
                                     'CPAN::Nox' => 1,
                                     'CPAN::FirstTime' => 1,
                                     'CPAN::Tarzip' => 1,
                                     'CPAN::Debug' => 1,
                                     'CPAN::Version' => 1,
                                     'CPAN::Admin' => 1,
                                     'CPAN' => 1,
                                     'CPAN::HandleConfig' => 1
                                   },
                      'dist_vers' => '1.8802',
                      'cpanid' => 'ANDK',
                      'dist_file' => 'CPAN-1.8802.tar.gz'
                    },
          'DB_File-SV18x-kit' => {
                                   'modules' => {
                                                  'DB_File::SV18x' => 1
                                                },
                                   'dist_vers' => '0.06',
                                   'cpanid' => 'ANDK',
                                   'dist_file' => 'DB_File-SV18x-kit-0.06.tar.gz'
                                 },
          'Data-Dump' => {
                           'modules' => {
                                          'Data::Dump' => 1
                                        },
                           'dist_vers' => '1.06',
                           'cpanid' => 'GAAS',
                           'dist_file' => 'Data-Dump-1.06.tar.gz'
                         },
          'CGI' => {
                        'modules' => {
                                       'CGI::Fast' => 1,
                                       'CGI::Cookie' => 1,
                                       'CGI::Util' => 1,
                                       'CGI::Pretty' => 1,
                                       'CGI::Push' => 1,
                                       'CGI' => 1,
                                       'CGI::Carp' => 1
                                     },
                        'dist_vers' => '3.25',
                        'cpanid' => 'LDS',
                        'dist_file' => 'CGI.pm-3.25.tar.gz'
                      }
        };
$mods = {
          'Apache::MP3::L10N::ms' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'Net::LDAP::LDIF' => {
                                 'dist_name' => 'perl-ldap',
                                 'mod_vers' => '0.16'
                               },
          'URI::QueryParam' => {
                                 'dist_name' => 'URI',
                                 'mod_vers' => undef
                               },
          'Apache::GzipChain' => {
                                   'dist_name' => 'Apache-GzipChain',
                                   'mod_vers' => '1.14'
                                 },
          'Lingua::Shakespeare' => {
                                     'dist_name' => 'Lingua-Shakespeare',
                                     'mod_vers' => '1.00'
                                   },
          'Tie::MAB2::Dualdb::Recno' => {
                                          'dist_name' => 'MAB2',
                                          'mod_vers' => '1.006'
                                        },
          'Bio::Das::Request' => {
                                   'dist_name' => 'Bio-Das',
                                   'mod_vers' => undef
                                 },
          'CPAN::Test::Dummy::Perl5::Build' => {
                                                 'dist_name' => 'CPAN-Test-Dummy-Perl5-Build',
                                                 'mod_vers' => '1.03'
                                               },
          'Ace::Graphics::Glyph::crossbox' => {
                                                'dist_name' => 'AcePerl',
                                                'mod_vers' => undef
                                              },
          'LWP::Sink::base64' => {
                                   'dist_name' => 'LWPng-alpha',
                                   'mod_vers' => undef
                                 },
          'URI::Split' => {
                            'dist_name' => 'URI',
                            'mod_vers' => undef
                          },
          'DB_File::SV18x' => {
                                'dist_name' => 'DB_File-SV18x-kit',
                                'mod_vers' => '0.06'
                              },
          'Apache::HeavyCGI::SquidRemoteAddr' => {
                                                   'dist_name' => 'Apache-HeavyCGI',
                                                   'mod_vers' => '1.005'
                                                 },
          'Apache::MP3::L10N::ru' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'Ace::Graphics::Glyph::triangle' => {
                                                'dist_name' => 'AcePerl',
                                                'mod_vers' => undef
                                              },
          'Net::LDAP::Control::Paged' => {
                                           'dist_name' => 'perl-ldap',
                                           'mod_vers' => '0.02'
                                         },
          'URI::_query' => {
                             'dist_name' => 'URI',
                             'mod_vers' => undef
                           },
          'Apache::MP3::L10N::RightToLeft' => {
                                                'dist_name' => 'Apache-MP3',
                                                'mod_vers' => '20020610'
                                              },
          'URI::file::QNX' => {
                                'dist_name' => 'URI',
                                'mod_vers' => undef
                              },
          'IO::Poll' => {
                          'dist_name' => 'IO',
                          'mod_vers' => '0.07'
                        },
          'File::CounterFile' => {
                                   'dist_name' => 'File-CounterFile',
                                   'mod_vers' => '1.04'
                                 },
          'Ace::Sequence::Homol' => {
                                      'dist_name' => 'AcePerl',
                                      'mod_vers' => undef
                                    },
          'Lisp::Localize' => {
                                'dist_name' => 'perl-lisp',
                                'mod_vers' => undef
                              },
          'Net::FTP::A' => {
                             'dist_name' => 'libnet',
                             'mod_vers' => '1.16'
                           },
          'Apache::MP3::Sorted' => {
                                     'dist_name' => 'Apache-MP3',
                                     'mod_vers' => '2.02'
                                   },
          'Convert::BER' => {
                              'dist_name' => 'Convert-BER',
                              'mod_vers' => '1.31'
                            },
          'Apache::Stage' => {
                               'dist_name' => 'Apache-Stage',
                               'mod_vers' => '1.20'
                             },
          'Lingua::Shakespeare::Character' => {
                                                'dist_name' => 'Lingua-Shakespeare',
                                                'mod_vers' => undef
                                              },
          'No::Sort' => {
                          'dist_name' => 'Norge',
                          'mod_vers' => '1.03'
                        },
          'Apache::HeavyCGI::ExePlan' => {
                                           'dist_name' => 'Apache-HeavyCGI',
                                           'mod_vers' => '1.010'
                                         },
          'Font::Metrics::TimesBold' => {
                                          'dist_name' => 'Font-AFM',
                                          'mod_vers' => undef
                                        },
          'IO::Pipe' => {
                          'dist_name' => 'IO',
                          'mod_vers' => '1.13'
                        },
          'Date::Language::Afar' => {
                                      'dist_name' => 'TimeDate',
                                      'mod_vers' => '0.99'
                                    },
          'CGI::Util' => {
                           'dist_name' => 'CGI',
                           'mod_vers' => '1.5'
                         },
          'LWP::Sink::Tee' => {
                                'dist_name' => 'LWPng-alpha',
                                'mod_vers' => undef
                              },
          'HTML::PullParser' => {
                                  'dist_name' => 'HTML-Parser',
                                  'mod_vers' => '2.09'
                                },
          'Ace::Freesubs' => {
                               'dist_name' => 'AcePerl',
                               'mod_vers' => '1.00'
                             },
          'URI::rtsp' => {
                           'dist_name' => 'URI',
                           'mod_vers' => undef
                         },
          'URI::urn::oid' => {
                               'dist_name' => 'URI',
                               'mod_vers' => undef
                             },
          'LWP::Socket' => {
                             'dist_name' => 'LWP-attic',
                             'mod_vers' => '1.24'
                           },
          'List::Util' => {
                            'dist_name' => 'Scalar-List-Utils',
                            'mod_vers' => '1.18'
                          },
          'URI::https' => {
                            'dist_name' => 'URI',
                            'mod_vers' => undef
                          },
          'Tie::RDBM' => {
                           'dist_name' => 'Tie-DBI',
                           'mod_vers' => '0.70'
                         },
          'HTTPD::UserAdmin' => {
                                  'dist_name' => 'HTTPD-User-Manage',
                                  'mod_vers' => '1.51'
                                },
          'Ace::Graphics::Glyph::transcript' => {
                                                  'dist_name' => 'AcePerl',
                                                  'mod_vers' => undef
                                                },
          'Net::LDAP::Constant' => {
                                     'dist_name' => 'perl-ldap',
                                     'mod_vers' => '0.04'
                                   },
          'URI::mms' => {
                          'dist_name' => 'URI',
                          'mod_vers' => undef
                        },
          'Net::Netrc' => {
                            'dist_name' => 'libnet',
                            'mod_vers' => '2.12'
                          },
          'URI::ssh' => {
                          'dist_name' => 'URI',
                          'mod_vers' => undef
                        },
          'Authen::SASL::Perl::EXTERNAL' => {
                                              'dist_name' => 'Authen-SASL',
                                              'mod_vers' => '1.03'
                                            },
          'IO::Interface::Simple' => {
                                       'dist_name' => 'IO-Interface',
                                       'mod_vers' => undef
                                     },
          'Boulder::LocusLink' => {
                                    'dist_name' => 'Boulder',
                                    'mod_vers' => '1'
                                  },
          'URI::file::Win32' => {
                                  'dist_name' => 'URI',
                                  'mod_vers' => undef
                                },
          'Apache::MP3::L10N::nb' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'Tkx::LabEntry' => {
                               'dist_name' => 'Tkx',
                               'mod_vers' => undef
                             },
          'Convert::ASN1' => {
                               'dist_name' => 'Convert-ASN1',
                               'mod_vers' => '0.20'
                             },
          'Apache::MP3::L10N::sk' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'Lingua::Shakespeare::Play' => {
                                           'dist_name' => 'Lingua-Shakespeare',
                                           'mod_vers' => undef
                                         },
          'LWP::Sink' => {
                           'dist_name' => 'LWPng-alpha',
                           'mod_vers' => undef
                         },
          'LWP::Protocol::GHTTP' => {
                                      'dist_name' => 'libwww-perl',
                                      'mod_vers' => undef
                                    },
          'Ace::Iterator' => {
                               'dist_name' => 'AcePerl',
                               'mod_vers' => '1.51'
                             },
          'Date::Language::Brazilian' => {
                                           'dist_name' => 'TimeDate',
                                           'mod_vers' => '1.01'
                                         },
          'Net::LDAP::Control::Sort' => {
                                          'dist_name' => 'perl-ldap',
                                          'mod_vers' => '0.02'
                                        },
          'Ace::Sequence::Multi' => {
                                      'dist_name' => 'AcePerl',
                                      'mod_vers' => undef
                                    },
          'HTTPD::GroupAdmin::Text' => {
                                         'dist_name' => 'HTTPD-User-Manage',
                                         'mod_vers' => '1.2'
                                       },
          'Authen::SASL' => {
                              'dist_name' => 'Authen-SASL',
                              'mod_vers' => '2.10'
                            },
          'LWP::UA::Cookies' => {
                                  'dist_name' => 'LWPng-alpha',
                                  'mod_vers' => undef
                                },
          'GD::Simple' => {
                            'dist_name' => 'GD',
                            'mod_vers' => undef
                          },
          'URI::file::Base' => {
                                 'dist_name' => 'URI',
                                 'mod_vers' => undef
                               },
          'GD' => {
                    'dist_name' => 'GD',
                    'mod_vers' => '2.35'
                  },
          'Boulder::Blast::NCBI' => {
                                      'dist_name' => 'Boulder',
                                      'mod_vers' => '1.02'
                                    },
          'Net::FTP::I' => {
                             'dist_name' => 'libnet',
                             'mod_vers' => '1.12'
                           },
          'LWP::Protocol::mailto' => {
                                       'dist_name' => 'libwww-perl',
                                       'mod_vers' => undef
                                     },
          'Errno' => {
                       'dist_name' => 'Errno',
                       'mod_vers' => '1.09'
                     },
          'Bio::Das::Stylesheet' => {
                                      'dist_name' => 'Bio-Das',
                                      'mod_vers' => '1.00'
                                    },
          'HTTP::Message' => {
                               'dist_name' => 'libwww-perl',
                               'mod_vers' => '1.57'
                             },
          'Apache::UploadSvr' => {
                                   'dist_name' => 'Apache-UploadSvr',
                                   'mod_vers' => '1.024'
                                 },
          'HTTP::Headers::Auth' => {
                                     'dist_name' => 'libwww-perl',
                                     'mod_vers' => '1.04'
                                   },
          'Ace::Sequence' => {
                               'dist_name' => 'AcePerl',
                               'mod_vers' => '1.51'
                             },
          'PerlBench::Results' => {
                                    'dist_name' => 'perlbench',
                                    'mod_vers' => undef
                                  },
          'Lisp::Printer' => {
                               'dist_name' => 'perl-lisp',
                               'mod_vers' => '1.07'
                             },
          'Date::Language::TigrinyaEritrean' => {
                                                  'dist_name' => 'TimeDate',
                                                  'mod_vers' => '1.00'
                                                },
          'Ace::Graphics::Track' => {
                                      'dist_name' => 'AcePerl',
                                      'mod_vers' => undef
                                    },
          'Ace::Object' => {
                             'dist_name' => 'AcePerl',
                             'mod_vers' => '1.66'
                           },
          'URI::nntp' => {
                           'dist_name' => 'URI',
                           'mod_vers' => undef
                         },
          'Regexp' => {
                        'dist_name' => 'Regexp',
                        'mod_vers' => '0.004'
                      },
          'LWP::RobotUA' => {
                              'dist_name' => 'libwww-perl',
                              'mod_vers' => '1.27'
                            },
          'Bundle::Net::LDAP' => {
                                   'dist_name' => 'perl-ldap',
                                   'mod_vers' => '0.02'
                                 },
          'Ace::Local' => {
                            'dist_name' => 'AcePerl',
                            'mod_vers' => '1.05'
                          },
          'LWP::Conn' => {
                           'dist_name' => 'LWPng-alpha',
                           'mod_vers' => undef
                         },
          'Boulder::Medline' => {
                                  'dist_name' => 'Boulder',
                                  'mod_vers' => '1.02'
                                },
          'LWP::Sink::IO' => {
                               'dist_name' => 'LWPng-alpha',
                               'mod_vers' => undef
                             },
          'Lisp::Cons' => {
                            'dist_name' => 'perl-lisp',
                            'mod_vers' => undef
                          },
          'Authen::SASL::Perl::ANONYMOUS' => {
                                               'dist_name' => 'Authen-SASL',
                                               'mod_vers' => '1.03'
                                             },
          'Net::NNTP' => {
                           'dist_name' => 'libnet',
                           'mod_vers' => '2.23'
                         },
          'Boulder::Swissprot' => {
                                    'dist_name' => 'Boulder',
                                    'mod_vers' => '1'
                                  },
          'IO' => {
                    'dist_name' => 'IO',
                    'mod_vers' => '1.23'
                  },
          'Unicode::CharName' => {
                                   'dist_name' => 'Unicode-String',
                                   'mod_vers' => '1.07'
                                 },
          'LWP::StdSched' => {
                               'dist_name' => 'LWPng-alpha',
                               'mod_vers' => undef
                             },
          'LWP::Version' => {
                              'dist_name' => 'LWPng-alpha',
                              'mod_vers' => '0.24'
                            },
          'Font::Metrics::TimesRoman' => {
                                           'dist_name' => 'Font-AFM',
                                           'mod_vers' => undef
                                         },
          'Digest::base' => {
                              'dist_name' => 'Digest',
                              'mod_vers' => '1.00'
                            },
          'Apache::HeavyCGI::Date' => {
                                        'dist_name' => 'Apache-HeavyCGI',
                                        'mod_vers' => '1.003'
                                      },
          'LWP::Sink::Buffer' => {
                                   'dist_name' => 'LWPng-alpha',
                                   'mod_vers' => undef
                                 },
          'Font::Metrics::Courier' => {
                                        'dist_name' => 'Font-AFM',
                                        'mod_vers' => undef
                                      },
          'Ace::Sequence::Feature' => {
                                        'dist_name' => 'AcePerl',
                                        'mod_vers' => undef
                                      },
          'UDDI::SOAP' => {
                            'dist_name' => 'UDDI',
                            'mod_vers' => undef
                          },
          'CPAN::FirstTime' => {
                                 'dist_name' => 'CPAN',
                                 'mod_vers' => '5.400879'
                               },
          'MAB2::Record::titel' => {
                                     'dist_name' => 'MAB2',
                                     'mod_vers' => '0.01'
                                   },
          'Font::Metrics::HelveticaOblique' => {
                                                 'dist_name' => 'Font-AFM',
                                                 'mod_vers' => undef
                                               },
          'Apache::MP3::L10N::pl' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'URI::urn' => {
                          'dist_name' => 'URI',
                          'mod_vers' => undef
                        },
          'Stone::GB_Sequence' => {
                                    'dist_name' => 'Boulder',
                                    'mod_vers' => undef
                                  },
          'PostScript::EPSF' => {
                                  'dist_name' => 'PostScript-EPSF',
                                  'mod_vers' => '0.01'
                                },
          'URI::sip' => {
                          'dist_name' => 'URI',
                          'mod_vers' => '0.10'
                        },
          'Ace::SocketServer' => {
                                   'dist_name' => 'AcePerl',
                                   'mod_vers' => '1.01'
                                 },
          'Font::Metrics::HelveticaBoldOblique' => {
                                                     'dist_name' => 'Font-AFM',
                                                     'mod_vers' => undef
                                                   },
          'URI::telnet' => {
                             'dist_name' => 'URI',
                             'mod_vers' => undef
                           },
          'Stone' => {
                       'dist_name' => 'Boulder',
                       'mod_vers' => '1.30'
                     },
          'Net::LDAP::ASN' => {
                                'dist_name' => 'perl-ldap',
                                'mod_vers' => '0.03'
                              },
          'LWP::Sink::qp' => {
                               'dist_name' => 'LWPng-alpha',
                               'mod_vers' => undef
                             },
          'HTTP::Headers::ETag' => {
                                     'dist_name' => 'libwww-perl',
                                     'mod_vers' => '1.04'
                                   },
          'Bio::Das::FeatureIterator' => {
                                           'dist_name' => 'Bio-Das',
                                           'mod_vers' => '0.01'
                                         },
          'IPC::Semaphore' => {
                                'dist_name' => 'IPC-SysV',
                                'mod_vers' => '1.00'
                              },
          'URI::_ldap' => {
                            'dist_name' => 'URI',
                            'mod_vers' => '1.10'
                          },
          'Python::Object' => {
                                'dist_name' => 'pyperl',
                                'mod_vers' => '1.00'
                              },
          'IPC::SysV' => {
                           'dist_name' => 'IPC-SysV',
                           'mod_vers' => '1.03'
                         },
          'Apache::MP3::L10N::it' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'WWW::RobotRules::AnyDBM_File' => {
                                              'dist_name' => 'libwww-perl',
                                              'mod_vers' => '1.11'
                                            },
          'Apache::HeavyCGI::UnmaskQuery' => {
                                               'dist_name' => 'Apache-HeavyCGI',
                                               'mod_vers' => '1.011'
                                             },
          'URI::pop' => {
                          'dist_name' => 'URI',
                          'mod_vers' => undef
                        },
          'IO::Socket::INET' => {
                                  'dist_name' => 'IO',
                                  'mod_vers' => '1.31'
                                },
          'Date::Language::Amharic' => {
                                         'dist_name' => 'TimeDate',
                                         'mod_vers' => '1.00'
                                       },
          'Ace::Sequence::Gene' => {
                                     'dist_name' => 'AcePerl',
                                     'mod_vers' => undef
                                   },
          'Ace::Object::Wormbase' => {
                                       'dist_name' => 'AcePerl',
                                       'mod_vers' => undef
                                     },
          'Data::Dump' => {
                            'dist_name' => 'Data-Dump',
                            'mod_vers' => '1.06'
                          },
          'Net::LDAP::Util' => {
                                 'dist_name' => 'perl-ldap',
                                 'mod_vers' => '0.10'
                               },
          'HTTP::Daemon' => {
                              'dist_name' => 'libwww-perl',
                              'mod_vers' => '1.36'
                            },
          'Net::LDAP::Entry' => {
                                  'dist_name' => 'perl-ldap',
                                  'mod_vers' => '0.22'
                                },
          'URI::_login' => {
                             'dist_name' => 'URI',
                             'mod_vers' => undef
                           },
          'SHA' => {
                     'dist_name' => 'SHA',
                     'mod_vers' => '2.01'
                   },
          'Ace::Model' => {
                            'dist_name' => 'AcePerl',
                            'mod_vers' => '1.51'
                          },
          'Boulder::Stream' => {
                                 'dist_name' => 'Boulder',
                                 'mod_vers' => '1.07'
                               },
          'Authen::SASL::CRAM_MD5' => {
                                        'dist_name' => 'Authen-SASL',
                                        'mod_vers' => '0.99'
                                      },
          'Date::Language::French' => {
                                        'dist_name' => 'TimeDate',
                                        'mod_vers' => '1.04'
                                      },
          'Bio::Das::Request::Feature2Segments' => {
                                                     'dist_name' => 'Bio-Das',
                                                     'mod_vers' => undef
                                                   },
          'URI::Escape' => {
                             'dist_name' => 'URI',
                             'mod_vers' => '3.28'
                           },
          'LWP::Sink::_Pipe' => {
                                  'dist_name' => 'LWPng-alpha',
                                  'mod_vers' => undef
                                },
          'UDDI' => {
                      'dist_name' => 'UDDI',
                      'mod_vers' => '0.03'
                    },
          'Convert::BER::BER' => {
                                   'dist_name' => 'Convert-BER',
                                   'mod_vers' => '1.31'
                                 },
          'No::PersonNr' => {
                              'dist_name' => 'Norge',
                              'mod_vers' => '1.17'
                            },
          'Net::HTTP::NB' => {
                               'dist_name' => 'libwww-perl',
                               'mod_vers' => '0.03'
                             },
          'Devel::Cycle' => {
                              'dist_name' => 'Devel-Cycle',
                              'mod_vers' => '1.07'
                            },
          'Apache::MP3::L10N::x_marklar' => {
                                              'dist_name' => 'Apache-MP3',
                                              'mod_vers' => '20020612'
                                            },
          'Bio::Das::AGPServer::Parser' => {
                                             'dist_name' => 'Bio-Das',
                                             'mod_vers' => undef
                                           },
          'LWP::Protocol::file' => {
                                     'dist_name' => 'libwww-perl',
                                     'mod_vers' => undef
                                   },
          'GFF::Filehandle' => {
                                 'dist_name' => 'AcePerl',
                                 'mod_vers' => undef
                               },
          'Lisp::Subr::All' => {
                                 'dist_name' => 'perl-lisp',
                                 'mod_vers' => undef
                               },
          'Boulder::Blast::WU' => {
                                    'dist_name' => 'Boulder',
                                    'mod_vers' => '1'
                                  },
          'URI::snews' => {
                            'dist_name' => 'URI',
                            'mod_vers' => undef
                          },
          'Net::LDAP' => {
                           'dist_name' => 'perl-ldap',
                           'mod_vers' => '0.33'
                         },
          'URI::news' => {
                           'dist_name' => 'URI',
                           'mod_vers' => undef
                         },
          'HTTPD::RealmManager' => {
                                     'dist_name' => 'HTTPD-User-Manage',
                                     'mod_vers' => '1.33'
                                   },
          'Tie::MAB2::RecnoViaId' => {
                                       'dist_name' => 'MAB2',
                                       'mod_vers' => '0.30'
                                     },
          'Net::LDAP::Control::ManageDsaIT' => {
                                                 'dist_name' => 'perl-ldap',
                                                 'mod_vers' => '0.01'
                                               },
          'Font::Metrics::Helvetica' => {
                                          'dist_name' => 'Font-AFM',
                                          'mod_vers' => undef
                                        },
          'URI::file::Mac' => {
                                'dist_name' => 'URI',
                                'mod_vers' => undef
                              },
          'Net::LDAPI' => {
                            'dist_name' => 'perl-ldap',
                            'mod_vers' => '0.02'
                          },
          'File::Listing' => {
                               'dist_name' => 'libwww-perl',
                               'mod_vers' => '1.15'
                             },
          'URI::rtspu' => {
                            'dist_name' => 'URI',
                            'mod_vers' => undef
                          },
          'Digest::Adler32' => {
                                 'dist_name' => 'Digest-Adler32',
                                 'mod_vers' => '0.03'
                               },
          'CGI::Carp' => {
                           'dist_name' => 'CGI',
                           'mod_vers' => '1.29'
                         },
          'LWP::ConnCache' => {
                                'dist_name' => 'libwww-perl',
                                'mod_vers' => '0.01'
                              },
          'Ace::Sequence::FeatureList' => {
                                            'dist_name' => 'AcePerl',
                                            'mod_vers' => undef
                                          },
          'CPAN::Debug' => {
                             'dist_name' => 'CPAN',
                             'mod_vers' => '5.400844'
                           },
          'Net::LDAP::Extension::SetPassword' => {
                                                   'dist_name' => 'perl-ldap',
                                                   'mod_vers' => '0.02'
                                                 },
          'Bio::Das::Segment' => {
                                   'dist_name' => 'Bio-Das',
                                   'mod_vers' => '0.9'
                                 },
          'LWP::Protocol' => {
                               'dist_name' => 'libwww-perl',
                               'mod_vers' => '1.43'
                             },
          'Boulder::Blast' => {
                                'dist_name' => 'Boulder',
                                'mod_vers' => '1.01'
                              },
          'Net::LDAP::DSML' => {
                                 'dist_name' => 'perl-ldap',
                                 'mod_vers' => '0.12'
                               },
          'Apache::MP3::L10N::ko' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'Date::Language::Greek' => {
                                       'dist_name' => 'TimeDate',
                                       'mod_vers' => '1.00'
                                     },
          'Scalar::Util' => {
                              'dist_name' => 'Scalar-List-Utils',
                              'mod_vers' => '1.18'
                            },
          'Apache::MP3::L10N::is' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'Apache::HeavyCGI::IfModified' => {
                                              'dist_name' => 'Apache-HeavyCGI',
                                              'mod_vers' => '1.001'
                                            },
          'Font::AFM' => {
                           'dist_name' => 'Font-AFM',
                           'mod_vers' => '1.19'
                         },
          'Date::Language::Tigrinya' => {
                                          'dist_name' => 'TimeDate',
                                          'mod_vers' => '1.00'
                                        },
          'Bio::Das::Request::Dnas' => {
                                         'dist_name' => 'Bio-Das',
                                         'mod_vers' => undef
                                       },
          'Net::LDAP::Control::EntryChange' => {
                                                 'dist_name' => 'perl-ldap',
                                                 'mod_vers' => '0.01'
                                               },
          'Apache::MP3::L10N::nb_no' => {
                                          'dist_name' => 'Apache-MP3',
                                          'mod_vers' => undef
                                        },
          'LWP::DebugFile' => {
                                'dist_name' => 'libwww-perl',
                                'mod_vers' => undef
                              },
          'Digest::SHA1' => {
                              'dist_name' => 'Digest-SHA1',
                              'mod_vers' => '2.11'
                            },
          'LWP::Server' => {
                             'dist_name' => 'LWPng-alpha',
                             'mod_vers' => undef
                           },
          'Date::Language::Czech' => {
                                       'dist_name' => 'TimeDate',
                                       'mod_vers' => '1.01'
                                     },
          'LWP::Protocol::ftp' => {
                                    'dist_name' => 'libwww-perl',
                                    'mod_vers' => undef
                                  },
          'Date::Language' => {
                                'dist_name' => 'TimeDate',
                                'mod_vers' => '1.10'
                              },
          'Apache::HeavyCGI::Debug' => {
                                         'dist_name' => 'Apache-HeavyCGI',
                                         'mod_vers' => undef
                                       },
          'CPAN::Version' => {
                               'dist_name' => 'CPAN',
                               'mod_vers' => '5.400844'
                             },
          'HTTP::Headers' => {
                               'dist_name' => 'libwww-perl',
                               'mod_vers' => '1.64'
                             },
          'MAB2::Record::Base' => {
                                    'dist_name' => 'MAB2',
                                    'mod_vers' => '0.03'
                                  },
          'LWP::Protocol::ldap' => {
                                     'dist_name' => 'perl-ldap',
                                     'mod_vers' => '1.10'
                                   },
          'Devel::Symdump::Export' => {
                                        'dist_name' => 'Devel-Symdump',
                                        'mod_vers' => undef
                                      },
          'IO::File' => {
                          'dist_name' => 'IO',
                          'mod_vers' => '1.14'
                        },
          'URI::rlogin' => {
                             'dist_name' => 'URI',
                             'mod_vers' => undef
                           },
          'MAB2::Record::lokal' => {
                                     'dist_name' => 'MAB2',
                                     'mod_vers' => '0.01'
                                   },
          'LWP::Conn::FILE' => {
                                 'dist_name' => 'LWPng-alpha',
                                 'mod_vers' => undef
                               },
          'Bundle::CpanTestDummies' => {
                                         'dist_name' => 'CPAN-Test-Dummy-Perl5-Make',
                                         'mod_vers' => '1.600967'
                                       },
          'Apache::MP3::L10N::sl' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'LWP::EventLoop' => {
                                'dist_name' => 'LWPng-alpha',
                                'mod_vers' => '0.11'
                              },
          'HTTP::Request' => {
                               'dist_name' => 'libwww-perl',
                               'mod_vers' => '1.40'
                             },
          'MIME::Base64::Perl' => {
                                    'dist_name' => 'MIME-Base64-Perl',
                                    'mod_vers' => '1.00'
                                  },
          'Bio::Das' => {
                          'dist_name' => 'Bio-Das',
                          'mod_vers' => '1.03'
                        },
          'Net::LDAP::Control::ProxyAuth' => {
                                               'dist_name' => 'perl-ldap',
                                               'mod_vers' => '1.05'
                                             },
          'URI::_segment' => {
                               'dist_name' => 'URI',
                               'mod_vers' => undef
                             },
          'Bio::Das::HTTP::Fetch' => {
                                       'dist_name' => 'Bio-Das',
                                       'mod_vers' => '1.11'
                                     },
          'HTML::TokeParser' => {
                                  'dist_name' => 'HTML-Parser',
                                  'mod_vers' => '2.37'
                                },
          'Digest::HMAC_MD5' => {
                                  'dist_name' => 'Digest-HMAC',
                                  'mod_vers' => '1.01'
                                },
          'Lisp::List' => {
                            'dist_name' => 'perl-lisp',
                            'mod_vers' => undef
                          },
          'HTTPD::UserAdmin::SQL' => {
                                       'dist_name' => 'HTTPD-User-Manage',
                                       'mod_vers' => '1.2'
                                     },
          'Apache::MP3::L10N::es' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'Ace::Graphics::Fk' => {
                                   'dist_name' => 'AcePerl',
                                   'mod_vers' => undef
                                 },
          'Tie::MAB2::Dualdb::Id' => {
                                       'dist_name' => 'MAB2',
                                       'mod_vers' => '1.005'
                                     },
          'Authen::SASL::Perl::PLAIN' => {
                                           'dist_name' => 'Authen-SASL',
                                           'mod_vers' => '1.04'
                                         },
          'WWW::Chat' => {
                           'dist_name' => 'webchat',
                           'mod_vers' => undef
                         },
          'Apache::MP3::L10N::no_no' => {
                                          'dist_name' => 'Apache-MP3',
                                          'mod_vers' => undef
                                        },
          'URI::_userpass' => {
                                'dist_name' => 'URI',
                                'mod_vers' => undef
                              },
          'Ace::Browser::AceSubs' => {
                                       'dist_name' => 'AcePerl',
                                       'mod_vers' => '1.21'
                                     },
          'Net::LDAP::Filter' => {
                                   'dist_name' => 'perl-ldap',
                                   'mod_vers' => '0.14'
                                 },
          'URI::file' => {
                           'dist_name' => 'URI',
                           'mod_vers' => '4.19'
                         },
          'LWP::Protocol::nogo' => {
                                     'dist_name' => 'libwww-perl',
                                     'mod_vers' => undef
                                   },
          'Date::Language::Norwegian' => {
                                           'dist_name' => 'TimeDate',
                                           'mod_vers' => '1.01'
                                         },
          'Net::LDAP::Control::VLV' => {
                                         'dist_name' => 'perl-ldap',
                                         'mod_vers' => '0.03'
                                       },
          'Bio::Das::Util' => {
                                'dist_name' => 'Bio-Das',
                                'mod_vers' => '0.01'
                              },
          'HTTPD::Realm' => {
                              'dist_name' => 'HTTPD-User-Manage',
                              'mod_vers' => '1.52'
                            },
          'URI::ldaps' => {
                            'dist_name' => 'URI',
                            'mod_vers' => undef
                          },
          'IO::Socket' => {
                            'dist_name' => 'IO',
                            'mod_vers' => '1.30'
                          },
          'HTML::Parser' => {
                              'dist_name' => 'HTML-Parser',
                              'mod_vers' => '3.55'
                            },
          'Bio::Das::AGPServer::SQLStorage' => {
                                                 'dist_name' => 'Bio-Das',
                                                 'mod_vers' => undef
                                               },
          'LWP::Authen::basic' => {
                                    'dist_name' => 'LWPng-alpha',
                                    'mod_vers' => undef
                                  },
          'HTML::Filter' => {
                              'dist_name' => 'HTML-Parser',
                              'mod_vers' => '2.11'
                            },
          'Bio::Das::AGPServer::Daemon' => {
                                             'dist_name' => 'Bio-Das',
                                             'mod_vers' => undef
                                           },
          'Authen::SASL::Perl' => {
                                    'dist_name' => 'Authen-SASL',
                                    'mod_vers' => '1.05'
                                  },
          'Net::LDAP::Search' => {
                                   'dist_name' => 'perl-ldap',
                                   'mod_vers' => '0.10'
                                 },
          'Digest::MD5' => {
                             'dist_name' => 'Digest-MD5',
                             'mod_vers' => '2.36'
                           },
          'CGI::Push' => {
                           'dist_name' => 'CGI',
                           'mod_vers' => '1.04'
                         },
          'Apache::MP3::L10N::fr' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'Net::Domain' => {
                             'dist_name' => 'libnet',
                             'mod_vers' => '2.19'
                           },
          'Devel::Symdump' => {
                                'dist_name' => 'Devel-Symdump',
                                'mod_vers' => '2.0604'
                              },
          'Ace::Graphics::Glyph::segments' => {
                                                'dist_name' => 'AcePerl',
                                                'mod_vers' => undef
                                              },
          'Bio::Das::AGPServer::Config' => {
                                             'dist_name' => 'Bio-Das',
                                             'mod_vers' => '1.0'
                                           },
          'Bio::Das::Request::Features' => {
                                             'dist_name' => 'Bio-Das',
                                             'mod_vers' => undef
                                           },
          'Convert::UU' => {
                             'dist_name' => 'Convert-UU',
                             'mod_vers' => '0.52'
                           },
          'LWP::Conn::HTTP' => {
                                 'dist_name' => 'LWPng-alpha',
                                 'mod_vers' => undef
                               },
          'Tkx::MegaConfig' => {
                                 'dist_name' => 'Tkx',
                                 'mod_vers' => undef
                               },
          'MIME::QuotedPrint::Perl' => {
                                         'dist_name' => 'MIME-Base64-Perl',
                                         'mod_vers' => '1.00'
                                       },
          'Authen::SASL::EXTERNAL' => {
                                        'dist_name' => 'Authen-SASL',
                                        'mod_vers' => '0.99'
                                      },
          'LWP::Protocol::http10' => {
                                       'dist_name' => 'libwww-perl',
                                       'mod_vers' => undef
                                     },
          'HTTP::Cookies::Microsoft' => {
                                          'dist_name' => 'libwww-perl',
                                          'mod_vers' => '1.07'
                                        },
          'Apache::HeavyCGI::Exception' => {
                                             'dist_name' => 'Apache-HeavyCGI',
                                             'mod_vers' => undef
                                           },
          'CPAN::HandleConfig' => {
                                    'dist_name' => 'CPAN',
                                    'mod_vers' => '5.400847'
                                  },
          'Bio::Das::DSN' => {
                               'dist_name' => 'Bio-Das',
                               'mod_vers' => undef
                             },
          'Net::LDAPS' => {
                            'dist_name' => 'perl-ldap',
                            'mod_vers' => '0.05'
                          },
          'Ace::Graphics::Glyph::group' => {
                                             'dist_name' => 'AcePerl',
                                             'mod_vers' => undef
                                           },
          'Date::Language::TigrinyaEthiopian' => {
                                                   'dist_name' => 'TimeDate',
                                                   'mod_vers' => '1.00'
                                                 },
          'MAB2::Record::pnd' => {
                                   'dist_name' => 'MAB2',
                                   'mod_vers' => '0.01'
                                 },
          'Apache::MP3::L10N::nl' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'HTML::LinkExtor' => {
                                 'dist_name' => 'HTML-Parser',
                                 'mod_vers' => '1.33'
                               },
          'Bio::Das::Request::Stylesheet' => {
                                               'dist_name' => 'Bio-Das',
                                               'mod_vers' => undef
                                             },
          'Gnus::Newsrc' => {
                              'dist_name' => 'perl-lisp',
                              'mod_vers' => '1.04'
                            },
          'Bio::Das::Feature' => {
                                   'dist_name' => 'Bio-Das',
                                   'mod_vers' => '0.90'
                                 },
          'Boulder::Genbank' => {
                                  'dist_name' => 'Boulder',
                                  'mod_vers' => '1.1'
                                },
          'LWP::MediaTypes' => {
                                 'dist_name' => 'libwww-perl',
                                 'mod_vers' => '1.32'
                               },
          'LWP::Protocol::data' => {
                                     'dist_name' => 'libwww-perl',
                                     'mod_vers' => undef
                                   },
          'Ace::Graphics::Glyph::box' => {
                                           'dist_name' => 'AcePerl',
                                           'mod_vers' => undef
                                         },
          'Bio::SCF' => {
                          'dist_name' => 'Bio-SCF',
                          'mod_vers' => '1.01'
                        },
          'Encode::MAB2table' => {
                                   'dist_name' => 'MAB2',
                                   'mod_vers' => '0.06'
                                 },
          'Date::Language::Swedish' => {
                                         'dist_name' => 'TimeDate',
                                         'mod_vers' => '1.01'
                                       },
          'PerlBench::Stats' => {
                                  'dist_name' => 'perlbench',
                                  'mod_vers' => undef
                                },
          'LWP::Simple' => {
                             'dist_name' => 'libwww-perl',
                             'mod_vers' => '1.41'
                           },
          'URI::file::Unix' => {
                                 'dist_name' => 'URI',
                                 'mod_vers' => undef
                               },
          'Ace::Graphics::Glyph::toomany' => {
                                               'dist_name' => 'AcePerl',
                                               'mod_vers' => undef
                                             },
          'Digest::file' => {
                              'dist_name' => 'Digest',
                              'mod_vers' => '1.00'
                            },
          'LWP::UA::Proxy' => {
                                'dist_name' => 'LWPng-alpha',
                                'mod_vers' => undef
                              },
          'Net::TFTP' => {
                           'dist_name' => 'Net-TFTP',
                           'mod_vers' => '0.16'
                         },
          'Text::Shellwords' => {
                                  'dist_name' => 'Text-Shellwords',
                                  'mod_vers' => '1.08'
                                },
          'LWP::MemberMixin' => {
                                  'dist_name' => 'libwww-perl',
                                  'mod_vers' => undef
                                },
          'URI::rsync' => {
                            'dist_name' => 'URI',
                            'mod_vers' => undef
                          },
          'LWP::Hooks' => {
                            'dist_name' => 'LWPng-alpha',
                            'mod_vers' => undef
                          },
          'LWP::Request' => {
                              'dist_name' => 'LWPng-alpha',
                              'mod_vers' => undef
                            },
          'LWP::UserAgent' => {
                                'dist_name' => 'libwww-perl',
                                'mod_vers' => '2.033'
                              },
          'URI::URL' => {
                          'dist_name' => 'URI',
                          'mod_vers' => '5.03'
                        },
          'Net::LDAP::Bind' => {
                                 'dist_name' => 'perl-ldap',
                                 'mod_vers' => '1.02'
                               },
          'Ace::RPC' => {
                          'dist_name' => 'AcePerl',
                          'mod_vers' => '1.00'
                        },
          'Date::Language::Finnish' => {
                                         'dist_name' => 'TimeDate',
                                         'mod_vers' => '1.01'
                                       },
          'Ace::Browser::GeneSubs' => {
                                        'dist_name' => 'AcePerl',
                                        'mod_vers' => undef
                                      },
          'Perl::Repository::APC' => {
                                       'dist_name' => 'Perl-Repository-APC',
                                       'mod_vers' => '1.221'
                                     },
          'CPAN::Test::Dummy::Perl5::Make::CircDepeOne' => {
                                                             'dist_name' => 'CPAN-Test-Dummy-Perl5-Make-CircDepeOne',
                                                             'mod_vers' => '1.00'
                                                           },
          'IO::Socket::UNIX' => {
                                  'dist_name' => 'IO',
                                  'mod_vers' => '1.23'
                                },
          'Ace::Graphics::Glyph::anchored_arrow' => {
                                                      'dist_name' => 'AcePerl',
                                                      'mod_vers' => undef
                                                    },
          'Date::Language::English' => {
                                         'dist_name' => 'TimeDate',
                                         'mod_vers' => '1.01'
                                       },
          'Lisp::Reader' => {
                              'dist_name' => 'perl-lisp',
                              'mod_vers' => '1.10'
                            },
          'Apache::MP3::L10N::hr' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'IO::Interface' => {
                               'dist_name' => 'IO-Interface',
                               'mod_vers' => '1.02'
                             },
          'MIME::QuotedPrint' => {
                                   'dist_name' => 'MIME-Base64',
                                   'mod_vers' => '3.07'
                                 },
          'Date::Parse' => {
                             'dist_name' => 'TimeDate',
                             'mod_vers' => '2.27'
                           },
          'HTTPD::UserAdmin::Text' => {
                                        'dist_name' => 'HTTPD-User-Manage',
                                        'mod_vers' => '1.2'
                                      },
          'IO::Sockatmark' => {
                                'dist_name' => 'IO-Sockatmark',
                                'mod_vers' => '1.00'
                              },
          'Bio::Das::Request::Entry_points' => {
                                                 'dist_name' => 'Bio-Das',
                                                 'mod_vers' => undef
                                               },
          'WWW::RobotRules' => {
                                 'dist_name' => 'libwww-perl',
                                 'mod_vers' => '1.33'
                               },
          'IO::Dir' => {
                         'dist_name' => 'IO',
                         'mod_vers' => '1.06'
                       },
          'Tie::MAB2::Recno' => {
                                  'dist_name' => 'MAB2',
                                  'mod_vers' => '1.006'
                                },
          'CGI::Cookie' => {
                             'dist_name' => 'CGI',
                             'mod_vers' => '1.27'
                           },
          'Ace::Graphics::Glyph::span' => {
                                            'dist_name' => 'AcePerl',
                                            'mod_vers' => undef
                                          },
          'Authen::SASL::Perl::CRAM_MD5' => {
                                              'dist_name' => 'Authen-SASL',
                                              'mod_vers' => '1.03'
                                            },
          'Date::Language::Austrian' => {
                                          'dist_name' => 'TimeDate',
                                          'mod_vers' => '1.01'
                                        },
          'IPC::Msg' => {
                          'dist_name' => 'IPC-SysV',
                          'mod_vers' => '1.00'
                        },
          'Apache::Session::Counted' => {
                                          'dist_name' => 'Apache-Session-Counted',
                                          'mod_vers' => '1.118'
                                        },
          'LWP::Authen::Digest' => {
                                     'dist_name' => 'libwww-perl',
                                     'mod_vers' => undef
                                   },
          'Bundle::CPAN' => {
                              'dist_name' => 'Bundle-CPAN',
                              'mod_vers' => '1.854'
                            },
          'Lisp::String' => {
                              'dist_name' => 'perl-lisp',
                              'mod_vers' => undef
                            },
          'Perl::Repository::APC2SVN' => {
                                           'dist_name' => 'Perl-Repository-APC',
                                           'mod_vers' => '1.220'
                                         },
          'CPAN' => {
                      'dist_name' => 'CPAN',
                      'mod_vers' => '1.8802'
                    },
          'Font::Metrics::CourierBoldOblique' => {
                                                   'dist_name' => 'Font-AFM',
                                                   'mod_vers' => undef
                                                 },
          'LWP::Protocol::cpan' => {
                                     'dist_name' => 'libwww-perl',
                                     'mod_vers' => undef
                                   },
          'Font::Metrics::CourierOblique' => {
                                               'dist_name' => 'Font-AFM',
                                               'mod_vers' => undef
                                             },
          'Apache::MP3::L10N::no' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => undef
                                     },
          'Ace::Graphics::GlyphFactory' => {
                                             'dist_name' => 'AcePerl',
                                             'mod_vers' => undef
                                           },
          'CPAN::Checksums' => {
                                 'dist_name' => 'CPAN-Checksums',
                                 'mod_vers' => '1.050'
                               },
          'CPAN::DistnameInfo' => {
                                    'dist_name' => 'CPAN-DistnameInfo',
                                    'mod_vers' => '0.06'
                                  },
          'Date::Language::Danish' => {
                                        'dist_name' => 'TimeDate',
                                        'mod_vers' => '1.01'
                                      },
          'HTTP::Status' => {
                              'dist_name' => 'libwww-perl',
                              'mod_vers' => '1.28'
                            },
          'Time::Zone' => {
                            'dist_name' => 'TimeDate',
                            'mod_vers' => '2.22'
                          },
          'Font::Metrics::TimesItalic' => {
                                            'dist_name' => 'Font-AFM',
                                            'mod_vers' => undef
                                          },
          'Net::LDAP::Control::SortResult' => {
                                                'dist_name' => 'perl-ldap',
                                                'mod_vers' => '0.01'
                                              },
          'Apache::MP3::L10N::uk' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'Ace::Graphics::Glyph::ex' => {
                                          'dist_name' => 'AcePerl',
                                          'mod_vers' => undef
                                        },
          'Apache::MP3::L10N::sr' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'Net::FTP' => {
                          'dist_name' => 'libnet',
                          'mod_vers' => '2.75'
                        },
          'URI::ldap' => {
                           'dist_name' => 'URI',
                           'mod_vers' => '1.11'
                         },
          'Net::POP3' => {
                           'dist_name' => 'libnet',
                           'mod_vers' => '2.28'
                         },
          'IO::Socket::Multicast' => {
                                       'dist_name' => 'IO-Socket-Multicast',
                                       'mod_vers' => '1.05'
                                     },
          'Apache::MP3::L10N::tr' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'LWP::SecureSocket' => {
                                   'dist_name' => 'LWP-attic',
                                   'mod_vers' => '1.03'
                                 },
          'Ace::Browser::SiteDefs' => {
                                        'dist_name' => 'AcePerl',
                                        'mod_vers' => undef
                                      },
          'Data::DumpXML' => {
                               'dist_name' => 'Data-DumpXML',
                               'mod_vers' => '1.06'
                             },
          'URI::file::OS2' => {
                                'dist_name' => 'URI',
                                'mod_vers' => undef
                              },
          'Apache::MP3::L10N::ca' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'URI::WithBase' => {
                               'dist_name' => 'URI',
                               'mod_vers' => '2.19'
                             },
          'LWP::Authen' => {
                             'dist_name' => 'LWPng-alpha',
                             'mod_vers' => undef
                           },
          'Net::LDAP::Message' => {
                                    'dist_name' => 'perl-ldap',
                                    'mod_vers' => '1.08'
                                  },
          'Lisp::Interpreter' => {
                                   'dist_name' => 'perl-lisp',
                                   'mod_vers' => '1.08'
                                 },
          'Data::DumpXML::Parser' => {
                                       'dist_name' => 'Data-DumpXML',
                                       'mod_vers' => '1.01'
                                     },
          'Net::LDAP::Control::VLVResponse' => {
                                                 'dist_name' => 'perl-ldap',
                                                 'mod_vers' => '0.03'
                                               },
          'Net::HTTP' => {
                           'dist_name' => 'libwww-perl',
                           'mod_vers' => '1.00'
                         },
          'URI' => {
                     'dist_name' => 'URI',
                     'mod_vers' => '1.35'
                   },
          'Apache::MP3::L10N::fi' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'CPAN::Test::Dummy::Perl5::Make' => {
                                                'dist_name' => 'CPAN-Test-Dummy-Perl5-Make',
                                                'mod_vers' => '1.05'
                                              },
          'CPAN::Test::Dummy::Perl5::Build::Fails' => {
                                                        'dist_name' => 'CPAN-Test-Dummy-Perl5-Build-Fails',
                                                        'mod_vers' => '1.03'
                                                      },
          'CGI::Fast' => {
                           'dist_name' => 'CGI',
                           'mod_vers' => '1.07'
                         },
          'Font::Metrics::HelveticaBold' => {
                                              'dist_name' => 'Font-AFM',
                                              'mod_vers' => undef
                                            },
          'Ace::Graphics::Glyph::dot' => {
                                           'dist_name' => 'AcePerl',
                                           'mod_vers' => undef
                                         },
          'CGI' => {
                     'dist_name' => 'CGI',
                     'mod_vers' => '3.25'
                   },
          'Bio::Das::AGPServer::SQLStorage::MySQL::DB' => {
                                                            'dist_name' => 'Bio-Das',
                                                            'mod_vers' => undef
                                                          },
          'Apache::MP3' => {
                             'dist_name' => 'Apache-MP3',
                             'mod_vers' => '3.06'
                           },
          'LWP::MainLoop' => {
                               'dist_name' => 'LWPng-alpha',
                               'mod_vers' => undef
                             },
          'URI::sips' => {
                           'dist_name' => 'URI',
                           'mod_vers' => undef
                         },
          'Authen::SASL::Perl::LOGIN' => {
                                           'dist_name' => 'Authen-SASL',
                                           'mod_vers' => '1.03'
                                         },
          'Module::Install::InstallDirs' => {
                                              'dist_name' => 'Module-Install-InstallDirs',
                                              'mod_vers' => '0.01'
                                            },
          'MD5' => {
                     'dist_name' => 'MD5',
                     'mod_vers' => '2.03'
                   },
          'Convert::ASN1::parser' => {
                                       'dist_name' => 'Convert-ASN1',
                                       'mod_vers' => undef
                                     },
          'Crypt::CBC' => {
                            'dist_name' => 'Crypt-CBC',
                            'mod_vers' => '2.22'
                          },
          'Net::FTP::E' => {
                             'dist_name' => 'libnet',
                             'mod_vers' => '0.01'
                           },
          'IO::Select' => {
                            'dist_name' => 'IO',
                            'mod_vers' => '1.17'
                          },
          'Date::Language::Dutch' => {
                                       'dist_name' => 'TimeDate',
                                       'mod_vers' => '1.02'
                                     },
          'URI::ftp' => {
                          'dist_name' => 'URI',
                          'mod_vers' => undef
                        },
          'Bio::Das::TypeHandler' => {
                                       'dist_name' => 'Bio-Das',
                                       'mod_vers' => undef
                                     },
          'Net::PH' => {
                         'dist_name' => 'Net-PH',
                         'mod_vers' => '2.21'
                       },
          'No::Dato' => {
                          'dist_name' => 'Norge',
                          'mod_vers' => '1.10'
                        },
          'Ace::Graphics::Glyph::line' => {
                                            'dist_name' => 'AcePerl',
                                            'mod_vers' => undef
                                          },
          'Apache::UploadSvr::Dictionary' => {
                                               'dist_name' => 'Apache-UploadSvr',
                                               'mod_vers' => '1.002'
                                             },
          'LWP::Protocol::https' => {
                                      'dist_name' => 'libwww-perl',
                                      'mod_vers' => undef
                                    },
          'Apache::UploadSvr::Directory' => {
                                              'dist_name' => 'Apache-UploadSvr',
                                              'mod_vers' => '1.004'
                                            },
          'Ace::Graphics::Glyph' => {
                                      'dist_name' => 'AcePerl',
                                      'mod_vers' => undef
                                    },
          'Net::LDAP::Extra' => {
                                  'dist_name' => 'perl-ldap',
                                  'mod_vers' => '0.01'
                                },
          'Ace::Graphics::Panel' => {
                                      'dist_name' => 'AcePerl',
                                      'mod_vers' => undef
                                    },
          'HTTP::Date' => {
                            'dist_name' => 'libwww-perl',
                            'mod_vers' => '1.47'
                          },
          'Net::Config' => {
                             'dist_name' => 'libnet',
                             'mod_vers' => '1.10'
                           },
          'Net::LDAP::Extension::WhoAmI' => {
                                              'dist_name' => 'perl-ldap',
                                              'mod_vers' => '0.01'
                                            },
          'CPAN::Test::Dummy::Perl5::Make::CircDepeTwo' => {
                                                             'dist_name' => 'CPAN-Test-Dummy-Perl5-Make-CircDepeTwo',
                                                             'mod_vers' => '1.00'
                                                           },
          'Apache::MP3::L10N::de' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'Date::Language::German' => {
                                        'dist_name' => 'TimeDate',
                                        'mod_vers' => '1.02'
                                      },
          'Bio::Das::AGPServer::SQLStorage::CSV::DB' => {
                                                          'dist_name' => 'Bio-Das',
                                                          'mod_vers' => undef
                                                        },
          'Net::HTTP::Methods' => {
                                    'dist_name' => 'libwww-perl',
                                    'mod_vers' => '1.02'
                                  },
          'Ace' => {
                     'dist_name' => 'AcePerl',
                     'mod_vers' => '1.89'
                   },
          'LWP::Dump' => {
                           'dist_name' => 'LWPng-alpha',
                           'mod_vers' => undef
                         },
          'Apache::MP3::L10N::nl_be' => {
                                          'dist_name' => 'Apache-MP3',
                                          'mod_vers' => undef
                                        },
          'MyPodHtml' => {
                           'dist_name' => 'perlbench',
                           'mod_vers' => '1.0503'
                         },
          'Unicode::String' => {
                                 'dist_name' => 'Unicode-String',
                                 'mod_vers' => '2.09'
                               },
          'Ace::Sequence::Transcript' => {
                                           'dist_name' => 'AcePerl',
                                           'mod_vers' => undef
                                         },
          'Ace::Graphics::Glyph::primers' => {
                                               'dist_name' => 'AcePerl',
                                               'mod_vers' => undef
                                             },
          'LWP::Sink::rot13' => {
                                  'dist_name' => 'LWPng-alpha',
                                  'mod_vers' => undef
                                },
          'Apache::MP3::L10N::nn' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => undef
                                     },
          'Net::FTP::dataconn' => {
                                    'dist_name' => 'libnet',
                                    'mod_vers' => '0.11'
                                  },
          'Tie::DBI' => {
                          'dist_name' => 'Tie-DBI',
                          'mod_vers' => '1.02'
                        },
          'Apache::MP3::L10N::ga' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'Font::Metrics::TimesBoldItalic' => {
                                                'dist_name' => 'Font-AFM',
                                                'mod_vers' => undef
                                              },
          'LWP::UA' => {
                         'dist_name' => 'LWPng-alpha',
                         'mod_vers' => '1.30'
                       },
          'CPAN::Test::Dummy::Perl5::Make::CircDepeThree' => {
                                                               'dist_name' => 'CPAN-Test-Dummy-Perl5-Make-CircDepeThree',
                                                               'mod_vers' => '1.00'
                                                             },
          'Ace::Graphics::Glyph::graded_segments' => {
                                                       'dist_name' => 'AcePerl',
                                                       'mod_vers' => undef
                                                     },
          'IO::Handle' => {
                            'dist_name' => 'IO',
                            'mod_vers' => '1.27'
                          },
          'LWP::Redirect' => {
                               'dist_name' => 'LWPng-alpha',
                               'mod_vers' => undef
                             },
          'Font::Metrics::CourierBold' => {
                                            'dist_name' => 'Font-AFM',
                                            'mod_vers' => undef
                                          },
          'Date::Format' => {
                              'dist_name' => 'TimeDate',
                              'mod_vers' => '2.22'
                            },
          'URI::Heuristic' => {
                                'dist_name' => 'URI',
                                'mod_vers' => '4.17'
                              },
          'HTML::Entities' => {
                                'dist_name' => 'HTML-Parser',
                                'mod_vers' => '1.35'
                              },
          'URI::Attr' => {
                           'dist_name' => 'LWPng-alpha',
                           'mod_vers' => '1.07'
                         },
          'Net::LDAP::Schema' => {
                                   'dist_name' => 'perl-ldap',
                                   'mod_vers' => '0.9903'
                                 },
          'URI::http' => {
                           'dist_name' => 'URI',
                           'mod_vers' => undef
                         },
          'LWP::Conn::_Cmd' => {
                                 'dist_name' => 'LWPng-alpha',
                                 'mod_vers' => undef
                               },
          'Apache::MP3::L10N' => {
                                   'dist_name' => 'Apache-MP3',
                                   'mod_vers' => '20020601'
                                 },
          'Lisp::Special' => {
                               'dist_name' => 'perl-lisp',
                               'mod_vers' => undef
                             },
          'LWP::Protocol::https10' => {
                                        'dist_name' => 'libwww-perl',
                                        'mod_vers' => undef
                                      },
          'Lisp::Subr::Core' => {
                                  'dist_name' => 'perl-lisp',
                                  'mod_vers' => '1.08'
                                },
          'Digest::HMAC' => {
                              'dist_name' => 'Digest-HMAC',
                              'mod_vers' => '1.01'
                            },
          'IO::Seekable' => {
                              'dist_name' => 'IO',
                              'mod_vers' => '1.10'
                            },
          'CPAN::Test::Dummy::Perl5::BuildOrMake' => {
                                                       'dist_name' => 'CPAN-Test-Dummy-Perl5-BuildOrMake',
                                                       'mod_vers' => '1.02'
                                                     },
          'B::FindAmpersand' => {
                                  'dist_name' => 'Devel-SawAmpersand',
                                  'mod_vers' => '0.04'
                                },
          'Bundle::MP3' => {
                             'dist_name' => 'Bundle-MP3',
                             'mod_vers' => '1.00'
                           },
          'URI::_generic' => {
                               'dist_name' => 'URI',
                               'mod_vers' => undef
                             },
          'Lisp::Symbol' => {
                              'dist_name' => 'perl-lisp',
                              'mod_vers' => '1.06'
                            },
          'LWP::Sink::Monitor' => {
                                    'dist_name' => 'LWPng-alpha',
                                    'mod_vers' => undef
                                  },
          'HTML::HeadParser' => {
                                  'dist_name' => 'HTML-Parser',
                                  'mod_vers' => '2.22'
                                },
          'URI::_server' => {
                              'dist_name' => 'URI',
                              'mod_vers' => undef
                            },
          'HTTP::Cookies' => {
                               'dist_name' => 'libwww-perl',
                               'mod_vers' => '1.39'
                             },
          'HTTP::Request::Common' => {
                                       'dist_name' => 'libwww-perl',
                                       'mod_vers' => '1.26'
                                     },
          'Digest::HMAC_SHA1' => {
                                   'dist_name' => 'Digest-HMAC',
                                   'mod_vers' => '1.01'
                                 },
          'Digest::MD2' => {
                             'dist_name' => 'Digest-MD2',
                             'mod_vers' => '2.03'
                           },
          'Bio::Das::Map' => {
                               'dist_name' => 'Bio-Das',
                               'mod_vers' => '1.01'
                             },
          'HTTP::Response' => {
                                'dist_name' => 'libwww-perl',
                                'mod_vers' => '1.53'
                              },
          'LWP::Protocol::loopback' => {
                                         'dist_name' => 'libwww-perl',
                                         'mod_vers' => undef
                                       },
          'Net::LDAP::Extension' => {
                                      'dist_name' => 'perl-ldap',
                                      'mod_vers' => '1.01'
                                    },
          'Bio::Das::Request::Sequences' => {
                                              'dist_name' => 'Bio-Das',
                                              'mod_vers' => undef
                                            },
          'Bio::SCF::Arrays' => {
                                  'dist_name' => 'Bio-SCF',
                                  'mod_vers' => undef
                                },
          'Apache::MP3::L10N::he' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'Apache::MP3::Playlist' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '1.05'
                                     },
          'Net::Cmd' => {
                          'dist_name' => 'libnet',
                          'mod_vers' => '2.26'
                        },
          'Net::LDAP::Control::PersistentSearch' => {
                                                      'dist_name' => 'perl-ldap',
                                                      'mod_vers' => '0.01'
                                                    },
          'Digest' => {
                        'dist_name' => 'Digest',
                        'mod_vers' => '1.15'
                      },
          'Stone::Cursor' => {
                               'dist_name' => 'Boulder',
                               'mod_vers' => undef
                             },
          'Date::Language::Gedeo' => {
                                       'dist_name' => 'TimeDate',
                                       'mod_vers' => '0.99'
                                     },
          'No::KontoNr' => {
                             'dist_name' => 'Norge',
                             'mod_vers' => '1.09'
                           },
          'Bundle::CPANxxl' => {
                                 'dist_name' => 'Bundle-CPAN',
                                 'mod_vers' => '0.1'
                               },
          'IO::String' => {
                            'dist_name' => 'IO-String',
                            'mod_vers' => '1.08'
                          },
          'Unicode::Map8' => {
                               'dist_name' => 'Unicode-Map8',
                               'mod_vers' => '0.12'
                             },
          'Lisp::Vector' => {
                              'dist_name' => 'perl-lisp',
                              'mod_vers' => undef
                            },
          'LWP::Sink::deflate' => {
                                    'dist_name' => 'LWPng-alpha',
                                    'mod_vers' => undef
                                  },
          'HTTP::Headers::Util' => {
                                     'dist_name' => 'libwww-perl',
                                     'mod_vers' => '1.13'
                                   },
          'Apache::PassFile' => {
                                  'dist_name' => 'Apache-GzipChain',
                                  'mod_vers' => '0.05'
                                },
          'HTTPD::GroupAdmin' => {
                                   'dist_name' => 'HTTPD-User-Manage',
                                   'mod_vers' => '1.5'
                                 },
          'Net::Time' => {
                           'dist_name' => 'libnet',
                           'mod_vers' => '2.10'
                         },
          'Apache::HeavyCGI' => {
                                  'dist_name' => 'Apache-HeavyCGI',
                                  'mod_vers' => '0.013302'
                                },
          'Net::LDAP::RootDSE' => {
                                    'dist_name' => 'perl-ldap',
                                    'mod_vers' => '0.01'
                                  },
          'Apache::MP3::L10N::ar' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'LWP::Debug' => {
                            'dist_name' => 'libwww-perl',
                            'mod_vers' => undef
                          },
          'URI::ldapi' => {
                            'dist_name' => 'URI',
                            'mod_vers' => undef
                          },
          'Tie::MAB2::Id' => {
                               'dist_name' => 'MAB2',
                               'mod_vers' => '1.005'
                             },
          'LWP::Conn::_Connect' => {
                                     'dist_name' => 'LWPng-alpha',
                                     'mod_vers' => undef
                                   },
          'CPAN::Test::Dummy::Perl5::Make::Failearly' => {
                                                           'dist_name' => 'CPAN-Test-Dummy-Perl5-Make-Failearly',
                                                           'mod_vers' => '1.02'
                                                         },
          'Ace::Browser::TreeSubs' => {
                                        'dist_name' => 'AcePerl',
                                        'mod_vers' => undef
                                      },
          'Date::Language::Italian' => {
                                         'dist_name' => 'TimeDate',
                                         'mod_vers' => '1.01'
                                       },
          'Apache::MP3::L10N::sh' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => undef
                                     },
          'Bio::Das::Request::Dsn' => {
                                        'dist_name' => 'Bio-Das',
                                        'mod_vers' => undef
                                      },
          'LWP::Authen::digest' => {
                                     'dist_name' => 'LWPng-alpha',
                                     'mod_vers' => undef
                                   },
          'Authen::SASL::Perl::GSSAPI' => {
                                            'dist_name' => 'Authen-SASL',
                                            'mod_vers' => '0.02'
                                          },
          'CPAN::Admin' => {
                             'dist_name' => 'CPAN',
                             'mod_vers' => '5.400844'
                           },
          'Devel::SawAmpersand' => {
                                     'dist_name' => 'Devel-SawAmpersand',
                                     'mod_vers' => '0.30'
                                   },
          'Net::LDAP::Control' => {
                                    'dist_name' => 'perl-ldap',
                                    'mod_vers' => '0.05'
                                  },
          'URI::urn::isbn' => {
                                'dist_name' => 'URI',
                                'mod_vers' => undef
                              },
          'Net::HTTPS' => {
                            'dist_name' => 'libwww-perl',
                            'mod_vers' => '1.00'
                          },
          'Tkx' => {
                     'dist_name' => 'Tkx',
                     'mod_vers' => '1.04'
                   },
          'Apache::MP3::L10N::zh_tw' => {
                                          'dist_name' => 'Apache-MP3',
                                          'mod_vers' => '20020612'
                                        },
          'Lisp::Subr::Perl' => {
                                  'dist_name' => 'perl-lisp',
                                  'mod_vers' => '1.04'
                                },
          'PerlBench' => {
                           'dist_name' => 'perlbench',
                           'mod_vers' => '0.93'
                         },
          'URI::data' => {
                           'dist_name' => 'URI',
                           'mod_vers' => undef
                         },
          'Array::RefElem' => {
                                'dist_name' => 'Array-RefElem',
                                'mod_vers' => '1.00'
                              },
          'Encode::MAB2' => {
                              'dist_name' => 'MAB2',
                              'mod_vers' => '0.06'
                            },
          'LWP::Authen::Ntlm' => {
                                   'dist_name' => 'libwww-perl',
                                   'mod_vers' => '0.05'
                                 },
          'Net::FTP::L' => {
                             'dist_name' => 'libnet',
                             'mod_vers' => '0.01'
                           },
          'Apache::MP3::L10N::fa' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'Apache::MP3::L10N::cs' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'Ace::Browser::SearchSubs' => {
                                          'dist_name' => 'AcePerl',
                                          'mod_vers' => '1.30'
                                        },
          'Ace::Sequence::GappedAlignment' => {
                                                'dist_name' => 'AcePerl',
                                                'mod_vers' => '1.20'
                                              },
          'Perl::Repository::APC::BAP' => {
                                            'dist_name' => 'Perl-Repository-APC',
                                            'mod_vers' => '1.220'
                                          },
          'GD::Polyline' => {
                              'dist_name' => 'GD',
                              'mod_vers' => '0.2'
                            },
          'Boulder::Store' => {
                                'dist_name' => 'Boulder',
                                'mod_vers' => '1.20'
                              },
          'Authen::SASL::Perl::DIGEST_MD5' => {
                                                'dist_name' => 'Authen-SASL',
                                                'mod_vers' => '1.05'
                                              },
          'Apache::MP3::L10N::zh_cn' => {
                                          'dist_name' => 'Apache-MP3',
                                          'mod_vers' => '20020612'
                                        },
          'CPAN::Tarzip' => {
                              'dist_name' => 'CPAN',
                              'mod_vers' => '5.400858'
                            },
          'Apache::MP3::L10N::nn_no' => {
                                          'dist_name' => 'Apache-MP3',
                                          'mod_vers' => undef
                                        },
          'Apache::HeavyCGI::Layout' => {
                                          'dist_name' => 'Apache-HeavyCGI',
                                          'mod_vers' => '1.002'
                                        },
          'Apache::MP3::L10N::nl_nl' => {
                                          'dist_name' => 'Apache-MP3',
                                          'mod_vers' => undef
                                        },
          'MAB2::Record::gkd' => {
                                   'dist_name' => 'MAB2',
                                   'mod_vers' => '0.01'
                                 },
          'URI::file::FAT' => {
                                'dist_name' => 'URI',
                                'mod_vers' => undef
                              },
          'Date::Language::Chinese_GB' => {
                                            'dist_name' => 'TimeDate',
                                            'mod_vers' => '1.01'
                                          },
          'Apache::MP3::L10N::ja' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020612'
                                     },
          'Net::SMTP' => {
                           'dist_name' => 'libnet',
                           'mod_vers' => '2.29'
                         },
          'MIME::Base64' => {
                              'dist_name' => 'MIME-Base64',
                              'mod_vers' => '3.07'
                            },
          'Apache::MP3::L10N::Aliases' => {
                                            'dist_name' => 'Apache-MP3',
                                            'mod_vers' => '1.01'
                                          },
          'URI::mailto' => {
                             'dist_name' => 'URI',
                             'mod_vers' => undef
                           },
          'CGI::Pretty' => {
                             'dist_name' => 'CGI',
                             'mod_vers' => '1.08'
                           },
          'Date::Language::Sidama' => {
                                        'dist_name' => 'TimeDate',
                                        'mod_vers' => '0.99'
                                      },
          'Convert::Recode' => {
                                 'dist_name' => 'Convert-Recode',
                                 'mod_vers' => '1.04'
                               },
          'Apache::MP3::L10N::en' => {
                                       'dist_name' => 'Apache-MP3',
                                       'mod_vers' => '20020611'
                                     },
          'LWP::Protocol::nntp' => {
                                     'dist_name' => 'libwww-perl',
                                     'mod_vers' => undef
                                   },
          'Tie::Dir' => {
                          'dist_name' => 'Tie-Dir',
                          'mod_vers' => '1.02'
                        },
          'LWP::Sink::identity' => {
                                     'dist_name' => 'LWPng-alpha',
                                     'mod_vers' => undef
                                   },
          'HTML::Form' => {
                            'dist_name' => 'libwww-perl',
                            'mod_vers' => '1.054'
                          },
          'LWP::Protocol::gopher' => {
                                       'dist_name' => 'libwww-perl',
                                       'mod_vers' => undef
                                     },
          'Ace::Graphics::Glyph::arrow' => {
                                             'dist_name' => 'AcePerl',
                                             'mod_vers' => undef
                                           },
          'CPAN::Nox' => {
                           'dist_name' => 'CPAN',
                           'mod_vers' => '5.400844'
                         },
          'URI::tn3270' => {
                             'dist_name' => 'URI',
                             'mod_vers' => undef
                           },
          'URI::gopher' => {
                             'dist_name' => 'URI',
                             'mod_vers' => undef
                           },
          'Devel::FindAmpersand' => {
                                      'dist_name' => 'Devel-SawAmpersand',
                                      'mod_vers' => undef
                                    },
          'Boulder::String' => {
                                 'dist_name' => 'Boulder',
                                 'mod_vers' => '1.01'
                               },
          'CPAN::Test::Dummy::Perl5::Build::DepeFails' => {
                                                            'dist_name' => 'CPAN-Test-Dummy-Perl5-Build-DepeFails',
                                                            'mod_vers' => '1.02'
                                                          },
          'LWP::Conn::FTP' => {
                                'dist_name' => 'LWPng-alpha',
                                'mod_vers' => undef
                              },
          'HTTP::Cookies::Netscape' => {
                                         'dist_name' => 'libwww-perl',
                                         'mod_vers' => '1.26'
                                       },
          'Bio::Das::Type' => {
                                'dist_name' => 'Bio-Das',
                                'mod_vers' => undef
                              },
          'LWP::Authen::Basic' => {
                                    'dist_name' => 'libwww-perl',
                                    'mod_vers' => undef
                                  },
          'Date::Language::Oromo' => {
                                       'dist_name' => 'TimeDate',
                                       'mod_vers' => '0.99'
                                     },
          'CPAN::Test::Dummy::Perl5::Make::Zip' => {
                                                     'dist_name' => 'CPAN-Test-Dummy-Perl5-Make-Zip',
                                                     'mod_vers' => '1.03'
                                                   },
          'LWP' => {
                     'dist_name' => 'libwww-perl',
                     'mod_vers' => '5.805'
                   },
          'LWP::Sink::HTML' => {
                                 'dist_name' => 'LWPng-alpha',
                                 'mod_vers' => undef
                               },
          'MAB2::Record::swd' => {
                                   'dist_name' => 'MAB2',
                                   'mod_vers' => '0.01'
                                 },
          'HTTP::Negotiate' => {
                                 'dist_name' => 'libwww-perl',
                                 'mod_vers' => '1.16'
                               },
          'Bio::Das::Request::Types' => {
                                          'dist_name' => 'Bio-Das',
                                          'mod_vers' => undef
                                        },
          'Apache::UploadSvr::User' => {
                                         'dist_name' => 'Apache-UploadSvr',
                                         'mod_vers' => '1.002'
                                       },
          'rlib' => {
                      'dist_name' => 'rlib',
                      'mod_vers' => '0.02'
                    },
          'Tie::MAB2::Dualdb' => {
                                   'dist_name' => 'MAB2',
                                   'mod_vers' => undef
                                 },
          'LWP::Protocol::http' => {
                                     'dist_name' => 'libwww-perl',
                                     'mod_vers' => undef
                                   },
          'Include' => {
                         'dist_name' => 'Include',
                         'mod_vers' => '1.02'
                       },
          'Bundle::libnet' => {
                                'dist_name' => 'Bundle-libnet',
                                'mod_vers' => '1.00'
                              },
          'Bundle::LWP' => {
                             'dist_name' => 'libwww-perl',
                             'mod_vers' => '1.11'
                           },
          'Date::Language::Somali' => {
                                        'dist_name' => 'TimeDate',
                                        'mod_vers' => '0.99'
                                      }
        };
$auths = {
          'LDS' => {
                     'email' => 'lstein@cshl.edu',
                     'fullname' => 'Lincoln D. Stein'
                   },
          'GAAS' => {
                      'email' => 'gisle@ActiveState.com',
                      'fullname' => 'Gisle Aas'
                    },
          'ANDK' => {
                      'email' => 'andreas.koenig@anima.de',
                      'fullname' => 'Andreas J. Koenig'
                    },
          'GBARR' => {
                       'email' => 'gbarr@pobox.com',
                       'fullname' => 'Graham Barr'
                     }
        };

sub has_hash_data {
  my $data = shift;
  return unless (defined $data and ref($data) eq 'HASH');
  return (scalar keys %$data > 0) ? 1 : 0;
}

sub vcmp {
  my ($v1, $v2) = @_;
# for some reason, on darwin, with some versions,
# a trailing 0 in the version numbers causes some
# tests to fail. Strip these out for now.
  if ($v1 =~ /^[0-9,\.]+$/) {
    $v1 = $v1+0;
  }
  if ($v2 =~ /^[0-9,\.]+$/) {
    $v2 = $v2+0;
  }
  return TestSQL::Version->vcmp($v1, $v2);
}


# This is borrowed essentially verbatim from CPAN::Version
# It's included here so as to not demand a CPAN.pm upgrade

package TestSQL::Version;

use strict;
our $VERSION = 0.1;
no warnings;

# CPAN::Version::vcmp courtesy Jost Krieger
sub vcmp {
  my ($self, $l, $r) = @_;

  return 0 if $l eq $r; # short circuit for quicker success

  for ($l, $r) {
      next unless tr/.// > 1;
      s/^v?/v/;
      1 while s/\.0+(\d)/.$1/;
  }
  if ($l =~ /^v/ <=> $r =~ /^v/) {
      for ($l, $r) {
          next if /^v/;
          $_ = $self->float2vv($_);
      }
  }

  return (
          ($l ne "undef") <=> ($r ne "undef") ||
          (
           $] >= 5.006 &&
           $l =~ /^v/ &&
           $r =~ /^v/ &&
           $self->vstring($l) cmp $self->vstring($r)
          ) ||
          $l <=> $r ||
          $l cmp $r
         );
}

sub vgt {
  my ($self, $l, $r) = @_;
  $self->vcmp($l, $r) > 0;
}

sub vlt {
  my ($self, $l, $r) = @_;
  0 + ($self->vcmp($l, $r) < 0);
}

sub vstring {
  my ($self, $n) = @_;
  $n =~ s/^v//
    or die "CPAN::Search::Lite::Version::vstring() called with invalid arg [$n]";
  {
    no warnings;
    pack "U*", split /\./, $n;
  }
}

# vv => visible vstring
sub float2vv {
    my ($self, $n) = @_;
    my ($rev) = int($n);
    $rev ||= 0;
    my ($mantissa) = $n =~ /\.(\d{1,12})/; # limit to 12 digits to limit
                                          # architecture influence
    $mantissa ||= 0;
    $mantissa .= "0" while length($mantissa)%3;
    my $ret = "v" . $rev;
    while ($mantissa) {
        $mantissa =~ s/(\d{1,3})// or
            die "Panic: length>0 but not a digit? mantissa[$mantissa]";
        $ret .= ".".int($1);
    }
    # warn "n[$n]ret[$ret]";
    $ret;
}

sub readable {
  my($self,$n) = @_;
  $n =~ /^([\w\-\+\.]+)/;

  return $1 if defined $1 && length($1)>0;
  # if the first user reaches version v43, he will be treated as "+".
  # We'll have to decide about a new rule here then, depending on what
  # will be the prevailing versioning behavior then.

  if ($] < 5.006) { # or whenever v-strings were introduced
    # we get them wrong anyway, whatever we do, because 5.005 will
    # have already interpreted 0.2.4 to be "0.24". So even if he
    # indexer sends us something like "v0.2.4" we compare wrongly.

    # And if they say v1.2, then the old perl takes it as "v12"

    warn("Suspicious version string seen [$n]\n");
    return $n;
  }
  my $better = sprintf "v%vd", $n;
  return $better;
}

1;
