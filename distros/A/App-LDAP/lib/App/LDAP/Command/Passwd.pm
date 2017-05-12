package App::LDAP::Command::Passwd;

use Modern::Perl;

use Moose;

with qw( App::LDAP::Role::Command
         App::LDAP::Role::Bindable );

has lock => (
    is  => "rw",
    isa => "Bool",
);

has unlock => (
    is  => "rw",
    isa => "Bool",
);

sub run {
    my ($self,) = @_;

    my $name = $self->extra_argv->[1];

    my $user = $name ? find_user(uid => $name) : current_user();

    if ( $< == 0 ) {
        $self->distinguish->($user);
    } else {
        if ($name and ( find_user(uid => $name)->dn ne current_user->dn ) ) {
            die "you may not view or modify password information for " . $user->dn;
        }
        $self->distinguish->($user);
    }
}

sub distinguish {
    my $self = shift;

    if ($self->lock && $self->unlock) {
        say "I'm dazzled with your key :p";
        exit;
    }

    if ($self->unlock) {
        return \&unlock_user if $> == 0;
        die "Permission denied";
    }

    if ($self->lock) {
        return \&lock_user if $> == 0;
        die "Permission denied";
    }
    return \&change_password;
}

sub change_password {
    my $user = shift;
    use Date::Calc qw(Today Delta_Days);
    $user->replace(
        userPassword     => encrypt(new_password()),
        shadowLastChange => Delta_Days(1970, 1, 1, Today()),
    )->update(ldap());
}

sub lock_user {
    my $user = shift;
    my $password = $user->get_value("userPassword");

    $password =~ s{{crypt}\$}{{crypt}!\$};

    $user->replace(
        userPassword => $password,
    )->update(ldap());
}

sub unlock_user {
    my $user = shift;
    my $password = $user->get_value("userPassword");

    $password =~ s{{crypt}!\$}{{crypt}\$};

    $user->replace(
        userPassword => $password,
    )->update(ldap());
}

use Net::LDAP;
use Net::LDAP::Extension::WhoAmI;
sub current_user {
    my $dn = ldap()->who_am_i->response;
    $dn =~ s{dn:}{};

    my $search = ldap()->search(
        base   => $dn,
        scope  => "base",
        filter => "objectClass=*",
    );

    if ($search->count > 0) {
        return $search->entry(0);
    } else {
        die "$dn not found";
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=pod

=head1 NAME

App::LDAP::Command::Passwd - manage the password in LDAP server

=head1 SYNOPSIS

    $ ldap passwd                  # change your own password

    $ sudo ldap passwd             # change password of ldap admin

    $ sudo ldap passwd shelling    # sudo the privilege of admin to change password of shelling

    $ sudo ldap passwd shelling -l # lock shelling

    $ sudo ldap passwd shelling -u # unlock shelling

=cut

