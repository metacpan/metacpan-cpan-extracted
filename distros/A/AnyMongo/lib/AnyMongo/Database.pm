package AnyMongo::Database;
BEGIN {
  $AnyMongo::Database::VERSION = '0.03';
}
# ABSTRACT: Asynchronous MongoDB::Database
use strict;
use warnings;
use namespace::autoclean;
use Any::Moose;
use constant {
    SYSTEM_NAMESPACE_COLLECTION => "system.namespaces",
    SYSTEM_INDEX_COLLECTION => "system.indexes",
    SYSTEM_PROFILE_COLLECTION => "system.profile",
    SYSTEM_USER_COLLECTION => "system.users",
    SYSTEM_JS_COLLECTION => "system.js",
    SYSTEM_COMMAND_COLLECTION => '$cmd',
};

has _connection => (
    is       => 'ro',
    isa      => 'AnyMongo::Connection',
    required => 1,
);

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub BUILD {
    my ($self) = @_;
    Any::Moose::load_class("AnyMongo::Collection");
}


sub collection_ns {
    my ($self,$collection_name) = @_;
    return $self->name.'.'.$collection_name;
}

sub collection_names {
    my ($self) = @_;
    my $it = $self->get_collection('system.namespaces')->query({});
    return map {
        substr($_, length($self->name) + 1)
    } map { $_->{name} } $it->all;
}

sub get_collection {
    my ($self, $collection_name) = @_;
    return AnyMongo::Collection->new(
        _database => $self,
        name      => $collection_name,
    );
}

sub get_gridfs {
    my ($self, $prefix) = @_;
    $prefix = "fs" unless $prefix;

    my $files = $self->get_collection("${prefix}.files");
    my $chunks = $self->get_collection("${prefix}.chunks");

    return AnyMongo::GridFS->new(
        _database => $self,
        files => $files,
        chunks => $chunks,
    );
}

sub drop {
    my ($self) = @_;
    return $self->run_command({ 'dropDatabase' => 1 });
}

sub last_error {
    my ($self, $options) = @_;

    my $cmd = Tie::IxHash->new("getlasterror" => 1);
    if ($options) {
        $cmd->Push("w", $options->{w}) if $options->{w};
        $cmd->Push("wtimeout", $options->{wtimeout}) if $options->{wtimeout};
        $cmd->Push("fsync", $options->{fsync}) if $options->{fsync};
    }

    return $self->run_command($cmd);
}

sub run_command {
    my ($self, $command,$hd) = @_;
    my $cursor = AnyMongo::Cursor->new(
        _ns => $self->collection_ns(SYSTEM_COMMAND_COLLECTION),
        _connection => $self->_connection,
        _socket_handle => $hd,
        _query => $command,
        _limit => -1,
        );
    my $obj = $cursor->next;
    return $obj if ref $obj && $obj->{ok};
    $obj->{'errmsg'};
}

sub eval {
    my ($self, $code, $args) = @_;

    my $cmd = tie(my %hash, 'Tie::IxHash');
    %hash = ('$eval' => $code,
             'args' => $args);

    my $result = $self->run_command($cmd);
    if (ref $result eq 'HASH' && exists $result->{'retval'}) {
        return $result->{'retval'};
    }
    else {
        return $result;
    }
}

__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

AnyMongo::Database - Asynchronous MongoDB::Database

=head1 VERSION

version 0.03

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHORS

=over 4

=item *

Pan Fan(nightsailer) <nightsailer at gmail.com>

=item *

Kristina Chodorow <kristina at 10gen.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Pan Fan(nightsailer).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

