package Bryar::DataSource::Multiplex;
use base qw(Bryar::DataSource::Base);

use warnings;
use strict;

=head1 NAME

Bryar::DataSource::Multiplex - multiplex Bryar datasources

=head1 VERSION

version 0.122

 $Id$

=cut

our $VERSION = '0.122';

=head1 DESCRIPTION

This module implements the Bryar::DataSource interface.  It aggregates other
datasources and provides sets of documents from all the multiplexed sources.

It expects to find a config entry called "sources" containing a reference to an
array of sub-configurations.  These elements are used as config data.  The
class named in their "source" key has called methods relayed to it, with the
rest of the element passed as the Bryar configuration data.  The elements must
also have an "id" entry uniquely identifying the datasource.

=head1 METHODS

=cut

=head2 search

(see: L<Bryar::DataSource::Base>)

If the "subblog" parameter has been passed, only the datasource with the given
id is searched.

=cut

sub search {
	my ($self, $config, %params) = @_;

	if ($params{subblog}) {
		my ($source) = grep { $_->{id} eq $params{subblog} } @{$config->{sources}};
		return $source->{source}->search($source, %params);
	}

	if ($params{id} and $params{id} =~ /:/) {
		my ($sourceid, $docid) = $params{id} =~ /(.*?):(.*)/;
		my ($source) = grep { $_->{id} eq $sourceid } @{$config->{sources}};
    ## no critic (ProhibitStringyEval)
		eval "require $source->{source};";
    ## use critic
		return $source->{source}->search($source, (%params, id => $docid));
	}

	my @documents;
	for my $source (@{$config->{sources}}) {
    ## no critic (ProhibitStringyEval)
		eval "require $source->{source};";
    ## use critic
		push @documents,
			map { $_->{id} = "$source->{id}:$_->{id}"; $_ }
			$source->{source}->search($source, %params);
	}
	@documents = sort { $b->epoch <=> $a->epoch } @documents;

	return @documents[0 .. $params{limit} - 1] if $params{limit};
	return @documents;
}

=head2 all_documents

(see: L<Bryar::DataSource::Base>)

=cut

sub all_documents {
	my ($self, $config, %params) = @_;

	my @documents;
	for my $source (@{$config->{sources}}) {
    ## no critic (ProhibitStringyEval)
		eval "require $source->{source};";
    ## use critic
		push @documents,
			map { $_->{id} = "$source->{id}:$_->{id}"; $_ }
			$source->{source}->all_documents($source);
	}
	@documents = sort { $b->epoch <=> $a->epoch } @documents;

}

=head1 AUTHOR

Ricardo Signes, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-bryar-datasource-multiplex@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT

Copyright 2004-2006 Ricardo Signes, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
