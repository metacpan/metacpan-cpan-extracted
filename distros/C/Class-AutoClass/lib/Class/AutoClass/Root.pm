package Class::AutoClass::Root;
use strict;

# NG 09-11-02: This class is deprecated and will go away in a future release

use vars qw(@ISA $DEBUG $ID $Revision $VERSION $VERBOSITY $ERRORLOADED @EXPORT);
use strict;

BEGIN { 

    $ID        = 'Class::AutoClass::Root';
    $VERSION   = 1.0;
    $Revision  = '';
    $DEBUG     = 0;
    $VERBOSITY = 0;
    $ERRORLOADED = 0;
}



sub new {
    my $class = shift;
    my $self = {};
    bless $self, ref($class) || $class;

    if(@_ > 1) {
	# if the number of arguments is odd but at least 3, we'll give
	# it a try to find -verbose
	shift if @_ % 2;
	my %param = @_;
	$self->verbose($param{'-VERBOSE'} || $param{'-verbose'});
    }
    return $self;
}
		     
sub verbose {
   my ($self,$value) = @_;
   # allow one to set global verbosity flag
   return $DEBUG  if $DEBUG;
   return $VERBOSITY unless ref $self;
   
    if (defined $value || ! defined $self->{'_root_verbose'}) {
       $self->{'_root_verbose'} = $value || 0;
    }
    return $self->{'_root_verbose'};
}

sub _register_for_cleanup {
  my ($self,$method) = @_;
  if($method) {
    if(! exists($self->{'_root_cleanup_methods'})) {
      $self->{'_root_cleanup_methods'} = [];
    }
    push(@{$self->{'_root_cleanup_methods'}},$method);
  }
}

sub _unregister_for_cleanup {
  my ($self,$method) = @_;
  my @methods = grep {$_ ne $method} $self->_cleanup_methods;
  $self->{'_root_cleanup_methods'} = \@methods;
}


sub _cleanup_methods {
  my $self = shift;
  return unless ref $self && $self->isa('HASH');
  my $methods = $self->{'_root_cleanup_methods'} or return;
  @$methods;

}

sub throw{
   my ($self,$string) = @_;

   my $std = $self->_stack_trace_dump();

   my $out = "\n-------------------- EXCEPTION --------------------\n".
       "MSG: ".$string."\n".$std."-------------------------------------------\n";
   die $out;

}

sub stack_trace{
   my ($self) = @_;

   my $i = 0;
   my @out;
   my $prev;
   while( my @call = caller($i++)) {
       # major annoyance that caller puts caller context as
       # function name. Hence some monkeying around...
       $prev->[3] = $call[3];
       push(@out,$prev);
       $prev = \@call;
   }
   $prev->[3] = 'toplevel';
   push(@out,$prev);
   return @out;
}

sub _stack_trace_dump{
   my ($self) = @_;

   my @stack = $self->stack_trace();

   shift @stack;
   shift @stack;
   shift @stack;

   my $out;
   my ($module,$function,$file,$position);
   

   foreach my $stack ( @stack) {
       ($module,$file,$position,$function) = @{$stack};
       $out .= "STACK $function $file:$position\n";
   }

   return $out;
}

sub deprecated{
   my ($self,$msg) = @_;
   if( $self->verbose >= 0 ) { 
       print STDERR $msg, "\n", $self->_stack_trace_dump;
   }
}

sub warn{
    my ($self,$string) = @_;
    
    my $verbose;
    if( $self->can('verbose') ) {
	$verbose = $self->verbose;
    } else {
	$verbose = 0;
    }

    if( $verbose == 2 ) {
	$self->throw($string);
    } elsif( $verbose == -1 ) {
	return;
    } elsif( $verbose == 1 ) {
	my $out = "\n-------------------- WARNING ---------------------\n".
		"MSG: ".$string."\n";
	$out .= $self->_stack_trace_dump;
	
	print STDERR $out;
	return;
    }    

    my $out = "\n-------------------- WARNING ---------------------\n".
       "MSG: ".$string."\n".
	   "---------------------------------------------------\n";
    print STDERR $out;
}

sub debug{
   my ($self,@msgs) = @_;
   
   if( $self->verbose > 0 ) { 
       print STDERR join("", @msgs);
   }   
}

sub DESTROY {
    my $self = shift;
    my @cleanup_methods = $self->_cleanup_methods or return;
    for my $method (@cleanup_methods) {
      $method->($self);
    }
}



1;

