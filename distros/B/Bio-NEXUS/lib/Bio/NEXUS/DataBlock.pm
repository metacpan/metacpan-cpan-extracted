#################################################################
# DataBlock.pm
#################################################################
# Author: Thomas Hladish
# $Id: DataBlock.pm,v 1.13 2007/09/21 23:09:09 rvos Exp $

#################### START POD DOCUMENTATION ##################

=head1 NAME

Bio::NEXUS::DataBlock - Represents the deprecated DATA Block in NEXUS file. 

=head1 SYNOPSIS

$block_object = new Bio::NEXUS::DataBlock($type, $block, $verbose, $taxlabels_ref);

=head1 DESCRIPTION

The DataBlock class represents the deprecated Data Block in a NEXUS file.  Data Blocks are still used by some prominent programs, unfortunately, although they are essentially the same as a Characters Block and a Taxa Block combined.  Data Blocks may be used as input, but are not output by the NEXPL library.  For more information on Data Blocks, see the Characters Block documentation.

=head1 COMMENTS

Don't use this block type if you can help it.

=head1 FEEDBACK

All feedback (bugs, feature enhancements, etc.) are greatly appreciated. 

=head1 AUTHORS

 Thomas Hladish (tjhladish at yahoo)

=head1 VERSION

$Revision: 1.13 $

=head1 METHODS

=cut

package Bio::NEXUS::DataBlock;

use strict;
#use Data::Dumper; # XXX this is not used, might as well not import it!
#use Carp; # XXX this is not used, might as well not import it!
use Bio::NEXUS::Functions;
use Bio::NEXUS::CharactersBlock;
use Bio::NEXUS::Util::Logger;
use Bio::NEXUS::Util::Exceptions;
use vars qw(@ISA $VERSION $AUTOLOAD);
use Bio::NEXUS; $VERSION = $Bio::NEXUS::VERSION;

@ISA = qw(Bio::NEXUS::CharactersBlock);
my $logger = Bio::NEXUS::Util::Logger->new();

=head2 new

 Title   : new
 Usage   : block_object = new Bio::NEXUS::CharactersBlock($block_type, $block, $verbose, $taxa);
 Function: Creates a new Bio::NEXUS::CharactersBlock object
 Returns : Bio::NEXUS::CharactersBlock object
 Args    : verbose flag (0 or 1), type (string) and the block to parse (string)

=cut

sub new {
    my $deprecated_class = shift;
    my $deprecated_type  = shift;
    $logger->info("Read in Data Block (deprecated), creating Characters Block instead");
    my $self = new Bio::NEXUS::CharactersBlock( 'characters', @_ );
    return $self;
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
}

1;
