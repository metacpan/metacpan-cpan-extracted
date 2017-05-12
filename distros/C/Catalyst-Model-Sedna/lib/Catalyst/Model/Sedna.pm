package Catalyst::Model::Sedna;
use Sedna;
use Moose;

our $VERSION = 0.004;

extends 'Catalyst::Model';
has 'conn' => (is => 'ro',
               isa => 'Sedna',
               required => 1,
               handles => [qw(execute begin
                              rollback getData
                              next commit )]);

__PACKAGE__->meta->make_immutable;

sub BUILDARGS {
    my ($self, $c, $config) = @_;

    my $conn =
      Sedna->connect($config->{url},
                     $config->{db_name},
                     $config->{login},
                     $config->{password});

    $conn->setConnectionAttr(%{$config->{attr}})
      if exists $config->{attr} &&
        ref $config->{attr} eq 'HASH';

    return { conn => $conn };
}

sub get_item {
    my $self = shift;
    if ($self->conn->next) {
        return $self->conn->getItem;
    } else {
        return;
    }
}


sub get_document {
    my ( $self, $doc ) = @_;
    $self->execute( 'for $x in doc("' . $doc . '") return $x' );
    my $data = $self->get_item;
    return $data;
}

sub store_document {
    my ( $self, $xml, $doc_id, $collection ) = @_;
    $self->conn->loadData( $xml, $doc_id, $collection );
    $self->conn->endLoadData();
}

42;

__END__

=head1 NAME

Catalyst::Model::Sedna - Access the Sedna XML Database

=head1 SYNOPSIS

  package MyApp::Model::Sedna;
  use base 'Catalyst::Model::Sedna;
  __PACKAGE__->config({ url => 'localhost',
                        db_name => 'mydb',
                        user => 'myuser',
                        password => 'password' });

  # later in your application
  my $s = $c->model('Sedna');
  $s->execute('for $x in document("doc123") return $x');
  if (my $item = $s->get_item()) {
    $c->res->content_type('application/xml');
    $c->res->body($item);
  }

=head1 DESCRIPTION

This module will manage a connection to the sedna database and perform
queries. The connection attributes are set in the config file. Note
that the Sedna connection does not support cursors, so if you need to
insert data while traversing another query, you need a second
connection.

=head1 METHODS

=over

=item conn

Returns the Sedna connection object.

=item execute/begin/rollback/getData/next/commit

Methods handled directly by the connection.

=item get_item

This is a convenience method that will see if there is a next item
available in the connection and already fetches the entire result to a
scalar value.

=item get_document($id)

This method will do a simple query to fetch a document by its id and
return its content.

=item store_document($xml, $id, $collection)

This method will load the xml data sent into a document of the given
id. Optionally a collection can be sent.

=head1 SEE ALSO

See the Sedna documentation, and also the Sedna bindings.

=head1 AUTHOR

Daniel Ruoso, E<lt>daniel@ruoso.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Daniel Ruoso

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
