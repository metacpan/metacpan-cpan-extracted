package CPAN::Index::API::File::Whois;

our $VERSION = '0.008';

use strict;
use warnings;

use XML::Twig;
use namespace::autoclean;
use Moose;
use MooseX::ClassAttribute;

with qw(
    CPAN::Index::API::Role::Writable
    CPAN::Index::API::Role::Readable
    CPAN::Index::API::Role::Clonable
    CPAN::Index::API::Role::HavingGeneratedBy
);

class_has _field_map => (
    is      => 'bare',
    isa     => 'HashRef',
    traits  => ['Hash'],
    handles => {
        _original_fields     => 'keys',
        _name_for_orig_field => 'get',
    },
    default => sub { {
        asciiname   => 'ascii_name',
        fullname    => 'full_name',
        email       => 'email',
        has_cpandir => 'has_cpandir',
        homepage    => 'homepage',
        id          => 'cpanid',
        info        => 'info',
        type        => 'type',
    } },
);

has authors => (
    is      => 'bare',
    isa     => 'ArrayRef[HashRef]',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        authors      => 'elements',
        add_author   => 'push',
        author_count => 'count',
    },
);

sub author
{
    my ($self, $name) = @_;
    return first { $_->{cpanid} eq $name } $self->authors;
}

sub parse {
    my ( $self, $content ) = @_;

    my $twig = XML::Twig->new;
    my $xml  = $twig->parse($content);
    my $root = $xml->root;

    my @authors;

    foreach my $author ( $xml->root->children('cpanid') ) {
        my %data;

        foreach my $field ( $self->_original_fields ) {
            if ( my $elt = $author->first_child($field) ) {
                my $elt_text = $elt->text eq '' ? undef : $elt->text;
                $data{ $self->_name_for_orig_field($field) } = $elt_text;
            }
        }

        push @authors, \%data;
    }

   return (
        last_generated => $root->att('last-generated'),
        generated_by   => $root->att('generated-by'),
        authors        => \@authors,
    );
}

sub _build_content {
    my $self = shift;

    my $twig = XML::Twig->new( pretty_print => 'indented' );
    $twig->parse(q[<?xml version="1.0" encoding="UTF-8"?><cpan-whois xmlns='http://www.cpan.org/xmlns/whois'/>]);
    $twig->root->set_att(
        'last-generated' => $self->last_generated,
        'generated-by'   => $self->generated_by,
    );

    foreach my $author ($self->authors) {
        my $elt_cpanid = XML::Twig::Elt->new('cpanid');

        foreach my $name ( $self->_original_fields ) {
            my $name_for_orig_field =  $self->_name_for_orig_field($name);
            if ( exists $author->{$name_for_orig_field} ) {
                my $elt_attribute = XML::Twig::Elt->new($name);
                $elt_attribute->set_text(
                    defined $author->{$name_for_orig_field}
                        ? $author->{$name_for_orig_field} : ''
                );
                $elt_attribute->paste( last_child => $elt_cpanid );
            }
        }

        $elt_cpanid->paste( last_child => $twig->root );
    }

    return $twig->sprint;
}

sub default_location { 'authors/00whois.xml' }

__PACKAGE__->meta->make_immutable;

=pod

=encoding UTF-8

=head1 NAME

CPAN::Index::File::Whois - Interface to C<00whois.xml>.

=head1 SYNOPSIS

  my $mailrc = CPAN::Index::File::Whois->parse_from_repo_uri(
    'http://cpan.perl.org'
  );

  foreach my $author ($mailrc->authors) {
    ... # do something
  }

=head1 DESCRIPTION

This is a class to read and write C<01mailrc.txt>.

=head1 METHODS

=head2 authors

List of hashrefs containing author data. The structure of the hashrefs is
as follows:

=over

=item cpanid

CPAN id of the author, required.

=item full_name

Author's full name. Can be an empty string.

=item ascii_name

Author's full name, but containing only ASCII characters.

=item email

Author's email.

=item has_cpandir

Boolean - true if the author has a cpan directory.

=item homepage

Author's homepage.

=item ino

Additional information about the author.

=item type

Author type, usually C<author>.

=back

=head2 authors_count

Number of authors in this file.

=head2 author

Method that fetches the entry for a given cpanid.

=head2 parse

Parses the file and returns its representation as a data structure.

=head2 default_location

Default file location - C<authors/00whois.xml>.

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

=item L<CPAN::Index::API::Role::HavingGeneratedBy/generated_by>

=item L<CPAN::Index::API::Role::HavingGeneratedBy/last_generated>

=back

=cut
