package App::PassManager::Command::open;
{
  $App::PassManager::Command::open::VERSION = '1.113580';
}
use Moose;

extends 'MooseX::App::Cmd::Command';
with qw/
    App::PassManager::CommandRole::Help
    App::PassManager::Role::Files
    App::PassManager::Role::Git
    App::PassManager::Role::CursesWin
    App::PassManager::Role::InitDialogs
/;

sub abstract {
    return "browse and edit the password repository";
}

sub description {
    return <<ENDDESC;
This command will ask for your personal passphrase then open the password
repository for browsing and editing.
ENDDESC
}

sub execute {
    my ($self, $opt, $args) = @_;

    die qq{$0: no password store (need to init?)\n}
        unless -e $self->store_file;

    die qq{$0: git repo is dirty, but I don't yet know how to fix that!\n}
        if $self->git->status->is_dirty;

    die (sprintf qq{%s: no such user "%s" (need to adduser?)\n}, $0, $self->username)
        unless -e $self->user_file;

    # no stderr once we fire up Curses::UI
    open STDERR, '>/dev/null';

    $self->new_base_win;
    $self->get_user_win( sub { $self->do_browse } );

    $self->win->{get_user}->focus;
    $self->ui->mainloop;
}

1;
