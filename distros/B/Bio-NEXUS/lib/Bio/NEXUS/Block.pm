#################################################################
# Block.pm
#################################################################
# Author: Chengzhi Liang, Weigang Wiu, Eugene Melamud, Peter Yang, Thomas Hladish
# $Id: Block.pm,v 1.49 2007/09/24 04:52:11 rvos Exp $

#################### START POD DOCUMENTATION ##################

=head1 NAME

Bio::NEXUS::Block - Provides useful functions for blocks in NEXUS file (parent class).

=head1 SYNOPSIS

This module is the super class of all NEXUS block classes. It is not used specifically from a program; in other words, you don't create a new Bio::NEXUS::Block object. Other modules, like AssumptionsBlock, simply inherit subroutines from this module.

=head1 DESCRIPTION

Provides a few useful functions for general blocks (to be used by sub-classes).

=head1 COMMENTS

=head1 FEEDBACK

All feedback (bugs, feature enhancements, etc.) are greatly appreciated. 

=head1 AUTHORS

 Chengzhi Liang (liangc@umbi.umd.edu)
 Weigang Qiu (weigang@genectr.hunter.cuny.edu)
 Eugene Melamud (melamud@carb.nist.gov)
 Peter Yang (pyang@rice.edu)
 Thomas Hladish (tjhladish at yahoo)

=head1 VERSION

$Revision: 1.49 $

=head1 METHODS

=cut

package Bio::NEXUS::Block;

use strict;
use Bio::NEXUS::Functions;
use Bio::NEXUS::Util::Logger;
use Bio::NEXUS::Util::Exceptions 'throw';
#use Data::Dumper; # XXX this is not used, might as well not import it!
#use Carp; # XXX this is not used, might as well not import it!
use vars qw($VERSION $AUTOLOAD);

use Bio::NEXUS; $VERSION = $Bio::NEXUS::VERSION;
my $logger = Bio::NEXUS::Util::Logger->new();

=head2 clone

 Title   : clone
 Usage   : my $newblock = $block->clone();
 Function: clone a block object (shallow)
 Returns : Block object
 Args    : none

=cut

sub clone {
    my ($self) = @_;
    my $class = ref($self);
    my $newblock = bless( { %{$self} }, $class );
    return $newblock;
}

=head2 get_type

 Title   : get_type
 Usage   : print $block->get_type();
 Function: Returns a string containing the block type
 Returns : type (string)
 Args    : none

=cut

sub get_type { shift->{'type'} }

=head2 set_ntax

 Title   : set_ntax
 Usage   : print $block->set_ntax();
 Function: Sets the value of Dimensions:ntax
 Returns : none
 Args    : number of taxa (scalar)

=cut

sub set_ntax {
    my ( $self, $ntax ) = @_;
    $self->{'dimensions'}{'ntax'} = $ntax;
    return;
}

=begin comment

 Title   : _parse_block
 Usage   : $block->_parse_block(\@commands, $verbose_flag);
 Function: Generic block parser that works for all block types, so long as appropriate command parsers have been written
 Returns : none
 Args    : array ref of commands, as parsed by Bio::NEXUS::read; and an optional verbose flag

=end comment

=cut

sub _parse_block {
    my ( $self, $commands, $verbose ) = @_;
    my $type = $self->get_type();
    $logger->info("Analyzing $type block now.");
	CMD: for my $command (@$commands) {
        # some of these "commands" are actually command-level comments
        if ( $command =~ /^\[.*\]$/s ) {
            $self->add_comment($command);
            next CMD;
        }

        my ( $key, $val ) = $command =~ /^ \s*  (\S+)  (?:\s+ (.+) )?  /xis;
        $key = lc $key;
        next CMD if $key eq 'begin' || $key eq 'end';

        my $parser_name = "_parse_$key";
        $self->$parser_name($val);
    }

    $self->_post_processing();
    $logger->info("Analysis of $type block complete.");
    return;
}

=begin comment

# This is a placeholding method only, for blocks that do not require
# any post-parser processing (i.e., most of them)

=end comment

=cut

sub _post_processing() {
    my ($self) = @_;
    return;
}

=begin comment

 Title   : _parse_title
 Usage   : $block->_parse_title($title);
 Function: parse title, set title attribute
 Returns : none
 Args    : block title (string)

=end comment
 
=cut

sub _parse_title {
    my ( $self, $title ) = @_;
    my $words = _parse_nexus_words($title);
    $self->set_title( $words->[0] );
    return;
}

=begin comment

 Title   : _parse_link
 Usage   : $block->_parse_link($link_command);
 Function: parse a link command, add a link attribute
 Returns : none
 Args    : link command (string)

=end comment

=cut

sub _parse_link {
    my ( $self, $string ) = @_;
    my ( $name, $title ) = split /\s*=\s*/, $string;
    my ($link) = @{ _parse_nexus_words($title) };
    $self->add_link( $name, $link );
    return $name, $link;
}

=begin comment

 Title   : _parse_dimensions
 Usage   : $block->_parse_dimensions($dimension_command);
 Function: parse a dimensions command, set dimensions attributes
 Returns : none
 Args    : dimensions command (string)

=end comment 

=cut

sub _parse_dimensions {
    my ( $self, $string ) = @_;
    my %dimensions = ();

    # Set dimension X to Y, if of the form X = Y; otherwise,
    # set X to 1 (i.e., TRUE)
    while ( $string =~ s/\s* (\S+) (?: \s*=\s* (\S+) )//x ) {
        $dimensions{ lc $1 } = defined $2 ? lc $2 : 1;
    }
    $self->set_dimensions( \%dimensions );
    return;
}

=head2 set_dimensions

 Title   : set_dimensions
 Usage   : $block->set_dimensions($dimensions);
 Function: set a dimensions command
 Returns : none 
 Args    : hash content of dimensions command

=cut

sub set_dimensions {
    my ( $self, $dimensions ) = @_;
    $self->{'dimensions'} = $dimensions;
    return;
}

=head2 get_dimensions

 Title   : get_dimensions
 Usage   : $block->get_dimensions($attribute);
 Function: get a dimensions command
 Returns : hash content of dimensions command, or the value for a particular attribute if specified
 Args    : none, or a string

=cut

sub get_dimensions {
    my ( $self, $attribute ) = @_;
    $attribute
        ? return $self->{'dimensions'}->{$attribute}
        : return $self->{'dimensions'};
}

=head2 set_command

 Title   : set_command
 Usage   : $block->set_command($command, $content);
 Function: Set a command
 Returns : none
 Args    : comand name, and content (string)

=cut

sub set_command {
    my ( $self, $command, $content ) = @_;
    $self->{$command} = $content;
    return;
}

=head2 set_title

 Title   : set_title
 Usage   : $block->set_title($name);
 Function: Set the block name
 Returns : none
 Args    : block name (string)

=cut

sub set_title {
    my ( $self, $title ) = @_;
    $self->{'title'} = $title;
    return;
}

=head2 get_title

 Title   : get_title
 Usage   : $block->get_title();
 Function: Returns a string containing the block title
 Returns : name (string)
 Args    : none

=cut

sub get_title { shift->{'title'} }

=head2 set_link

 Title   : set_link
 Usage   : $block->set_link($link_hashref);
 Function: Set the block link commands
 Returns : none
 Args    : block link (hash)

=cut

sub set_link {
    my ( $self, $link_hashref ) = @_;
    $self->{'link'} = $link_hashref;
    return;
}

=head2 add_link

 Title   : add_link
 Usage   : $block->add_link($linkname, $title);
 Function: add a link command
 Returns : none
 Args    : $link, $title (of another block)

=cut

sub add_link {
    my ( $self, $link, $title ) = @_;
    $self->{'link'}{$link} = $title;
}

=head2 get_link

 Title   : get_link
 Usage   : $block->get_link();
 Function: Returns a hash containing the block links
 Returns : link (hash)
 Args    : none

=cut

sub get_link {
    my ( $self, $link ) = @_;
    if ( !$self->{'link'} ) { return {}; }
    if ($link) { return $self->{'link'}{$link}; }
    return $self->{'link'};
}

=begin comment

 Title   : _parse_taxlabels
 Usage   : $self->_parse_taxlabels($buffer); (private)
 Function: Processes the buffer containing taxonomic labels
 Returns : array ref to the taxlabels
 Args    : the buffer to parse (string)
 Method  : Gets rid of extra blanks and semicolon if any. Removes 'taxlabels',
           then separates by whitespace. For each OTU, creates a Bio::NEXUS::Node
           to store information. Method halts
           program if number of taxa input does not equal the dimensions given
           in the actual file.

=end comment 

=cut

# Used by TaxaBlock and all Matrix subclasses

sub _parse_taxlabels {
    my ( $self, $buffer, $ntax ) = @_;
    my @taxlabels = @{ _parse_nexus_words($buffer) };

    my $counter = scalar @taxlabels;
    if ( $ntax && $counter != $ntax ) {
    	throw 'BadArgs' => "Number of taxa specified does not equal number of taxa listed:\n"
            . "\tdimensions = $ntax, whereas actual number = $counter.\n";
    }
    $self->set_taxlabels( \@taxlabels );
    return \@taxlabels;
}

=head2 set_taxlabels

 Title   : set_taxlabels
 Usage   : $block->set_taxlabels($labels);
 Function: Set the taxa names
 Returns : none
 Args    : array of taxa names 

=cut

# Used by TaxaBlock and all Matrix subclasses

sub set_taxlabels {
    my ( $self, $taxlabels ) = @_;
    $self->{'taxlabels'} = $taxlabels;
    return;
}

=head2 add_taxlabel

 Title   : add_taxlabel
 Usage   : $block->add_taxlabel($label);
 Function: add a taxon name
 Returns : none
 Args    : a taxon name 

=cut

# Used by TaxaBlock and all Matrix subclasses

sub add_taxlabel {
    my ( $self, $label ) = @_;
    push @{ $self->{'taxlabels'} }, $label;
}

=head2 get_taxlabels

 Title   : get_taxlabels
 Usage   : $block->get_taxlabels();
 Function: Returns an array of taxa labels
 Returns : taxa names
 Args    : none

=cut

# Used by TaxaBlock and all Matrix subclasses

sub get_taxlabels { shift->{'taxlabels'} || [] }

=head2 set_otus

 Title   : set_otus
 Usage   : $block->set_otus($otus);
 Function: sets the list of OTUs 
 Returns : none
 Args    : array of OTUs

=cut

sub set_otus {
    my ( $self, $otus ) = @_;
    $self->{'otuset'}->set_otus($otus);
    return;
}

=head2 get_otus

 Title   : get_otus
 Usage   : $block->get_otus();
 Function: Returns array of otus
 Returns : all otus
 Args    : none

=cut

sub get_otus { shift->{'otuset'}->get_otus() }

=head2 set_otuset

 Title   : set_otuset
 Usage   : $block->set_otuset($otuset);
 Function: Set the otus
 Returns : none
 Args    : TaxUnitSet object

=cut

sub set_otuset {
    my ( $self, $set ) = @_;
    $self->{'otuset'} = $set;
    return;
}

=head2 get_otuset

 Title   : get_otuset
 Usage   : $block->get_otuset();
 Function: get the OTUs 
 Returns : TaxUnitSet object
 Args    : none

=cut

sub get_otuset { shift->{'otuset'} }

=head2 select_otus

 Title   : select_otus
 Usage   : $block->select_otus($names);
 Function: select a subset of OTUs
 Returns : array of OTUs
 Args    : OTU names

=cut

sub select_otus {
    my ( $self, $otunames ) = @_;
    if ( $self->get_otuset() ) {
        $self->set_otuset( $self->get_otuset()->subset($otunames) );
    }
    if ( $self->get_taxlabels() ) {
        $self->set_taxlabels($otunames);
    }
    if ( $self->get_type() =~ m/sets/i ) {
        $self->select_otus($otunames);
    }
}

=head2 rename_otus

 Title   : rename_otus
 Usage   : $block->rename_otus($names);
 Function: rename all OTUs
 Returns : none
 Args    : hash of OTU names

=cut

sub rename_otus {
    my ( $self, $translate ) = @_;
    if ( $self->get_otuset() ) {
        $self->get_otuset()->rename_otus($translate);
    }
    if ( $self->get_taxlabels() ) {
        $self->set_taxlabels( values %{$translate} );
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
	$logger->warn("method not fully implemented");
}

=head2 set_comments

 Title   : set_comments
 Usage   : $block->set_comments($comments);
 Function: Set the block comments
 Returns : none
 Args    : block comments (array of strings)

=cut

sub set_comments {
    my ( $self, $comments ) = @_;
    $self->{'comments'} = $comments;
    return;
}

=head2 get_comments

 Title   : get_comments
 Usage   : $block->get_comments();
 Function: Returns block comments
 Returns : comments (array of strings)
 Args    : none

=cut

sub get_comments { shift->{'comments'} || [] }

=head2 add_comment

 Title   : add_comment
 Usage   : $block->add_comment($comment);
 Function: add a comment
 Returns : none
 Args    : comment (string)

=cut

sub add_comment {
    my ( $self, $comment ) = @_;
    push @{ $self->{'comments'} }, $comment;
}

=head2 equals

 Name    : equals
 Usage   : $block->equals($another);
 Function: compare if two Block objects are equal
 Returns : boolean 
 Args    : a Block object'

=cut

sub equals {
    my ( $self, $block ) = @_;
    if ( $self->get_type ne $block->get_type ) { return 0; }
    if ( ( $self->get_title || $block->get_title )
        && !( $self->get_title && $block->get_title ) )
    {
        return 0;
    }
    if ( ( $self->get_title || '' ) ne ( $block->get_title || '' ) ) {
        return 0;
    }
    my @keys1 = sort keys %{ $self->get_link() };
    my @keys2 = sort keys %{ $block->get_link() };
    if ( scalar @keys1 != scalar @keys2 ) { return 0; }
    for ( my $i = 0; $i < @keys1; $i++ ) {
        if (   $keys1[$i] ne $keys2[$i]
            || $self->{'link'}{ $keys1[$i] } ne $block->{'link'}{ $keys2[$i] } )
        {
            return 0;
        }
    }
    return 1;
}

=begin comment

 Title   : _write_comments
 Usage   : $block->_write_comments();
 Function: Writes comments stored in the block
 Returns : none
 Args    : none

=end comment 

=cut

sub _write_comments {
    my $self = shift;
    my $fh = shift || \*STDOUT;
    for my $comment ( @{ $self->get_comments() } ) {
        print $fh "$comment\n";
    }
}

=begin comment

 Title   : _load_module
 Usage   : $block->_load_module('Some::Class');
 Function: tries to load a class 
 Returns : class on success, throws ExtensionError on failure
 Args    : a class name

=end comment

=cut

sub _load_module {
	my ( $self, $class ) = @_;
	my $path = $class;
	$path =~ s|::|/|g;
	$path .= '.pm';
	eval { require $path };
	if ( $@ ) {
		throw 'ExtensionError' => "Can't load $class: $@";
	}
	return $class;
}

=begin comment

 Name    : _write
 Usage   : $block->_write($filehandle, $verbose);
 Function: Writes NEXUS block commands from stored data
 Returns : none
 Args    : none

=end comment 

=cut

sub _write {
    my ( $self, $fh ) = @_;
    $fh ||= \*STDOUT;

    my $type = uc $self->get_type();
    print $fh "BEGIN $type;\n";
    $self->_write_comments($fh);

    if ( $self->get_title ) {
    # added _nexus_formatted to protect name with embedded symbols
        print $fh "\tTITLE ", _nexus_formatted($self->get_title), ";\n";
    }
    if ( $self->get_link ) {
        for my $key ( keys %{ $self->get_link } ) {
            print $fh "\tLINK ", "$key=", $self->get_link->{$key}, ";\n";
        }
    }
}

sub AUTOLOAD {
    return if $AUTOLOAD =~ /DESTROY$/;
    my $package_name = __PACKAGE__ . '::';

    # The following methods are deprecated and are temporarily supported
    # via a warning and a redirection
    my %synonym_for = (
        "${package_name}parse_stringtokens" =>
            "${package_name}_parse_nexus_words",
        "${package_name}_parse_stringtokens" =>
            "${package_name}_parse_nexus_words",
        "${package_name}write" => "${package_name}_write",
    );

    if ( defined $synonym_for{$AUTOLOAD} ) {
        $logger->warn("$AUTOLOAD() is deprecated; use $synonym_for{$AUTOLOAD}() instead");
        goto &{ $synonym_for{$AUTOLOAD} };
    }
    else {
    	throw 'UnknownMethod' => "ERROR: Unknown method $AUTOLOAD called";
    }
}

1;
