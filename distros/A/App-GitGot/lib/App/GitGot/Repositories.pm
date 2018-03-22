package App::GitGot::Repositories;
our $AUTHORITY = 'cpan:GENEHACK';
$App::GitGot::Repositories::VERSION = '1.335';
# ABSTRACT: Object holding a collection of repositories
use 5.014;

use Types::Standard -types;

use App::GitGot::Types qw/ GotRepo /;

use Moo;
use MooX::HandlesVia;
use namespace::autoclean;

use overload '@{}' => sub { $_[0]->all };


has repos => (
  is          => 'ro',
  isa         => ArrayRef[GotRepo],
  default     => sub { [] },
  required    => 1,
  handles_via => 'Array' ,
  handles     => {
    all => 'elements'
  }
);


sub name {
  my( $self, $name ) = @_;

  return App::GitGot::Repositories->new( repos => [
    grep { $_->{name} eq $name } $self->all
  ]);
}


sub tags {
  my( $self, @tags ) = @_;

  my @repos = $self->all;

  for my $tag ( @tags ) {
    @repos = grep { $_->tags =~ /\b$tag\b/ } @repos;
  }

  return App::GitGot::Repositories->new( repos => \@repos );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GitGot::Repositories - Object holding a collection of repositories

=head1 VERSION

version 1.335

=head1 ATTRIBUTES

=head2 repos

Array of the C<App::GitGot::Repo> objects in the collection.

=head1 METHODS

=head2 name

Given a repo name, will return a L<App::GitGot::Repositories> object
containing the subset of repos from the current object that have that name.

=head2 tags

Given a list of tag names, returns a L<App::GitGot::Repositories> object
containing the subset of repos from the current object that have one or more
of those tags.

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
