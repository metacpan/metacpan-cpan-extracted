######################################################
# SpanBlock.pm
######################################################
# Author: Chengzhi Liang, Thomas Hladish
# $Id: SpanBlock.pm,v 1.33 2007/09/21 23:09:09 rvos Exp $

#################### START POD DOCUMENTATION ##################

=head1 NAME

Bio::NEXUS::SpanBlock - Represent SPAN block in a NEXUS file (contains meta data).

=head1 SYNOPSIS

 if ( $type =~ /spanblock/i ) {
     $block_object = new Bio::NEXUS::SpanBlock($type, $block, $verbose);
 }

=head1 DESCRIPTION

This module representing a SPAN block in a NEXUS file for meta data.

=head1 FEEDBACK

All feedback (bugs, feature enhancements, etc.) are greatly appreciated. 

=head1 AUTHORS

 Chengzhi Liang (liangc@umbi.umd.edu)
 Thomas Hladish (tjhladish at yahoo)

=head1 CONTRIBUTORS

=head1 METHODS

=cut

package Bio::NEXUS::SpanBlock;

use strict;
#use Data::Dumper; # XXX this is not used, might as well not import it!
use Bio::NEXUS::Functions;
use Bio::NEXUS::Block;
#use Carp;# XXX this is not used, might as well not import it!
use Bio::NEXUS::Util::Exceptions;
use Bio::NEXUS::Util::Logger;
use vars qw(@ISA $VERSION $AUTOLOAD);
use Bio::NEXUS; $VERSION = $Bio::NEXUS::VERSION;

@ISA = qw(Bio::NEXUS::Block);
my $logger = Bio::NEXUS::Util::Logger->new();

=head2 new

 Title   : new
 Usage   : block_object = new Bio::NEXUS::SpanBlock($block_type, $commands, $verbose);
 Function: Creates a new Bio::NEXUS::SpanBlock object 
 Returns : Bio::NEXUS::SpanBlock object
 Args    : type (string), the commands/comments to parse (array ref), and a verbose flag (0 or 1; optional)

=cut

sub new {
    my ( $class, $type, $commands, $verbose ) = @_;
    unless ($type) { ( $type = lc $class ) =~ s/Bio::NEXUS::(.+)Block/$1/i; }

    my $self = { type => $type, };
    bless $self, $class;
    $self->_parse_block( $commands, $verbose )
        if ( ( defined $commands ) and @$commands );
    return $self;
}

=head2 get_spandex

 Title   : get_spandex
 Usage   : $hash_ref = $span_block->get_spandex(;
 Function: Gets the SPANDEX command contents as hash_reference
 Returns : hash reference of the SPANDEX command contents
 Args    : none

=cut

sub get_spandex {
    my ($self) = @_;
    return $self->{'spandex'} || {};
}

=head2 add_spandex

 Title   : add_spandex
 Usage   : $span_block->add_spandex(;
 Function: Adds the SPANDEX command contents as hash_reference
 Returns : none 
 Args    : hash reference of the SPANDEX command contents

=cut

sub add_spandex {
    my ( $self, $new_spandex ) = @_;
    my %current_spandex = %{ $self->get_spandex() };
    $self->{'spandex'} = { %current_spandex, %$new_spandex };
    return;
}

=begin comment

 Title   : _parse_spandex
 Usage   : $block->_parse_spandex($buffer_string);
 Function: parser that parses the spandex command adds it to the SpanBlock object
 Returns : none
 Args    : the attributes and the value of the spandex command as array

=end comment 

=cut

sub _parse_spandex {
    my ( $self, $buffer ) = @_;
    my ( $key, $val ) = split /\s*=\s*/, $buffer;
    $self->add_spandex( { $key, $val } );
    return $key, $val;
}

=begin comment

 Title   : _parse_add
 Usage   : $span_block->_parse_add($content);
 Function: parse the additional commands (_parse_block parses the standard commands) in the spanblock
 Returns : hash of command and values
 Args    : a spanblock content as string

=end comment 

=cut

sub _parse_add {
    my ( $self, $content ) = @_;
    my %add;
    $content =~ s/to\s*=\s*(\S+)//;
    my $key = $1;
    $content =~ s/attributes\s*=\s*\(([^\)]+)\)//;
    my @attributes = split /\s*,\s*/, $1;
    $add{$key}{'attributes'} = \@attributes;
    $content =~ s/source\s*=\s*(\S+)//;
    $add{$key}{'source'} = $1;
    $content =~ s/data\s*=\s*//;
    my @data = split ',', $content;

    for my $values (@data) {
        $values =~ s/^\s*(.*?)\s*/$1/;
        if ( $values =~ s/^\s*("|')([^"]+)("|')// ) {
            my $keyvalue = $2;
            $keyvalue =~ s/\s+/_/g;
            $values = $keyvalue . $values;
        }
        my @values = split /\s+/, $values;
        push @{ $add{$key}{'data'} }, \@values;
    }
    $self->add_add( \%add );
    return \%add;
}

=head2 get_add

 Title   : get_add
 Usage   : $hash_ref = $span_block->get_add();
 Function: gets ADD command content to the span block
 Returns : hash reference of ADD command's attributes and values 
 Args    : none

=cut

sub get_add {
    my ($self) = @_;
    return $self->{'add'} || {};
}

=head2 add_add

 Title   : add_add
 Usage   : $span_block->add_add($hash_ref);
 Function: Adds ADD command contents to the span block
 Returns : none
 Args    : hash reference of ADD command's attributes and values 

=cut

sub add_add {
    my ( $self, $new_add ) = @_;
    my %current_add = %{ $self->get_add() };
    $self->{'add'} = { %current_add, %$new_add };
    return;
}

=begin comment

 Title   : _parse_method
 Usage   : $span_block->_parse_method($content);
 Function: parse the methods in the spanblock
 Returns : hash reference of name and values
 Args    : a spanblock content as string

=end comment 

=cut

sub _parse_method {
    my ( $self, $content ) = @_;
    my %method;
    $content =~ s/^\s*(\S+)//;
    my $name = $1;
    if ( $content =~ /parameters/ ) {
        $content =~ s/parameters\s*=\s*\(([^\)]+)\)//gi;
        my $parameters = $1;
        $method{$name}{'parameters'} = $parameters;
    }

    $method{$name} =
        { %{ $method{$name} || {} }, %{ $self->_parse_pair($content) } };
    $self->add_method( \%method );
    return \%method;
}

=head2 get_method

 Title   : get_method
 Usage   : $hash_ref = $span_block->get_method();
 Function: gets METHOD command content to the span block
 Returns : hash reference of METHOD command's attributes and values 
 Args    : none

=cut

sub get_method {
    my ($self) = @_;
    return $self->{'method'} || {};
}

=head2 add_method

 Title   : add_method
 Usage   : $span_block->add_method($string);
 Function: Adds METHOD command content to the span block
 Returns : none
 Args    : hash reference of METHOD command's attributes and values 

=cut

sub add_method {
    my ( $self, $new_method ) = @_;
    my %current_method = %{ $self->get_method() };
    $self->{'method'} = { %current_method, %$new_method };
    return;
}

=begin comment

 Title   : _parse_pair
 Usage   : $data_hash = $span_block->_parse_pair($string);
 Function: parse the pairs in the string to hash reference
 Returns : hash reference of name and values
 Args    : string as 'a=b c=d'

=end comment 

=cut

# This method seems obsolete to me.  should use _parse_nexus_words instead (TH, 8/06)
sub _parse_pair {

    # a=b c=d ..
    my ( $self, $string ) = @_;
    $string =~ s/^\s*(.+)/$1/;
    $string =~ s/(.*\S)\s*$/$1/;
    $string =~ s/=/ /g;

    my %hash = split /\s+/, $string;
    return \%hash;
}

=head2 get_attributes

 Title   : get_attributes
 Usage   : $attr_array_ref = $span_block->get_attributes($name);
 Function: get the attributes of a particular identifier name
 Returns : array reference of attributes.
 Args    : identifier name 

=cut

sub get_attributes {
    my ( $self, $name ) = @_;
    return $self->{'add'}{$name}{'attributes'};
}

=head2 get_data

 Title   : get_data
 Usage   : $data_array_ref = $span_block->get_data($name);
 Function: get the data of a particular identifier 
 Returns : array reference of data
 Args    : identifier name 

=cut

sub get_data {
    my ( $self, $name ) = @_;
    return $self->{'add'}{$name}{'data'};
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
    for my $values ( @{ $self->{'add'}{'taxlabels'}{'data'} } ) {
        ${$values}[0] = $$translation{ ${$values}[0] }
            if $$translation{ ${$values}[0] };
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
	#print "Warning: Bio::NEXUS::SpanBlock::add_otu_clone() method not fully implemented\n";
	
	foreach my $set ( @{ $self->{'add'}{'taxlabels'}{'data'} } ) {
		foreach my $item ( @{ $set } ) {
			if ($item eq $original_otu_name) {
				#print "found the otu in some set\n";
				unshift (@$set, $copy_otu_name);
				last;
			}
		}
	}
}

=head2 equals

 Name    : equals
 Usage   : $span->equals($another);
 Function: compare if two Bio::NEXUS::SpanBlock objects are equal
 Returns : boolean 
 Args    : a Bio::NEXUS::SpanBlock object

=cut

sub equals {
    my ( $self, $block ) = @_;

    if ( !Bio::NEXUS::Block::equals( $self, $block ) ) { return 0; }
    my @keys1 = sort keys %{ $self->{'add'} };
    my @keys2 = sort keys %{ $block->{'add'} };
    if ( scalar @keys1 != scalar @keys2 ) { return 0; }
    for ( my $i = 0; $i < @keys1; $i++ ) {
        if ( $keys1[$i] ne $keys2[$i] ) {
            return 0;
        }
    }
    @keys1 = sort keys %{ $self->{'method'} };
    @keys2 = sort keys %{ $block->{'method'} };
    if ( scalar @keys1 != scalar @keys2 ) { return 0; }
    for ( my $i = 0; $i < @keys1; $i++ ) {
        if ( $keys1[$i] ne $keys2[$i] ) {
            return 0;
        }
    }

    return 1;
}

=begin comment

 Name    : _write
 Usage   : $block->_write($filename);
 Function: Writes NEXUS block from stored data
 Returns : none
 Args    : none

=end comment

=cut

sub _write {
    my ( $self, $fh, $verbose ) = @_;
    $fh ||= \*STDOUT;

    Bio::NEXUS::Block::_write( $self, $fh );

    for my $key ( keys %{ $self->{'spandex'} || {} } ) {
        print $fh "\tSPANDEX $key=", $key = $self->{'spandex'}{$key}, ";\n";
    }

    for my $key ( keys %{ $self->{'add'} || {} } ) {
        print $fh "\tADD to=", $key;
        print $fh " attributes=(";
        print $fh ( join ',', @{ $self->{'add'}{$key}{'attributes'} } );
        print $fh ')';
        print $fh " source=", $self->{'add'}{$key}{'source'};
        print $fh " data=\n";
        for my $values ( @{ $self->{'add'}{$key}{'data'} } ) {
            print $fh "\t";
            for my $value (@$values) {
                print $fh "\t", _nexus_formatted($value);
            }
            print $fh ",\n";
        }
        print $fh "\t\t;\n";
    }
    for my $key ( keys %{ $self->{'method'} } ) {
        print $fh "\tMETHOD $key";
        print $fh " program=", $self->{'method'}{$key}{'program'};

        for my $key1 ( keys %{ $self->{'method'}{$key} } ) {
            if ( !$self->{'method'}{$key}{$key1} ) { next; }
            if ( $key1 =~ /program/i )    { next; }
            if ( $key1 =~ /parameters/i ) {
                print $fh " $key1=(", $self->{'method'}{$key}{$key1}, ')';
            }
            else {
                print $fh " $key1=", $self->{'method'}{$key}{$key1};
            }
        }
        print $fh ";\n";
    }
    for my $comm ( @{ $self->{'unknown'} || [] } ) {
        print $fh "\t$comm;\n";
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
