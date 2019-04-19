use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App::Task',
    license           => 'artistic2',
    dist_author       => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from => 'lib/App/Task.pm',
    requires          => {
        'Test::More'            => 0,
        'Test::Trap'            => 0,
        'Text::OutputFilter'    => 0,
        'Tie::Handle::Base'     => 0,
        'IPC::Open3::Utils'     => 0,
        'IO::Interactive::Tiny' => 0,
    },

    # delete_share => '.', # NYI https://rt.cpan.org/Ticket/Display.html?id=92863
    # install_share => 'share',
    add_to_cleanup => ['App-Task-*'],
);

$builder->create_build_script();

# package MY;
# use File::ShareDir::Install 0.07 qw(postamble);
# File::ShareDir::Install::delete_share('.');
