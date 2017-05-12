package Test::Catalyst::Model::MogileFS::Client::Utils;

use strict;
use warnings;

use base qw/Class::Accessor::Fast/;

use MogileFS::Client;
use MogileFS::Admin;

use Carp::Clan qw(croak);

our $MOGILE_TEST_HOSTS = ($ENV{MOGILE_TEST_HOSTS}) ? [split(/\s+/, $ENV{MOGILE_TEST_HOSTS})] : ['127.0.0.1:7001'];
our $MOGILE_TEST_DOMAIN = $ENV{MOGILE_TEST_DOMAIN} || "test.domain";
our $MOGILE_TEST_CLASS = $ENV{MOGILE_TEST_CLASS} || "test.class";

__PACKAGE__->mk_accessors(qw/admin client hosts domain class/);

sub new {
    my ($class, $args) = @_;

    $args = {} unless ($args);
    $args->{hosts} ||= $MOGILE_TEST_HOSTS;
    $args->{domain} ||= $MOGILE_TEST_DOMAIN;
    $args->{class} ||= $MOGILE_TEST_CLASS;

    my $self = $class->SUPER::new($args);

    eval {
        $self->admin(MogileFS::Admin->new(hosts => $args->{hosts}));
        $self->setup;
        $self->client(MogileFS::Client->new(hosts => $args->{hosts}, domain => $args->{domain}));
    };
    if ($@) {
        croak("Maybe not running mogilefsd, " . $@);
    }

    return $self;
}

sub setup {
    my $self = shift;

    $self->create_domain;
    $self->create_class;
}

sub teardown {
    my $self = shift;

    my $keys;
    eval {
        $keys = $self->client->list_keys("", "");
    };
    if ($@) {
        croak($@);
    }

    foreach my $key (@$keys) {
        $self->client->delete($key);
    }

    my $domains = $self->admin->get_domains;

    foreach my $class (keys %{$domains->{$self->domain}}) {
        $self->delete_class($self->domain, $class);
    }

    $self->delete_domain;
}

sub DESTROY {
    shift->teardown(@_);
}

sub create_domain {
    my ($self, $domain) = @_;
    $domain ||= $self->domain;

    unless ($self->is_exists_domain) {
        $self->admin->create_domain($domain);
    }
}

sub delete_domain {
    my ($self, $domain) = @_;
    $domain ||= $self->domain;

    if ($self->is_exists_domain) {
        $self->admin->delete_domain($domain);
    }
}

sub is_exists_domain {
    my ($self, $domain) = @_;
    $domain ||= $self->domain;

    my $domains = $self->admin->get_domains;

    return (exists $domains->{$domain}) ? 1 : 0;
}

sub create_class {
    my ($self, $domain, $class, $mindevcount) = @_;

    $domain ||= $self->domain;
    $class ||= $self->class;
    $mindevcount ||= 2;

    return $self->admin->create_class($domain, $class, $mindevcount);
}

sub delete_class {
    my ($self, $domain, $class) = @_;

    $domain ||= $self->domain;
    $class ||= $self->class;

    return $self->admin->delete_class($domain, $class);
}

1;
