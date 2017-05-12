package Class::DBI::Loader::GraphViz;
use Class::DBI::Loader;
use base 'GraphViz::DBI';
use strict;
use warnings;
use Carp qw(croak);
our $VERSION = "1.0";

sub new {
	my ($class, $loader) = @_;
	my $self = $class->SUPER::new();
	$self->{loader} = $loader;
	# Pick the DBH from a random table
	my $table = ($self->get_tables)[0]
		or croak "Don't seem to have any tables";
	$self->set_dbh($loader->_table2class($table)->db_Main);
}

sub get_tables { shift->{loader}->tables }

# Music::CD->has_many(tracks => 'Music::Track');
# Music::CD->has_a(artist => 'Music::Artist');
# is_foreign_key("track", "cd") => "cd"
# is_foreign_key("cd", "artist") => "artist"   
sub is_foreign_key {
	my ($self, $table, $field) = @_;
	my $class = $self->{loader}->_table2class($table);
    return unless $class->can("__hasa_rels");
    my $hasa = $class->__hasa_rels;
	if (exists $hasa->{$field}) {
		return $hasa->{$field}->[0]->table;
	}
	return;
}
	
=head1 NAME

Class::DBI::Loader::GraphViz - Graph tables and relationships

=head1 SYNOPSIS

    my $loader = Class::DBI::Loader->new(
        namespace => "BeerDB",
        dsn => "dbi:SQLite:dbname=t/test.db");
    BeerDB::Beer->has_a(brewery => "BeerDB::Brewery");
    # ...

    my GraphViz $g = $loader->graph_tables;
    my $dot = $g->as_dot;

=head1 DESCRIPTION

This module bridges C<Class::DBI::Loader> and C<GraphViz::DBI>, to
allow C<GraphViz::DBI> to know about C<Class::DBI>'s C<has_a> relationships.

It provides one method in C<Class::DBI::Loader>, C<graph_tables> which
returns a graphviz object.

=head1 SEE ALSO

L<Class::DBI::Loader>, L<GraphViz::DBI>.

=head1 AUTHOR

Simon Cozens, E<lt>simon@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

package Class::DBI::Loader::Generic;

sub graph_tables { return Class::DBI::Loader::GraphViz->new(shift)->graph_tables; }

1;

