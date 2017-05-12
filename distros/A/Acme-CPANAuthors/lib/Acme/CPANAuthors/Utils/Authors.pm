package Acme::CPANAuthors::Utils::Authors;

use strict;
use warnings;
use base 'Acme::CPANAuthors::Utils::CPANIndex';

sub _mappings {+{author => 'authors'}}

sub _parse {
  my ($self, $file) = @_;

  my $handle = $self->_handle($file);

  while (my $line = $handle->getline) {
    $line =~ s/\r?\n$//;
    my ($alias, $pauseid, $long) = split ' ', $line, 3;
    $long =~ s/^"//;
    $long =~ s/"$//;
    my ($name, $email) = $long =~ /(.*) <(.+)>$/;
    my $author = Acme::CPANAuthors::Utils::Authors::Author->new({
      pauseid => $pauseid,
      name    => $name,
      email   => $email,
    });

    $self->{authors}{$pauseid} = $author;
  }
}

package #
  Acme::CPANAuthors::Utils::Authors::Author;

use strict;
use warnings;
use base 'Class::Accessor::Fast';

__PACKAGE__->mk_ro_accessors(qw/pauseid name email/);

1;

__END__

=head1 NAME

Acme::CPANAuthors::Utils::Authors

=head1 SYNOPSIS

  use Acme::CPANAuthors::Utils::Authors;

  # you can't pass the raw content of 01mailrc.txt(.gz)
  my $authors = Acme::CPANAuthors::Utils::Authors->new(
    'cpan/authors/01mailrc.txt.gz'
  );

  my $author = $authors->author('ISHIGAKI');

=head1 DESCRIPTION

This is a subset of L<Parse::CPAN::Authors>. The reading
methods are similar in general (accessors are marked as
read-only, though). Internals and data-parsing methods may
be different, but you usually don't need to care.

=head1 METHODS

=head2 new

always takes a file name (both raw C<.txt> file and C<.txt.gz>
file name are acceptable). Raw content of the file is not
acceptable.

=head2 author

takes a name of an author, and returns an object that represents it.

=head2 authors

returns a list of stored author objects.

=head2 author_count

returns the number of stored authors.

=head1 AUTHOR ACCESSORS

=head2 pauseid, name, email

  my $author = $authors->author('ISHIGAKI');
  print $author->pauseid, "\n"; # ISHIGAKI
  print $author->name, "\n";    # Kenichi Ishigaki
  print $author->email, "\n";   # ishigaki@cpan.org

=head1 SEE ALSO

L<Parse::CPAN::Authors>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
