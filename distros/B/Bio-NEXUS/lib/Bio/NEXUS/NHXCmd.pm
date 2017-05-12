
######################################################
# NHXCmd.pm
######################################################
# Author:
# $Id: NHXCmd.pm,v 1.9 2007/09/21 23:09:09 rvos Exp $

#################### START POD DOCUMENTATION ##################

=head1 NAME

Bio::NEXUS::NHXCmd - Provides functions for manipulating nodes in trees

=head1 SYNOPSIS

new Bio::NEXUS::NHXCmd;

=head1 DESCRIPTION

Provides a few useful functions for nodes.

=head1 FEEDBACK

All feedback (bugs, feature enhancements, etc.) are all greatly appreciated. There are no mailing lists at this time for the Bio::NEXUS::Node module, so send all relevant contributions to Dr. Weigang Qiu (weigang@genectr.hunter.cuny.edu).

=head1 AUTHORS

Mikhail Bezruchko (bezruchk@umbi.umd.edu), Vivek Gopalan

=head1 CONTRIBUTORS


=head1 METHODS

=cut

package Bio::NEXUS::NHXCmd;

use strict;

#use Bio::NEXUS::Functions;
#use Data::Dumper; # XXX this is not used, might as well not import it!
#use Carp;# XXX this is not used, might as well not import it!
use Bio::NEXUS::Util::Exceptions;
use vars '$VERSION';
use Bio::NEXUS; $VERSION = $Bio::NEXUS::VERSION;

sub BEGIN {
    eval {
        require warnings;
        1;
        }
        or do {
        no strict 'refs';
        *warnings::import = *warnings::unimport = sub { };
        $INC{'warnings.pm'} = '';
        };
}

=head2 new

 Title   : new
 Usage   : $nhx_cmd = new Bio::NEXUS::NHXCmd($comment_string);
 Function: Creates a new Bio::NEXUS::NHXCmd object
 Returns : Bio::NEXUS::NHXCmd object
 Args    : $comment_string - a string representation of the comment (w/o brackets)

=cut

sub new {
    my ( $class, $command_str ) = @_;
    my $self = { '_tag_data' => undef };
    bless $self, $class;
    if ( defined $command_str and $self->_is_nhx_command($command_str) ) {
        $self->_parse_nhx_command($command_str);
    }
    return $self;
}

=head2 to_string

 Title   : to_string
 Usage   : $comment_str = $nhx_obj->to_string
 Function: Returns a string representation of the NHX command
 Returns : String
 Args    : None

=cut

sub to_string {
    my ($self) = @_;
    my $result = "&&NHX";
    if ( not defined $self->{_tag_data} ) {
        $result = undef;
        return $result;
    }
    else {
        for my $tag ( sort keys %{ $self->{_tag_data} } ) {

            #print $tag;

            if ( defined $tag ) {
                my @values = $self->get_values($tag);

                for my $value (@values) {
                    next unless defined $value;
                    $result .= ":$tag=$value";
                }
            }
        }
        return $result;
    }
}

=head2 equals

 Title   : equals
 Usage   : $nhx_one->equals($nhx_two);
 Function: compares two NHX objects for equality
 Returns : 1 if the two objects contain the same date; 0 if they don't
 Args    : $nhx_two - a Bio::NEXUS::NHXCmd object

=cut

sub equals {
    my ( $self, $other ) = @_;

    my @self_tags  = $self->get_tags();
    my @other_tags = $other->get_tags();

    if ( scalar @self_tags != scalar @other_tags ) {
        return 0;
    }
    else {
        for my $tag (@self_tags) {
            if ( !$other->contains_tag($tag) ) { 
            	return 0; 
            }

            my @self_values  = sort $self->get_values($tag);
            my @other_values = sort $other->get_values($tag);

            if ( scalar @self_values != scalar @other_values ) { 
            	return 0; 
            }

            for ( my $i = 0; $i < scalar @self_values; $i++ ) {
                if ( $self_values[$i] ne $other_values[$i] ) { 
                	return 0; 
                }
            }
        }
        return 1;
    }
    return 0;
}

=head2 clone

 Title   : clone
 Usage   : $new_obj = $original->clone();
 Function: Creates a "deep copy" of a Bio::NEXUS::NHXCmd
 Returns : A "deep copy" of a Bio::NEXUS::NHXCmd
 Args    : None

=cut

sub clone {
    my ($self) = @_;
    my $class = ref($self);

    #return bless( { %{$self} }, $class );
    my $data;
    $data->{_tag_data} = _deep_copy( $self->{_tag_data} );
    return bless( { %{$data} }, $class );

}    # end of sub

#### ?????????? Has to be added to the Bio::NEXUS::Functions package for deep copying data structures
## reference : http://www.stonehenge.com/merlyn/UnixReview/col30.html
####

sub _deep_copy {
    my $this = shift;
    if ( not ref $this ) {
        $this;
    }
    elsif ( ref $this eq "ARRAY" ) {
        [ map _deep_copy($_), @$this ];
    }
    elsif ( ref $this eq "HASH" ) {
        +{ map { $_ => _deep_copy( $this->{$_} ) } keys %$this };
    }
    else { die "what type is $_?" }
}

=begin comment

 Title   : _parse_nhx_command
 Usage   : N/A
 Function: A utility (private) function that parses an NHX comment of the tree node
 Returns	: Hash of arrays, where each key is an NHX tag (i.e. 'B'), and the value is an array of values associated with that tag
 Args	: $comment - a string containing the comment

=end comment

=cut

sub _parse_nhx_command {
    my ( $self, $command_str ) = @_;
    my @command = split( //, $command_str );
    my $word    = "";
    my @words   = ();

    #
    #	1. Split the NHX command into words (tag+value combo)
    #
    my $open_quote = 0;
    for my $char (@command) {

        # try converting all dbl-quotes to sngl-quotes
        if ( !$open_quote && $char =~ /("|')/ ) {
            $open_quote = 1;
            next;
        }

        if ( $open_quote && $char =~ /("|')/ ) {
            $open_quote = 0;
            next;
        }

=begin comment 

            warn "invalid whitespace ! - check your file\n" if ( ( !$open_quote ) && $char =~ /\s/ ); #whitespace_guardian

=end comment

=cut

        # The main part
        elsif ( !$open_quote && $char eq ':' ) {

           # start of a new tag; add the previous word to the array, reset $word
            push( @words, $word );
            $word = ":";
        }

        else {
            $word .= $char;
        }

    }

    # This is a broken solution - works, but should be re-written
    push( @words, $word );

    #
    #	2. Split each word into a _tag_ and a _value_
    #
    for my $word (@words) {
        my ( $tag, $value ) = $word =~ m/^:(.*?)=(.*$)/;
        next if not defined $tag;
        push( @{ $self->{'_tag_data'}->{$tag} }, $value );
    }

}    # end of sub

=begin comment

 Title   : _is_nhx_command
 Usage   : $foo = _is_nhx_command($command)
 Function: A utility (private) function that checks if a given string appears to be an NHX command
 Returns : 1 if the string is an NHX command, 0 if not
 Args    : $comment - string representation of the comment/command

=end comment 

=cut

sub _is_nhx_command {
    my ( $self, $comment ) = @_;
    return $comment =~ m/^\s*&&NHX/i;
}

=head2 contains_tag

 Title   : contains_tag
 Usage   : $nhx_obj->_contains_tag($tag_name)
 Function: Checks if a given tag exists
 Returns : 1 if the tax exists, 0 if it doesn't
 Args    : $tag_name - a string representation of a tag

=cut

sub contains_tag {
    my ( $self, $tag_name ) = @_;
    return defined( $self->{'_tag_data'}->{$tag_name} );
}

=head2 get_tags

 Title   : get_tags
 Usage   : $nhx_obj->get_tags(); 
 Function: Reads and returns an array of tags
 Returns : An array of tags
 Args    : None

=cut

sub get_tags {
    my ($self) = @_;
    return sort keys %{ $self->{_tag_data} };
}

=head2 get_values 

 Title   : get_values
 Usage   : $nhx_obj->get_values($tag_name);
 Function: Returns the list of values associated with the given tag ($tag_name)
 Returns : Array of values
 Args    : $tag_name - a string representation of the tag

=cut

sub get_values {
    my ( $self, $tag_name ) = @_;
	if ( not defined $tag_name ) {
		Bio::NEXUS::Util::Exceptions::BadArgs->throw(
			'error' => "Required argument tag_name not defined"
		);
	}
    if ( $self->contains_tag($tag_name) ) {
        return @{ $self->{_tag_data}->{$tag_name} };
    }
    else {
        return undef;
    }
}

=head2 set_tag

 Title   : set_tag
 Usage   : nhx_obj->set_tag($tag_name, $tag_reference);
 Function: Updates the list of values associated with a given tag
 Returns : Nothing
 Args    : $tag_name - a string, $tag_reference - an array-reference

=cut

sub set_tag {
    my ( $self, $tag_name, $tag_values ) = @_;
	if ( not defined $tag_name || not defined $tag_values ) {
		Bio::NEXUS::Util::Exceptions::BadArgs->throw(
			'error' => "Required arguments tag_name and/or tag_values are not defined"
		);
	}
	if ( not ref $tag_values eq 'ARRAY' ) {
		Bio::NEXUS::Util::Exceptions::BadArgs->throw(
			'error' => "tag_values is not an array reference"
		);
	}

    #croak "no such tag: $tag_name\n" unless $self->contains_tag($tag_name);

    $self->{'_tag_data'}->{$tag_name} = $tag_values;

}

=head2 check_tag_value_present

 Title   : check_tag_value
 Usage   : $boolean = nhx_obj->check_tag_value($tag_name, $value);
 Function: check whether a particular value is present in a tag
 Returns : 0 or 1 [ true or false]
 Args    : $tag_name - a string, $value - scalar (string or number)

=cut

sub check_tag_value_present {
    my ( $self, $tag_name, $tag_value ) = @_;
    if ( not defined $tag_name || not defined $tag_value ) {
    	Bio::NEXUS::Util::Exceptions::BadArgs->throw(
    		'error' => "tag_name or tag_value is not defined"
    	);
    }

    #croak "no such tag: $tag_name\n" unless $self->contains_tag($tag_name);
    my $present = 0;
    for my $value ( $self->get_values($tag_name) ) {
        next unless defined $value;
        if ( $value eq $tag_value ) {
            $present = 1;
            last;
        }
    }
    return $present;
}

=head2 add_tag_value

 Title   : add_tag_value
 Usage   : $nhx_obj->add_tag_value($tag_name, $tag_value);
 Function: Adds a new tag/value set to the $nhx_obj;
 Returns : 0 if not added or 1 if added [false or true]
 Args    : $tag_name - a string, $tag_value - a string

=cut

sub add_tag_value {
    my ( $self, $tag_name, $tag_value ) = @_;
    if ( not defined $tag_name || not defined $tag_value ) {
    	Bio::NEXUS::Util::Exceptions::BadArgs->throw(
    		'error' => "tag_name or tag_value is not defined"
    	);
    }

    #croak "no such tag: $tag_name\n" unless $self->contains_tag($tag_name);

    my $is_value_present =
        $self->check_tag_value_present( $tag_name, $tag_value );
    push @{ $self->{_tag_data}->{$tag_name} }, $tag_value
        unless $is_value_present;
    return $is_value_present ? 0 : 1;

}

=head2 delete_tag

 Title   : delete_tag
 Usage   : $nhx_obj->delete_tag($tag_name);
 Function: Removes a given tag (and the associated valus) from the $nhx_obj
 Returns : Nothing
 Args    : $tag_name - a string representation of the tag

=cut

sub delete_tag {
    my ( $self, $tag_name ) = @_;

    delete $self->{_tag_data}->{$tag_name} if defined $tag_name;

}

=head2 delete_all_tags

 Title   : delete_all_tags
 Usage   : $nhx_obj->delete_all_tags();
 Function: Removes all tags from $nhx_obj
 Returns : Nothing
 Args    : None

=cut

sub delete_all_tags {
    my ($self) = @_;

    $self->{'_tag_data'} = undef;
}

1;

