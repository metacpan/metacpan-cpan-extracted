#################################################################
# NotesBlock.pm
#################################################################
# 
# thanks to Tom Hladish for the original version 
#
# $Id: NotesBlock.pm,v 1.13 2012/02/07 21:38:09 astoltzfus Exp $

#################### START POD DOCUMENTATION ##################

=head1 NAME

Bio::NEXUS::NotesBlock - Represents a NOTES block in a NEXUS file.

=head1 SYNOPSIS

=head1 DESCRIPTION

Placeholding module for the Notes Block class.

=head1 COMMENTS

=head1 FEEDBACK

All feedback (bugs, feature enhancements, etc.) are greatly appreciated. 

=head1 VERSION

$Revision: 1.13 $

=head1 METHODS

=cut

package Bio::NEXUS::NotesBlock;

use strict;
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
 Usage   : block_object = new Bio::NEXUS::NotesBlock($block_type, $commands, $verbose);
 Function: Creates a new Bio::NEXUS::NotesBlock object 
 Returns : Bio::NEXUS::NotesBlock object
 Args    : type (string), the commands/comments to parse (array ref), and a verbose flag (0 or 1; optional)

=cut

sub new {
    my ( $class, $type, $commands, $verbose ) = @_;
    if ( not $type ) { 
    	( $type = lc $class ) =~ s/Bio::NEXUS::(.+)Block/$1/i; 
    }
    my $self = { 
    	'type' => $type, 
    };
    bless $self, $class;
    if ( defined $commands and @$commands ) {
    	$self->_parse_block( $commands, $verbose );
    }
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
        	'UnknownMethod' => "ERROR: Unknown method $AUTOLOAD called"
        );
    }
    return;
}

1;
