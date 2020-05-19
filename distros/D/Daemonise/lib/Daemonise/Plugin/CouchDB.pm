package Daemonise::Plugin::CouchDB;

use Mouse::Role;

# ABSTRACT: Daemonise CouchDB plugin

use Store::CouchDB;
use Carp;


has 'couch_host' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'localhost' },
);


has 'couch_port' => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => sub { 5984 },
);


has 'couch_db' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'test' },
);


has 'couch_user' => (
    is  => 'rw',
    isa => 'Str',
);


has 'couch_pass' => (
    is  => 'rw',
    isa => 'Str',
);


has 'couch_debug' => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { 0 },
);

has 'couchdb' => (
    is       => 'rw',
    isa      => 'Store::CouchDB',
    required => 1,
);


after 'configure' => sub {
    my ($self, $reconfig) = @_;

    $self->log("configuring CouchDB plugin") if $self->debug;

    if (ref($self->config->{couchdb}) eq 'HASH') {
        foreach
            my $conf_key ('host', 'port', 'user', 'pass', 'db', 'view', 'debug')
        {
            my $attr = "couch_" . $conf_key;
            $self->$attr($self->config->{couchdb}->{$conf_key})
                if defined $self->config->{couchdb}->{$conf_key};
        }
    }

    my $sc = Store::CouchDB->new(
        host  => $self->couch_host,
        port  => $self->couch_port,
        debug => $self->couch_debug,
    );
    $sc->db($self->couch_db) if ($self->couch_db);
    if ($self->couch_user && $self->couch_pass) {
        $sc->user($self->couch_user);
        $sc->pass($self->couch_pass);
    }
    $self->couchdb($sc);

    return;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Daemonise::Plugin::CouchDB - Daemonise CouchDB plugin

=head1 VERSION

version 2.13

=head1 SYNOPSIS

    use Daemonise;
    
    my $d = Daemonise->new();
    $d->debug(1);
    $d->foreground(1) if $d->debug;
    $d->config_file('/path/to/some.conf');
    
    $d->load_plugin('CouchDB');
    
    $d->configure;
    
    # simple document GET (see Store::CouchBB for more)
    my $doc = $d->couchdb->get_doc({id => "some_couchdb_id"});

=head1 ATTRIBUTES

=head2 couch_host

=head2 couch_port

=head2 couch_db

=head2 couch_user

=head2 couch_pass

=head2 couch_debug

=head1 SUBROUTINES/METHODS provided

=head2 configure

=head1 AUTHOR

Lenz Gschwendtner <norbu09@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Lenz Gschwendtner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
