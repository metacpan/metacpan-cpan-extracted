package App::PassManager::Role::Git;
{
  $App::PassManager::Role::Git::VERSION = '1.113580';
}
use Moose::Role;

use Git::Wrapper;
use XML::Simple;

has '_git' => (
    is => 'ro',
    isa => 'Git::Wrapper',
    reader => 'git',
    lazy_build => 1,
);

sub _build__git {
    my $self = shift;
    return Git::Wrapper->new($self->git_home);
}

sub init_git {
    my $self = shift;

    # silently skip if passmanager home already exists
    if (! -d $self->home) {
        mkdir($self->home)
            or die qq{$0: failed to create home directory: "$!"\n};
    }

    # silently skip if git repo already exists
    if (! -d $self->git_home) {
        mkdir($self->git_home)
            or die qq{$0: failed to create git directory: "$!"\n};
        $self->git->init;
    }
}


# this logging routine is useful in combo with something like:
#   $self->c(scalar [caller(0)]->[3]);
#   $self->dump;

#sub c {
#    my $self = shift;
#    return unless $ENV{PASSMANAGER_TRACE};
#
#    $self->ui->leave_curses;
#    print @_, "\n";
#    $self->ui->reset_curses;
#}

#sub dump {
#    my $self = shift;
#
#    use Data::Dumper;
#    $self->c(Dumper $self->data);
#}

sub abort {
    my $self = shift;

    if ($self->git->status->is_dirty) {
        $self->git->reset({ hard => 1 });
    }

    exit(0);
}

sub cleanup {
    my $self = shift;

    if ($self->data) {
        $self->encrypt_file($self->store_file, $self->master,
            split m/\n+/, XML::Simple::XMLout($self->data));
    }

    if ($self->git->status->is_dirty) {
        $self->git->add($self->git_home);
        $self->git->commit({ all => 1, message => "Updated by ". $self->username });
    }

    exit(0);
}

1;
