package App::LDAP::Role::Stem;

use Modern::Perl;

use Moose::Role;

with qw( App::LDAP::Role );

around run => sub {
    my $orig = shift;
    my $self = shift;

    $self->$orig(@_);

    my $handler = $self->current_handler;

    say "usage: ldap$handler [subhandler]\n";

    say "Available subhandlers are:";

    my $leaves = ref($self)->leaves();

    for (@$leaves) {
        printf("   %-11s", $_);
        # show annotation of the module here;
        say "";
    }
};

sub current_handler {
    my ($self, ) = @_;

    my $command = lc(ref($self));

    $command =~ s{app::ldap::command}{};
    $command =~ s{::}{ }g;
    return $command;
}

no Moose::Role;

1;

=pod

=head1 NAME

App::LDAP::Role::Stem - A stem command shows its submodules

=head1 SYNOPSIS

    package App::LDAP::Command::AStemCommand;
    use Moose;
    with qw( App::LDAP::Role::Command
             App::LDAP::Role::Stem );

    sub run {

    }

=cut
