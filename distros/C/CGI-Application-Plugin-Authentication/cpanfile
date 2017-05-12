requires 'perl' => '5.008';

requires 'Attribute::Handlers';
requires 'CGI' => '3.16';
requires 'CGI::Application' => 4;
requires 'Class::ISA';
requires 'Digest::SHA';
requires 'MIME::Base64';
requires 'Scalar::Util';
requires 'UNIVERSAL::require';

recommends 'Apache::Htpasswd' => '1.8';
recommends 'CGI::Application::Plugin::Session';
recommends 'Color::Calc' => '0.12';
recommends 'Digest::MD5';

on 'test' => sub {
   requires 'Readonly';
   requires 'Test::Exception';
   requires 'Test::MockObject';
   requires 'Test::More' => '1.302015';
   requires 'Test::NoWarnings';
   requires 'Test::Regression'; # login_box generates a lot of HTML to verify
   requires 'Test::Taint';
   requires 'Test::Warn' => '0.11';  # older versions may have problems with fresh Sub::Uplevel
   requires 'Test::Without::Module';
};
