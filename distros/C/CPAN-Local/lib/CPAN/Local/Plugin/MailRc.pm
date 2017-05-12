package CPAN::Local::Plugin::MailRc;
{
  $CPAN::Local::Plugin::MailRc::VERSION = '0.010';
}

# ABSTRACT: Update 01mailrc.txt

use strict;
use warnings;

use CPAN::Index::API::File::MailRc;
use CPAN::DistnameInfo;
use IO::String;
use URI;
use Path::Class qw(file dir);
use Carp qw(croak);
use Path::Class::URI;
use List::Util qw(first);
use Regexp::Common qw(URI);
use Compress::Zlib qw(gzopen Z_STREAM_END), '$gzerrno';
use namespace::autoclean;
use Moose;
use MooseX::CoercePerAttribute;
extends 'CPAN::Local::Plugin';
with qw(CPAN::Local::Role::Initialise CPAN::Local::Role::Index);

has 'root' =>
(
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'source' =>
(
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    traits  => [qw(Array CoercePerAttribute)],
    handles => { sources => 'elements' },
    coerce  => { Str => sub { [$_] } }
);

has 'no_update' =>
(
    is  => 'ro',
    isa => 'Bool',
);

sub initialise
{
    my $self = shift;

    dir($self->root)->mkpath;

    my $mailrc = CPAN::Index::API::File::MailRc->new(
        repo_path => $self->root,
    );

    $mailrc->write_to_tarball;
}

sub index
{
    my ($self, @distros) = @_;

    return if $self->no_update;

    my ( @authors, %seen_authors, %authors_in_repo );

    # extract all author ids form the local 02packages.details file
    $authors_in_repo{$_}++ for map {
        CPAN::DistnameInfo->new($_->{distribution})->cpanid
    } CPAN::Index::API::File::PackagesDetails->read_from_repo_path($self->root)->packages;

    # also check the newly injected distros
    $authors_in_repo{$_->{authorid}}++ for @distros;

    foreach my $source ( $self->sources )
    {
        # convert a local path to a 'file://' uri for LWP::Simple::get()
        # (this whole business can be handled better by IO::All)
        my $source_uri = $source =~ /$RE{URI}/ ? URI->new($source) : file($source)->uri;

        my $content = LWP::Simple::get($source_uri->as_string);

        # handle tarballs
        if ($source_uri->path =~ /\.tar\.gz$/) {
            my $io = IO::String->new($content);
            my $gz = gzopen($io, 'rb') or croak "Cannot read gzipped mailrc: $gzerrno";

            my ($buffer, $unzipped_content);

            $unzipped_content .= $buffer while $gz->gzread($buffer) > 0 ;

            croak "Error reading from mailrc: $gzerrno" . ($gzerrno+0) . "\n"
                if $gzerrno != Z_STREAM_END;

            $gz->gzclose and croak "Error closing mailrc";

            $content = $unzipped_content;
        }

        my $mailrc = CPAN::Index::API::File::MailRc->read_from_string($content);

        foreach my $author ( $mailrc->authors )
        {
            next if $seen_authors{$author->{authorid}}++;
            next unless $authors_in_repo{$author->{authorid}};
            push @authors, $author;
        }
    }

    my $combined_mailrc = CPAN::Index::API::File::MailRc->new(
        authors   => \@authors,
        repo_path => $self->root,
    );
    $combined_mailrc->write_to_tarball;
}

sub requires_distribution_roles { qw(Metadata) }

__PACKAGE__->meta->make_immutable;



__END__
=pod

=head1 NAME

CPAN::Local::Plugin::MailRc - Update 01mailrc.txt

=head1 VERSION

version 0.010

=head1 IMPLEMENTS

=over

=item L<CPAN::Local::Role::Initialise>

=item L<CPAN::Local::Role::Index>

=back

=head1 METHODS

=head2 initialise

Initializes the following index files:

=over

=item C<authors/01mailrc.txt.>

=item C<modules/02packages.details.txt.gz>

=item C<modules/03modlist.data.gz>

=back

=head2 index

Updates C<02packages.details.txt.gz> with information for the
newly added distributions.

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

