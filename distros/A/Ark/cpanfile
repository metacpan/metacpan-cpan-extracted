requires 'Class::Data::Inheritable';
requires 'Clone';
requires 'Data::UUID';
requires 'Exporter::AutoClean';
requires 'FormValidator::Lite';
requires 'HTML::Escape';
requires 'HTML::Shakan', '2.00';
requires 'HTTP::Cookies';
requires 'HTTP::Request';
requires 'JSON';
requires 'Mouse', '1.00';
requires 'Object::Container', '0.08';
requires 'Path::AttrRouter', '0.03';
requires 'Path::Class', '0.16';
requires 'Plack::Request::WithEncoding', '0.10';
requires 'Plack', '0.9910';
requires 'Try::Tiny',   '0.02';
requires 'URI::WithBase';
requires 'perl', '5.008001';

requires 'Cookie::Baker', '0.11';
requires 'Digest::SHA1';

# Context::Debug
requires 'Devel::StackTrace';
requires 'Text::SimpleTable';
requires 'Text::MicroTemplate';

# templates
recommends 'Text::Xslate';
recommends 'Text::MicroTemplate::Extended', '0.09';

suggests 'Ark::Plugin::Authentication';
suggests 'Ark::Plugin::MobileJP';
suggests 'Ark::Plugin::I18N';
suggests 'Ark::Plugin::ReproxyCallback';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'File::Temp';
    requires 'HTTP::Request::Common';
    requires 'Test::More', '0.98';
    requires 'Test::Output';
    requires 'Test::Requires';
    requires 'URI';
};

on develop => sub {
    requires 'Cache::MemoryCache';
    requires 'JSON';
    requires 'Template';
    requires 'Text::MicroTemplate::Extended';
    requires 'Text::Xslate';
};
