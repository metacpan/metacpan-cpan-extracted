package Audio::Metadata::Flac;
{
  $Audio::Metadata::Flac::VERSION = '0.16';
}
BEGIN {
  $Audio::Metadata::Flac::VERSION = '0.15';
}

use strict;
use warnings;
use autodie;

use Any::Moose;
use List::Util qw/first/;
use IO::File;
use Audio::Metadata::Flac::Block;


extends 'Audio::Metadata';

has vendor_string           => ( isa => 'Str', is => 'rw', );
has _block_chain_size_saved => ( isa => 'Int', is => 'rw', );

has _block_chain => (
    isa        => 'Audio::Metadata::Flac::Block',
    is         => 'rw',
    lazy_build => 1,
);
has _comments_block => (
    isa        => 'Audio::Metadata::Flac::Block::Comments',
    is         => 'rw',
    lazy_build => 1,
);


__PACKAGE__->meta->make_immutable;


# FLAC constants.
my $FLAC_MARKER = 'fLaC';

# Delegate variable manipulation to comments block object.
# Moose delegation doesn't work for delegates built lazily.
sub get_var { shift->_comments_block->get_var(@_) }
sub set_var { shift->_comments_block->set_var(@_) }
sub vars_as_hash { shift->_comments_block->comments(@_) }


sub _openr_with_format_check {
    ## Opens the file for reading, checking for format marker.
    my $self = shift;

    # Open the file for reading.
    my $fh = $self->path->openr;

    # Check lead marker to make sure the file is FLAC.
    $fh->read(my $marker, length $FLAC_MARKER);
    die "Not a FLAC file: it does not begin with \"$FLAC_MARKER\"" unless $marker eq $FLAC_MARKER;

    return $fh;
}


sub _build__block_chain {
    ## Populates _block_chain property, reading all metadata blocks into linked list.
    my $self = shift;

    my $fh = $self->_openr_with_format_check;
    my $chain_size;
    my ($head, $tail);
    my $is_last;
    do {
        (my $block, $is_last) = Audio::Metadata::Flac::Block->new_from_fh($fh);
        if (!$tail) {
            $tail = $head = $block;
        }
        else {
            $tail->next($block);
            $tail = $block;
        }
        $chain_size += $block->size;
    } while (!$is_last);

    $fh->close;
    $self->_block_chain_size_saved($chain_size);
    return $head;
}


sub _build__comments_block {
    ## Builds _comments_block attribute.
    my $self = shift;

    # Traverse block chain looking for comment block. Return undef if not found.
    for (my $block = $self->_block_chain; defined $block; $block = $block->next) {
        return $block if ref($block) =~ /::Comments$/;
    }
    return;
}


sub _adjust_padding {
    ## Removes all padding blocks from the block chain and adds one of given size
    ## at the end.
    my $self = shift;
    my ($new_padding_size) = @_;

    # Walk the chain, removing all padding blocks.
    my $removed_count = 0;
    my $last_block;
    for (my $block = $self->_block_chain; defined $block; $block = $block->next) {

        if ($block->next && ref($block->next) =~ /::Padding$/) {
            # Next block is padding, remove it.

            $block->next($block->next->next);
            $removed_count++;
        }
        $last_block = $block;
    }

    # Add padding of specified size to the end.
    my $class = 'Audio::Metadata::Flac::Block::Padding';
    my $added_padding_size = $new_padding_size + (($removed_count - 1) * $class->header_size);
    $last_block->next($class->new(chr(0) x $added_padding_size));
}


sub save {
    ## Overriden.
    my $self = shift;

    # Measure current block chain size and available padding size.
    my ($block_chain_size, $padding_avail) = (0, 0);
    for (my $block = $self->_block_chain; defined $block; $block = $block->next) {
        $block_chain_size += $block->size;
        $padding_avail += $block->content_size if ref($block) =~ /::Padding$/;
    }

    # See how much chain size changed and adjust padding respectively.
    my $block_chain_size_delta = $block_chain_size - $self->_block_chain_size_saved;

    my $with_new_file = 1;
    if ($block_chain_size_delta <= $padding_avail) {
        # Block chain is small enough to be rewritten in the same space.

        $self->_adjust_padding($padding_avail - $block_chain_size_delta);
        $with_new_file = 0;
    }

    # Determine output file name - either the same as input or temporary.
    my $out_file_name = $self->file_path;
    $out_file_name .= ".$$.tmp" if $with_new_file;

    # Write the chain out.
    my $fh = IO::File->new($out_file_name, $with_new_file ? '>' : '+<');
    if ($with_new_file) {
        $fh->syswrite($FLAC_MARKER);
    }
    else {
        $fh->seek(length($FLAC_MARKER), 0);
    }
    for (my $block = $self->_block_chain; defined $block; $block = $block->next) {
        $fh->syswrite($block->as_string);
    }

    if ($with_new_file) {
        # Copy sound stream to the temporary file.

        my $orig_fh = $self->path->openr;
        $orig_fh->seek(length($FLAC_MARKER) + $self->_block_chain_size_saved, 0);
        while ($orig_fh->read(my $buff, 1024)) {
            $fh->syswrite($buff);
        }

        $fh->close;
        $orig_fh->close;
        rename($out_file_name, $self->file_path);
    }
    else {
        $fh->close;
    }

    # Update saved block chain size.
    $self->_block_chain_size_saved($block_chain_size);
}


no Any::Moose;


1;


__END__

=head1 NAME

Audio::Metadata::Flac - FLAC format support for Audio::Metadata

=head1 DESCRIPTION

This module implements FLAC format support for L<Audio::Metadata>. It's implemented in
pure Perl, doesn't rely on external libraries and allows metadata of arbitary length,
rewriting the file, if necessary. For description and usage see L<Audio::Metadata>.

=head1 AUTHOR

Egor Shipovalov, C<< <kogdaugodno at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Egor Shipovalov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
