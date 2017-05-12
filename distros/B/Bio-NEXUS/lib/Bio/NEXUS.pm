######################################################
# NEXUS.pm
######################################################
#
# $Id: NEXUS.pm,v 1.122 2012/02/10 13:28:28 astoltzfus Exp $
# $Revision: 1.122 $
#
#################### START POD DOCUMENTATION ##################

=head1 NAME

Bio::NEXUS - An object-oriented Perl Applications Programming Interface (API) for the NEXUS file format

=head1 SYNOPSIS

 my $nexus =Bio::NEXUS->new($file); 
 # if $file is not provided, an empty Bio::NEXUS object will be created
 $nexus->write($newfile);

=head1 DESCRIPTION

This is the base class for the Bio::NEXUS package, providing an object-oriented API to 
the NEXUS file format of I<Maddison, et al.>, 1997.  This module provides methods to 
add/remove blocks, select blocks/trees/subtrees/OTUs/characters and so on.  For a 
tutorial illustrating how to use Bio::NEXUS, see L<doc/Tutorial.pod>.

=head1 FEEDBACK

All feedback (bugs, feature enhancements, etc.) are all greatly appreciated. 

=head1 AUTHORS

 Chengzhi Liang (liangc@umbi.umd.edu)
 Weigang Qiu (weigang@genectr.hunter.cuny.edu)
 Peter Yang (pyang@rice.edu)
 Thomas Hladish (tjhladish at yahoo)
 Arlin Stoltzfus (arlin.stoltzfus@nist.gov)

=head1 METHODS

=cut

package Bio::NEXUS;

use strict;
# use Data::Dumper; # XXX this is not used, might as well not load it!
# use Carp; # XXX this is not used, might as well not load it!

use Bio::NEXUS::Functions;
use Bio::NEXUS::AssumptionsBlock;
use Bio::NEXUS::CharactersBlock;
use Bio::NEXUS::TreesBlock;
use Bio::NEXUS::HistoryBlock;
use Bio::NEXUS::Node;
use Bio::NEXUS::TaxaBlock;
use Bio::NEXUS::SetsBlock;
use Bio::NEXUS::SpanBlock;
use Bio::NEXUS::UnalignedBlock;
use Bio::NEXUS::UnknownBlock;
use Bio::NEXUS::DataBlock;
use Bio::NEXUS::DistancesBlock;
# in progress
use Bio::NEXUS::CodonsBlock; 
use Bio::NEXUS::NotesBlock; 

use Bio::NEXUS::Util::Logger;
use Bio::NEXUS::Util::Exceptions 'throw';

#use Bio::NEXUS::CodonsBlock;
#use Bio::NEXUS::NotesBlock;

# Version number is obtained cvs $Name tag (eg. release_1_05).
# ExtUtils::MakeMaker reads package global $VERSION

use vars qw($VERSION $AUTOLOAD);
$VERSION = do { my @r = ( q$Name:  $ =~ /\d+/g ); ( $#r < 0 ) ? '0.78' : sprintf " %d." . "%02d" x $#r, @r; };

# a logger is an object that conditionally prints messages,
# so we don't need to add print statements and then comment
# them out anymore. You can leave the logging in the code, and
# make it invisible by lowering the log level.
my $logger = Bio::NEXUS::Util::Logger->new; # XXX

=head2 new

 Title   : new
 Usage   : my $nexus = Bio::NEXUS->new($filename, $verbose);
 Function: Creates a new Bio::NEXUS object 
 Returns : Bio::NEXUS object
 Args    : $filename, $verbose, or none

=cut

sub new {
    my ( $class, $filename, $verbose ) = @_;
    
    # XXX notify user conditionally
    $logger->info( "Constructor for $class called" );
    my $self = {};
    bless( $self, $class );
    if ($filename) {
        $self->read_file( $filename, $verbose );
        $filename =~ s/\.nex$//;
        $self->set_name($filename);
    }
    return $self;
}


=head2 get_bionexus_version

 Title   : get_bionexus_version
 Usage   : Bio::NEXUS->get_bionexus_version();
 Function: gets the package version  
 Returns : value of \$VERSION
 Args    : none

=cut

sub get_bionexus_version { return $VERSION; }

=head2 read_file

 Title   : read_file
 Usage   : Bio::NEXUS->read_file($filename, $verbose);
 Function: Reads the contents of the NEXUS file and populate the data in the Bio::NEXUS object
 Returns : None
 Args    : $filename, $verbose, or none

=cut

sub read_file {
    my ( $self, $filename, $verbose ) = @_;
    if ( not -e $filename ) {
    	
    	# XXX refer to Bio::NEXUS::Util::Exceptions -
    	# exceptions are generally more useful for 
    	# tracking down problems
    	throw 'FileError' => "$filename is not a valid filename";
    }
    $self->read( { 
    	'format'  => 'filename', 
    	'param'   => $filename, 
    	'verbose' => $verbose,     
    } );
}

=head2 read

 Title   : read
 Usage   : Bio::NEXUS->read({format => 'string', 'param' => $buffer, 'verbose' => $verbose});
 Usage   : Bio::NEXUS->read({format => 'file', 'param' => $filename, 'verbose' => $verbose});
 Function: Reads the contents of the NEXUS file and populate the data in the NEXUS object
 Returns : None
 Args    : $filename, $verbose, or none

=cut

sub read {
    my ( $self, $args ) = @_;
    $args->{'format'} ||= 'string';
    $args->{'param'}  ||= '';
    my $verbose = $args->{'verbose'} || 0;
    my $nexus_file;
    my $filename;

    if ( lc $args->{'format'} eq 'string' ) {
        $nexus_file = $args->{'param'};
        $filename   = 'INPUT';
    }
    else {
        $filename   = $args->{'param'};
        $nexus_file = _slurp($filename);
    }

    # Read entire file into scalar $nexus_file
    $logger->info('Reading NEXUS file');
    $self->{'filename'} = $filename;

    my $found_nexus_token     = 0;
    my $comment_level         = 0;
    my $quote_level           = 0;
    my $comment               = '';
    my $block_type            = '';
    my @command_level_strings = ();
    my $command               = '';
    my $in_tree_string        = 0;
    my $prev_text_char        = '';

    for my $text_char ( split //, $nexus_file ) {

        # if we're at the beginning of a single-quoted string
        # (We're also supporting double quoting, since double quotes don't seem
        # to be used for a different meaning, and we need to support double
        # quotes in output from programs like clustal.  We will not, however,
        # output double quotes.)

        $text_char = q{'} if $text_char eq q{"};

        if (   ( $text_char eq q{'} )
            && $quote_level == 0
            && $comment_level == 0
            && $found_nexus_token )
        {
            $command .= $text_char;
            $quote_level++;
        }

        # if we're inside a single-quoted string
        elsif ( $quote_level > 0 ) {
            $command .= $text_char;

            #turn off the quote flag if we're ending the quoted string
            if ( $text_char eq q{'} ) {
                $quote_level =
                    ( $prev_text_char eq $text_char )
                    ? $quote_level + 1
                    : $quote_level - 1;
            }

        }

        # if we're entering a (possibly nested) comment, or we're already in
        # one, but we're not looking at bracketed bootstraps in the tree string
        elsif ( ( $text_char eq '[' || $comment_level > 0 )
            && $in_tree_string == 0 )
        {
            $comment .= $text_char;
            $comment_level++ if $text_char eq '[';

            # if we see the end of a (possibly nested) comment
            if ( $text_char eq ']' ) {
                $comment_level--;

                # if we just closed found the last right bracket in the comment,
                # then add the comment to the Bio::NEXUS obj
                if ( $comment_level == 0 && @command_level_strings == 0 ) {
                    $self->add_comment($comment);
                    $comment = q{};
                }
            }
        }

        # if we haven't found '#NEXUS' yet
        elsif ( !$found_nexus_token ) {
            $command .= $text_char;

            # if we've found the whole #NEXUS token that's supposed
            # to start the file (though it may be broken by comments)
            if ( $command =~ /^\s*#NEXUS/i ) {
                $found_nexus_token = 1;
                $command           = q{};
            }

            # If the file starts with something else, then throw.
            # This regex will match '#NEX' and '#NEXUS', but not '#NEXT'
            elsif ( $command !~ /^\s*(?:#(?:N(?:E(?:X(?:U(?:S)?)?)?)?)?)?$/i ) {
                throw 'BadFormat' => "'$filename' does not begin with the \n'#NEXUS' token; it does not appear to be a NEXUS file.\n";
            }
        }

        # if we're at the beginning of a block/command
        elsif ( $command eq q{} ) {
            if ( $comment ) {
                push( @command_level_strings, $comment );
                $comment = q{};
            }
            if ( $text_char ne "\n" ) { 
            	$command .= $text_char; 
            }
        }

        # if we're inside a block, but haven't gotten to the end of the command
        elsif ( $command !~ /;$/ ) {
            $command .= $text_char;
            if (   ( $in_tree_string == 0 )
                && ( $block_type eq 'trees' || $block_type eq 'history' )
                && ( $text_char eq '=' ) )
            {
                $in_tree_string = 1 if ( $command =~ /tree\s.+=/i );
            }
            else { $in_tree_string = 0 if $text_char eq ';' }
        }

        $prev_text_char = $text_char;

        # Only process if we might genuinely have reached the end
        # of a command or block
        if ( !$comment_level && !$quote_level && $text_char eq ';' ) {

            # if we've read in the entire begin block command
            if ( $command =~ /begin\s+(.+)\s*;/i ) {
                $block_type = lc $1;
                $logger->info("found 'begin' token for a $block_type block");
                push( @command_level_strings, $command );
                $command = q{};
                if ($comment) {
                    push( @command_level_strings, $comment );
                    $comment = q{};
                }
            }

            # if we've found the end of the block
            elsif ( $command =~ /^\s*end(?:block)?\s*;/i ) {
            	$logger->info("found 'end' token");
                $command = 'end';
                push( @command_level_strings, $command );
                $command = q{};
                if ($comment) {
                    push( @command_level_strings, $comment );
                    $comment = q{};
                }

                # Send the commands [and comments] off to be turned into a block
                my $block_obj =
                    $self->create_block( $block_type, \@command_level_strings,
                    $verbose );
                $self->add_block($block_obj);
                @command_level_strings = ();
                $block_type            = q{};

            }

            # if we've found the end of a command (but not an
            # 'END BLOCK;' command, since we already asked that) remove the
            # semicolon at the end, since the block parsers aren't expecting
            # one, as well as surrounding white space.  Two substitutions
            # are faster than one, in this case.
            elsif ( $command =~ s/\s*;\s*$// ) {
                $command =~ s/^\s*//;
                if ($comment) {
                    push( @command_level_strings, $comment );
                    $comment = q{};
                }
                push( @command_level_strings, $command );
                $command = q{};
            }
        }
    }

    # Create a taxa block if we didn't find one in the file
    if ( !$self->get_block('taxa') ) {
        $logger->info("No taxa block found, will create one");
        $self->set_taxablock;
    }

    my $counter = scalar @{ $self->get_blocks() };
    $logger->info("$counter blocks read. NEXUS read complete.");
    return $self;
}

=head2 create_block

 Title   : create_block
 Usage   : my $block = Bio::NEXUS->create_block($blocktype,$block_string, $verbose);
 Function: Creates a block object based on the input block type and block content as string
 Returns : A block object (If Block type is 'Characters' then 'Bio::NEXUS::CharactersBlock' is returned
 Args    : $block_type (as string), $block_content (as string), verbose

=cut

sub create_block {
    my ( $self, $block_type, $commands, $verbose ) = @_;
    $logger->info("creating block $block_type");
    my $block;    # This will hold a block object, once one is constructed
    my @args = ( $block_type, $commands, $verbose );

    my %block_types = (
        'assumptions' => "Bio::NEXUS::AssumptionsBlock",
        'characters'  => "Bio::NEXUS::CharactersBlock",
# in progress: codons
        # 'codons'      =>    "Bio::NEXUS::CodonsBlock",
        'data'      => "Bio::NEXUS::DataBlock",
        'distances' => "Bio::NEXUS::DistancesBlock",
        'history'   => "Bio::NEXUS::HistoryBlock",
# in progress: notes
        # 'notes'       =>    "Bio::NEXUS::NotesBlock",
        'sets'      => "Bio::NEXUS::SetsBlock",
        'span'      => "Bio::NEXUS::SpanBlock",
        'taxa'      => "Bio::NEXUS::TaxaBlock",
        'trees'     => "Bio::NEXUS::TreesBlock",
        'unaligned' => "Bio::NEXUS::UnalignedBlock"
    );
    my $class = $block_types{$block_type};
    if ( defined( $class ) ) { $logger->info("class: $class"); }

    my $taxlabels;
    if ( defined $self->get_block('taxa') ) {
        $taxlabels = $self->get_taxlabels();
    }
    if ( $class ) {
        $block = $class->new( @args, $taxlabels );
    }
    else {
        $logger->info("An UnknownBlock is being created for block_type: $block_type");
        $block = Bio::NEXUS::UnknownBlock->new( @args );
    }

    if ( $block_type =~ m/taxa/i and my $title = $block->get_title() ) {
        $self->set_name( $title );
    }

    # Check to make sure that if a Taxa Block is defined,
    # that everything is included in it
    $self->_validate_taxa($block);

    return $block;
}

=begin comment

 Title   : _validate_taxa
 Usage   : 
 Function: 
 Returns : 
 Args    : 

=end comment 

=cut

sub _validate_taxa {
    my ( $self, $block ) = @_;
    my $block_type = $block->get_type();
    my $taxablock  = $self->get_block('taxa');
    return unless $taxablock;

    my @taxlabels = @{ $taxablock->get_taxlabels() };

    # Every taxon listed in the characters or trees blocks should be in the
    # Taxa Block as well
    if ( lc $block_type eq 'characters' || lc $block_type eq 'trees' ) {
        my @taxlabels  = @{ $taxablock->get_taxlabels() };
        my @block_taxa = @{ $block->get_taxlabels() };
    LABEL:
        for my $label (@block_taxa) {
            my $match = 0;
            next LABEL if grep { $label eq $_ } @taxlabels;
            throw 'ObjectMismatch' => "Taxon <$label> in $block_type block is not in the TAXA Block";
        }
    }

    # And every set element should be in the Taxa Block
    elsif ( lc $block_type eq 'sets' ) {

        my %taxsets = %{ $block->get_taxsets() };
        for my $setname ( keys %taxsets ) {
            my @elements = @{ $taxsets{$setname} };
        ELEMENT:
            for my $element (@elements) {
                next ELEMENT if grep { $element eq $_ } @taxlabels;
                throw 'ObjectMismatch' =>  "Element <$element> of set <$setname> is not in the TAXA Block";
            }
        }
    }
    return;
}

=head2 clone

 Name    : clone
 Usage   : my $newnexus = $nexus->clone();
 Function: clone a NEXUS object; each block is also (shallow) cloned.
 Returns : new Bio::NEXUS object
 Args    : none

=cut

sub clone {
    my ($self) = @_;
    my $class = ref($self);
    my $newnexus = bless( { %{$self} }, $class );
	
	# clone blocks
    my @newblocks;
    for my $block ( @{ $self->get_blocks() } ) {
        push @newblocks, $block->clone();
    }
    $newnexus->set_blocks( \@newblocks );
    return $newnexus;
}

=head2 set_name

 Title   : set_name
 Usage   : Bio::NEXUS->set_name($name);
 Function: Sets name for the NEXUS object (usually the filename).
 Returns : Nothing
 Args    : $name (as string)

=cut

sub set_name {
    my ( $self, $name ) = @_;
    $self->{'name'} = $name;
}

=head2 get_name

 Title   : get_name
 Usage   : $name = Bio::NEXUS->get_name();
 Function: Returns the name of the NEXUS object as string. (NEXUS filename).
 Returns : NEXUS filename
 Args    : None

=cut

sub get_name {
    my ($self) = @_;
    return $self->{'name'};
}

=head2 add_comment

 Name    : add_comment
 Usage   : $nexus->add_comment($comment);
 Function: add a block of comments.
 Returns : none
 Args    : a string object

=cut

sub add_comment {
    my ( $self, $comment ) = @_;
    $self->add_block($comment);
}

=head2 get_comments

 Name    : get_comments
 Usage   : $nexus->get_comments();
 Function: Retrieves all comments.
 Returns : ref to an array of strings
 Args    : none

=cut

sub get_comments {
    my ($self) = @_;
    my @blocks_and_comments = @{ $self->get_blocks_and_comments() };
    my @comments;
    for my $block_or_comment (@blocks_and_comments) {
        if ( _is_comment($block_or_comment) ) {
            push( @comments, $block_or_comment );
        }
    }
    return \@comments || [];
}

=head2 get_filename

 Name    : get_filename
 Usage   : $nexus->get_filename;
 Function: get the NEXUS filename for this object.
 Returns : A filename
 Args    : none

=cut

sub get_filename {
    my ($self) = @_;
    return $self->{'filename'};
}

=head2 set_blocks

 Name    : set_blocks
 Usage   : $nexus->set_blocks($blocks);
 Function: set the blocks in this nexus file.
 Returns : none
 Args    : an array of Block objects

=cut

sub set_blocks {
    my ( $self, $blocks ) = @_;
    $self->{'block_level'} = $blocks;
}

=head2 add_block

 Name    : add_block
 Usage   : $nexus->add_block($block_obj);
 Function: add a block.
 Returns : none
 Args    : a Bio::NEXUS::*Block object

=cut

sub add_block {
    my ( $self, $block ) = @_;
    push @{ $self->{'block_level'} }, $block;
    return;
}

=head2 remove_block

 Name    : remove_block
 Usage   : $nexus->remove_block($blocktype, $title);
 Function: remove a block
 Returns : none
 Args    : block type and block name (strings)

=cut

sub remove_block {
    my ( $self, $blocktype, $title ) = @_;
    my $items = $self->get_blocks_and_comments();
    my $found_block         = 0;
    ITEM: for my $i ( 0 .. $#{ $items } ) {
        my $item = $items->[$i];
        next ITEM if _is_comment($item);
        if ( $item->get_type() =~ m/$blocktype/i ) {
	    
            # if either no title was specified, or the title matches
            if ( !$title || $item->get_title =~ m/$title/i ) {
            	$logger->info("> found the block!");
            	
				# the next statement removes a reference
				# from a copy array - but will it remove the
				# reference from the actual array of blocks? 
				# XXX yes -- RAV
				splice( @{ $items }, $i, 1 );
				
				# sanity check
				$logger->info('> blocks_and_comments.length: ' . scalar @{ $items } );
				$logger->info('> self->get_blocks_and_comments.length: ' . scalar @{ $self->get_blocks_and_comments() } );
				
                $found_block = 1;
            }
        }
		$self->{'block_level'} = $items;
    }

    if ( not $found_block ) {
        my $blockname = $blocktype;
        if ( $title ) { 
        	$blockname .= " ($title)" 
        }
        $logger->warn("could not find a $blockname block");
    }
}

=head2 get_block

 Name    : get_block
 Usage   : $nexus->get_block($blocktype, $blockname);
 Function: Retrieves NEXUS block.
 Returns : A Bio::NEXUS::*Block object
 Args    : none

=cut

sub get_block {
    my ( $self, $blocktype, $blockname ) = @_;

    for my $block ( @{ $self->get_blocks($blocktype) } ) {
        if ( $block->get_type() =~ m/$blocktype/i ) {
            if ( !$blockname ) { 
            	return $block; 
            }
            elsif ( $block->get_title() =~ m/$blockname/i ) { 
            	return $block; 
            }
        }
    }
    return undef;
}

=head2 get_blocks

 Name    : get_blocks
 Usage   : $nexus->get_blocks($blocktype);
 Function: Retrieves list of blocks of some type or all blocks.
 Returns : Array of Bio::NEXUS::Block objects
 Args    : $blocktype or none

=cut

sub get_blocks {
    my ( $self, $blocktype ) = @_;

    my @blocks;

    for my $item ( @{ $self->get_blocks_and_comments() } ) {

        # if it's actually a block object, and not a block-level comment
        if ( !_is_comment($item) ) {
            if (!$blocktype || $item->get_type() =~ /$blocktype/i ) {
                push @blocks, $item;
            }
        }
    }

    return \@blocks;
}

=head2 get_blocks_and_comments

 Name    : get_blocks_and_comments
 Usage   : @blocks_and_comments = @{ $nexus->get_blocks_and_comments() };
 Function: get all comments and blocks in the NEXUS object
 Returns : array of strings and block objects
 Args    : none

=cut

sub get_blocks_and_comments {
    my ($self) = @_;
    return $self->{'block_level'} || [];
}

=head2 get_weights

 Name    : get_weights
 Usage   : $nexus->get_weights($charblockname);
 Function: get all weights for a block.
 Returns : the weights of alignments in a Characters Block
 Args    : an hash of weightset objects

=cut

sub get_weights {
    my ( $self, $characters ) = @_;
    my $blocks = $self->get_blocks('assumptions');
    my %weights;
    for my $block (@$blocks) {
        if ( lc $block->get_link('characters') eq lc $characters ) {
            push @{ $weights{ $block->get_title } },
                @{ $block->get_assumptions };
        }
    }
    return \%weights;
}

=head2 get_taxlabels

 Name    : get_taxlabels
 Usage   : $nexus->get_taxlabels();
 Function: get the taxa labels of the NEXUS object (obtained from TAXA block).
 Returns : an arrayreference of taxa labels.
 Args    : none

=cut

sub get_taxlabels {
    my $self = shift;
    return $self->get_block('taxa')->get_taxlabels();
}

=head2 get_otus

 Name    : get_otus
 Usage   : $nexus->get_otus();
 Function: Retrieves list of OTUs 
 Returns : Array of OTU names or Bio::NEXUS::TaxUnit objects
 Args    : none

=cut

sub get_otus {
    my $self = shift;

    if ( my $taxablock = $self->get_block('taxa') ) {
        return $taxablock->get_taxlabels();
    }
    if ( my $charblock = $self->get_block('characters') ) {
        return $charblock->get_otus();
    }
    if ( my $treesblock = $self->get_block('trees') ) {
        return $treesblock->get_otus();
    }
    throw 'BadArgs' => 'no appropriate block exists to get the otus from';
}

=head2 rename_otus

 Name    : rename_otus
 Usage   : $nexus->rename_otus(\%translation);
 Function: rename all OTUs 
 Returns : a new nexus object with new OTU names
 Args    : a ref to hash based on OTU name pairs

=cut

sub rename_otus {
    my ( $self, $translation ) = @_;
    my $nexus = $self->clone();
    for my $block ( @{ $nexus->get_blocks() } ) {
    	# XXX duck-typing is probably okay, no? -- RAV
#        if ( $block->get_type()
#            =~ /^(?:characters|taxa|sets|span|history|trees)$/i )
        if ( $block->can('rename_otus') ) {
            $block->rename_otus($translation);
        }
    }
    return $nexus;
}

=head2 add_otu_clone

 Name    : add_otu_clone
 Usage   : $nexus_object->add_otu_clone($original_otu_name, $copy_otu_name);
 Function: creates a copy of a specified otu inside this Bio::NEXUS object
 Returns : n/a
 Args    : $original_otu_name (string) - the name of the otu that will be cloned, $copy_otu_name (string) - the desired name for the new clone
 Preconditions : $original_otu_name and $copy_otu_name are not equal, $original_otu_name is a valid otu name (existing otu)
 
=cut

sub add_otu_clone {
	my ( $self, $original_otu_name, $copy_otu_name ) = @_;
	$logger->warn( "not fully implemented!" );
	
	if (! defined $original_otu_name || ! defined $copy_otu_name) {
		throw 'BadArgs' => 'missing argument!';
	}

	if ($original_otu_name eq $copy_otu_name) {
		throw 'BadArgs' => 'otu names should be different';	
	}
	
	if ( grep {$_ eq $copy_otu_name} @{$self->get_taxlabels} ) {
		throw 'BadArgs' => "duplicate otu name [$copy_otu_name] already exists";		
	}
	$logger->debug("orig: $original_otu_name; copy: $copy_otu_name");
	
	# todo:
	# a portion of the following code should be re-written as
	# a stand-alone, utility method
	my $contains_otu = "false";
	foreach my $otu (@{ $self->get_taxlabels() }) {
		$logger->debug("$otu");
		if ($otu eq $original_otu_name) {
			$contains_otu = "true";
			last;
		}
	}

	if ($contains_otu eq "true") {
		# otu cloning happens here:
		# - cycle through all blocks and call add_otu_clone() method on each block
		foreach my $block ( @{ $self->get_blocks() } ) {
			$logger->debug( "> Block: " . $block->get_type() );
			$block->add_otu_clone($original_otu_name, $copy_otu_name);
		}
	}
	else {
		throw 'BadArgs' => "the specified otu [$original_otu_name] does not exist";
	}
	
}

=head2 select_blocks

 Name    : select_blocks
 Usage   : $nexus->select_blocks(\@blocknames);
 Function: select a subset of blocks
 Returns : a new nexus object 
 Args    : a ref to array of block names to be selected

=cut

sub select_blocks {
    my ( $self, $blocknames ) = @_;
    my $nexus = __PACKAGE__->new();
    for my $blockname (@$blocknames) {
        $nexus->add_block( $self->get_block($blockname) );
    }
    return $nexus;
}

=head2 exclude_blocks

 Name    : exclude_blocks
 Usage   : $nexus->exclude_blocks(\@blocknames);
 Function: remove a subset of blocks
 Returns : a new nexus object 
 Args    : a ref to array of block names to be removed

=cut

sub exclude_blocks {
    my ( $self, $blocknames ) = @_;
    my $nexus = $self->clone();
    for my $blockname (@$blocknames) {
        $nexus->remove_block($blockname);
    }
    return $nexus;
}

=head2 select_otus

 Name    : select_otus
 Usage   : $nexus->select_otus(\@otunames);
 Function: select a subset of OTUs
 Returns : a new nexus object 
 Args    : a ref to array of OTU names

=cut

sub select_otus {
    my ( $self, $otunames ) = @_;
    my $nexus = $self->clone();

    for my $block ( @{ $nexus->get_blocks() } ) {
    	# XXX duck-typing probably okay, no? -- RAV
        #if ( $block->get_type() =~ /^(?:characters|taxa|sets|span|history)$/i )
        if ( $block->can('select_otus') ) {
            $block->select_otus($otunames);
        }
    }
    return $nexus;
}

=head2 exclude_otus

 Name    : exclude_otus
 Usage   : $nexus->exclude_otus(\@otunames);
 Function: remove a subset of OTUs
 Returns : a new nexus object 
 Args    : a ref to array of OTU names to be removed

=cut

sub exclude_otus {
    my ( $self, $otus ) = @_;
    my @OTUs;
    for my $otu ( @{ $self->get_otus() } ) {
        my $exclude = 0;
        for my $name ( @{$otus} ) {
            last if ( $otu eq $name ) && ( $exclude = 1 );
        }
        push( @OTUs, $otu ) unless ($exclude);
    }
    return $self->select_otus( \@OTUs );
}

=head2 select_tree

 Name    : select_tree
 Usage   : $nexus->select_tree($treename);
 Function: select a tree
 Returns : a new nexus object 
 Args    : a tree name

=cut

sub select_tree {
    my ( $self, $treename ) = @_;
    my $nexus = $self->clone();
    $nexus->get_block('trees')->select($treename);
    return $nexus;
}

=head2 select_subtree

 Name    : select_subtree
 Usage   : $nexus->select_subtree($inodename);
 Function: select a subtree
 Returns : a new nexus object 
 Args    : an internal node name for subtree to be selected

=cut

sub select_subtree {
    my ( $self, $nodename, $treename ) = @_;
    if ( not defined $nodename ) {
    	throw 'BadArgs' => 'Need to specify an internal node name for subtree';
    }

    my $nexus      = $self->clone();
    my $treesblock = $nexus->get_block("trees");
    $treesblock->select_subtree( $nodename, $treename );
    my $OTUnames = $treesblock->get_taxlabels();
    $nexus->get_block('taxa')->select_otus($OTUnames);

    for my $block ( @{ $nexus->get_blocks() } ) {
        # XXX duck-typing probably okay, no? -- RAV
        #if ( $block->get_type() =~ /^(?:characters|taxa|sets|span|history)$/i )
        if ( $block->can('select_otus') ) {
            $block->select_otus($OTUnames);
        }
    }

    return $nexus;
}

=head2 exclude_subtree

 Name    : exclude_subtree
 Usage   : $nexus->exclude_subtree($inodename);
 Function: remove a subtree
 Returns : a new nexus object 
 Args    : an internal node for subtree to be removed

=cut

sub exclude_subtree {
    my ( $self, $nodename, $treename ) = @_;
    if ( not defined $nodename ) {
    	throw 'BadArgs' => 'Need to specify an internal node name for subtree';
    }

    my $nexus      = $self->clone();
    my $treesblock = $nexus->get_block('trees');
    $treesblock->exclude_subtree( $nodename, $treename );
    my $OTUnames = $treesblock->get_taxlabels();

    for my $block ( @{ $nexus->get_blocks() } ) {
        # XXX duck-typing probably okay, no? --RAV
        #if ( $block->get_type() =~ /^(?:characters|taxa|sets|span|history)$/i )
        if ( $block->can('select_otus') ) {
            $block->select_otus($OTUnames);
        }
    }

    return $nexus;
}

=head2 select_chars

 Name    : select_chars
 Usage   : $nexus->select_chars(\@columns);
 Function: select a subset of characters
 Returns : a new nexus object 
 Args    : a ref to array of character columns

=cut

sub select_chars {
    my ( $self, $columns, $title ) = @_;
    my @labels = ();
    my $nexus  = $self->clone();
    my $block  = $nexus->get_block( "characters", $title );
    $block->select_columns($columns);

#
# temp change by arlin
#  to do this right, we need to separate two systems, column numbers (index + 1)
#  and column labels.  Default should be to select labels if they exist, and
#  otherwise to assigning old column numbers as new labels.  An alternative
#  to the default would be to leave the new column labels unset (i.e., ignore
#  previous labels or numbers).
#    print &Dumper($columns);exit;
    for my $i ( 0 .. $#{ $columns } ) {
        $labels[$i] = $$columns[$i] + 1;
    }

    # use these to set labels
    if ( !$block->get_charlabels || @{ $block->get_charlabels } == 0 ) {
        $block->set_charlabels( \@labels );
    }
    $block = $nexus->get_block("assumptions");
    if ($block) {
        $block->select_assumptions($columns);
    }

    return $nexus;
}

=head2 exclude_chars

 Name    : exclude_chars
 Usage   : $nexus->exclude_chars($columns,block_type);
 Function: exclude specified columns from a block.
 Returns : new nexus object 
 Args    : column numbers to exclude as array reference, block_type as string

=cut

sub exclude_chars {
    my ( $self, $columns, $title ) = @_;
    my $block = $self->get_block( "characters", $title );

    my $len = $block->get_dimensions()->{'nchar'};
    print "$len\n";
    my @columns = ( -1, @{$columns}, $len );
    my @select = ();
    for my $i ( 0 .. $#columns ) {
        for ( my $j = $columns[$i] + 1; $j < $columns[ $i + 1 ]; $j++ ) {
            push @select, $j;
        }
    }
    print "@select\n";
    return $self->select_chars( \@select, $title );
}

=head2 reroot

 Name    : reroot
 Usage   : $nexus->reroot($outgroupname);
 Function: reroot the tree using the new outgroup
 Returns : a new nexus object 
 Args    : a OTU name as new outgroup

=cut

sub reroot {
    my ( $self, $outgroup, $root_position, $treename ) = @_;
    my $nexus = $self->clone();
    my $trees = $nexus->get_block('trees');
    if ( defined $treename ) {
        $trees->reroot_tree( $outgroup, $root_position, $treename );
    }
    else {
        $trees->reroot_all_trees( $outgroup, $root_position );
    }
    return $nexus;
}

=head2 equals

 Name    : equals
 Usage   : $nexus->equals($another);
 Function: compare if two Bio::NEXUS objects are equal
 Returns : boolean 
 Args    : a Bio::NEXUS object

=cut

sub equals {
    my ( $self, $nexus ) = @_;
    my @blocks1 = @{ $self->get_blocks() };
    my @blocks2 = @{ $nexus->get_blocks() };
    if ( @blocks1 != @blocks2 ) { return 0; }
    @blocks1 = sort {
              $a->get_type()
            . ( $a->get_title || '' ) cmp $b->get_type()
            . ( $b->get_title || '' )
    } @blocks1;
    @blocks2 = sort {
              $a->get_type()
            . ( $a->get_title || '' ) cmp $b->get_type()
            . ( $b->get_title || '' )
    } @blocks2;

    for ( my $i = 0; $i < @blocks1; $i++ ) {
        if ( ( !$blocks1[$i] ) && ( !$blocks2[$i] ) ) { next; }
        if ( !$blocks1[$i]->equals( $blocks2[$i] ) ) {

            #            print &Dumper($blocks1[$i]);
            #            print &Dumper($blocks2[$i]);
            return 0;
        }
    }
    return 1;
}

=head2 write

 Name    : write
 Usage   : $nexus->write($filename, $verbose);
 Function: Writes to NEXUS file from stored NEXUS data
 Returns : none
 Args    : file name (string) for output to file or '-' or 'STDOUT' for standard output

=cut

sub write {
    my ( $self, $filename, $verbose ) = @_;
    my $fh;

    if ( ref($filename) eq "GLOB" ) { 
    	$fh = $filename; 
    }
    elsif ( $filename eq "-" || $filename eq \*STDOUT ) { 
    	$fh = \*STDOUT; 
    }
    else {
        open( $fh, ">$filename" ) || throw 'FileError' => $!;
    }

    print $fh "#NEXUS\n\n";

    my @blocks_and_comments = @{ $self->get_blocks_and_comments() };

    # First, print any comments that are at the top level
    for ( my $i = 0; $i < @blocks_and_comments; $i++ ) {
        if ( _is_comment( $blocks_and_comments[$i] ) ) {
            print $fh "$blocks_and_comments[$i]\n\n";
            shift @blocks_and_comments;
            $i--;
            next;
        }
        else {
            last;
        }
    }

    # Then print the TAXA Block
    $self->set_taxablock;
    $self->get_block('taxa')->_write( $fh, $verbose );
    print $fh "\n";

    # And print whatever else there is
    for my $block_or_comment (@blocks_and_comments) {
        if ( _is_comment($block_or_comment) ) {
            print $fh "$block_or_comment\n\n";
            next;
        }
        my $type = $block_or_comment->get_type();
        if ( lc $type eq 'taxa' ) { next; }
        $block_or_comment->_write($fh);
        print $fh "\n";
    }
    
    # if $fh is STDOUT, don't close it!
    close($fh) unless ($fh == \*STDOUT);
}

=head2 set_taxablock

 Name    : set_taxablock
 Usage   : $nexus->set_taxablock();
 Function: Sets taxablock if taxablock is not already defined in the nexus object
 Returns : none
 Args    : none

=cut

sub set_taxablock {
    my $self = shift;
    if ( not defined $self->get_block('taxa') ) {
        for my $block ( @{ $self->get_blocks } ) {
            my $block_type = lc $block->get_type();
            if ( $block_type eq 'characters' || $block_type eq 'trees' ) {
                my $taxlabels = $block->get_taxlabels();
                if ( ( not defined $taxlabels ) or ( not @$taxlabels ) ) {
                    if ( $block_type eq 'trees' ) {
                        $block->set_taxlabels(
                            $block->get_tree()->get_node_names() );
                    }
                    else {
                        $block->set_taxlabels(
                            $block->get_otuset->get_otu_names() );
                    }
                    $taxlabels = $block->get_taxlabels();
                }
                my $taxa_block = new Bio::NEXUS::TaxaBlock('taxa');
                $taxa_block->set_taxlabels($taxlabels);
                $self->add_block($taxa_block);
                return;
            }
        }
    }
}

sub AUTOLOAD {
    return if $AUTOLOAD =~ /DESTROY$/;
    my $package_name = __PACKAGE__ . '::';

    # The following methods are deprecated and are temporarily supported
    # via a warning and a redirection
    my %synonym_for =
        ( "${package_name}is_comment" => 'Bio::NEXUS::Functions::_is_comment',
        );

    if ( defined $synonym_for{$AUTOLOAD} ) {
        $logger->warn("$AUTOLOAD() is deprecated; use $synonym_for{$AUTOLOAD}() instead");
        goto &{ $synonym_for{$AUTOLOAD} };
    }
    else {
    	throw 'UnknownMethod' => "Unknown method $AUTOLOAD called";
    }
}

1;
