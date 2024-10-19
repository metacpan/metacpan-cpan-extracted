package Acme::CPANAuthors;

use strict;
use warnings;
use Carp;
use Acme::CPANAuthors::Utils qw( cpan_authors cpan_packages );

our $VERSION = '0.27';

sub new {
  my ($class, @categories) = @_;

  @categories = _list_categories() unless @categories;

  my %authors;
  foreach my $category ( @categories ) {
    %authors = ( %authors, _get_authors_of($category) );
  }

  bless {
      categories => \@categories,
      authors => \%authors,
  }, $class;
}

sub count {
  my $self = shift;

  return scalar keys %{ $self->{authors} };
}

sub id {
  my ($self, $id) = @_;

  unless ( $id ) {
    my @ids = sort keys %{ $self->{authors} };
    return @ids;
  }
  else {
    return $self->{authors}{$id} ? 1 : 0;
  }
}

sub name {
  my ($self, $id) = @_;

  unless ( $id ) {
    return sort values %{ $self->{authors} };
  }
  else {
    return $self->{authors}{$id};
  }
}

sub categories {
  my $self = shift;
  return @{$self->{categories}};
}

sub distributions {
  my ($self, $id) = @_;

  return unless $id;

  my @packages;
  foreach my $package ( cpan_packages->distributions ) {
    if ( $package->cpanid eq $id ) {
      push @packages, $package;
    }
  }

  return @packages;
}

sub latest_distributions {
  my ($self, $id) = @_;

  return unless $id;

  my @packages;
  foreach my $package ( cpan_packages->latest_distributions ) {
    if ( $package->cpanid eq $id ) {
      push @packages, $package;
    }
  }

  return @packages;
}

sub avatar_url {
  my ($self, $id, %options) = @_;

  return unless $id;

  eval {require Gravatar::URL; 1}
      or warn($@), return;
  my $author = cpan_authors->author($id) or return;

  my $default = delete $options{default};
  return Gravatar::URL::gravatar_url(
    email => $author->email,
    %options,
    default => Gravatar::URL::gravatar_url(
      # Fall back to the CPAN address, as used by metacpan, which will in
      # turn fall back to a generated image.
      email => $id . '@cpan.org',
      %options,
      $default ? ( default => $default ) : (),
    ),
  );
}

sub kwalitee {
  my ($self, $id) = @_;

  return unless $id;

  require Acme::CPANAuthors::Utils::Kwalitee;
  return  Acme::CPANAuthors::Utils::Kwalitee->fetch($id);
}

sub look_for {
  my ($self, $id_or_name) = @_;

  return unless defined $id_or_name;
  unless (ref $id_or_name eq 'Regexp') {
    $id_or_name = qr/$id_or_name/i;
  }

  my @found;
  my @categories = ref $self ? @{ $self->{categories} } : ();
  @categories = _list_categories() unless @categories;
  foreach my $category ( @categories ) {
    my %authors = _get_authors_of($category);
    while ( my ($id, $name) = each %authors ) {
      if ($id =~ /$id_or_name/ or $name =~ /$id_or_name/) {
        push @found, {
          id       => $id,
          name     => $name,
          category => $category,
        };
      }
    }
  }
  return @found;
}

sub _list_categories {
  require Module::Find;
  return grep { $_ !~ /^(?:Register|Utils|Not|Search|Factory)$/ }
         map  { s/^Acme::CPANAuthors:://; $_ }
         Module::Find::findsubmod( 'Acme::CPANAuthors' );
}

sub _get_authors_of {
  my $category = shift;

  $category =~ s/^Acme::CPANAuthors:://;

  return if $category =~ /^(?:Register|Utils|Search)$/;

  my $package = "Acme::CPANAuthors\::$category";
  unless ($package->can('authors')) {
    eval "require $package";
    if ( $@ ) {
      carp "$category CPAN Authors are not registered yet: $@";
      return;
    }
    # some may actually lack 'authors' interface
    return unless $package->can('authors');
  }
  $package->authors;
}

1;

__END__

=head1 NAME

Acme::CPANAuthors - We are CPAN authors

=head1 SYNOPSIS

    use Acme::CPANAuthors;

    my $authors = Acme::CPANAuthors->new('Japanese');

    my $number   = $authors->count;
    my @ids      = $authors->id;
    my @distros  = $authors->distributions('ISHIGAKI');
    my $url      = $authors->avatar_url('ISHIGAKI');
    my $kwalitee = $authors->kwalitee('ISHIGAKI');
    my @info     = $authors->look_for('ishigaki');

  If you don't like this interface, just use a specific authors list.

    use Acme::CPANAuthors::Japanese;

    my %authors = Acme::CPANAuthors::Japanese->authors;

    # note that ->author is context sensitive. however, you can't
    # write this without dereference for older perls as "keys"
    # checks the type (actually, the number) of args.
    for my $name (keys %{ Acme::CPANAuthors::Japanese->authors }) {
      print Acme::CPANAuthors::Japanese->authors->{$name}, "\n";
    }

=head1 DESCRIPTION

Sometimes we just want to know something to confirm we're not
alone, or to see if we're doing right things, or to look for
someone we can rely on. This module provides you some basic
information on us.

=head1 WHY THIS MODULE?

We've been holding a Kwalitee competition for Japanese CPAN Authors
since 2006. Though Japanese names are rather easy to distinguish
from Westerner's names (as our names have lots of vowels), it's
tedious to look for Japanese authors every time we hold the contest.
That's why I wrote this module and started maintaining the Japanese
authors list with a script to look for candidates whose name looks
like Japanese by the help of L<Lingua::JA::Romaji::Valid> I coined.

Since then, dozens of lists are uploaded on CPAN. It may be time
to start other games, like offering more useful statistics online.

=head1 WEBSITE

Now we have a website: L<http://acme.cpanauthors.org/>. You can
easily see who is the most kwalitative author in your community,
or who released or updated most in the past 365 days. More statistics
would come, and suggestions are welcome.

=head1 ENVIRONMENTAL VARIABLE

=head2 ACME_CPANAUTHORS_HOME

Since 0.14, Acme::CPANAuthors checks C<ACME_CPANAUTHORS_HOME>
environmental variable to look for a place where CPAN indices
are located. If you have a local (mini) CPAN mirror, or a source
directory for your CPAN clients (C<~/.cpan/sources> etc), set
the variable to point there. If not specified, the indices will
be downloaded from the CPAN (to your temporary directory, or
to the current directory).

=head1 METHODS

=head2 new

creates an object and loads the subclasses corresponding to the
category/categories you specified.
If you don't specify any categories, it tries to load all
the subclasses found just under the "Acme::CPANAuthors"
namespace (except L<Acme::CPANAuthors::Not> and some other internal classes).

=head2 count

returns how many CPAN authors are registered.

=head2 id

returns all the registered ids by default. If called with an
id, this returns if there's a registered author of the id.

=head2 name

returns all the registered authors' name by default. If called
with an id, this returns the name of the author of the id.

=head2 categories

returns the list of categories represented by this class (the names passed to
C<new>).

=head2 distributions, latest_distributions

returns an array of Acme::CPANAuthors::Utils::Packages::Distribution
objects for the author of the id. 

=head2 avatar_url

returns gravatar url of the id shown at search.cpan.org
(or undef if you don't have L<Gravatar::URL>).
See L<http://site.gravatar.com/site/implement> for details.


=head2 kwalitee

returns kwalitee information for the author of the id.
This information is fetched from a remote API server.

=head2 look_for

  my @authors = Acme::CPANAuthors->look_for('SOMEONE');
  foreach my $author (@authors) {
    printf "%s (%s) belongs to %s.\n",
      $author->{id}, $author->{name}, $author->{category};
  }

takes an id or a name (or a part of them, or even a regexp)
and returns an array of hash references, each of which contains
an id, a name, and a basename of the class where the person is
registered. Note that this will load all the installed
Acme::CPANAuthors:: modules but L<Acme::CPANAuthors::Not> and
modules with deeper namespaces.

=head1 SEE ALSO

As of writing this, there are quite a number of lists on the CPAN,
including:

=over 4

=item L<Acme::CPANAuthors::Australian>

=item L<Acme::CPANAuthors::Austrian>

=item L<Acme::CPANAuthors::Belarusian>

=item L<Acme::CPANAuthors::Brazilian>

=item L<Acme::CPANAuthors::British>

=item L<Acme::CPANAuthors::Canadian>

=item L<Acme::CPANAuthors::Catalonian>

=item L<Acme::CPANAuthors::Chinese>

=item L<Acme::CPANAuthors::Czech>

=item L<Acme::CPANAuthors::Danish>

=item L<Acme::CPANAuthors::Dutch>

=item L<Acme::CPANAuthors::EU>

=item L<Acme::CPANAuthors::European>

=item L<Acme::CPANAuthors::French>

=item L<Acme::CPANAuthors::German>

=item L<Acme::CPANAuthors::Icelandic>

=item L<Acme::CPANAuthors::India>

=item L<Acme::CPANAuthors::Indonesian>

=item L<Acme::CPANAuthors::Israeli>

=item L<Acme::CPANAuthors::Japanese>

=item L<Acme::CPANAuthors::Korean>

=item L<Acme::CPANAuthors::Norwegian>

=item L<Acme::CPANAuthors::Portuguese>

=item L<Acme::CPANAuthors::Russian>

=item L<Acme::CPANAuthors::Spanish>

=item L<Acme::CPANAuthors::Swedish>

=item L<Acme::CPANAuthors::Taiwanese>

=item L<Acme::CPANAuthors::Turkish>

=item L<Acme::CPANAuthors::Ukrainian>

=back

These are not regional ones but for some local groups.

=over 4

=item L<Acme::CPANAuthors::Booking>

=item L<Acme::CPANAuthors::British::Companies>

=item L<Acme::CPANAuthors::CodeRepos>

=item L<Acme::CPANAuthors::GeekHouse>

=item L<Acme::CPANAuthors::GitHub>

=back

These are lists for specific module authors.

=over 4

=item L<Acme::CPANAuthors::AnyEvent>

=item L<Acme::CPANAuthors::DualLife>

=item L<Acme::CPANAuthors::POE>

=item L<Acme::CPANAuthors::ToBeLike>

=item L<Acme::CPANAuthors::Acme::CPANAuthors::Authors>

=back

And other stuff.

=over 4

=item L<Acme::CPANAuthors::CPANTS::FiveOrMore>

=item L<Acme::CPANAuthors::Misanthrope>

=item L<Acme::CPANAuthors::Nonhuman>

=item L<Acme::CPANAuthors::Not>

=item L<Acme::CPANAuthors::Pumpkings>

=item L<Acme::CPANAuthors::You::re_using>

=back

Thank you all. And I hope more to come.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2012 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
