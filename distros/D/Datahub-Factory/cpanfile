requires 'perl', '5.008005';

# requires 'Some::Module', 'VERSION';

on 'test', sub {
  requires 'Log::Any::Adapter::Log4perl', 0;
  requires 'Log::Any::Test', '1.03';
  requires 'Log::Log4perl' , 0;
  requires 'Test::Deep', '0.112';
  requires 'Test::Exception', '0.43';
  requires 'Test::LWP::UserAgent' , 0;
  requires 'Test::More', '0.99';
  requires 'Test::Pod', 0;
};

requires 'Catmandu', '1.0603';
requires 'App::Cmd';
requires 'Config::Simple';
requires 'Catmandu::LIDO';
requires 'Catmandu::Store::Datahub';
requires 'HTTP::Request::StreamingUpload';
requires 'Log::Any';
requires 'Log::Any::Adapter';
requires 'Log::Any::Adapter::Log4perl';
requires 'Log::Log4perl';
requires 'Module::Load';
requires 'Moo';
requires 'MooX::Aliases';
requires 'Moose::Role';
requires 'MooX::Role::Logger';
requires 'namespace::clean';
requires 'Sub::Exporter';
requires 'Catmandu::OAI';
requires 'Catmandu::Solr';
requires 'Catmandu::Importer::XML';
requires "Ref::Util";
requires "DateTime";
requires 'Term::ANSIColor';
requires 'Try::Tiny';
requires 'URI::URL';
requires 'Config::Onion';
requires 'HTTP::Headers';
requires 'HTTP::Request::Common';
requires 'JSON';
requires 'Try::Tiny::ByClass';
requires 'XML::LibXML';
requires 'DBI';

# https://github.com/libwww-perl/libwww-perl/issues/201
conflicts "LWP::Authen::Negotiate";

on test => sub {
    requires 'Test::More', '0.96';
};
