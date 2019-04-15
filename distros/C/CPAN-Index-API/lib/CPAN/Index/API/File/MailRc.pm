package CPAN::Index::API::File::MailRc;

our $VERSION = '0.008';

use strict;
use warnings;
use Scalar::Util qw(blessed);
use namespace::autoclean;
use Moose;

with qw(
    CPAN::Index::API::Role::Writable
    CPAN::Index::API::Role::Readable
    CPAN::Index::API::Role::Clonable
);

has authors => (
    is      => 'bare',
    isa     => 'ArrayRef',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        author_count => 'count',
        authors      => 'elements',
    },
);

sub sorted_authors {
    my $self = shift;
    return sort { $a->{authorid} cmp $b->{authorid} } $self->authors;
}

sub parse {
    my ( $self, $content ) = @_;

    my @authors;

    if ($content)
    {

        foreach my $line ( split "\n", $content ) {
            my ( $alias, $authorid, $long ) = split ' ', $line, 3;
            $long =~ s/^"//;
            $long =~ s/"$//;
            my ($name, $email) = $long =~ /(.*) <(.+)>$/;

            undef $email if $email eq 'CENSORED';

            my $author = {
                authorid => $authorid,
                name     => $name,
                email    => $email,
            };

            push @authors, $author;
        }
    }

    return ( authors => \@authors );
}

sub default_location { 'authors/01mailrc.txt.gz' }

__PACKAGE__->meta->make_immutable;

=pod

=encoding UTF-8

=head1 NAME

CPAN::Index::File::MailRc - Interface to C<01mailrc.txt>.

=head1 SYNOPSIS

  my $mailrc = CPAN::Index::File::MailRc->parse_from_repo_uri(
    'http://cpan.perl.org'
  );

  foreach my $author ($mailrc->sorted_authors) {
    ... # do something
  }

=head1 DESCRIPTION

This is a class to read and write C<01mailrc.txt>.

=head1 METHODS

=head2 authors

List of hashrefs containing author data. The structure of the hashrefs is
as follows:

=over

=item authorid

CPAN id of the author. This should be a string containing only capital Latin
letters and is at least 2 characters long.

=item name

Author's full name.

=item email

Author's email.

=back

=head2 sorted_authors

List of authors sorted by pause id.

=head2 parse

Parses the file and returns its representation as a data structure.

=head2 default_location

Default file location - C<authors/01mailrc.txt.gz>.

=head1 METHODS FROM ROLES

=over

=item <CPAN::Index::API::Role::Readable/read_from_string>

=item <CPAN::Index::API::Role::Readable/read_from_file>

=item <CPAN::Index::API::Role::Readable/read_from_tarball>

=item <CPAN::Index::API::Role::Readable/read_from_repo_path>

=item <CPAN::Index::API::Role::Readable/read_from_repo_uri>

=item L<CPAN::Index::API::Role::Writable/tarball_is_default>

=item L<CPAN::Index::API::Role::Writable/repo_path>

=item L<CPAN::Index::API::Role::Writable/template>

=item L<CPAN::Index::API::Role::Writable/content>

=item L<CPAN::Index::API::Role::Writable/write_to_file>

=item L<CPAN::Index::API::Role::Writable/write_to_tarball>

=item L<CPAN::Index::API::Role::Clonable/clone>

=back

=cut

__DATA__
[%
    foreach my $author ($self->sorted_authors) {
        $OUT .= sprintf qq[alias %s "%s <%s>"\n],
            $author->{authorid},
            $author->{name},
            $author->{email} ? $author->{email} : 'CENSORED';
    }
%]
