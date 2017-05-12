# Copyright 2008-2010 Tim Rayner
# 
# This file is part of Bio::MAGETAB.
# 
# Bio::MAGETAB is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
# 
# Bio::MAGETAB is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Bio::MAGETAB.  If not, see <http://www.gnu.org/licenses/>.
#
# $Id: TagValueFile.pm 382 2013-11-26 11:03:51Z tfrayner $

package Bio::MAGETAB::Util::Reader::TagValueFile;

use Moose;
use MooseX::FollowPBP;

use Carp;
use List::Util qw(first);

use MooseX::Types::Moose qw( HashRef );

BEGIN { extends 'Bio::MAGETAB::Util::Reader::Tabfile' };

has 'text_store'          => ( is         => 'rw',
                               isa        => HashRef,
                               default    => sub { {} },
                               required   => 1 );

has 'dispatch_table'      => ( is         => 'rw',
                               isa        => HashRef,
                               default    => sub { {} },
                               required   => 1 );

# Define some standard regexps:
my $BLANK = qr/\A [ ]* \z/xms;
my $COMMENT_TAG = qr/\A \s* Comment \s* \[ ([^\]]+) \] \s* \z/ixms;

###################
# Private methods #
###################

sub _create_termsources {

    my ( $self ) = @_;

    my @termsources;
    TS:
    foreach my $ts_data ( @{ $self->get_text_store()->{'termsource'} } ) {

        # Term Sources without Names are never going to work, so we skip them.
        next TS unless ( defined $ts_data->{'name'}
                              && $ts_data->{'name'} !~ $BLANK );

        my $termsource = $self->get_builder()->find_or_create_term_source( $ts_data );
	push @termsources, $termsource;
    }

    return \@termsources;
}

sub _create_controlled_terms {

    my ( $self, $type, $category ) = @_;

    my @terms;
    TERM:
    foreach my $term_data ( @{ $self->get_text_store()->{ $type } } ) {

        # Value is required for all ControlledTerm objects.
        next TERM unless ( defined $term_data->{'value'}
                                && $term_data->{'value'} !~ $BLANK );

        my $termsource;
        if ( my $ts = $term_data->{'termSource'} ) {
            $termsource = $self->get_builder()->get_term_source({
                'name' => $ts,
            });
        }

        my $args = {
            'category'   => $category,
            'value'      => $term_data->{'value'},
        };
        $args->{'accession'}  = $term_data->{'accession'}
            if defined $term_data->{'accession'};
        $args->{'termSource'} = $termsource if $termsource;

        my $term = $self->get_builder()->find_or_create_controlled_term( $args );

	push @terms, $term;
    }

    return \@terms;
}

sub _create_comments {

    my ( $self ) = @_;

    my @comments;
    COMM:
    foreach my $entry ( @{ $self->get_text_store()->{'comment'} } ) {

        my $values = $entry->{ 'store' };

        # Value is required for all Comment objects.
        foreach my $value ( @$values ) {
            next COMM unless ( defined $value
                                   && $value !~ $BLANK );
            
            my $comment = $self->get_builder()->find_or_create_comment({
                'name'    => $entry->{ 'name' },
                'value'   => $value,
            });

            push @comments, $comment;
        }
    }

    return \@comments;
}

sub _read_as_arrayref {

    # Method to parse the TagValueFile object file into an array of
    # arrayrefs. This method uses Text::CSV_XS to parse tab-delimited
    # text.

    my ( $self ) = @_;

    # This is required for Text::CSV_XS.
    local $/ = $self->get_eol_char();

    my (@rows, $larry);

    FILE_LINE:
    while ( $larry = $self->getline() ) {

        # Skip empty lines, comments.
        next FILE_LINE if $self->can_ignore( $larry );

	# Strip surrounding whitespace from each element.
        $larry = $self->strip_whitespace( $larry );

	# Strip off empty trailing values.
	my $end_value;
	until ( defined($end_value) && $end_value !~ /\A \s* \z/xms ) {
	    $end_value = pop(@$larry);
	}
	push @$larry, $end_value;

	# Reset empty strings to undefs.
	foreach my $value ( @$larry ) {
	    undef($value) if ( defined($value) && $value eq q{} );
	}

	push @rows, $larry;
    }

    # Check we've parsed to the end of the file.
    $self->confirm_full_parse();

    return \@rows;
}

sub _validate_arrayref_tags {

    # Method to check the return value from _read_as_arrayref to check
    # for (a) duplicate tags, and (b) unrecognised tags. Returns a
    # hash with keys corresponding to known tags and value arrayrefs
    # containing the file annotation.

    my ($self, $array_of_rows) = @_;

    # Array with row tags linked to rest-of-row arrayref values.
    my @file_data;
    foreach my $row ( @{ $array_of_rows } ) {
        push @file_data, [ $row->[0], [@{ $row }[1..$#$row] ] ];
    }

    # A list of acceptable tags, expressed as qr//
    my @acceptable = keys %{ $self->get_dispatch_table() };
    foreach my $datum ( @file_data ) {
        my ( $tag, $values ) = @$datum;

	# N.B. acceptable tag REs may contain whitespace; no x option
	# here.
	next if $tag =~ /\A\s*$COMMENT_TAG\s*\z/ms;

	# Check for recognised tags here.
	unless ( first { $tag =~ /\A\s*$_\s*\z/ms } @acceptable ) {
	    croak(qq{Error: unrecognized tag(s): "$tag"});
	}

	# Empty Name tags are invalid and will cause fatal crashes
	# later; we check for them here.
	if ( $tag =~ m/name \s* \z/ixms ) {
	    foreach my $value ( @$values ) {
		warn(
		    qq{Warning: Name attribute "$tag" is empty.\n}
		) unless $value;
	    }
	}
    }

    return \@file_data;
}

sub _add_grouped_data {

    # Create an ordered set of data groups indexed by $i.
    my ( $self, $group, $tag, @args ) = @_;

    for ( my $i = 0; $i <= $#args; $i++ ) {

        # It's conceivable that this should actually be valid, but
        # until someone comes up with a way to unambiguously group
        # more than one set of lines specifying a given list of
        # objects (e.g. protocols) *within the current specification*,
        # it's not practical to try and support it.
        if ( defined $self->get_text_store()->{ $group }[$i]{ $tag } ) {
            croak("Error: Duplicate $group $tag field encountered")
        }
        $self->get_text_store()->{ $group }[$i]{ $tag } = $args[$i];
    }

    return;
}

sub _add_singleton_data {

    # Record a 1:n object:args relationship.
    my ( $self, $group, $tag, @args ) = @_;

    # Make a copy of @args, just in case.
    my $data = $self->get_text_store()->{ $group }{ $tag } || [];
    push @{ $data }, @args;
    my %uniq = map { $_ => 1 } @{ $data };
    $self->get_text_store()->{ $group }{ $tag } = [ keys %uniq ];

    return;
}

sub _add_singleton_datum {

    # Record a 1:1 group:arg relationship.
    my ( $self, $group, $tag, $arg ) = @_;

    # These really aren't allowed to be duplicated so we throw an
    # error here rather than try and cope.
    if ( defined $self->get_text_store()->{ $group }{ $tag } ) {
        croak("Error: Duplicate $group $tag field encountered");
    }

    $self->get_text_store()->{ $group }{ $tag } = $arg;

    return;
}

sub _retrieve_comment_store {

    my ( $self, $name ) = @_;

    $self->get_text_store()->{ 'comment' } ||= [];

    # For brevity.
    my $ref = $self->get_text_store()->{ 'comment' };

    foreach my $entry ( @{ $ref } ) {
        if ( $entry->{ 'name' } eq $name ) {
            return $entry->{ 'store' };
        }
    }

    my $new = { 'name' => $name, 'store' => [] };
    push @{ $ref }, $new;

    return $new->{ 'store' };
}

sub _add_comment {

    # Comments are currently processed at the level of the top-level
    # enclosing object (Investigation or ArrayDesign) only.
    my ( $self, $name, @values ) = @_;

    my $comments = $self->_retrieve_comment_store( $name );

    VALUE:
    foreach my $value ( @values ) {
        next VALUE if ( ! defined $value || $value =~ $BLANK );
        push @{ $comments }, $value;
    }

#    my %uniq = map { $_ => 1 } @{ $comments };
#    $self->get_text_store()->{ 'comment' }{ $name } = [ keys %uniq ];

    return;
}
    
sub _retrieve_sub {

    my ( $self, $tag ) = @_;

    my $rc;

    while ( my ( $key, $sub ) = each %{ $self->get_dispatch_table() } ) {

	# $key may contain whitespace, no x option here.
	if ( $tag =~ /\A\s*$key\s*\z/ms ) {
	    $rc = $sub;
	}
	
	# Have to loop through the rest of the list to reset while()
	# on the hash.
    }

    return $rc;
}

sub _dispatch {

    my ( $self, $tag, @args ) = @_;

    unless (defined $tag) {
	confess("Error: dispatch needs a defined tag name.");
    }

    my $sub = $self->_retrieve_sub( $tag );
    unless (defined $sub && ref $sub eq 'CODE') {
	if ( my ( $commentname ) = ( $tag =~ /\A\s*$COMMENT_TAG\s*\z/ms ) ) {
	    $self->_add_comment($commentname, @args);
	}
	else {

	    # This should have been caught in _validate_arrayref_tags
	    croak(qq{Error: Cannot parse the tag: "$tag".});
	}
    }

    return $sub ? $sub->(@args) : undef;
}

# Make the classes immutable. In theory this speeds up object
# instantiation for a small compilation time cost.
__PACKAGE__->meta->make_immutable();

no Moose;

=head1 NAME

Bio::MAGETAB::Util::Reader::TagValueFile - An abstract class providing methods for
handling tab-delimited files.

=head1 SYNOPSIS

 use base qw(Bio::MAGETAB::Util::Reader::TagValueFile);

=head1 DESCRIPTION

This is an abstract class providing methods for parsing tag-value
files such as the MAGE-TAB IDF component, and the header of ADF
files. It is not designed to be used directly.

=head1 ATTRIBUTES

See the L<Tabfile|Bio::MAGETAB::Util::Reader::Tabfile> class for superclass attributes.

=over 2

=item text_store

=item dispatch_table

These are internal caches not designed to be addressed directly.

=back

=head1 METHODS

No public methods.

=head1 SEE ALSO

L<Bio::MAGETAB::Util::Reader::Tabfile>
L<Bio::MAGETAB::Util::Reader>
L<Bio::MAGETAB::Util::Reader::ADF>
L<Bio::MAGETAB::Util::Reader::IDF>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 LICENSE

This library is released under version 2 of the GNU General Public
License (GPL).

=cut

1;
