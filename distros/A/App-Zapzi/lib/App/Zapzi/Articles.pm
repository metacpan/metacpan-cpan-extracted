package App::Zapzi::Articles;
# ABSTRACT: routines to access Zapzi articles


use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_articles get_article articles_summary add_article
                    move_article delete_article export_article);

use Carp;
use App::Zapzi;
use App::Zapzi::Folders qw(get_folder);


sub get_articles
{
    my ($folder) = @_;

    my $folder_rs = get_folder($folder);
    croak "Folder $folder does not exist" if ! $folder_rs;

    my $rs = _articles()->search({folder => $folder_rs->id},
                                 {prefetch => [qw(folder article_text)] });

    return $rs;
}


sub get_article
{
    my ($id) = @_;

    my $rs = _articles()->find({id => $id});
    return $rs;
}


sub articles_summary
{
    my ($folder) = @_;

    my $rs = get_articles($folder);
    my $summary = [];

    while (my $article = $rs->next)
    {
        push @$summary, {id => $article->id,
                        created => $article->created,
                        source => $article->source,
                        text => $article->article_text->text,
                        title => $article->title};
    }

    return $summary;
}


sub add_article
{
    my %args = @_;

    croak 'Must provide title, source and folder'
        unless $args{title} && $args{source} && $args{folder};

    my $folder_rs = get_folder($args{folder});
    croak "Folder $args{folder} does not exist" unless $folder_rs;

    my $new_article = _articles()->create({title => $args{title},
                                           folder => $folder_rs->id,
                                           source => $args{source},
                                           article_text =>
                                               {text => $args{text}}});

    croak "Could not create article" unless $new_article;

    return $new_article;
}


sub move_article
{
    my ($id, $new_folder) = @_;

    my $article = get_article($id);
    croak 'Article does not exist' unless $article;

    my $new_folder_rs = get_folder($new_folder);
    croak "Folder $new_folder does not exist" unless $new_folder_rs;

    if (! $article->update({folder => $new_folder_rs->id}))
    {
        croak 'Could not move article';
    }

    return 1;
}


sub delete_article
{
    my ($id) = @_;
    my $article = get_article($id);

    # Ignore if the article does not exist
    return 1 unless $article;

    return $article->delete;
}


sub export_article
{
    my $id = shift;

    my $rs = get_article($id);
    return unless $rs;

    my $html = sprintf("<html><head><meta charset=\"utf-8\">\n" .
                       "<title>%s</title></head><body>%s</body></html>\n",
                       $rs->title, $rs->article_text->text);

    return $html;
}

# Convenience function to get the DBIx::Class::ResultSet object for
# this table.

sub _articles
{
    return App::Zapzi::get_app()->database->schema->resultset('Article');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Articles - routines to access Zapzi articles

=head1 VERSION

version 0.017

=head1 DESCRIPTION

These routines allow access to Zapzi articles via the database.

=head1 METHODS

=head2 get_articles(folder)

Returns a resultset of articles that are in C<$folder>.

=head2 get_article(id)

Returns the resultset for the article identified by C<id>.

=head2 articles_summary(folder)

Return a summary of articles in C<folder> as a list of articles, each
item being a hash ref with keys id, created, source, text and title.

=head2 add_article(args)

Adds a new article. C<args> is a hash that must contain

=over 4

=item * C<title> - title of the article

=item * C<source> - source, eg file or URL, of the article

=item * C<folder> - name of the folder to store it in

=item * C<text> - text of the article

=back

The routine will croak if the wrong args are provided,  if the folder
does not exist or if the article can't be created in the database.

=head2 move_article(id, new_folder)

Move the given article to folder C<new_folder>. Will croak if the
folder or article does not exist.

=head2 delete_article(id)

Deletes article C<id> if it exists. Returns the DB result status for
the deletion.

=head2 export_article(id)

Returns the text of article C<id> if it exists, else undef. Text will
be wrapped in a HTML header so it can be viewed separately.

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
