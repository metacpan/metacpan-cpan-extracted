package Biblio::Zotero::DB::Library::Trash;
$Biblio::Zotero::DB::Library::Trash::VERSION = '0.004';
use strict;
use warnings;
use Moo;

has _db => ( is => 'ro', weak_ref => 1 );

has name => ( is => 'ro', default => sub { 'Trash' } );

sub items {
	my $self = shift;
	my $schema = $self->_db->schema;
	$schema->resultset('Item')->_trash_items;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Library::Trash

=head1 VERSION

version 0.004

=head1 ATTRIBUTES

=head2 name

TODO

=head1 METHODS

=head2 items

TODO

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
