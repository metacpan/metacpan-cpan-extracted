use strict;
use warnings;

use lib "./inc";

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    module_name                => 'App::Notifier::Service',
    license => 'mit',
    dist_author => q{Shlomi Fish <shlomif@cpan.org>},
    dist_version_from => 'lib/App/Notifier/Service.pm',
    dist_abstract => 'HTTP service to notify that an event happened.',
    configure_requires => {
        'Module::Build' => '0.39',
    },
    requires => {
        'Dancer'     => '1.3097',
        'Errno' => 0,
        'File::Spec' => 0,
        'JSON::MaybeXS' => 0,
        'List::MoreUtils' => 0,
        'perl' => '5.014',
        'POSIX' => 0,
        'YAML'       => 0,
        'YAML::XS'       => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    meta_merge =>
    {
        resources =>
        {
            repository => "https://bitbucket.org/shlomif/app-notifier",
            homepage => "http://www.shlomifish.org/open-source/projects/App-Notifier/",
        },
        keywords =>
        [
            'notify',
            'notifier',
            'alert',
            'finish',
            'cue',
        ],
    },
);

$builder->create_build_script;
