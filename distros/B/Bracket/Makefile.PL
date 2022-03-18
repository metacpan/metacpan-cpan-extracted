use inc::Module::Install;

name 'Bracket';
all_from 'lib/Bracket.pm';

requires(
    'Catalyst'                                     => '5.8000',
    'Catalyst::Action::RenderView'                 => 0,
    'Catalyst::Action::REST'                       => 0,
    'Catalyst::Authentication::Store::DBIx::Class' => 0,
    'Catalyst::Model::DBIC::Schema'                => '0.01',
    'Catalyst::Plugin::Authentication'             => '0.10005',
    'Catalyst::Plugin::ConfigLoader'               => 0,
    'Catalyst::Plugin::Session::State::Cookie'     => '0.11',
    'Catalyst::Plugin::Session::Store::DBIC'       => 0,
    'Catalyst::Plugin::Static::Simple'             => 0,
    'Catalyst::View::TT'                           => 0,
    'Config::General'                              => 0,
    'Config::JFDI'                                 => 0,
    'Crypt::Eksblowfish::Bcrypt'                   => 0,
    'DateTime',                                    => 0,
    'DBIx::Class'                                  => '0.08120',
    'DBIx::Class::EncodedColumn'                   => 0,
    'DBIx::Class::Schema'                          => 0,
    'Email::Sender',                               => 0,
    'Email::Simple',                               => 0,
    'Email::Valid',                                => 0,
    'HTML::FormHandler'                            => 0,
    'HTML::FormHandler::Model::DBIC'               => 0,
    'Net::SMTP',                                   => 0,
    'Perl6::Junction',                             => 0,
    'SQL::Translator'                              => '0.11005',
    'Term::Prompt'                                 => 0,
    'Time::HiRes'                                  => 0,
);

#catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
