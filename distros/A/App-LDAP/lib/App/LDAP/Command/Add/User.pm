package App::LDAP::Command::Add::User;

use Modern::Perl;

use Moose;

with qw( App::LDAP::Role::Command
         App::LDAP::Role::Bindable );

has shell => (
    is            => "rw",
    isa           => "Str",
    documentation => "the login shell. default /bin/bash.",
);

has home => (
    is            => "rw",
    isa           => "Str",
    documentation => 'the home directory. default /home/\$username',
);

has group => (
    is            => "rw",
    isa           => "Str",
    documentation => 'the group name. default $username',
);

has base => (
    is            => "rw",
    isa           => "Str",
    documentation => 'the organizational unit this user belongs to. default /etc/ldap/ldap.conf nss_base_passwd.',
);

# inetOrgPerson

has surname => (
    is            => "rw",
    isa           => "ArrayRef[Str]",
    default       => sub { ["NULL"] },
    documentation => 'the surname. default $username',
);

has mail => (
    is            => "rw",
    isa           => "ArrayRef",
    required      => 1,
    documentation => "the email addresses. this option can be multiple values"
);

use App::LDAP::LDIF::User;

around prepare => sub {
    my $orig = shift;
    my $self = shift;

    $self->group($self->extra_argv->[2]) unless $self->group;
    # $self->group is the same as user name if undefined

    $self->$orig(@_);
};

# {{{ sub run
sub run {
    my ($self) = shift;

    my $uid = next_uid();

    my $username = $self->extra_argv->[2] or die "no username specified";

    die "user $username already exists" if App::LDAP::LDIF::User->search(
        base   => config()->{nss_base_passwd}->[0],
        scope  => config()->{nss_base_passwd}->[1],
        filter => "uid=$username",
    );

    my $user = App::LDAP::LDIF::User->new(
        base         => $self->base // config()->{nss_base_passwd}->[0],
        uid          => $username,
        userPassword => encrypt(new_password()),
        uidNumber    => $uid->get_value("uidNumber"),
        gidNumber    => $self->gid_of( $self->group ),
        sn           => $self->surname,
        mail         => $self->mail,
    );

    $user->loginShell    ( $self->shell )  if $self->shell;
    $user->homeDirectory ( $self->home  )  if $self->home;

    $user->save;

    $uid->replace(uidNumber => $uid->get_value("uidNumber")+1)->update(ldap());

    $user;
}
# }}}

sub next_uid {
    ldap()->search(
        base   => config()->{base},
        filter => "(objectClass=uidnext)",
    )->entry(0);
}

sub gid_of {
    my ($self, $groupname) = @_;

    use App::LDAP::LDIF::Group;
    my $group = App::LDAP::LDIF::Group->search(
        base   => config()->{nss_base_group}->[0],
        scope  => config()->{nss_base_group}->[1],
        filter => "cn=$groupname",
    );

    return $group ? $group->gidNumber : $self->create_group($groupname)->gidNumber;
}

sub create_group {
    my ($self, $groupname) = @_;

    use App::LDAP::Command::Add::Group;
    local *ARGV = ['add', 'group', $groupname];

    App::LDAP::Command::Add::Group->new_with_options->run;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=pod

=head1 NAME

App::LDAP::Command::Add::User - handler for adding users

=head1 SYNOPSIS

    # ldap add user hello --mail hello@example.com

    # ldap add user mark --mail mark@facebook.com \
                         --surname Zuckerberg \
                         --group founder \
                         --shell zsh \
                         --home /home/developer/mark


=cut
