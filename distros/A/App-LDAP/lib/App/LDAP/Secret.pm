package App::LDAP::Secret;

use Modern::Perl;
use Moose;
use MooseX::Singleton;

our @locations = qw(
    /etc/ldap.secret
    /etc/libnss-ldap.secret
    /etc/pam_ldap.secret
);

has secret => (
    is  => "rw",
    isa => "Str",
);

sub read {
    my ($class, ) = @_;
    my $self = $class->new;

    my $secret = read_secret(
        grep {
            -f $_ 
        } ( 
            $< == 0 ?
            @locations :
            "$ENV{HOME}/.ldap.secret"
        )
    );

    $self->secret($secret) if $secret;
}

sub read_secret {
    my $file = shift;
    return undef unless $file;

    open FILE, " < $file";
    my $secret = <FILE>;
    chomp $secret;
    return $secret;
}

1;

=pod

=head1 NAME

App::LDAP::Secret - loader of secret file

=head1 DESCRIPTION

this module would be called automatically in App::LDAP::run() to load the password for binding

=cut

