package Bryar::Document;
use Time::Piece;
use 5.006;
use strict;
use warnings;
use Carp;
our $VERSION = '1.0';

=head1 NAME

Bryar::Document - Represents a blog post

=head1 SYNOPSIS

	$self->new(...);

	$self->content();     # Get content
	$self->title();       # Get title

	$self->epoch();       # Get epoch
    $self->timepiece();   # Get the date as a Time::Piece object

	$self->category();    # Get category
	$self->author();      # Get author

	$self->keywords(...); # Return keywords relating to this document
    $self->id             # Unique identifier

    $self->comments();    # Get comments

=head1 DESCRIPTION

This encapsulates a blog post, as returned from a search on a data
source.

=head1 METHODS

=head2 new

    $self->new(%params)

Creates a new Bryar::Document instance. 

=cut


sub new {
    my $class = shift;
    my %args = @_;
    my $self = bless {
        epoch =>  $args{epoch} ,
        content =>  $args{content} ,
        author =>  $args{author} ,
        category =>  $args{category} ,
        title =>  $args{title} ,
        id => $args{id},
        comments => ($args{comments} || [])

    }, $class;
    return $self;
}


=head2 content

	$self->content();    # Get content

Gets the value of the document's content

=cut

sub content {
    my $self = shift;
    return $self->{content};
}


=head2 title

	$self->title();    # Get title

Gets the value of the document's title

=cut

sub title {
    my $self = shift;
    return $self->{title};
}


=head2 epoch

	$self->epoch();    # Get epoch

Gets the value of the document's epoch

=cut

sub epoch {
    my $self = shift;
    return $self->{epoch};
}

=head2 timepiece 

Returns the date of the document as a Time::Piece object.

=cut

sub timepiece {
    my $self = shift;
    return Time::Piece->new($self->{epoch});
}

=head2 datetime

Returns the date of the document as a DateTime object

=cut

sub datetime {
    my $self = shift;
    return DateTime->from_epoch( epoch => $self->{epoch}, time_zone => "local" );
}



=head2 category

	$self->category();    # Get category

Gets the value of the document's category

=cut

sub category {
    my $self = shift;
    return $self->{category};
}


=head2 author

	$self->author();    # Get author

Gets the value of the document's author

=cut

sub author {
    my $self = shift;
    return $self->{author};
}


=head2 keywords

    $self->keywords

Returns the keywords for this blog entry, using C<Lingua::EN::Keywords>
if it's installed. May be computationally expensive!

=cut

sub keywords {
    my $self = shift;
    eval { require Lingua::EN::Keywords; };
    return "" if $@;
    return Lingua::EN::Keywords::keywords($self->content);
    # Goodbye, CPU time!
}

=head2 id

	$self->id();    # Get id

Returns a unique identifier for the document.

=cut

sub id {
    my $self = shift;
    return $self->{id};
}

=head2 url

    $self->url;

Returns the post url relative to $bryar->config->baseurl.

=cut

sub url {
    my $self = shift;

    my $id = $self->{id};
    $id =~ s#^.*/##;
    my $url = '';
    $url = '/' . $self->{category} if $self->{category} ne 'main';
    return $url . '/id_' . $id;
}

=head2 comments

    @comments = $self->comments();

Returns a list of L<Bryar::Comment> objects attached to this document.

=cut

sub comments {
    my $self = shift;
    return @{$self->{comments}};
}

=head2 excerpt
	
	my $excerpt = $self->excerpt(20); # get a 20 word excerpt
	my $excerpt = $self->excerpt( );  # get excerpt as long as the excerpt_words config variable

=cut

sub excerpt {
	my $self = shift;
	my $num_words = shift || 40;

	my $content = $self->{content};

	# NOTE: I lifted this from MT, but in reality, i will be making it more flexible and neater.  
	# Now if only this document had some sense of the Bryar environment so it could pull the 
	# default $num_words from the config.
	
	# $text = remove_html($text);
    my @words = split /\s+/, $content;
    my $max_words = @words > $num_words ? $num_words : @words;
    return join ' ', @words[0..$max_words-1];
}

=head1 LICENSE

This module is free software, and may be distributed under the same
terms as Perl itself.

=head1 AUTHOR

Copyright (C) 2003, Simon Cozens C<simon@kasei.com>

=head1 SEE ALSO

=cut

1;
