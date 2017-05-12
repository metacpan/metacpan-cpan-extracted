#
#   Copyright (c) 2005, Presicient Corp., USA
#
# Permission is granted to use this software according to the terms of the
# Artistic License, as specified in the Perl README file,
# with the exception that commercial redistribution, either 
# electronic or via physical media, as either a standalone package, 
# or incorporated into a third party product, requires prior 
# written approval of the author.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# Presicient Corp. reserves the right to provide support for this software
# to individual sites under a separate (possibly fee-based)
# agreement.
#
#	History:
#
#		2005-Jan-27		D. Arnold
#			Coded.
#
package SQL::Amazon::Spool;

use base qw(SQL::Eval::Table);
use strict;

our $engine;

sub new {
	my ($class, $table, $reqids) = @_;
	my $keys = $table->fetch_all($reqids);
	my $metadata = $table->get_metadata();
	my $timeout = time() + $table->get_time_limit();
	my $obj = {
		_keys => $keys,
		_timeout => $timeout,
		_table => $table,
		_reqids => $reqids,
		NAME => $table->name,
		TYPE => $metadata->{TYPE},
		PRECISION => $metadata->{PRECISION},
		SCALE => $metadata->{SCALE},
		NULLABLE => $metadata->{NULLABLE},
		col_names => $metadata->{NAME},
	};

	my %colnums = ();
	$colnums{$obj->{col_names}[$_]} = $_
		foreach (0..$#{$obj->{col_names}});

	$obj->{col_nums} = \%colnums;

	return $class->SUPER::new($obj);
}

sub is_readonly { return 1; }

sub trim { 
	my $x = shift; 
	$x =~ s/^\s+//; 
	$x =~ s/\s+$//; 
	$x; 
}
sub get_metadata {
	my $obj = shift;
	
	return ($obj->{NAME}, 
		$obj->{TYPE}, 
		$obj->{PRECISION}, 
		$obj->{SCALE},
		$obj->{NULLABLE});
}
sub row {
	my $obj = shift;
	return $obj->{_currkey} ?
		$obj->{_table}->fetch($obj->{_currkey}) :
		undef;
}

sub fetch_row ($$) {
    my($obj, $handle) = @_;
	$obj->{errstr} = 'Resultset timeout has expired.',
	$obj->{_keys} = undef,
	return undef
		if (time() > $obj->{_timeout});

	my $cursor = defined($obj->{_cursor}) ?  $obj->{_cursor} : -1;
	my $keys = $obj->{_keys};
	return undef
		if ($cursor >= $#$keys);
	my $row;
	$cursor++;
	while ($cursor <= $#$keys) {
		$row = $obj->{_table}->fetch($keys->[$cursor]);
		$obj->{_currkey} = $keys->[$cursor];
		last if $row;
		$cursor++;
	}
	
	$obj->{_cursor} = $cursor;
	$obj->{errstr} = $row,
	$obj->{row} = undef,
	$obj->{_currkey} = undef,
	return undef
		unless ref $row;

	$obj->{row} = undef,
	$obj->{_currkey} = undef,
	return undef
		unless $row;

	@$row = map( $_ = &trim($_), @$row)
	    if $handle->{Database}{ChopBlanks};

    $obj->{row} = [ @$row ];
    return $obj->{row};
}

sub push_names ($$$) {
    my($obj, $data, $names) = @_;

    return undef;
}

sub push_row ($$$) {
    my($obj, $data, $fields) = @_;

	return undef;
}

sub seek ($$$$) {
    my($obj, $data, $pos, $whence) = @_;
	return 1;
}

sub drop ($$) {
    my($obj, $data) = @_;
    return undef;
}

sub truncate ($$) {
    my ($obj, $data) = @_;
    
    return undef;
}
sub DESTROY { 
	my $obj = shift;
	
	undef; 
}

1;

