use inc::Module::Install;

name 'App-Office-Contacts';

license 'artistic_2';

perl_version '5.014000';

all_from 'lib/App/Office/Contacts.pm';

install_share;

requires 'CGI'                       => 3.63;
requires 'CGI::Snapp'                => 1.03;
requires 'CGI::Snapp::Dispatch'      => 1.02;
requires 'charnames'                 => 1.18;
requires 'Config::Tiny'              => 2.12;
requires 'Data::Session'             => 1.13;
requires 'Data::Verifier'            => 0.31;
requires 'DateTime'                  => 0.55;
requires 'DBI'                       => 1.611;
requires 'DBIx::Admin::CreateTable'  => 2.04;
requires 'DBIx::Simple'              => 1.35;
requires 'Digest::SHA'               => 5.82;
requires 'Encode'                    => 2.47;
requires 'feature'                   => 1.20;
requires 'File::Copy'                => 2.14;
requires 'File::ShareDir'            => 1.03;
requires 'FindBin'                   => 1.49;
requires 'Getopt::Long'              => 2.38;
requires 'JSON::XS'                  => 2.29;
requires 'Lingua::ENG::Inflect'      => 0.0577;
requires 'List::Compare'             => 0.37;
requires 'Log::Handler::Output::DBI' => 0.12;
requires 'Moo'                       => 1.001000;
requires 'Moo::Role'                 => undef;
requires 'open'                      => 1.08;
requires 'parent'                    => 0.218;
requires 'Path::Iterator::Rule'      => 1.005;
requires 'Path::Tiny'                => 0.004;
requires 'Perl6::Slurp'              => 0.03;
requires 'Pod::Usage'                => 1.51;
requires 'strict'                    => 0;
requires 'Sub::Exporter'             => 0.982;
requires 'Text::CSV::Encoded'        => 0.10;
requires 'Text::Xslate'              => 1.6002;
requires 'Time::Stamp'               => 1.300;
requires 'Try::Tiny'                 => 0.12;
requires 'Unicode::Collate'          => 0.97;
requires 'utf8'                      => 1.09;
requires 'warnings'                  => 0;

test_requires 'Test::More' => 0.98;
#test_requires 'Test::Pod'  => 1.45; # Make it optional. See t/pod.t

WriteAll;
