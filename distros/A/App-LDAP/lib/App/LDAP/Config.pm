package App::LDAP::Config;

use Modern::Perl;
use Moose;
use MooseX::Singleton;

our @locations = qw(
  $ENV{HOME}/.ldaprc
  /etc/ldap.conf
  /etc/ldap/ldap.conf
  /usr/local/etc/ldap.conf
);

our @has_scope = qw(
    nss_base_passwd
    nss_base_shadow
    nss_base_group
    nss_base_hosts
    sudoers_base
);

sub read {
    my ($class, ) = @_;
    my $self = $class->new;
    my @locations = grep { -f $_ } @locations;
    die "no config file found" unless scalar @locations;
    $self->read_config_file(@locations);
    $self;
}

sub read_config_file {
    my ($self, $file) = @_;
    open my $config, "<", $file;
    $self->config_from_line($_) while <$config>;
}

sub config_from_line {
    my ($self, $line) = @_;
    return if $line =~ /(^#|^\n)/;

    my ($key, $value) = split /\s+/, $line;
    $self->{$key} = ( 
        $key ~~ @has_scope ? 
        [split /\?/, $value] :
        $value
    );
}

1;

=pod

=head1 NAME

App::LDAP::Config - loader of config files

=head1 DESCRIPTION

This module would be called automatically in App::LDAP::run() to load the configurations.

=cut
