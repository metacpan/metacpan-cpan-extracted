package App::Zapzi::FetchArticle;
# ABSTRACT: routines to get articles for Zapzi


use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use Module::Find 0.11;
our @_plugins;
BEGIN { @_plugins = sort(Module::Find::useall('App::Zapzi::Fetchers')); }

use Carp;
use App::Zapzi;
use Moo;


has source => (is => 'ro', default => '');


has validated_source => (is => 'rwp', default => '');


has fetcher => (is => 'rwp', default => '');


has text => (is => 'rwp', default => '');


has content_type => (is => 'rwp', default => 'text/plain');


has error => (is => 'rwp', default => '');


sub fetch
{
    my $self = shift;

    my $module;
    for (@_plugins)
    {
        my $plugin = $_;
        my $valid_source = $plugin->handles($self->source);
        if (defined $valid_source)
        {
            $module = $plugin->new(source => $valid_source);
            $self->_set_validated_source($valid_source);
            last;
        }
    }

    if (!defined $module)
    {
        $self->_set_error("Failed to fetch article - can't find or handle");
        return;
    }

    my $rc = $module->fetch;
    if ($rc)
    {
        $self->_set_text($module->text);
        $self->_set_content_type($module->content_type);
        $self->_set_fetcher($module->name);
    }
    else
    {
        $self->_set_error($module->error);
    }

    return $rc;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::FetchArticle - routines to get articles for Zapzi

=head1 VERSION

version 0.017

=head1 DESCRIPTION

These routines get articles, either via HTTP or from the file system
and returns the raw HTML or text.

=head1 ATTRIBUTES

=head2 source

Pass in the source of the article - either a filename or a URL.

=head2 validated_source

The actual source used to fetch the article, eg the full filename
derived from the partial filename passed in to source.

=head2 fetcher

Name of the module that was used to fetch the article.

=head2 text

Holds the raw text of the article

=head2 content_type

MIME content type for text.

=head2 error

Holds details of any errors encountered while retrieving the article;
will be blank if no errors.

=head1 METHODS

=head2 fetch

Retrieves the article and returns 1 if OK. Text of the article can
then be found in L<text>.

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
