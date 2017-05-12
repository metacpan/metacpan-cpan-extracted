use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Services::SearchParser;
our $VERSION = '0.98';

=pod

=head1 NAME

Apache::Wyrd::Services::SearchParser - Object for performing logical word-searches

=head1 SYNOPSIS

	use Apache::Wyrd::Services::SearchParser;
	
	sub key {'key'};
	sub search {
	
		.....
	
	}
	
	my $parser = Apache::Wyrd::Services::SearchParser->new($self);
	return $parser->parse('(search AND word) OR (web NOT page)');

=head1 DESCRIPTION

Allows for logical parsing of a search using AND, OR, NOT and DIFF
keywords.    Note that these keywords MUST be in upper-case to parse,
otherwise they will be interpreted as the literal words.

Any search object using the parser should implement a C<search()> method
which does a word search against a reverse-key index, returning an array
of hashes.

Designed to work with C<Apache::Wyrd::Services::Index>, but can work
with another search object as long as the search object returns arrays
of hash items with unique IDs under the ID hash key.  This ID hash key
defaults to 'id', which is the default key for an
Apache::Wyrd::Services::Index object.  If your object uses a different
ID key, it should return the (scalar) name of this ID key when it's
C<key()> method is called.

=head1 METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (Apache::Wyrd::Services::SearchParser) C<new> (objectref)

Create a new parser object.  The search object using the parser should
pass a reference to itself as the argument, as C<parse> will call it's
C<search> and C<key> methods.

=cut

sub new {
	my ($class, $creator) = @_;
	die "An object using $class must pass itself as an argument and must define the method search() which returns an array of hashrefs.  It should also define the method key(), which returns the key (i.e. unique ID of the hashes in the array of hashrefs returned by search())"
		unless (UNIVERSAL::can($creator, 'search'));
	my $key = 'id';
	$key = $creator->key if ($creator->can('key'));
	my $data = {
		creator	=>	$creator,
		key		=>	$key,
		counter	=>	0,
		hash	=>	{}
	};
	bless $data, $class;
	return $data;
}

=item (array) C<parse> (scalar, array)

Parse accepts a phrase to parse for searching and an array which it will
transparently pass to the C<search> method of the calling object. 
Returns an array of results derived from recursively calling C<search>
and joining the results based on the logical operators.

=cut

sub parse {
	my ($self, $phrase, @options) = @_;

	#remove leading bogus operators
	$phrase =~ s/^\s*(AND|OR|DIFF)\s*//;

	#change leading NOTs to negative searches
	#WARNING: This is only for compatibility with search engines which
	#understand that a leading '-' in a search term means "return every
	#document that does not match this term".  Apache::Wyrds::Services::Index
	#is one such engine.
	$phrase =~ s/^\s*(NOT)\s*/-/;

	my $result = $self->recursive_parse($phrase, @options);
	return @{$self->{'hash'}->{$result}};
}

sub recursive_parse {
	my ($self, $phrase, @options) = @_;
	my ($matched) = (1);
	while ($matched) {#first deal with parentheticals using a non-greedy regexp.
		$matched = $phrase =~ s/\(([^\(]*?)\)/$self->recursive_parse($1)/e;
	}
	$matched = 1;
	while ($matched) {#then deal with ands
		$matched = $phrase =~ s/(\S+)\s+AND\s+(\S+)/$self->intersection($self->recursive_parse($1),$self->recursive_parse($2))/e;
	}
	$matched = 1;
	while ($matched) {#then deal with ors
		$matched = $phrase =~ s/(\S+)\s+OR\s+(\S+)/$self->union($self->recursive_parse($1),$self->recursive_parse($2))/e;
	}
	$matched = 1;
	while ($matched) {#then deal with nots
		$matched = $phrase =~ s/(\S+)\s+NOT\s+(\S+)/$self->negation($self->recursive_parse($1),$self->recursive_parse($2))/e;
	}
	$matched = 1;
	while ($matched) {#then deal with diffs
		$matched = $phrase =~ s/(\S+)\s+DIFF\s+(\S+)/$self->difference($self->recursive_parse($1),$self->recursive_parse($2))/e;
	}
	return $self->get_results($phrase, @options);
}

sub get_results {
	my ($self, $item, @options) = @_;
	return $item if ($item =~ /__RESULT_\d+__/);
	my $id = $self->new_id;
	$self->{'hash'}->{$id} = [$self->{'creator'}->search($item, @options)];
	#print "item $item is $id\n";
	return $id;
}

sub new_id {
	my $self=shift;
	return '__RESULT_' . $self->{'counter'}++ . '__';
}

sub union {
	my ($self, $a, $b) = @_;
	my $id = $self->new_id;
	$self->{'hash'}->{$id} = $self->join_sets('u', $self->{'key'}, $self->{'hash'}->{$a}, $self->{'hash'}->{$b});
	#use Data::Dumper;
	#warn Dumper($self->{'hash'}->{$a}) . ' union ' . Dumper($self->{'hash'}->{$b}) . ' is ' . Dumper($self->{'hash'}->{$id}) . "\n";
	return $id;
}

sub intersection {
	my ($self, $a, $b) = @_;
	my $id = $self->new_id;
	$self->{'hash'}->{$id} = $self->join_sets('i', $self->{'key'}, $self->{'hash'}->{$a}, $self->{'hash'}->{$b});
	#use Data::Dumper;
	#warn Dumper($self->{'hash'}->{$a}) . ' intersection ' . Dumper($self->{'hash'}->{$b}) . ' is ' . Dumper($self->{'hash'}->{$id}) . "\n";
	return $id;
}

sub negation {
	my ($self, $a, $b) = @_;
	my $id = $self->new_id;
	$self->{'hash'}->{$id} = $self->join_sets('n', $self->{'key'}, $self->{'hash'}->{$a}, $self->{'hash'}->{$b});
	#use Data::Dumper;
	#warn Dumper($self->{'hash'}->{$a}) . ' negation ' . Dumper($self->{'hash'}->{$b}) . ' is ' . Dumper($self->{'hash'}->{$id}) . "\n";
	return $id;
}

sub difference {
	my ($self, $a, $b) = @_;
	my $id = $self->new_id;
	$self->{'hash'}->{$id} = $self->join_sets('d', $self->{'key'}, $self->{'hash'}->{$a}, $self->{'hash'}->{$b});
	#use Data::Dumper;
	#warn Dumper($self->{'hash'}->{$a}) . ' difference ' . Dumper($self->{'hash'}->{$b}) . ' is ' . Dumper($self->{'hash'}->{$id}) . "\n";
	return $id;
}

sub join_sets {
	my ($self, $type, $index, $a, $b) = @_;
	my (@intersection, @difference) = ();
	my (%count, %objects) = ();
	foreach my $e (@$a, @$b) {
		#WARNING: this assumes the arrays @$a and @$b are made of UNIQUE items.
		#Apache::Wyrd::Services::Index returns unique results from the search method.
		$count{$e->{$index}}++;
		$objects{$e->{$index}} = $e;
	}
	return [values %objects] if ($type eq 'u');
	if ($type eq 'n') {
		foreach my $e (@$b) {
			delete $objects{$e->{$index}};
		}
		return [values %objects];
	}
	foreach my $e (keys %count) {
		if ($count{$e} == 2) {
			push @intersection, $objects{$e};
		} else {
			push @difference, $objects{$e};
		}
	}
	if ($type eq 'i') {
		return \@intersection
	}
	return \@difference;
}


=pod

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

UNKNOWN

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;