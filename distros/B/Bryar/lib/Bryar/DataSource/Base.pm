package Bryar::DataSource::Base;
use Bryar::Document;
use 5.006;
use strict;
use warnings;
use Carp;
our $VERSION = '1.0';

=head1 NAME

Bryar::DataSource::Base - Base class for DataSources

=head1 SYNOPSIS

	$self->all_documents(...);
	$self->search(...);

=head1 DESCRIPTION

This class doesn't do anything much, but shows you what you need to
handle when writing your own data source.

=head1 METHODS

=head2 all_documents

    $self->all_documents

Returns all documents making up the blog.

=cut

sub all_documents {
    my ($self, $config) = @_;
    croak "Must pass in a Bryar::Config object" unless UNIVERSAL::isa($config, "Bryar::Config");
    $config->frontend->error("Bad coder. No biscuit",
    "Looks like the programmer used an abstract base class for their
    datasource. That trick obviously won't work.");

    my @docs = get_your_documents_from_somewhere();
    return @docs;
}


=head2 search

    $self->search($config, %params)

A more advanced search for specific documents. Here, we B<do> implement
the search the slow, stupid way, so you can inherit from this if you're
really lazy. However, you should use the parameters to filter which
documents you want to find, doing something like an SQL select
statement.

Parameters you want to look out for:

    contains => "some text"           # Full-text search of entries

    subblog  => "blogname"            # Categorised into some sub-blog
    id       => "uniqueid"            # Unique document identifier, used
                                      # for archive links.

    since    => $epoch_time           # Bounds for when the document was
    before   => $epoch_time           # written

=cut

sub search {
    my ($self, $config, %params) = @_;
    croak "Must pass in a Bryar::Config object" unless UNIVERSAL::isa($config, "Bryar::Config");

    my @docs = $self->all_documents($config);
    my @out_docs;

    for my $doc (@docs) {
        if ($params{subblog}) { next unless $doc->category eq $params{subblog} }
        if ($params{id})      { next unless $doc->id eq $params{id} }
        if ($params{since})   { next unless $doc->epoch > $params{since} }
        if ($params{before})  { next unless $doc->epoch < $params{before} }
        if ($params{contains}){ next unless $doc->content =~ /\Q$params{contains}\E/ }
        # I said it was the slow stupid way.

        push @out_docs, $doc;
        last if $params{limit} and @out_docs >= $params{limit};
    }

    return @out_docs;
}

=head2 add_comment

    Class->add_comment($config,
                       document => $document,
                         author => $author,
                            url => $url,
                        content => $content );

When your class receives this method, it needs to store a comment for a
particular L<Bryar::Document> with the given author name, link and
content. Obviously, we can't implement this for you either.

=cut

sub add_comment {
    die "The old abstract base class problem, I'm afraid."
}

=head1 LICENSE

This module is free software, and may be distributed under the same
terms as Perl itself.

=head1 AUTHOR

Copyright (C) 2003, Simon Cozens C<simon@kasei.com>

=cut

1;
