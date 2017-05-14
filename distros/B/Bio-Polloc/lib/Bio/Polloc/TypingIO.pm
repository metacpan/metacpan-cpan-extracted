=head1 NAME

Bio::Polloc::TypingIO - I/O interface for genotyping methods (L<Bio::Polloc::TypingI>)

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

package Bio::Polloc::TypingIO;
use base qw(Bio::Polloc::Polloc::Root Bio::Polloc::Polloc::IO);
use strict;
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

=back

=cut

sub new {
   my($caller,@args) = @_;
   my $class = ref($caller) || $caller;
   
   if($class !~ m/Bio::Polloc::TypingIO::(\S+)/){
      my $bme = Bio::Polloc::Polloc::Root->new(@args);
      my($format,$file) = $bme->_rearrange([qw(FORMAT FILE)], @args);
      
      if(!$format && $file){
         $format = $file;
         $format =~ s/.*\.//;
      }
      if($format){
         $format = Bio::Polloc::TypingIO->_qualify_format($format);
         $class = "Bio::Polloc::TypingIO::" . $format if $format;
      }
   }

   if($class =~ m/Bio::Polloc::TypingIO::(\S+)/){
      if(Bio::Polloc::TypingIO->_load_module($class)){;
         my $self = $class->SUPER::new(@args);
	 $self->debug("Got the TypingIO class $class ($1)");
	 $self->format($1);
         $self->_initialize(@args);
         return $self;
      }
      my $bme = Bio::Polloc::Polloc::Root->new(@args);
      $bme->throw("Impossible to load the module", $class);
   } else {
      my $bme = Bio::Polloc::Polloc::Root->new(@args);
      $bme->throw("Impossible to load the proper Bio::Polloc::TypingIO class with [".
      		join("; ",@args)."]", $class);
   }
}

=head2 format

Sets/gets the format.

=cut

sub format {
   my($self,$value) = @_;
   $value = $self->_qualify_format($value);
   $self->{'_format'} = $value if $value;
   return $self->{'_format'};
}

=head2 read

=cut

sub read {
   my $self = shift;
   $self->throw("read",$self,"Bio::Polloc::Polloc::NotImplementedException");
}


=head2 typing

Sets/gets the L<Bio::Polloc::TypingI> object

B<Arguments>

A L<Bio::Polloc::TypingI> object (optional).

B<Returns>

A L<Bio::Polloc::TypingI> object or C<undef>.

B<Throws>

L<Bio::Polloc::Polloc::Error> if trying to set some value
other than a L<Bio::Polloc::TypingI> object.

=cut

sub typing {
   my($self, $value) = @_;
   if(defined $value){
      $self->throw('Unexpected object type', $value)
      		unless UNIVERSAL::can($value, 'isa')
		and $value->isa('Bio::Polloc::TypingI');
      $self->{'_typing'} = $value;
   }
   return $self->{'_typing'};
}

=head2 safe_value

Sets/gets a parameter of arbitrary name and value.  Serves to provide a
safe interface for setting values from the parsed file.

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

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

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
   $format =~ s/[^a-z]//g;
   $format = "cfg" if $format =~ /^(conf|config|bme)$/;
   return $format;
   return;
}

1;
