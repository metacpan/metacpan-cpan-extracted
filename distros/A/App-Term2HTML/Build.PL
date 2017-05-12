use strict;
use warnings;
use Module::Build::Pluggable qw/CPANfile/;

my $builder = Module::Build::Pluggable->new(
    name                => 'App-Term2HTML',
    module_name         => 'App::Term2HTML',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    script_files        => [ 'script/term2html' ],
    dist_version_from   => 'lib/App/Term2HTML.pm',
    add_to_cleanup      => [ 'App-Term2HTML-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/App-Term2HTML',
        bugtracker  => 'http://github.com/bayashi/App-Term2HTML/issues',
        x_IRC       => {
            url => 'irc://chat.freenode.org/#bayadev',
            web => 'http://webchat.freenode.net/?channels=%23bayadev',
        },
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
    create_license => 1,
);

$builder->create_build_script();
