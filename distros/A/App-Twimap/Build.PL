#!perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    create_license => 1,
    create_readme  => 1,
    dist_abstract  => 'Push your Twitter home timeline to an IMAP server',
    dist_author    => 'Leon Brocard <acme@astray.com>',
    license        => 'perl',
    meta_merge     => {
        resources =>
            { homepage => 'http://search.cpan.org/dist/App-Twimap/', },
    },
    'meta-spec' => {
        version => '2',
        url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
    },
    module_name => 'App::Twimap',
    requires    => {
        'Algorithm::TokenBucket'     => 0,
        'Config::Tiny'               => 0,
        'DateTime'                   => 0,
        'DateTime::Format::Strptime' => 0,
        'Email::Date::Format'        => 0,
        'Email::MIME'                => 0,
        'Email::MIME::Creator'       => 0,
        'Encode'                     => 0,
        'HTML::Entities'             => 0,
        'List::Util'                 => 0,
        'LWP::UserAgent'             => 0,
        'Mail::IMAPClient'           => 0,
        'Moose'                      => 0,
        'Net::Twitter'               => '4.00006',
        'Web::oEmbed::Common'        => 0,
        'Test::Differences::Color'   => 0,
        'Text::Wrap'                 => 0,
        'TryCatch'                   => 0,
        'URI::WithBase'              => 0,
    },
    sign => 1,
);
$build->create_build_script;
