# Copyright (c) 2024 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2024 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with Tag databases

package Data::TagDB::Exporter;

use v5.10;
use strict;
use warnings;

use Carp;

our $VERSION = v0.08;

use parent 'Data::TagDB::WeakBaseObject';

use constant {
    FORMAT_TAGPOOL_SOURCE_FORMAT => 'e5da6a39-46d5-48a9-b174-5c26008e208e',
    FORMAT_TAGPOOL_TAGLIST_V1    => 'afdb46f2-e13f-4419-80d7-c4b956ed85fa',

    FEATURE_MODERN_LIMITED       => 'f06c2226-b33e-48f2-9085-cd906a3dcee0',
};



sub db {
    my ($self) = @_;
    return $self->{db};
}


sub tag {
    my ($self, $tag, %opts) = @_;
    my $format = $self->{format};
    my Data::TagDB $db = $self->db;
    my $ise = $tag->ise;

    return if exists $self->{tags_done}->{$ise};
    $self->{tags_done}->{$ise} = undef;

    if ($format eq FORMAT_TAGPOOL_SOURCE_FORMAT) {
        my File::ValueFile::Simple::Writer $writer = $self->_valuefile_handle;

        $writer->write;
        $writer->write_tag_ise($tag);
        unless ($opts{skip_metadata}) {
            $db->metadata(tag => $tag)->foreach(sub {
                    $writer->write_tag_metadata($_[0]);
                });
        }
        unless ($opts{skip_relation}) {
            $db->relation(tag => $tag)->foreach(sub {
                    $writer->write_tag_relation($_[0]);
                });
        }
    } elsif ($format eq FORMAT_TAGPOOL_TAGLIST_V1) {
        my File::ValueFile::Simple::Writer $writer = $self->_valuefile_handle;
        $writer->write(tag => $tag);
    } else {
        croak 'Bad format';
    }
}


sub metadata {
    my ($self, $link, %opts) = @_;
    my $format = $self->{format};
    my Data::TagDB $db = $self->db;

    if ($format eq FORMAT_TAGPOOL_SOURCE_FORMAT) {
        my File::ValueFile::Simple::Writer $writer = $self->_valuefile_handle;
        $writer->write_tag_metadata($link);
    } else {
        croak 'Bad format';
    }
}


sub relation {
    my ($self, $link, %opts) = @_;
    my $format = $self->{format};
    my Data::TagDB $db = $self->db;

    if ($format eq FORMAT_TAGPOOL_SOURCE_FORMAT) {
        my File::ValueFile::Simple::Writer $writer = $self->_valuefile_handle;
        $writer->write_tag_relation($link);
    } else {
        croak 'Bad format';
    }
}

# ---- Private helpers ----

sub _new {
    my ($pkg, @args) = @_;
    my $self = $pkg->SUPER::_new(@args);

    $self->{format} //= FORMAT_TAGPOOL_SOURCE_FORMAT;
    $self->{format} = $self->{format}->ise if ref $self->{format};

    $self->{tags_done} = {};

    return $self;
}

sub _valuefile_handle {
    my ($self) = @_;
    require File::ValueFile::Simple::Writer;
    return $self->{_valuefile_handle} //= File::ValueFile::Simple::Writer->new(
        $self->{target},
        format => $self->{format},
        required_feature => [
            $self->{format} eq FORMAT_TAGPOOL_SOURCE_FORMAT ? (FEATURE_MODERN_LIMITED) : (),
        ],
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagDB::Exporter - Work with Tag databases

=head1 VERSION

version v0.08

=head1 SYNOPSIS

    use Data::TagDB;

    my Data::TagDB $db = Data::TagDB->new(...);

    my Data::TagDB::Exporter $exporter = $db->exporter(...);

    $exporter->tag($tag);
    $exporter->metadata($metadata);
    $exporter->relation($relation);

Generic exporter for database entries.

See also L<Data::TagDB/exporter>.

=head1 METHODS

=head2 db

    my Data::TagDB $db = $exporter->db;

Returns the current L<Data::TagDB> object.

=head2 tag

    $exporter->tag($tag [, %opts ] );

Exports a single tag.

C<$tag> must be a L<Data::TagDB::Tag>.

The following options (all optional) are supported:

=over

=item C<skip_metadata>

If set true do not export metadata associated with this tag.
If the selected format does not support metadata this option is silently ignored.

=item C<skip_relation>

If set true do not export relations associated with this tag.
If the selected format does not support metadata this option is silently ignored.

=back

=head2 metadata

    $exporter->metadata($metadata);

Exports the given metadata. It needs to be an instance of L<Data::TagDB::Metadata>.
If the selected format does not support metadata this method C<die>s.

=head2 relation

    $exporter->relation($relation);

Exports the given relation. It needs to be an instance of L<Data::TagDB::Relation>.
If the selected format does not support relations this method C<die>s.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
