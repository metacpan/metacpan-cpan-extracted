=head1 NAME

Bio::Polloc::GroupCriteria::operator - An acillary object for Bio::Polloc::GroupCriteria

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=head1 SYNOPSIS

    # ...
    $Bio::Polloc::GroupCriteria::operator::cons::OP_CONS->{'KEY1'} = $some_value_1;
    my $op = Bio::Polloc::GroupCriteria::operator->new(@args);
    my $res = $op->operate;
    # ...

=cut

package Bio::Polloc::GroupCriteria::operator;
use base qw(Bio::Polloc::Polloc::Root);
use strict;
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 APPENDIX

Methods provided by the package

=head2 new

Attempts to initialize a Bio::Polloc::GroupCriteria::operator::* object

=head3 Arguments

=over

=item -type I<str>

Type of operator

=item -val I<mix>

The value of the operator

=item -name I<str>

A name for the operator

=item -operation I<str>

The operation itself

=item -operators I<refarr>

A refarray containing the operators (I<mix>).

=back

=head3 Returns

A L<Bio::Polloc::Locus::repeat> object.

=cut

sub new {
   my($caller,@args) = @_;
   my $class = ref($caller) || $caller;
   
   if($class !~ m/Bio::Polloc::GroupCriteria::operator::(\S+)/){
      my $bme = Bio::Polloc::Polloc::Root->new(@args);
      my($type) = $bme->_rearrange([qw(TYPE)], @args);
      
      if($type){
         $type = Bio::Polloc::GroupCriteria::operator->_qualify_type($type);
         $class = "Bio::Polloc::GroupCriteria::operator::" . $type if $type;
      }
   }

   if($class =~ m/Bio::Polloc::GroupCriteria::operator::(\S+)/){
      my $load = 0;
      my $loadtype = $1;
      if(Bio::Polloc::GroupCriteria::operator->_load_module($class)){
         $load = $class;
      }
      
      if($load){
         my $self = $load->SUPER::new(@args);
	 $self->debug("Got the GroupCriteria operator class $load");
	 my($val, $name, $operation, $operators) = $self->_rearrange([qw(VAL NAME OPERATION OPERATORS)], @args);
	 $self->type($loadtype);
         $self->val($val);
	 $self->name($name);
	 $self->operation($operation);
	 $self->operators($operators);
	 $self->_initialize(@args);
	 return $self;
      }
      
      my $bme = Bio::Polloc::Polloc::Root->new(@args);
      $bme->throw("Impossible to load the module", $class);
   }
   my $bme = Bio::Polloc::Polloc::Root->new(@args);
   $bme->throw("Impossible to load the proper Bio::Polloc::GroupCriteria::operator class with ".
   		"[".join("; ",@args)."]", $class);
}

=head2 val

Sets/gets the value

=cut

sub val {
   my($self, $value) = @_;
   my $k = '_val';
   $self->{$k} = $value if defined $value;
   return $self->{$k};
}

=head2 name

Sets/gets the name

=cut

sub name {
   my($self, $value) = @_;
   my $k = '_name';
   $self->{$k} = $value if defined $value;
   return $self->{$k};
}

=head2 operation

Sets/gets the operation

=cut

sub operation {
   my($self, $value) = @_;
   my $k = '_operation';
   $self->{$k} = $value if defined $value;
   return $self->{$k};
}

=head2 operators

Sets/gets the operators

=cut

sub operators {
   my($self, $value) = @_;
   my $k = '_operators';
   $self->{$k} = $value if defined $value;
   return $self->{$k};
}

=head2 type

Sets/gets the type of operator

=cut

sub type {
   my($self, $value) = @_;
   my $k = '_type';
   $self->{$k} = $value if defined $value;
   return $self->{$k};
}

=head2 operate

=cut

sub operate { $_[0]->throw('operate', $_[0], 'Bio::Polloc::Polloc::NotImplementedException') }

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _qualify_type

=cut

sub _qualify_type {
   my($self, $value) = @_;
   return lc $value if defined $value;
}

=head2 _initialize

=cut

sub _initialize { $_[0]->throw('_initialize', $_[0], 'Bio::Polloc::Polloc::NotImplementedException') }

1;
