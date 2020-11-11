package App::GitGot::Repo;
our $AUTHORITY = 'cpan:GENEHACK';
$App::GitGot::Repo::VERSION = '1.339';
# ABSTRACT: Base repository objects
use 5.014;

use List::Util qw/ uniq /;
use Types::Standard -types;

use App::GitGot::Types;

use Moo;
use namespace::autoclean;


has label => (
  is  => 'ro' ,
  isa => Str ,
);


has name => (
  is       => 'ro',
  isa      => Str,
  required => 1 ,
);


has number => (
  is       => 'ro',
  isa      => Int,
  required => 1 ,
);


has path => (
  is       => 'ro',
  isa      => Str,
  required => 1 ,
  coerce   => sub { ref $_[0] && $_[0]->isa('Path::Tiny') ? "$_[0]" : $_[0] } ,
);


has repo => (
  is  => 'ro',
  isa => Str,
);


has tags => (
  is  => 'rw',
  isa => Str,
);


has type => (
  is       => 'ro',
  isa      => Str,
  required => 1 ,
);

sub BUILDARGS {
  my( $class , $args ) = @_;

  my $count = $args->{count} || 0;

  die "Must provide entry" unless
    my $entry = $args->{entry};

  my $repo = $entry->{repo} //= '';

  if ( ! defined $entry->{name} ) {
    ### FIXME this is unnecessarily Git-specific
    $entry->{name} = ( $repo =~ m|([^/]+).git$| ) ? $1 : '';
  }

  $entry->{tags} //= '';

  my $return = {
    number => $count ,
    name   => $entry->{name} ,
    path   => $entry->{path} ,
    repo   => $repo ,
    type   => $entry->{type} ,
    tags   => $entry->{tags} ,
  };

  $return->{label} = $args->{label} if $args->{label};

  return $return;
}


sub add_tags {
  my( $self, @tags ) = @_;

  $self->tags( join ' ', uniq sort @tags, split ' ', $self->tags );
}


sub in_writable_format {
  my $self = shift;

  my $writeable = {
    name => $self->name ,
    path => $self->path ,
  };

  foreach ( qw/ repo tags type /) {
    $writeable->{$_} = $self->$_ if $self->$_;
  }

  return $writeable;
}


sub remove_tags {
  my( $self, @tags ) = @_;

  my %verboten = map { $_ => 1 } @tags;

  $self->tags( join ' ', grep { !$verboten{$_} } split ' ', $self->tags );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GitGot::Repo - Base repository objects

=head1 VERSION

version 1.339

=head1 ATTRIBUTES

=head2 label

Optional label for the repo.

=head2 name

The name of the repo.

=head2 number

The number of the repo.

=head2 path

The path to the repo.

=head2 repo

=head2 tags

Space-separated list of tags for the repo

=head2 type

The type of the repo (git, svn, etc.).

=head1 METHODS

=head2 add_tags

Given a list of tags, add them to the current repo object.

=head2 in_writable_format

Returns a serialized representation of the repository for writing out in a
config file.

=head2 remove_tags

Given a list of tags, remove them from the current repo object.

Passing a tag that is not on the current repo object will silently no-op.

=for Pod::Coverage BUILDARGS

=head1 AUTHOR

John SJ Anderson <john@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
