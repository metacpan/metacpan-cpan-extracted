package CGI::Wiki::Plugin;

use strict;

use vars qw( $VERSION );
$VERSION = '0.03';

=head1 NAME

CGI::Wiki::Plugin - A base class for CGI::Wiki plugins.

=head1 DESCRIPTION

Provides methods for accessing the backend store, search and formatter
objects of the L<CGI::Wiki> object that a plugin instance is
registered with.

=head1 SYNOPSIS

  package CGI::Wiki::Plugin::Foo;
  use base qw( CGI::Wiki::Plugin);

  # And then in your script:
  my $wiki = CGI::Wiki->new( ... );
  my $plugin = CGI::Wiki::Plugin::Foo->new;
  $wiki->register_plugin( plugin => $plugin );
  my $node = $plugin->datastore->retrieve_node( "Home" );

=head1 METHODS

=over 4

=item B<new>

  sub new {
      my $class = shift;
      my $self = bless {}, $class;
      $self->_init if $self->can("_init");
      return $self;
  }

Generic contructor, just returns a blessed object.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->_init if $self->can("_init");
    return $self;
}

=item B<datastore>

Returns the backend store object, or C<undef> if the C<register_plugin>
method hasn't been called on a L<CGI::Wiki> object yet.

=cut

sub datastore {
    my $self = shift;
    $self->{_datastore} = $_[0] if $_[0];
    return $self->{_datastore};
}

=item B<indexer>

Returns the backend search object, or C<undef> if the
C<register_plugin> method hasn't been called on a L<CGI::Wiki> object
yet, or if the wiki object had no search object defined.

=cut

sub indexer {
    my $self = shift;
    $self->{_indexer} = $_[0] if $_[0];
    return $self->{_indexer};
}

=item B<formatter>

Returns the backend formatter object, or C<undef> if the C<register_plugin>
method hasn't been called on a L<CGI::Wiki> object yet.

=cut

sub formatter {
    my $self = shift;
    $self->{_formatter} = $_[0] if $_[0];
    return $self->{_formatter};
}

=back

=head1 SEE ALSO

L<CGI::Wiki>

=head1 AUTHOR

Kake Pugh (kake@earth.li).

=head1 COPYRIGHT

     Copyright (C) 2003-4 Kake Pugh.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;





