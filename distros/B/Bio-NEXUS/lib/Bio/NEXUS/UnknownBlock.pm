######################################################
# UnknownBlock.pm
######################################################
# Author: Peter Yang, Thomas Hladish
# $Id: UnknownBlock.pm,v 1.27 2007/09/24 04:52:14 rvos Exp $

#################### START POD DOCUMENTATION ##################

=head1 NAME

Bio::NEXUS::UnknownBlock - Represents a simple  object for storing information unrecognized blocks by the Bio::NEXUS module.

=head1 SYNOPSIS

$block_object = new Bio::NEXUS::UnknownBlock($block_type, $block, $verbose);

=head1 DESCRIPTION

Provides a simple way of storing information about a block that is not currently recognized by the NEXUS package. This is useful for remembering custom blocks.

=head1 FEEDBACK

All feedback (bugs, feature enhancements, etc.) are all greatly appreciated. There are no mailing lists at this time for the Bio::NEXUS::TaxaBlock module, so send all relevant contributions to Dr. Weigang Qiu (weigang@genectr.hunter.cuny.edu).

=head1 AUTHORS

 Peter Yang (pyang@rice.edu)
 Thomas Hladish (tjhladish at yahoo)

=head1 VERSION

$Revision: 1.27 $

=head1 METHODS

=cut

package Bio::NEXUS::UnknownBlock;

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
 Usage   : block_object = new Bio::NEXUS::UnknownBlock($block_type, $commands, $verbose);
 Function: Creates a new Bio::NEXUS::UnknownBlock object and automatically reads the file
 Returns : Bio::NEXUS::UnknownBlock object
 Args    : type (string), the commands/comments to parse (array ref), and a verbose flag (0 or 1; optional)

=cut

sub new {
    my ( $class, $type, $commands, $verbose ) = @_;
    unless ($type) { ( $type = lc $class ) =~ s/Bio::NEXUS::(.+)Block/$1/i; }
    my $self = { type => $type, };
    bless $self, $class;
    $self->_parse_block( $commands, $verbose );
    return $self;
}

=begin comment

 Title   : _parse_block
 Usage   : $block->_parse_block(\@commands, $verbose_flag);
 Function: Simple block parser that stores commands literally
 Returns : none
 Args    : array ref of commands, as parsed by Bio::NEXUS::read; and an optional verbose flag

=end comment

=cut

sub _parse_block {
    my ( $self, $commands, $verbose ) = @_;
    my $type = $self->get_type();
    $logger->info("Analyzing $type block now.");

CMD:
    for my $command (@$commands) {
        next CMD if $command =~ /^\s*(?:begin|end)/i;
        push @{ $self->{'block'} }, $command;
    }

	$logger->info("Analysis of $type block complete.");
    return;
}

=begin comment

 Name    : _write
 Usage   : $block->_write();
 Function: Writes NEXUS block from stored data
 Returns : none
 Args    : none

=end comment

=cut

sub _write {
    my $self = shift;
    my $fh = shift || \*STDOUT;
    print $fh "BEGIN ", uc $self->get_type(), ";\n";
    my $commands = $self->{'block'};
    for my $cmd (@$commands) {
        next if lc $cmd eq 'begin';
        print $fh "$cmd\n";
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
        $logger->warn( "$AUTOLOAD() is deprecated; use $synonym_for{$AUTOLOAD}() instead" );
        goto &{ $synonym_for{$AUTOLOAD} };
    }
    else {
        Bio::NEXUS::Util::Exceptions::UnknownMethod->throw(
        	'error' => "ERROR: Unknown method $AUTOLOAD called"
        );
    }
}

1;
