use inc::Module::Install;

name           ( 'Bundle-Email'                        );
abstract       ( 'Installs the main set of Email:: modules' );
author         ( 'Ricardo SIGNES <rjbs@cpan.org>'      );
version_from   ( 'lib/Bundle/Email.pm'                 );
license        ( 'perl'                                );

requires       ( 'Email::Address'           => '0'     );
requires       ( 'Email::MIME::Encodings'   => '0'     );
requires       ( 'Email::MIME::ContentType' => '0'     );
requires       ( 'Email::MessageID'         => '0'     );
requires       ( 'Email::Simple'            => '0'     );
requires       ( 'Email::Date'              => '0'     );
requires       ( 'Module::Pluggable'        => '0'     );
requires       ( 'Email::Abstract'          => '0'     );
requires       ( 'Email::MIME'              => '0'     );
requires       ( 'Email::Simple::Creator'   => '0'     );
requires       ( 'Email::MIME::Modifier'    => '0'     );
requires       ( 'Email::MIME::Creator'     => '0'     );
requires       ( 'Net::SMTP'                => '0'     );
requires       ( 'Email::Send'              => '0'     );
requires       ( 'Email::Send::Test'        => '0'     );
requires       ( 'Email::FolderType'        => '0'     );
requires       ( 'Email::FolderType::Net'   => '0'     );
requires       ( 'Email::LocalDelivery'     => '0'     );
requires       ( 'Email::Folder'            => '0'     );
requires       ( 'File::Type'               => '0'     );
requires       ( 'File::Slurp'              => '0'     );
requires       ( 'Email::Stuff'             => '0'     );

build_requires ( 'File::Spec'               => '0.82'  );
build_requires ( 'Test::More'               => '0.47'  );

repository('http://github.com/rjbs/bundle-email');

auto_install();

&WriteAll;
