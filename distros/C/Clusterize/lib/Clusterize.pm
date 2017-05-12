package Clusterize;
use warnings;
use strict;
use Clusterize::Pattern;
our $VERSION = '0.02';

sub pair {
	my ($self, $key, $val) = @_;
	$self->{pairs}{$key} = $val if defined $val; 
	$self->{pairs}{$key}; 
}

sub delete_pair {
	my ($self, $key) = @_;
	delete $self->{pairs}{$key};
}

sub cluster_list { keys %{shift->{clusters}} }
sub remove_cluster_pair {
	my ($self, $digest, $key) = @_;
	delete $self->{clusters}{$digest}{$key};
	delete $self->{clusters}{$digest}
		unless %{$self->{clusters}{$digest}};
}

sub add_cluster_pair {
	my ($self, $digest, $pair) = @_;
	$self->{clusters}{$digest}{$pair->{key}} = $pair->{val};
}

sub cluster_pairs {
	my ($self, $digest) = @_;
	return $self->{clusters}{$digest};
}

sub new { return bless {}, shift }
sub add_pair {
	my ($self, $key, $digest) = @_;
	return if $self->pair($key);
	$digest = Clusterize::Pattern->text2digest($digest)
		if ref $digest eq 'ARRAY';
	$self->pair($key, $digest);
	for (keys %{$digest}) {
		$self->add_cluster_pair($_, {key => $key, val => $digest->{$_}});
	}
}

sub remove_pair {
	my ($self, $key) = @_;
	my $cluster_pair = $self->pair($key) || return;
	for (keys %{$cluster_pair}) {$self->remove_cluster_pair($_, $key)}
	$self->delete_pair($key);
}

sub list {
	my ($self, $opt) = @_;
	my (%md5, @clusters);
	for (map { Clusterize::Pattern->new($self->cluster_pairs($_)) }
		$self->cluster_list($opt)) {
		next if $md5{$_->digest};
		$md5{$_->digest} = 1;
		push @clusters, $_
	}
	@clusters;
}

1;

=head1 NAME

Clusterize - clustering text documents.

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

	use Clusterize;

	my %pairs = (
		key1 => [ string1, string2, ...stringN ],
		key2 => [ string5, string6, ...stringM ],
		...
		keyN => [ ... ],
	);

	my $clusterize = Clusterize->new();
	while (my @pair = each %files) { $clusterize->add_pair(@pair) }

	foreach my $c ( $clusterize->list ) {
		printf "# /%s/ (digest=%s) (accuracy=%.3f) (size=%d)",
			$c->pattern, $digest, $c->accuracy, $c->size;
		my $pairs = $c->pairs;
		for ( keys %{$pairs} ) { print $_." ".$pairs->{$_} }
	}


=head1 DESCRIPTION

B<Clusterize> module implements specific algorithm for clustering text documents.

=head1 PUBLIC METHODS

=head2 new

This is the constructor. No parameter is required.

=head2 add_pair

This method is used to add new document into cluster set:

$clusterize->add_pair($key, [$string1, $string2, ...]);

$key - is uniq name of the document (e.g. filename),
[$string1, $string2, ...] - text of the document.

=head2 remove_pair

This method is used to remove document from cluster set:

$clusterize->remove_pair($key);

$key - is name of the document (e.g. filename).

=head2 list

This method is used to get list of built clusters:

my @clusters = $clusterize->list();

Returns list of B<Clusterize::Pattern> objects with the following attributes:

$c->pattern - regexp that matches all strings in the given cluster;

$c->accuracy - this value reflects how similar strings in the cluster (value from 0 to 1);

$c->size - how many documents in the cluster;

$c->digest - MD5 digest of the cluster to identify duplicate clusters;

$c->pairs - list of { key => $key1, val => $val1 } hash pairs, where:
	key - is name of document, val - is string from 'key' document;

=head1 AUTHOR

Slava Moiseev, <slava.moiseev@yahoo.com>

