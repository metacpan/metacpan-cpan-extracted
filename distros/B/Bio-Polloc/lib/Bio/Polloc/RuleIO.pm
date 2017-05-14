=head1 NAME

Bio::Polloc::RuleIO - I/O interface for the sets of rules (L<Bio::Polloc::RuleI>)

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=head1 IMPLEMENTS OR EXTENDS

=over

=item *

L<Bio::Polloc::Polloc::Root>

=item *

L<Bio::Polloc::Polloc::IO>

=back

=cut

package Bio::Polloc::RuleIO;
use strict;
use base qw(Bio::Polloc::Polloc::Root Bio::Polloc::Polloc::IO);
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 PUBLIC METHODS

Methods provided by the package

=cut

=head2 new

The basic initialization method

B<Arguments>

The same arguments of L<Bio::Polloc::Polloc::IO>, plus:

=over

=item -format

The format of the file

=item -genomes

The genomes to be scaned

=back

=cut

sub new {
   my($caller,@args) = @_;
   my $class = ref($caller) || $caller;
   
   if($class !~ m/Bio::Polloc::RuleSet::(\S+)/){
      my $bme = Bio::Polloc::Polloc::Root->new(@args);
      my($format,$file) = $bme->_rearrange([qw(FORMAT FILE)], @args);
      
      ($format = $file) =~ s/.*\.// if $file and not $format;
      if($format){
         $format = Bio::Polloc::RuleIO->_qualify_format($format);
         $class = "Bio::Polloc::RuleSet::" . $format if $format;
      }
   }

   if($class =~ m/Bio::Polloc::RuleSet::(\S+)/){
      if(Bio::Polloc::RuleIO->_load_module($class)){;
         my $self = $class->SUPER::new(@args);
	 $self->debug("Got the RuleIO class $class ($1)");
	 $self->format($1);
	 my ($genomes) = $self->_rearrange([qw(GENOMES)], @args);
	 $self->genomes($genomes);
         $self->_initialize(@args);
         return $self;
      }
      my $bme = Bio::Polloc::Polloc::Root->new(@args);
      $bme->throw("Impossible to load the module", $class);
   } else {
      my $bme = Bio::Polloc::Polloc::Root->new(@args);
      $bme->throw("Impossible to load the proper Bio::Polloc::RuleIO class with [".
      		join("; ",@args)."]", $class);
   }
}

=head2 prefix_id

Sets/gets the prefix ID, unique for the RuleSet

B<Purpose>

To allow the identification of children in a unique namespace

B<Arguments>

A string, supposedly unique.  Any colon (:) will be changed to '_'

B<Returns>

The prefix ID.

=cut

sub prefix_id {
  my($self,$value) = @_;
  if(defined $value && "$value"){ #<- to avoid empty string ('') but allow zero (0)
     $value =~ s/:/_/g;
     $self->{'_prefix_id'} = "$value";
  }
  # Attempt to set from the parsed values if not explicitly setted
  $self->{'_prefix_id'} = $self->safe_value('prefix_id') unless defined $self->{'_prefix_id'};
  return $self->{'_prefix_id'};
}

=head2 init_id

=cut

sub init_id {
   my($self,$value) = @_;
   $self->{'_init_id'} = $value if defined $value;
   $self->{'_init_id'} ||= 1;
   return $self->{'_init_id'};
}

=head2 format

=cut

sub format {
   my($self,$value) = @_;
   $value = $self->_qualify_format($value);
   $self->{'_format'} = $value if $value;
   return $self->{'_format'};
}



=head2 add_rule

Appends rules to the rules set.

=head2 Arguments

One or more L<Bio::Polloc::RuleI> objects

=head2 Returns

The index of the last rule

=head2 Throws

A L<Bio::Polloc::Polloc::Error> exception if some object is not a L<Bio::Polloc::RuleI>

=cut

sub add_rule {
   my($self, @rules) = @_;
   return unless $#rules >= 0;
   $self->get_rules; #<- to initialize the array if does not exist
   for my $rule (@rules){
      $self->throw("Trying to add an illegal class of Rule", $rule)
      		unless $rule->isa('Bio::Polloc::RuleI');
      $rule->ruleset($self);
      push @{$self->{'_registered_rules'}}, $rule;
   }
   return $#{$self->{'_registered_rules'}};
}


=head2 get_rule

Gets the rule at the given index

B<Arguments>

The index (int)

B<Returns>

A L<Bio::Polloc::RuleI> object or undef

=cut

sub get_rule {
   my($self,$index) = @_;
   return unless defined $index;
   return if $index < 0;
   return if $index > $#{$self->get_rules};
   return $self->get_rules->[$index];
}

=head2 get_rules

=cut

sub get_rules {
   my($self, @args) = @_;
   $self->{'_registered_rules'} ||= [];
   return $self->{'_registered_rules'};
}

=head2 next_rule

B<Returns>

A L<Bio::Polloc::RuleI> object

=cut
sub next_rule {
   my($self, @args) = @_;
   my $rule = $self->get_rule($self->{'_loop_index_rules'} || 0);
   $self->{'_loop_index_rules'}++;
   $self->_end_rules_loop unless $rule;
   return $rule;
}

=head2 groupcriteria

Sets/gets the group criteria objects.

B<Arguments>

A L<Bio::Polloc::GroupCriteria> array ref (optional)

B<Returns>

A L<Bio::Polloc::GroupCriteria> array ref or undef

=cut

sub groupcriteria {
   my($self,$value) = @_;
   $self->{'_grouprules'} = $value if defined $value;
   return $self->{'_grouprules'};
}

=head2 grouprules

Alias of L<groupcriteria> (for backwards-compatibility).

=cut

sub grouprules { return shift->groupcriteria(@_) }

=head2 addgrouprules

Adds a grouprules object

B<Arguments>

A L<Bio::Polloc::GroupCriteria> object

B<Throws>

A L<Bio::Polloc::Polloc::Error> if not a proper object

=cut

sub addgrouprules {
   my($self,$value) = @_;
   $self->throw("Illegal grouprules object",$value) unless $value->isa("Bio::Polloc::GroupCriteria");
   $self->{'_grouprules'} = [] unless defined $self->{'_grouprules'};
   push @{$self->{'_grouprules'}}, $value;
}

=head2 execute

Executes the executable rules only over the whole list of genomes

B<Arguments>

Any argument supported/required by the rules, plus:

=over

=item -advance L<sub ref>

A reference to a method to be called to report the advance
of the execution.  The method must accept four arguments,
namely:

=over

=item 1

The number of loci detected so far

=item 2

The number of genomes scanned so far

=item 3

The total number of genomes to scan

=item 4

The ID of the running rule

=back

=back

B<Returns>

A L<Bio::Polloc::LociGroup> object.

=cut

sub execute {
   my($self, @args) = @_;
   $self->debug("Evaluating executable rules");
   my($advance) = $self->_rearrange([qw(ADVANCE)], @args);
   my $locigroup = Bio::Polloc::LociGroup->new(
   		-name=>'Full collection - '.time().".".rand(1000),
   		-genomes=>$self->genomes);
   $self->throw("Impossible to execute without genomes") unless defined $self->genomes;
   for my $gk (0 .. $#{$self->genomes}){
      my $genome = $self->genomes->[$gk];
      $self->_end_rules_loop;
      my $rulek = 0;
      while ( my $rule = $self->next_rule ){
         $rulek++;
	 $self->debug("On " . $self->{'_loop_index_rules'});
	 if($rule->executable){
	    $self->debug("RUN! on ".($#{$genome->get_sequences}+1)." sequences");
	    for my $seq (@{$genome->get_sequences}){
	       for my $locus (@{ $rule->execute(-seq=>$seq, @args) }){
	          $locus->genome($genome);
	          $locigroup->add_loci($locus);
	       }
	       &$advance($#{$locigroup->loci}+1, $gk+1, $#{$self->genomes}+1, $rulek)
	       		if defined $advance;
	    }
	 }
      }
      $self->_increase_index;
   }
   $self->debug("Got ".($#{$locigroup->loci}+1)." loci");
   return $locigroup;
}

=head2 safe_value

Sets/gets a parameter of arbitrary name and value

B<Purpose>

To provide a safe interface for setting values from the parsed file

B<Arguments>

=over

=item -param

The parameter's name (case insensitive)

=item -value

The value of the parameter (optional)

=back

B<Returns>

The value of the parameter or undef

=cut

sub safe_value {
   my ($self,@args) = @_;
   my($param,$value) = $self->_rearrange([qw(PARAM VALUE)], @args);
   $self->{'_values'} ||= {};
   return unless $param;
   $param = lc $param;
   if(defined $value){
      $self->{'_values'}->{$param} = $value;
   }
   return $self->{'_values'}->{$param};
}


=head2 parameter

B<Purpose>

Gets/sets some generic parameter.  It is intended to provide an
interface between L<Bio::Polloc::RuleIO>'s general configuration and
L<Bio::Polloc::RuleI>, regardless of the format.

B<Arguments>

The key (str) and the value (mix, optional)

B<Returns>

The value (mix or undef)

B<Throws>

A L<Bio::Polloc::Polloc::NotImplementedException> if not implemented

=cut

sub parameter {
   my $self = shift;
   $self->throw("parameter",$self,"Bio::Polloc::Polloc::NotImplementedException");
}

=head2 read

=cut

sub read {
   my $self = shift;
   $self->throw("read",$self,"Bio::Polloc::Polloc::NotImplementedException");
}

=head2 genomes

Gets/sets the genomes to be used as analysis base.

B<Arguments>

A reference to an array of L<Bio::Polloc::Genome> objects.

=cut

sub genomes {
   my($self, $value) = @_;
   $self->{'_genomes'} = $value if defined $value;
   return unless defined $self->{'_genomes'};
   $self->throw("Unexpected type of genomes collection", $self->{'_genomes'})
   	unless ref($self->{'_genomes'}) and ref($self->{'_genomes'})=~m/ARRAY/i;
   return $self->{'_genomes'};
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _register_rule_parse

=cut

sub _register_rule_parse {
   my $self = shift;
   $self->throw("_register_rule_parse",$self,"Bio:Polloc::Polloc::NotImplementedException");
}

=head2 _increase_index

=cut

sub _increase_index {
   my $self = shift;
   while ( my $rule = $self->next_rule ){
      my $nid = $self->_next_child_id;
      $rule->id($nid) if defined $nid;
      $rule->restart_index;
   }
}

=head2 _next_child_id

=cut

sub _next_child_id {
   my $self = shift;
   return unless defined $self->prefix_id;
   $self->{'_next_child_id'} ||= $self->init_id;
   return $self->prefix_id . ":" . ($self->{'_next_child_id'}++);
}

=head2 _initialize

=cut

sub _initialize {
   my($self,@args) = @_;
   $self->throw("_initialize", $self, "Bio::Polloc::Polloc::NotImplementedException");
}

=head2 _qualify_format

=cut

sub _qualify_format {
   my($caller, $format) = @_;
   return unless $format;
   $format = lc $format;
   $format = "cfg" if $format =~ /^(conf|config|bme)$/;
   return $format if $format =~ /^(cfg)$/;
   return;
}

=head2 _end_rules_loop

=cut

sub _end_rules_loop { shift->{'_loop_index_rules'} = 0 }

1;
