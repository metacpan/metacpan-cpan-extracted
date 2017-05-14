=head1 NAME

Bio::Polloc::Polloc::Error - Errors handler for the Bio::Polloc::* packages

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Bio::Polloc::Polloc::Error;
use strict;
use Error qw(:try);
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


@Bio::Polloc::Polloc::Error::ISA = qw( Error );

=head1 PUBLIC METHODS

Methods provided by the package

=cut

=head2 new

The basic initialization method

=over

=item -text

Text of the message

=item -value

Value or objected refered by the message

=back

=cut

sub new {
   my($class, @args) = @_;
   my($text, $value);
   if(@args % 2 == 0 && $args[0] =~ m/^-/){
      my %params = @args;
      $text = $params{'-text'};
      $value = $params{'-value'};
   }else{
      $text = $args[0];
      $value = $args[1];
   }

   if(defined $value && !$value){
      $value = length($value)==0 ? "\"\"" : "zero (0)";
   }

   my $self = $class->SUPER::new( -text=>$text, -value=>$value );
   return $self;
}

=head2 stringify

=cut

sub stringify {
   my($self, @args) = @_;
   return $self->error_msg(@args);
}

=head2 error_msg

=cut

sub error_msg {
   my($self,@args) = @_;
   my $msg = $self->text;

   my $value = $self->value; 
   my $bme = Bio::Polloc::Polloc::Root->new();
   my $out = " ".("-"x10)." ERROR ".("-"x10)." \n";
   if($msg=~/[\n]/){
      $msg=~s/([\n])/$1\t/g;
      $msg = "\n\t".$msg;
   }
   $out.= ref($self) . "\n";
   $out.= "MSG: $msg.\n";
   if(defined $value){
      if(ref($value)=~/hash/i){
         $out.= "VALUE: HASH: ".$_."=>".
	 	(defined $value->{$_} ? $value->{$_} : "undef" ).
		"\n" for keys %{$value};
      }elsif(ref($value)=~/array/i){
         $out.= "VALUE: ARRAY: ".join(", ",@{$value}) . "\n";
      }elsif($value=~/[\n]/){
         $value =~ s/([\n])/$1\t/g;
	 $out.= "VALUE:\n\t" . $value . "\n";
      }else{
         $out.= "VALUE: ".$value." - ".ref(\$value)."\n";
      }
   }
   $out.= " ".("."x27)." \n";
   $out.= $bme->stack_trace_dump();
   $out.= " ".("-"x27)." \n";
   return $out;
}

=head1 CHILDREN

Children objects included

=head2 Bio::Polloc::Polloc::IOException

I/O related error

=cut

@Bio::Polloc::Polloc::IOException::ISA = qw( Bio::Polloc::Polloc::Error );

=head2 Bio::Polloc::Polloc::ParsingException

Parsing error of some external file

=cut

@Bio::Polloc::Polloc::ParsingException::ISA = qw( Bio::Polloc::Polloc::Error );

=head2 Bio::Polloc::Polloc::LoudWarningException

Warning transformed into C<throw> due to a high verbosity

=cut

@Bio::Polloc::Polloc::LoudWarningException::ISA = qw( Bio::Polloc::Polloc::Error );

=head2 Bio::Polloc::Polloc::NotLogicException

=cut

@Bio::Polloc::Polloc::NotLogicException::ISA = qw( Bio::Polloc::Polloc::Error );

=head2 Bio::Polloc::Polloc::UnexpectedException

An error probably due to an internal bug

=cut

@Bio::Polloc::Polloc::UnexpectedException::ISA = qw( Bio::Polloc::Polloc::Error );

=head2 Bio::Polloc::Polloc::NotImplementedException

Error launched when a method is called from an object
not implementing it, despite it is defined by at least
one parent interface

=cut

@Bio::Polloc::Polloc::NotImplementedException::ISA = qw( Bio::Polloc::Polloc::Error );

1;
