package App::Zapzi::Transform;
# ABSTRACT: routines to transform Zapzi articles to readable HTML


use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use Module::Find 0.11;
our @_plugins;
BEGIN { @_plugins = sort(Module::Find::useall('App::Zapzi::Transformers')); }

use Carp;
use App::Zapzi;
use App::Zapzi::FetchArticle;
use Moo;



has raw_article => (is => 'ro', isa => sub
                    {
                        croak 'Source must be an App::Zapzi::FetchArticle'
                            unless ref($_[0]) eq 'App::Zapzi::FetchArticle';
                    });


has transformer => (is => 'rw', default => '');


has readable_text => (is => 'rwp', default => '');


has title => (is => 'rwp', default => '');


has error => (is => 'rwp', default => '');


sub to_readable
{
    my $self = shift;

    my $module;
    for (@_plugins)
    {
        my $selected;

        $selected = $_ if $self->transformer &&
                       lc($self->transformer) eq lc($_->name);

        $selected = $_ if !$self->transformer &&
                          ($_->handles($self->raw_article->content_type));

        if ($selected)
        {
            $module = $selected->new(input => $self->raw_article);
            $self->transformer($selected->name);
            last;
        }
    }

    if (! defined($module))
    {
        if ($self->transformer)
        {
            $self->_set_error("no such transformer " .
                              $self->transformer . "\n");
        }
        else
        {
            $self->_set_error("no suitable transformer");
        }

        return;
    }

    my $rc = $module->transform;
    if ($rc)
    {
        $self->_set_title($module->title);
        $self->_set_readable_text($module->readable_text);
    }
    else
    {
        $self->_set_error("error while transforming");
    }

    return $rc;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Transform - routines to transform Zapzi articles to readable HTML

=head1 VERSION

version 0.017

=head1 DESCRIPTION

This class takes text or HTML and returns readable HTML.

=head1 ATTRIBUTES

=head2 raw_article

Object of type App::Zapzi::FetchArticle to get original text from.

=head2 transformer

Name of the transformer to use. If not specified it will choose the
best option based on the content type of the raw article and set this
field.

=head2 readable_text

Holds the readable text of the article

=head2 title

Title extracted from the article

=head2 error

Holds details of any errors encountered while transforming the article;
will be blank if no errors.

=head1 METHODS

=head2 to_readable

Converts L<raw_article> to readable text. Returns true if converted OK.

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
