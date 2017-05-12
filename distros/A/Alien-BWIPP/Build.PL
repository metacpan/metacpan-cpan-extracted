use 5.010;
use strict;
use warnings FATAL => 'all';

use Module::Build 0.35_14;
my $build = Module::Build->new(
    license            => 'mit',
    module_name        => 'Alien::BWIPP',
    meta_merge => {
        resources => {
            repository => 'http://github.com/daxim/Alien-BWIPP',
            bugtracker => 'http://github.com/daxim/Alien-BWIPP/issues',
        },
    },
    configure_requires => {
        'perl'          => '5.010',
        'Module::Build' => '0.35_14',
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl'                   => '5.010',
        'English'                => '1.04',
        'File::ShareDir'         => '1.01',
        'IO::File'               => '1.14',
        'Moose'                  => '0.93',
        'Moose::Meta::Class'     => '0.93',
        'MooseX::ClassAttribute' => '0.10',
        'Storable'               => '2.21',
    },
    share_dir => 'share',
);
$build->create_build_script;

__END__

=encoding UTF-8

=head1 INSTALLATION

=head2 system-wide installation

    perl Build.PL
    ./Build
    ./Build test
    sudo ./Build install

=head2 installation in a private directory

    perl Build.PL --install_base ~/modules_prefix
    ./Build
    ./Build test
    ./Build install

Do not forget to add F<$HOME/modules_prefix/lib/perl5> to your C<@INC>, see
L<perlfaq8/"How do I add a directory to my include path (@INC) at runtime?">.
