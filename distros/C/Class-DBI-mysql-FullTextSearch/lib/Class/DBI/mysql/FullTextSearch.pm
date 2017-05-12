package Class::DBI::mysql::FullTextSearch;

=head1 NAME

Class::DBI::mysql::FullTextSearch - Full Text Indexing for Class::DBI::mysql

=head1 SYNOPSIS

  package Film;
  use Class::DBI::mysql::FullTextSearch;

  __PACKAGE__->full_text_search('mysearch' => [qw/title director/]);


  package main;

  use Film;

  my @films = Film->mysearch('Godfather');
  my @films = Film->mysearch('Godfather', { sort => 'title' });
  my @films = Film->mysearch('Godfather', { nsort => 'year' });

=head1 DESCRIPTION

This provides a convenient abstraction to DBIx::FullTextSearch for use
with Class::DBI::mysql. It sets up lots of default values for you, handles
all the updating of the index when you create, delete or edit values, 
and provides a simple way for you to create your search method.

=head1 METHODS

=head2 full_text_search

  Class->full_text_search('search_method_name' => [qw/columns to index/]);

This creates your search method with the required name.

When calling the search method, if you wish to order the resulting values
you can supply a field by which we either 'sort' or 'n(umeric)sort'
the results.

For details on the syntax of the other search arguments etc, see
L<DBIx::FullTextSearch>.

Later versions will provide ways for you to override any of the defaults,
if anyone actually requests it!

=head1 SEE ALSO

L<Class::DBI::mysql>. L<Class::DBI>. L<DBIx::FullTextSearch>.

=head1 AUTHOR

Tony Bowden and Marty Pauley

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Class-DBI-mysql-FullTextSearch@rt.cpan.org

=head1 COPYRIGHT

Copyright (C) 2001-05 Kasei. All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use strict;

require 5.006;
our $VERSION = '1.01';

use base 'Exporter';
use DBIx::FullTextSearch;
use DBIx::FullTextSearch::StopList;

our @EXPORT = 'full_text_search';

sub full_text_search { goto &_make_searcher }

sub _make_searcher {
	my $me      = shift;
	my $callpkg = (caller)[0];
	my $handle  = __PACKAGE__->_handle_for($callpkg, @_);
	my $method  = shift;

	no strict 'refs';

	*{"$callpkg\::$method"} = sub {
		my ($class, $query, $args) = @_;
		my @results = map $class->retrieve($_), $handle->search($query);
		if (my $sortby = $args->{'sort'}) {
			@results = map $_->[0], sort { $a->[1] cmp $b->[1] }
				map [ $_, lc $_->$sortby() ], @results;
		} elsif (my $nsortby = $args->{'nsort'}) {
			@results = map $_->[0], sort { $a->[1] <=> $b->[1] }
				map [ $_, $_->$nsortby() ], @results;
		}
		return @results;

	};

	*{"$callpkg\::_${method}_handle"} = sub { $handle };

	$callpkg->add_trigger(
		before_delete => sub { $handle->delete_document(shift->id) },
		create        => sub { $handle->index_document(shift->id) },
		after_update  => sub { $handle->index_document(shift->id) },
	);
}

sub _handle_for {
	my $class = shift;
	$class->_open_handle(@_) || $class->_create_handle(@_);
}

sub _open_handle {
	my ($class, $other, $method, $cols) = @_;
	DBIx::FullTextSearch->open($other->db_Main => "_fts_$method");
}

sub _create_handle {
	my ($class, $other, $method, $cols) = @_;
	ref($cols) eq "ARRAY" or warn "Columns should be an array ref, not $cols";
	$class->_check_for_stoplist($other);
	my $handle = DBIx::FullTextSearch->create(
		$other->db_Main => "_fts_$method",
		frontend        => 'table',
		backend         => 'phrase',
		stoplist        => '_en',
		stemmer         => 'en-uk',
		table_name      => $other->table,
		column_id_name  => $other->primary_column->name,
		column_name     => $cols,
	);
	$handle->index_document($_->id) for $other->retrieve_all;
	return $handle;
}

sub _check_for_stoplist {
	my $class = shift;
	my $dbh   = shift->db_Main;
	return if eval { DBIx::FullTextSearch::StopList->open($dbh => '_en') };
	DBIx::FullTextSearch::StopList->create_default($dbh, '_en', 'English');
}

1;

