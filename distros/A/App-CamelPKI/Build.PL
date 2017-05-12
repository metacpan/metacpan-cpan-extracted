# Build.PL, (C) Dominique Quatravaux 2007 (See README for license details)

# This script automatically builds a "Build" file in the current
# directory (using a custom-made subclass to Module::Build), which in
# turn builds the Camel-PKI package.

use strict;
use warnings;
use FindBin; use lib "$FindBin::Bin/inc";
use My::Module::Build;

my $builder = My::Module::Build->new
    ( module_name         => 'App::CamelPKI',
      license             => 'perl',
      dist_author         =>
      'Jérémie Klein <grm.klein@gmail.com>',
      requires            =>
      {
       'B'                                  => 0, # To detect mod_perl (!)
       'Error'                              => 0,
       'NEXT'                               => 0,
       'Class::Inspector'                   => 0,
       'MIME::Base64'                       => 0,
       'DateTime'                           => 0,
       'Sys::Hostname'                      => 0,
       'IO::Socket::INET'                   => 0, # App::CamelPKI::SysV::Apache
       'Crypt::OpenSSL::CA'                 => 0.09,
       'Catalyst'                           => '5.7006', # RenderView is needed
       'Catalyst::Plugin::ConfigLoader'     => 0,
       'Catalyst::Plugin::Static::Simple'   => 0,
       'Catalyst::Action::RenderView'       => 0,
       'Catalyst::Engine::Apache'           => 0,
       'Catalyst::View::TT'					=> 0,
       'JSON'                               => 1.07, # UTF-8 support needed
       'Catalyst::View::JSON'               => 0,
       'DBIx::Class'                        => 0.07,
       'SQL::Translator'                    => 0.07,
       'DBD::SQLite'                        => 0,
       'Test::Group'						=> 0,
       'Test::More'							=> 0,
       'App::Info::HTTPD::Apache'			=> 0,
       'File::Slurp'						=> 0,

       # The following modules won't probably last ad vitam within
       # App-CamelPKI:

       # Yet another module to rewrite from scratch one of these days...
       'Crypt::X509'                        => 0.32,
       # For the Quick and Dirty `openssl`, to be rewrite too one of these
       # days...
       'IPC::Run'                           => 0,
      },
      build_requires      =>
      {
       My::Module::Build->requires_for_build(),
       # Packages below are needed for the test suite. (And yes,
       # running the test suite *is* a requirement of the build
       # process)
       'Test::Builder'                     => 0,
       'Test::More'                        => 0,
       'Test::Group'                       => 0,
       'Test::NoBreakpoints'			   => 0,
       'Test::Pod::Coverage'			   => 1.04,
       'File::Which'                       => 0,
       'File::Slurp'					   => 0,
       'File::Find'						   => 0,
       'Cwd'							   => 0,
       'Errno'                             => 0,
       'LWP::Simple'                       => 0,
       'LWP::UserAgent'                    => 0,
        # 0.20 release comes with UTF-8 bugfixes :
       'Convert::ASN1'                     => 0.20,
       'IO::Socket::SSL'                   => 0, # App::CamelPKI::SysV::Apache
       'Catalyst::View::TT'		   			=> 0,
       'HTTP::Request::Form'		   		=> 0,
       'HTML::TreeBuilder'					=> 0,
       'HTTP::Request::Common'				=> 0,
       'HTTP::Request'						=> 0,
       'URI::URL'							=> 0,
       'Module::ScanDeps'					=> 0,
      },
    add_to_cleanup      => [ '*.gz', 'Build', 'META.yml' ],
    create_makefile_pl  => 'passthrough',
);

$builder->create_build_script();

1;

