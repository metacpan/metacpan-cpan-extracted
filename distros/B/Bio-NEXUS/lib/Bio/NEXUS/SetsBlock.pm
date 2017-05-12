######################################################
# SetsBlock.pm
######################################################
# Author: Thomas Hladish
# $Id: SetsBlock.pm,v 1.32 2007/09/21 23:09:09 rvos Exp $
#################### START POD DOCUMENTATION ##################

=head1 NAME

Bio::NEXUS::SetsBlock - Represents SETS block of a NEXUS file

=head1 SYNOPSIS

$block_object = new Bio::NEXUS::SetsBlock($block_type, $block, $verbose);

=head1 DESCRIPTION

Parses Sets block of NEXUS file and stores Sets data.

=head1 FEEDBACK

All feedback (bugs, feature enhancements, etc.) are greatly appreciated.

=head1 AUTHORS

 Thomas Hladish (tjhladish at yahoo)

=head1 VERSION

$Revision: 1.32 $

=head1 METHODS

=cut

package Bio::NEXUS::SetsBlock;

use strict;
#use Carp; # XXX this is not used, might as well not import it!
#use Data::Dumper; # XXX this is not used, might as well not import it!
use Bio::NEXUS::Functions;
use Bio::NEXUS::Block;
use Bio::NEXUS::Util::Exceptions;
use Bio::NEXUS::Util::Logger;
use vars qw(@ISA $VERSION $AUTOLOAD);
use Bio::NEXUS; $VERSION = $Bio::NEXUS::VERSION;

@ISA = qw(Bio::NEXUS::Block);
my $logger = Bio::NEXUS::Util::Logger->new();

=head2 new

 Title   : new
 Usage   : $block_object = new Bio::NEXUS::SetsBlock($block_type, $commands, $verbose)
 Function: Creates a new Bio::NEXUS::SetsBlock object
 Returns : Bio::NEXUS::SetsBlock object
 Args    : type (string), the commands/comments to parse (array ref), and a verbose flag (0 or 1)

=cut

sub new {
    my ( $class, $type, $commands, $verbose, $taxlabels ) = @_;
    unless ($type) { ( $type = lc $class ) =~ s/Bio::NEXUS::(.+)Block/$1/i; }
    my $self = { type => $type };
    bless $self, $class;
    $self->_parse_block( $commands, $verbose, $taxlabels )
        if ( ( defined $commands ) and @$commands );
    return $self;
}

=begin comment

 Title   : _parse_taxset
 Usage   : 

=end comment 

=cut

sub _parse_taxset {
    my ( $self, $buffer ) = @_;
    my ( $setname, $equals_symb, @taxa ) = @{ _parse_nexus_words($buffer) };

    my $taxsets;
    $taxsets->{$setname} = \@taxa;

    #$self->set_taxsets($taxsets);
    $self->add_taxsets( { $setname, \@taxa } );

    return $taxsets;
}

=head2 set_taxsets

 Title   : set_taxsets
 Usage   : $block->set_taxsets($taxsets);
 Function: Set the taxsets hash
 Returns : none
 Args    : hash of set name keys and element arrays

=cut

sub set_taxsets {
    my ( $self, $taxsets ) = @_;
    $self->{'taxsets'} = $taxsets;
}

=head2 add_taxsets

 Title   : add_taxsets
 Usage   : $block->add_taxsets($taxsets);
 Function: add taxa sets
 Returns : none
 Args    : a reference to a hash of taxa sets

=cut

sub add_taxsets {
    my ( $self, $taxsets ) = @_;
    for my $setname ( keys %{$taxsets} ) {
        ${ $self->{'taxsets'} }{$setname} = ( $$taxsets{$setname} );
    }
}

=head2 get_taxsets

 Title   : get_taxsets
 Usage   : $block->get_taxsets();
 Function: Returns a hash of taxa sets
 Returns : taxa sets
 Args    : none

=cut

sub get_taxsets {
    my ($self) = @_;
    return $self->{'taxsets'} || {};
}

=head2 get_taxset

 Title   : get_taxset
 Usage   : $block->get_taxset($setname);
 Function: Returns a list of OTU's
 Returns : OTU's
 Args    : none

=cut

sub get_taxset {
    my ( $self, $setname ) = @_;
    return $self->{'taxsets'}->{$setname} || [];
}

=head2 get_taxset_names

 Title     : get_taxset_names
 Usage     : $block->get_taxset_names()
 Function: gets the names of all sets
 Returns : array of names
 Args     : none
 
=cut

sub get_taxset_names {
    my ($self) = @_;
    return [ sort keys %{ $self->{'taxsets'} } ];
}

=head2 print_all_taxsets

 Title     : print_all_taxsets
 Usage     : $block->print_all_taxsets($outfile)
 Function: prints set names and elements
 Returns : none
 Args     : filename or filehandle
 
=cut

sub print_all_taxsets {
    my ( $self, $outfile ) = @_;
    my $fh;
    if ( $outfile eq "-" || $outfile eq \*STDOUT ) {
        $fh = \*STDOUT;
    }
    else {
        open( $fh, ">$outfile" )
            || Bio::NEXUS::Util::Exceptions::FileError->throw(
        	'error' => "Could not open $outfile for writing" 
        );
    }

    for my $setname ( sort keys %{ $self->{'taxsets'} } ) {
        print $fh "$setname = [@{$self->{'taxsets'}->{$setname}}]\n\n";
    }
}

=head2 delete_taxsets

 Title     : delete_taxsets
 Usage     : $block->delete_taxsets($set1 [$set2 $set3 ...])
 Function: Removes the named sets from the Sets block
 Returns : none
 Args     : Names of sets to be deleted

=cut

sub delete_taxsets {
    my ( $self, @setnames ) = @_;
    for my $setname (@setnames) {
        delete ${ $self->{'taxsets'} }{$setname};
    }
}

=head2 exclude_otus

 Title     : exclude_otus
 Usage     : $block->exclude_otus($otu_array_ref)
 Function: Finds and deletes each of the given otus from any sets they appear in
 Returns : none
 Args     : Names of otus to be removed
 
=cut

sub exclude_otus {
    my ( $self, $otus_to_remove ) = @_;
    for my $setname ( keys %{ $self->{'taxsets'} } ) {
        for ( my $i = 0; $i < @{ $self->{'taxsets'}{$setname} }; $i++ ) {
            for my $otu_to_remove (@$otus_to_remove) {
                if ( $self->{'taxsets'}->{$setname}[$i] eq $otu_to_remove ) {
                    splice( @{ $self->{'taxsets'}{$setname} }, $i, 1 );
                }
            }
        }
    }
}

=head2 select_otus

 Title     : select_otus
 Usage     : $block->select_otus($otu_array_ref)
 Function: Finds the given otus and removes all others from any sets they appear in
 Returns : none
 Args     : Names of otus to be removed
 
=cut

sub select_otus {
    my ( $self, $otus_to_keep ) = @_;
    my $newsets;
    for my $setname ( keys %{ $self->{'taxsets'} } ) {
        $$newsets{$setname} = [];
        for my $otu_element ( @{ $self->{'taxsets'}{$setname} } ) {
            for my $otu_to_keep (@$otus_to_keep) {
                if ( $otu_element eq $otu_to_keep ) {
                    push( @{ $$newsets{$setname} }, $otu_to_keep );
                }
            }
        }
    }
    $self->set_taxsets($newsets);
}

=head2 rename_otus

 Title   : rename_otus
 Usage   : $block->rename_otus($names);
 Function: rename all OTUs
 Returns : none
 Args    : hash of OTU names

=cut

sub rename_otus {
    my ( $self, $translation ) = @_;
    for my $setname ( @{ $self->get_taxset_names() } ) {
        my @otu_names = @{ $self->get_taxset($setname) };
        my @new_otu_names;
        for my $otu_name (@otu_names) {
            if ( my $new_name = $$translation{$otu_name} ) {
                push( @new_otu_names, $new_name );
            }
            else {
                push( @new_otu_names, $otu_name );
            }
        }
        $self->add_taxsets( { $setname, \@new_otu_names } );
    }
}

=head2 add_otu_clone

 Title   : add_otu_clone
 Usage   : ...
 Function: ...
 Returns : ...
 Args    : ...

=cut

sub add_otu_clone {
	my ( $self, $original_otu_name, $copy_otu_name ) = @_;
	# print "Warning: Bio::NEXUS::SetsBlock::add_otu_clone() method not fully implemented\n";
	
	# add the cloned otu to those sets that contain the original otu
	foreach my $set_id (keys %{ $self->get_taxsets() }) {
		#print "> set ", $set_id, "\n";
		my @set = @{ $self->get_taxsets()->{$set_id} };
		foreach my $otu (@set) {
			if ($otu eq $original_otu_name) {
				#print "> found the original otu in ", $set_id, "\n";
				push (@{$self->{'taxsets'}{$set_id}}, $copy_otu_name);
			}
		}
	}
}

=head2 rename_taxsets

 Title     : rename_taxsets
 Usage     : $block->rename_taxsets($oldsetname1, $newsetname1, ...)
 Function: Renames sets
 Returns : none
 Args     : Oldname, newname pairs

=cut

sub rename_taxsets {
    my ( $self, @old_and_new ) = @_;
    my ( @old, @new );
    while (@old_and_new) {
        push( @old, shift(@old_and_new) );
        push( @new, shift(@old_and_new) );
    }
    for ( my $i = 0; $i < scalar(@old); $i++ ) {
        if ( $self->{'taxsets'}{ $old[$i] } ) {
            $self->{'taxsets'}{ $new[$i] } = $self->{'taxsets'}{ $old[$i] };
            delete $self->{'taxsets'}{ $old[$i] };
        }
        else {
            print "$old[$i] is not the name of a set in this NEXUS file.\n";
        }
    }
}

=head2 equals

 Name    : equals
 Usage   : $setsblock->equals($another);
 Function: compare if two Bio::NEXUS::SetsBlock objects are equal
 Returns : boolean 
 Args    : a Bio::NEXUS::SetsBlock object

=cut

sub equals {
    my ( $block1, $block2 ) = @_;
    if ( !Bio::NEXUS::Block::equals( $block1, $block2 ) ) { return 0; }
    my $sets1 = $block1->get_taxsets();
    my $sets2 = $block2->get_taxsets();
    if ( keys %$sets1 != keys %$sets2 ) { return 0; }
    for my $setname1 ( keys %$sets1 ) {
        unless ( ( defined $$sets2{$setname1} )
            && ( @{ $$sets1{$setname1} } == @{ $$sets2{$setname1} } ) )
        {
            return 0;
        }
    }
    for my $setname1 ( keys %$sets1 ) {
        @{ $$sets1{$setname1} } = sort @{ $$sets1{$setname1} };
        @{ $$sets2{$setname1} } = sort @{ $$sets2{$setname1} };
        for ( my $i = 0; $i < @{ $$sets1{$setname1} }; $i++ ) {
            unless (
                ${ $$sets1{$setname1} }[$i] eq ${ $$sets2{$setname1} }[$i] )
            {
                return 0;
            }
        }
    }
    return 1;
}

=begin comment

 Name    : _write
 Usage   : $sets -> _write($filehandle, $verbose);
 Function: Writes NEXUS Sets block from stored data
 Returns : none
 Args    : none

=end comment 

=cut

sub _write {
    my ( $self, $fh, $verbose ) = @_;
    $fh ||= \*STDOUT;

    Bio::NEXUS::Block::_write( $self, $fh );
    for my $setname ( sort keys %{ $self->{'taxsets'} } ) {
        my @set_elements = sort @{ ${ $self->{'taxsets'} }{$setname} };
        my $i            = 0;
        for ( my $j = 0; $j + 1 < @set_elements; $j++ ) {
            if ( $set_elements[$i] eq $set_elements[ $i + 1 ] ) {
                splice( @set_elements, $i, 1 );
            }
            else {
                $i++;
            }
        }
        $setname = _nexus_formatted($setname);
        print $fh "\tTAXSET $setname =";
        for my $element (@set_elements) {
            $element = _nexus_formatted($element);
            print $fh " $element";
        }
        print $fh ";\n";
    }
    print $fh "END;\n";
}

sub AUTOLOAD {
    return if $AUTOLOAD =~ /DESTROY$/;
    my $package_name = __PACKAGE__ . '::';

    # The following methods are deprecated and are temporarily supported
    # via a warning and a redirection
    my %synonym_for = (

#        "${package_name}parse"      => "${package_name}_parse_tree",  # example
    );

    if ( defined $synonym_for{$AUTOLOAD} ) {
        $logger->warn("$AUTOLOAD() is deprecated; use $synonym_for{$AUTOLOAD}() instead");
        goto &{ $synonym_for{$AUTOLOAD} };
    }
    else {
        Bio::NEXUS::Util::Exceptions::UnknownMethod->throw(
        	'error' => "ERROR: Unknown method $AUTOLOAD called"
        );
    }
    return;
}

1;
