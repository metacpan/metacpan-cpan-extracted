# $Id: Buffered.pm,v 1.3 2005/11/29 11:55:01 dk Exp $

package DBIx::Roles::Buffered;

# Saves do() and selectrow_array() in a buffer, calls these as a single query later.
# Useful with lots of UPDATES and INSERTS over connections with high latency

use strict;
use vars qw(%defaults $VERSION);

$VERSION = '1.00';

%defaults = (
	Buffered	=> 1,
	BufferLimit	=> 16384,
);

sub initialize
{
	return {
		buffer	=> [],
		params	=> [],
		curr	=> 0,
		lock	=> 0,
	}, \%defaults, qw(flush);
}

sub dbi_method
{
	my ( $self, $storage, $method, @params) = @_;

	return $self-> super( $method, @params) if
		$storage-> {lock} or
		not $self->{attr}->{Buffered} or
		( $method ne 'do' and $method ne 'selectrow_array');
	my ( $query, $attr_hash) = ( shift @params, shift @params);

	die "Fatal: DBIx::Roles::Buffered does not implement \%attr passed to DBI methods\n"
		if $attr_hash and scalar keys %$attr_hash;
	
	my $length = length($query);
	$length += 2 + length $_ for @params; 

	flush( $self, $storage) if 
		$self-> {attr}-> {BufferLimit} and
		$length + $storage-> {curr} > $self-> {attr}-> {BufferLimit};

	my $expected = scalar( @_ = $query =~ m/\?/g );
	die "Query '$query' contains references to $expected parameters, got ",
		scalar(@params), " passed\n"
		if $expected != @params;

	push @{$storage-> {buffer}}, $query;
	push @{$storage-> {params}}, @params;
	$storage-> {curr} += $length;

	return ( $method eq 'do') ? "0E0" : ();
}

sub flush
{
	my ( $self, $storage, $discard) = @_;
	return unless $storage-> {curr};

	# clear the internal state to be re-entrant
	my $q = join(';', @{$storage->{buffer}});
	my @p = @{$storage->{params}};
	@{$storage->{buffer}} = ();
	@{$storage->{params}} = ();
	$storage-> {curr} = 0;

	local $storage->{lock} = 1;
	$self-> do( $q, {}, @p) unless $discard;
}

sub begin_work
{
	my ( $self, $storage) = @_;
	flush( $self, $storage);
	return $self-> super;
}

sub rollback
{
	my ( $self, $storage) = @_;
	flush( $self, $storage, 1);
	return $self-> super;
}

sub commit
{
	my ( $self, $storage) = @_;
	flush( $self, $storage);
	return $self-> super;
}

sub disconnect
{
	my ( $self, $storage) = @_;
	flush( $self, $storage);
	return $self-> super;
}

sub STORE
{
	my ( $self, $storage, $key, $val) = @_;

	if ( $key eq 'Buffered' and not $val) {
		$self-> {attr}-> {Buffered} = 0;
		flush( $self, $storage);
	} elsif ( $key eq 'BufferLimit') {
		die "Fatal: 'BufferLimit' must be a positive integer"
			unless $val =~ /^\d+$/;
	}

	return $self-> super( $key, $val);
}

1;

__DATA__

=pod

=head1 NAME

DBIx::Roles::Buffered - buffer write-only queries.

=head1 DESCRIPTION

Saves do() and selectrow_array() in a buffer, calls these as a single query later.
Useful with lots of UPDATES and INSERTS over connections with high latency.

=head1 SYNOPSIS

     use DBIx::Roles qw(Buffered);

     my $dbh = DBI-> connect(
           "dbi:Pg:dbname=template1",
	   "postgres",
	   "password",
	   { Buffered => 1, BufferSize => 2048 },
     );

     $dbh-> do('INSERT INTO moo VALUES(?)', {}, 1);
     $dbh-> do('INSERT INTO moo VALUES(?)', {}, 1);
     $dbh-> do('INSERT INTO moo VALUES(?)', {}, 1);
     $dbh-> flush;


=head1 Attributes

=over

=item Buffered $IS_BUFFERED

Boolean flag, does buffering only if 1 ; is 1 by default.
When set to 0, flushes the buffer. 

=item BufferLimit $BYTES

Tries to preserve buffer so that maximal query ( the SQL query, after the
expansion ) is no longer than $BYTES.

=back

=head1 Methods

=over

=item flush [ $DISCARD = 0 ]

Flushes the buffer; discards the buffer content if $DISCARD is 1.

=back

=head1 SEE ALSO

L<DBI>, L<DBIx::Roles>.

=head1 COPYRIGHT

Copyright (c) 2005 catpipe Systems ApS. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Dmitry Karasik <dk@catpipe.net>

=cut
