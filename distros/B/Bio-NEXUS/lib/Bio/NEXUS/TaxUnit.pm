########################################################################
# TaxUnit.pm
########################################################################
# Author: Chengzhi Liang, Thomas Hladish
# $Id: TaxUnit.pm,v 1.23 2007/09/24 04:52:14 rvos Exp $

#################### START POD DOCUMENTATION ##################

=head1 NAME

Bio::NEXUS::TaxUnit - Represents a taxon unit in a NEXUS file

=head1 SYNOPSIS

$tu = new Bio::NEXUS::TaxUnit($name, $seq);

=head1 DESCRIPTION

This module represents a taxon unit in a NEXUS file (in characters block or History block)

=head1 COMMENTS

=head1 FEEDBACK

All feedback (bugs, feature enhancements, etc.) are greatly appreciated. 

=head1 AUTHORS

 Chengzhi Liang (liangc@umbi.umd.edu)
 Thomas Hladish (tjhladish at yahoo)

=head1 VERSION

$Revision: 1.23 $

=head1 METHODS

=cut

package Bio::NEXUS::TaxUnit;

use strict;
use Bio::NEXUS::Functions;
#use Carp;# XXX this is not used, might as well not import it!
#use Data::Dumper; # XXX this is not used, might as well not import it!
use Bio::NEXUS::Util::Exceptions 'throw';
use Bio::NEXUS::Util::Logger;
# Note: This script uses Clone::PP to clone the
# nested perl data structures
#use Clone::PP; # XXX changed this to a lazy loading 'require' where it's needed, in the clone function
use vars qw($VERSION $AUTOLOAD);
use Bio::NEXUS; $VERSION = $Bio::NEXUS::VERSION;

my $logger = Bio::NEXUS::Util::Logger->new();

=head2 new

 Title   : new
 Usage   : $otu = new Bio::NEXUS::TaxUnit($name, $seq);
 Function: Creates a new Bio::NEXUS::TaxUnit object 
 Returns : Bio::NEXUS::TaxUnit object
 Args    : name and sequence of TaxUnit object

=cut

sub new {
    my ( $class, $name, $seq ) = @_;
    my $self = { name => $name, seq => $seq, };
    bless $self, $class;
    return $self;
}

=head2 clone

 Title   : clone
 Usage   : my $newtu = $set->clone();
 Function: clone an TaxUnit object 
 Returns : TaxUnit object
 Args    : none

=cut

sub clone {
    my ($self) = @_;
    my $class = ref($self);
    my $newtu = bless( { %{$self} }, $class );
    # clone the sequence using Clone::PP
    if (defined $self->{'seq'}) {
	    eval { require Clone::PP };
	    if ( $@ ) {
	    	throw 'ExtensionError' => "Can't clone, no Clone::PP $@";
	    }
	    $newtu->{'seq'} = Clone::PP::clone($self->{'seq'});
	}
    return $newtu;
}

=head2 set_name

 Title   : set_name
 Usage   : $tu->set_name($name);
 Function: sets the name of OTU 
 Returns : none
 Args    : name

=cut

sub set_name {
    my ( $self, $name ) = @_;
    $self->{'name'} = $name;
}

=head2 get_name

 Title   : get_name
 Usage   : $tu->get_name();
 Function: Returns name
 Returns : name
 Args    : none

=cut

sub get_name {
    my ($self) = @_;
    return $self->{'name'};
}

=head2 set_seq

 Title   : set_seq
 Usage   : $tu->set_seq($seq);
 Function: sets the sequence of OTU 
 Returns : none
 Args    : sequence

=cut

sub set_seq {
    my ( $self, $seq ) = @_;
    $self->{'seq'} = $seq;
}

=head2 get_seq

 Title   : get_seq
 Usage   : $tu->get_seq();
 Function: Returns sequence
 Returns : sequence (an array of characters or tokens)
 Args    : none

=cut

sub get_seq {
    my ($self) = @_;
    return $self->{'seq'};
}

=head2 get_seq_string

 Title   : get_seq_string
 Usage   : $taxunit->get_seq_string($tokens_flag);
 Function: Returns sequence
 Returns : sequence (a string, wherein tokens or characters are space-delimited 
           if a true value has been passed in for $tokens)
 Args    : boolean tokens argument (optional)

=cut

sub get_seq_string {
    my ( $self, $tokens_flag ) = @_;
    my @seq;
    for my $token ( @{ $self->get_seq } ) {
        if ( ref $token eq 'HASH' ) {
            my $token_type = $token->{'type'};
            if ( ref $token->{'states'} eq 'ARRAY' ) {
                my @states = @{ $token->{'states'} };
                if ( $token_type eq 'uncertainty' ) {
                    push @seq, '{', @states, '}';
                }
                elsif ( $token_type eq 'polymorphism' ) {
                    push @seq, '(', @states, ')';
                }
                else {
                	throw 'BadFormat' => "Unknown token type encountered: only 'uncertainty' and 'polymorphism' are valid";
                }
            }
            elsif ( ref $token->{'states'} eq 'HASH' ) {
                my %states = %{ $token->{'states'} };
                my @polymorphism
                    ;  # will contain something like ('A:0.2', 'G:0.4', 'P:0.4')
                if ( $token_type eq 'polymorphism' ) {
                    while ( my ( $key, $val ) = each %states ) {
                        push @polymorphism, "$key:$val";
                    }
                    push @seq, join q{ }, '(', @polymorphism, ')';
                }
                else {
                	throw 'BadFormat' => "Unknown token type <$token_type> encountered: only 'polymorphism' is valid when explicit frequencies are included";
                }
            }
        }
        else {
            push @seq, $token;
        }
    }
    my $delimiter = $tokens_flag ? q{ } : q{};
    return join $delimiter, @seq;
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
    	throw 'UnknownMethod' => "Unknown method $AUTOLOAD called";
    }
}

1;
