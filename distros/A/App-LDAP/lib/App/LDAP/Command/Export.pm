package App::LDAP::Command::Export;

use Modern::Perl;

use Moose;

with qw( App::LDAP::Role::Command
         App::LDAP::Role::Bindable );

has base => (
    is  => "rw",
    isa => "Str",
);

has scope => (
    is  => "rw",
    isa => "Str",
);

has filter => (
    is  => "rw",
    isa => "Str",
);

sub run {
    my ($self) = shift;

    my $file = $self->extra_argv->[1];

    if (! defined($file)) {
        say "you must give the file name to export";
        exit;
    }

    my @entries = ldap()->search(
        base   => $self->base   // config()->{base},
        scope  => $self->scope  // config()->{scope},
        filter => $self->filter // "objectClass=*",
    )->entries;


    open my $output, ">", $file or die "can not open $file";
    for (@entries) {
        print $output $_->ldif;
    }

}


__PACKAGE__->meta->make_immutable;
no Moose;

1;

=head1 NAME

App::LDAP::Command::Export

=head1 SYNOPSIS

    $ sudo ldap export backup.ldif
    backup whole DIT

    $ ldap export people.ldif --base ou=people,dc=example,dc=com
    dump user information without password

    $ sudo ldap export people.ldif --base ou=people,dc=example,dc=com
    dump user information with password

=cut
