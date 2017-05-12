use strict;
use warnings FATAL => 'all';
use Module::Build;

my $class = Module::Build->subclass( code  => <<'END_OF_CODE' );
sub ACTION_test {
    my $self = shift;
    require App::Prove;
    my $prove = App::Prove->new();
    my @args = qw(--lib -Pt::lib::Prove::Plugin::StartArangoDB);
    $prove->process_args(@args, @{$self->{properties}{test_files}});
    $prove->run();
}
END_OF_CODE

$class->new(
    name                 => 'ArangoDB',
    module_name          => 'ArangoDB',
    dist_author          => 'Hideaki Ohno<hide.o.j55@gmail.com>',
    license              => 'perl',
    recursive_test_files => 1,
    dynamic_config       => 0,
    build_requires       => {
        'Test::More'        => '0.98',
        'App::Prove'        => 0,
        'Test::Fatal'       => 0,
        'Test::Deep'        => 0,
        'Test::TCP'         => 0,
        'Test::Mock::Guard' => 0,
        'File::Temp'        => 0,
    },
    configure_requires => { 'Module::Build' => '0.38' },
    requires           => {
        'perl'                  => '5.008001',
        'parent'                => 0,
        'Scalar::Util'          => '1.19',
        'Class::Accessor::Lite' => '0.05',
        'Carp'                  => 0,
        'JSON'                  => '2.53',
        'List::MoreUtils'       => 0,
        'Furl::HTTP'            => '0.42',
        'MIME::Base64'          => 0,
        'Data::Util'            => '0.59',
    },
    recommends => { 'Data::Clone' => 0, },
    no_index   => { 'directory'   => [ 't', 'xt', 'inc', 'eg' ] },
    test_files => ( -d '.git' || $ENV{RELEASE_TESTING} ) ? [qw(t/ xt/)] : ['t/'],
    create_readme  => 1,
    add_to_cleanup => ['ArangoDB-*'],
    meta_merge     => {
        keywords  => [qw/arngodb database/],
        resources => {
            repository => 'git://github.com/hideo55/p5-ArangoDB.git',
            bugtracker => 'https://github.com/hideo55/p5-ArangoDB/issues',
        },
    },
)->create_build_script();
