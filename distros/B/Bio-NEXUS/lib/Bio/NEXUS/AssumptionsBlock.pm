######################################################
# AssumptionsBlock.pm
######################################################
# Author: Chengzhi Liang, Weigang Qiu, Eugene Melamud, Peter Yang, Thomas Hladish
# $Id: AssumptionsBlock.pm,v 1.51 2012/02/07 21:38:09 astoltzfus Exp $

#################### START POD DOCUMENTATION ##################

=head1 NAME

Bio::NEXUS::AssumptionsBlock - Represents ASSUMPTIONS block of a NEXUS file

=head1 SYNOPSIS

 if ( $type =~ /assumptions/i ) {
     $block_object = new Bio::NEXUS::AssumptionsBlock($block_type, $block, $verbose);
 }

=head1 DESCRIPTION

If a NEXUS block is an assumptions block, this module parses the block and stores the assumptions data. Currently this only works with SOAP weight data, but we hope to extend its functionality.

=head1 FEEDBACK

All feedback (bugs, feature enhancements, etc.) are greatly appreciated. 

=head1 AUTHORS

 Chengzhi Liang (liangc@umbi.umd.edu)
 Weigang Qiu (weigang@genectr.hunter.cuny.edu)
 Eugene Melamud (melamud@carb.nist.gov)
 Peter Yang (pyang@rice.edu)
 Thomas Hladish (tjhladish at yahoo)

=head1 VERSION

$Revision: 1.51 $

=head1 METHODS

=cut

package Bio::NEXUS::AssumptionsBlock;

use strict;
use Bio::NEXUS::Functions;
use Bio::NEXUS::Block;
use Bio::NEXUS::WeightSet;
use Bio::NEXUS::Util::Logger;
use Bio::NEXUS::Util::Exceptions 'throw';
use vars qw(@ISA $AUTOLOAD $VERSION);
use Bio::NEXUS; $VERSION = $Bio::NEXUS::VERSION;

@ISA = qw(Bio::NEXUS::Block);
my $logger = Bio::NEXUS::Util::Logger->new();

=head2 new

 Title   : new
 Usage   : block_object = new Bio::NEXUS::AssumptionsBlock($block_type, $commands, $verbose );
 Function: Creates a new Bio::NEXUS::AssumptionsBlock object 
 Returns : Bio::NEXUS::AssumptionsBlock object
 Args    : type (string), the commands/comments to parse (array ref), and a verbose flag (0 or 1; optional)

=cut

sub new {
    my ( $class, $type, $commands, $verbose ) = @_;
    if ( not $type ) { 
    	( $type = lc $class ) =~ s/Bio::NEXUS::(.+)Block/$1/i; 
    }
    my $self = { 
    	'type'        => $type, 
    	'assumptions' => [], 
    	'options'     => undef 
    };
    bless $self, $class;        
    if ( ( defined $commands ) and @$commands ) {
    	$self->_parse_block( $commands, $verbose );  
    }
    return $self;
}

=begin comment

 Title   : _parse_wtset
 Usage   : $self->_parse_wtset($buffer); (private)
 Function: Processes the buffer containing weights data
 Returns : name and array of weights
 Args    : the buffer to parse (string)
 Method  : Creates a Bio::NEXUS::WeightSet object and sets the name and list of weight values.
           Adds the newly created WeightSet object to the set of assumptions
           this block contains.

=end comment 

=cut

sub _parse_wtset {
    my ( $self, $buffer ) = @_;
    my ( $name, $weights ) = split /=/, $buffer;
    $name =~ s/(\(.*\))//;
    my $flags = $1;
    my ( $type, $tokens );
    $type   = ( $flags =~ /vector/i )   ? 'VECTOR' : 'STANDARD';
    $tokens = ( $flags =~ /notokens/i ) ? 0        : 1;
    $name    =~ s/^\s*(\S+)\s*$/$1/;
    $weights =~ s/^\s*(\S+.*\S+)\s*$/$1/s;
    my @weights;
    if ( $tokens ) {
        @weights = split /\s*/, $weights;
    }
    else {
        @weights = split //, $weights;
    }
    my $is_weightset = 1;
    my $new_weightset = Bio::NEXUS::WeightSet->new( 
    	$name, 
    	\@weights, 
    	$is_weightset, 
    	$tokens,
        $type 
    );
    $self->add_weightset($new_weightset);
    return ( $name, \@weights, $is_weightset, $tokens, $type );
}

=begin comment

 Title   : _parse_options
 Usage   : ...
 Function: parses the $buffer and populates the 'options' data structure; see options command in the assumptions block (Maddison p 611)
 Returns : n/a
 Args    : $buffer (string) - the option command and its subcommands
 Method  : extracts the options and their values from the buffer.
    Creates a hash from those data, and adds it to the Bio::NEXUS::AssumptionsBlock object.

=end comment 

=cut

sub _parse_options {
    my ( $self, $buffer ) = @_;
    my @mix = split( /\s+/, $buffer );
    for my $word ( @mix ) {
        my ( $command, $value ) = $word =~ m/^(.+?)=(.+)$/;
        next if !defined $command;

        # check if the value should be converted to a 'preferred synonym'
        $command = lc $command;
        $value   = lc $value;
        if ( $value eq 'irrev.up' || $value eq 'irrev.dn' ) { $value = 'irrev' }
        if ( $value eq 'dollo.up' || $value eq 'dollo.dn' ) { $value = 'dollo' }
        $self->{'options'}->{$command} = $value;
    }
    $self->_validate_options($self->{'options'});
}


=begin comment

 Title   : _validate_options
 Usage   : _validate_options($options);
 Function: checks if the options passed conform to the Nexus file standard
 Returns : n/a
 Args    : $options (hashref) - hash containing option-value pairs

=end comment 

=cut

sub _validate_options {
    my ( $self, $opts ) = @_;
    my $is_valid = 1;
    if ( defined $opts ) {
		for my $option ( keys %{ $opts } ) {
		    my $is_ok = 1;
	    	my $value = $$opts{$option};
		    if ($option eq 'deftype') {
				if ($value !~ m/^(unord|ord|irrev|irrev\.up|irrev\.dn|dollo|dollo\.up|dollo\.dn)$/i) {
				    $is_valid = 0;
				    $is_ok = 0;
				}
		    }
	    	elsif ($option eq 'polytcount') {
				if ($value !~ m/^(maxsteps|minsteps)$/i) {
				    $is_valid = 0;
				    $is_ok = 0;
				}
		    }
		    elsif ($option eq 'gapmode') {
				if ($value !~ m/^(missing|newstate)$/i) {
				    $is_valid = 0;
			    	$is_ok = 0;
				}
		    }
	    	# the option is not in the Nexus file standard
		    else {
				$is_valid = 0;
				$logger->info("Unknown option $option");
		    }
		    if ( $is_ok == 0 ) {  
	    		$logger->info("Unknown value ($value) for $option");
		    }
		}
    }
    else {
		$logger->warn("Missing argument 'options'");
		return 0;
    }
    return $is_valid;
}


=head2 get_option

 Title   : get_option
 Usage   : $val = $assump_block->get_option($option_type);
 Function: Returns the value of the specified option
 Returns : $value (string)
 Args    : $option_type (string); nexus standard permits: deftype, polytcount, gapmode

=cut

sub get_option {
    my ( $self, $option ) = @_;

    return undef if not defined $option;
    $option = lc $option;
    if ( $option =~ qr/^(?:deftype|polytcount|gapmode)$/ ) {
        if ( defined $self->{'options'}->{$option} ) {
            return $self->{'options'}->{$option};
        }
        else {
            return undef;
        }
    }
    else {
        if ( defined $self->{'options'}->{$option} ) {
            return $self->{'options'}->{$option};
        }
        else { 
        	return undef; 
        }
    }
}

=head2 set_option

 Title   : set_option
 Usage   : $assumption_block->set_option($option, $value)
 Function: Updates/sets a particular option (DefType, PolyTCount, GapMode, etc.)
 Returns : n/a
 Args    : $option (string) , $value (string)

=cut

sub set_option {
    my ( $self, $option, $value ) = @_;
    if ( defined $option && defined $value ) {
        $option                       = lc $option;
        $value                        = lc $value;
        $self->{'options'}->{$option} = $value;
		# validate the input
		my $data = {$option => $value};
		$self->_validate_options($data);
    }
    else {
        $logger->warn("Missing argument(s)");
    }
}

=head2 get_all_options

 Title   : get_all_options
 Usage   : $hash_ref = $assumption_block->get_all_options();
 Function: Retrieve all the options stored in the block
 Returns : a hash reference (key-value pair), where each 'key' is an option (subcommand) and the 'value' is the corresponding value
 Args    : none

=cut

sub get_all_options {
    # note: this method returns a copy of
    # the 'options' hash, rather thatn a 
    # reference to the original. Why?
    # By passing a reference to the actual
    # data structure you give the user
    # direct access to it. And ...
    # direct access to the objects 
    # bypasses the validation and correction
    # which are a major part of the various
    # 'set_' methods - not a good thing.
    my ($self) = @_;

    if ( defined $self->{'options'} ) {
        my %options;
        for my $key ( keys %{ $self->{'options'} } ) {
            my $value = $self->{'options'}->{$key};
            if ( defined $value ) {
                $options{$key} = $value;
            }
        }
		$self->_validate_options(\%options);
        return \%options;
    }
    else {
        return undef;
    }
}

=head2 set_all_options

 Title   : set_all_options
 Usage   : $assumption_block->set_all_options($options);
 Function: Updates/sets options (of this assumptions block) and their values
 Returns : n/a
 Args    : $options (hashref) {'option' => 'value', ... }

=cut

sub set_all_options {
    my ( $self, $options ) = @_;
    if ( defined $options ) {
        for my $key ( keys %{$options} ) {
            my $value = $$options{$key};
            $self->{'options'}->{ lc $key } = lc $value;
        }
    }
    else {
        $logger->warn("Missing argument(s)");
    }
}

=head2 add_weightset

 Title   : add_weightset
 Usage   : $block->add_weightset(weightset);
 Function: add a weightset to this assumption block
 Returns : none
 Args    : WeightSet object

=cut

sub add_weightset {
    my ( $self, $weight ) = @_;
    push @{ $self->{'assumptions'} }, $weight;
}

=head2 get_assumptions

 Title   : get_assumptions
 Usage   : $block->get_assumptions();
 Function: Gets the list of assumptions (Bio::NEXUS::WeightSet objects) and returns it
 Returns : ref to array of Bio::NEXUS::WeightSet objects
 Args    : none

=cut

sub get_assumptions { shift->{'assumptions'} || [] }

=head2 select_assumptions

 Title   : select_assumptions
 Usage   : $block->select_assumptions($columns);
 Function: select assumptions (Bio::NEXUS::WeightSet objects) for a set of characters (columns)
 Returns : none
 Args    : column numbers for the set of characters to be selected

=cut

sub select_assumptions {
    my ( $self, $columns ) = @_;
    if ( !$self->get_assumptions() ) { return; }
    my @assump = @{ $self->get_assumptions() };
    for my $assump (@assump) {
        $assump->select_weights($columns);
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
	$logger->warn("Bio::NEXUS::AssumptionsBlock::add_otu_clone() method not fully implemented");

}

=head2 equals

 Name    : equals
 Usage   : $assump->equals($another);
 Function: compare if two Bio::NEXUS::AssumptionsBlock objects are equal
 Returns : boolean 
 Args    : a Bio::NEXUS::AssumptionsBlock object

=cut

sub equals {
    my ( $self, $block ) = @_;
    if ( ! $self->SUPER::equals($block) ) { 
    	return 0; 
    }
    my @weightset1 = @{ $self->get_assumptions() };
    my @weightset2 = @{ $block->get_assumptions() };
    if ( @weightset1 != @weightset2 ) { 
    	return 0; 
    }
    # XXX Schwartzian transforms
    @weightset1 = 
    	map  { $_->[0] }
    	sort { $a->[1] cmp $b->[1] } 
    	map  { [ $_, $_->get_name() ] } @weightset1;
    @weightset2 =
    	map  { $_->[0] } 
    	sort { $a->[1] cmp $b->[1] }
    	map  { [ $_, $_->get_name() ] } @weightset2;
    for my $i ( 0 .. $#weightset1 ) {
        if ( !$weightset1[$i]->equals( $weightset2[$i] ) ) { 
        	return 0; 
        }
    }
    return 1;
}

=begin comment

 Name    : _write_options
 Usage   : $assump->_write_options($filehandle, $verbose);
 Function: Writes 'options' command 
 Returns : none
 Args    : $fh - (filehandle) output target; if undefined, STDOUT will be used

=end comment

=cut

sub _write_options {
    my ( $self, $fh, $verbose ) = @_;
    $fh ||= \*STDOUT;
    my $return_val = "";
    for my $option ( keys %{ $self->{'options'} } ) {
        my $value = $self->{'options'}->{$option};
        if ( defined $value && ( $value ne "" ) ) {
            $return_val .= " " . $option . "=" . $value;
        }
    }
    if ( $return_val ne "" ) {
        $return_val = "Options" . $return_val . ";";
        print $fh $return_val, "\n";
    }
}

=begin comment

 Name    : _write
 Usage   : $assump->_write($filehandle, $verbose);
 Function: Writes NEXUS block from stored data
 Returns : none
 Args    : none

=end comment 

=cut

sub _write {
    my ( $self, $fh, $verbose ) = @_;
    $fh ||= \*STDOUT;

    $self->SUPER::_write($fh);
    $self->_write_options($fh);
    for my $assumption ( @{ $self->get_assumptions() } ) {
        if ( $assumption->is_wt() ) {
            my @wt        = @{ $assumption->get_weights() };
            my $delimiter = ' ';
            my $format = '(STANDARD TOKENS)';    ## This is the NEXUS default
            if ( !$assumption->_is_tokens() ) {
                $delimiter = '';
                $format =~ s/TOKENS/NOTOKENS/;
            }
            if ( $assumption->_is_vector() ) {
                $format =~ s/STANDARD/VECTOR/;
            }
            my @wtstring = join $delimiter, @wt;
            print $fh "\tWTSET ", $assumption->get_name(), " $format = \n\t";
            print $fh @wtstring, ";\n";
        }
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
    my %synonym_for =
      ( "${package_name}parse_weightset" => "${package_name}_parse_wtset", );

    if ( defined $synonym_for{$AUTOLOAD} ) {
        $logger->warn("$AUTOLOAD() is deprecated; use $synonym_for{$AUTOLOAD}() instead");
        goto &{ $synonym_for{$AUTOLOAD} };
    }
    else {
    	throw 'UnknownMethod' => "ERROR: Unknown method $AUTOLOAD called";
    }
    return;
}

1;
