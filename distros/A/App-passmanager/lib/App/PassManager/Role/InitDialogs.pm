package App::PassManager::Role::InitDialogs;
{
  $App::PassManager::Role::InitDialogs::VERSION = '1.113580';
}
use Moose::Role;

with qw/
    App::PassManager::Role::GnuPG
    App::PassManager::Role::Store
/;

use Curses qw(KEY_ENTER);
use XML::Simple;

#
# This package is a bit of a twisty-turny mess, but works OK.
#

sub get_user_win {
    my ($self, $target) = @_;

    $self->win->{get_user} = $self->ui->add(
        'get_user', 'Window', 
        -title => "User Passphrase",
        $self->win_config,
    );
    $self->win->{get_user}->add(
        "get_user_question", 'Dialog::Question',
        -question => "Enter your passphrase",
    );
    my $q = $self->win->{get_user}->getobj("get_user_question");
    $q->getobj('answer')->set_password_char('*');
    $q->getobj('answer')->set_binding($target, KEY_ENTER());
    $q->getobj('buttons')->set_routine('press-button', $target);
}

sub new_thing_win {
    my ($self, $thing, $next) = @_;

    $self->win->{$thing} = $self->ui->add(
        $thing, 'Window', 
        -title => (ucfirst $thing) ." Passphrase",
        $self->win_config,
    );
    $self->win->{$thing}->add(
        "${thing}question", 'Dialog::Question',
        -question => "Enter the $thing passphrase",
    );
    my $q = $self->win->{$thing}->getobj("${thing}question");
    $q->getobj('answer')->set_password_char('*');
    $q->getobj('answer')->set_binding(sub { $self->new_thing($thing,$next) }, KEY_ENTER());
    $q->getobj('buttons')->set_routine('press-button', sub { $self->new_thing($thing,$next) });
}

sub new_thing {
    my ($self, $thing, $next) = @_;
    my $q = $self->win->{$thing}->getobj("${thing}question");
    my $response = $q->getobj('buttons')->get;
    my $value = $q->getobj('answer')->get;

    $self->cleanup if not $response;

    if (not $value) {
        $self->ui->error('Empty passphrase, try again!');
        my $clear = "clear_$thing";
        $self->$clear;
        $q->getobj('answer')->text('');
        $q->getobj('question')->text("Enter the $thing passphrase");
        return;
    }

    if ($self->$thing) {
        if ($self->$thing eq $value) {
            $self->ui->delete($thing); # XXX hack :-/
            $self->win->{ $next }->focus;
            my $next_init = "init_". $next;
            $self->$next_init;
            return;
        }
        else {
            $self->ui->error('Passphrases do not match, try again!');
            my $clear = "clear_$thing";
            $self->$clear;
            $q->getobj('answer')->text('');
            $q->getobj('question')->text("Enter the $thing passphrase");
        }
    }
    else {
        $self->$thing($value);
        $q->getobj('answer')->text('');
        $q->getobj('question')->text("Enter $thing passphrase again");
    }

    $self->win->{$thing}->focus;
}

sub init_master {
    my $self = shift;
    # nothing to do here
}

sub init_browse {
    my $self = shift;
    # encrypt new store with master password
    $self->encrypt_file($self->store_file, $self->master, '<opt></opt>');
    # encrypt master password with user password
    $self->encrypt_file($self->user_file, $self->user, $self->master);

    $self->data(XML::Simple::XMLin('<opt></opt>', ForceArray => 1));
    $self->category_list;
}

sub init_get_user {
    my $self = shift;
    # stash the new user password before asking for the auth user password
    $self->newuser($self->user);
    $self->clear_user;
}

sub save_user_and_quit {
    my $self = shift;

    my $q = $self->win->{get_user}->getobj("get_user_question");
    my $response = $q->getobj('buttons')->get;
    my $value = $q->getobj('answer')->get;

    $self->cleanup if not $response;

    if (not $value) {
        $self->ui->error('Empty passphrase, try again!');
        $q->getobj('answer')->text('');
        return;
    }

    $self->user($value);
    my $master = scalar eval {
        $self->decrypt_file($self->user_file, $self->user) };

    if (not $master) {
        $self->ui->error('Incorrect passphrase, try again!');
        $q->getobj('answer')->text('');
        return;
    }
    $self->master($master);

    # encrypt master password with new user password
    $self->encrypt_file($self->newuser_file, $self->newuser, $self->master);

    $self->cleanup;
}

sub do_browse {
    my $self = shift;
    my $q = $self->win->{get_user}->getobj("get_user_question");
    my $response = $q->getobj('buttons')->get;
    my $value = $q->getobj('answer')->get;

    $self->cleanup if not $response;

    if (not $value) {
        $self->ui->error('Empty passphrase, try again!');
        $q->getobj('answer')->text('');
        return;
    }

    $self->user($value);
    my $master = scalar eval {
        $self->decrypt_file($self->user_file, $self->user) };

    if (not $master) {
        $self->ui->error('Incorrect passphrase, try again!');
        $q->getobj('answer')->text('');
        return;
    }

    $self->master($master);
    $self->data(XML::Simple::XMLin(
        (join '', ($self->decrypt_file($self->store_file, $self->master))),
        ForceArray => 1,
    ));

    $self->ui->delete('get_user'); # XXX hack :-/
    $self->category_list;
    $self->win->{browse}->focus;
}

1;
