requires 'Plack', '0.9910';
requires 'Plack::Request::WithEncoding', '0.10';
requires 'Plack::Response';
requires 'Mouse',       '1.0';
requires 'Try::Tiny',   '0.02';
requires 'Path::Class', '0.16';
requires 'URI';
requires 'URI::WithBase';
requires 'Module::Pluggable::Object';
requires 'Class::Data::Inheritable';
requires 'Data::UUID';
requires 'Data::Util';
requires 'Digest::SHA1';
requires 'Object::Container', '0.08';
requires 'Exporter::AutoClean';
requires 'Path::AttrRouter', '0.03';
requires 'HTML::Escape';

# Ark::Test
requires 'HTTP::Cookies';
requires 'HTTP::Message';

# Context::Debug
requires 'Devel::StackTrace';
requires 'Text::SimpleTable';
requires 'Text::MicroTemplate';

# build-in form generator/validator
requires 'HTML::Shakan', '2.00';
requires 'FormValidator::Lite';
requires 'Clone';

# templates
recommends 'Text::Xslate';
recommends 'Text::MicroTemplate::Extended', '0.09';

# View::JSON
recommends 'JSON';

suggests 'Ark::Plugin::Authentication';
suggests 'Ark::Plugin::MobileJP';
suggests 'Ark::Plugin::I18N';
suggests 'Ark::Plugin::ReproxyCallback';

on test => sub {
    requires 'Test::More' => '0.98';
    requires 'Test::Output';
    requires 'Test::Requires';
};
