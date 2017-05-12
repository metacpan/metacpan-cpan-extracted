package Autodia::Handler::umbrello;
require Exporter;
use strict;

=head1 NAME

Autodia::Handler::umbrello - AutoDia handler for umbrello

=head1 DESCRIPTION

This provides Autodia with the ability to read umbrello files, allowing you to convert them via the Diagram Export methods to images (using GraphViz and VCG) or html/xml using custom templates.

The umbrello handler will parse umbrello xml/xmi files using XML::Simple and populating the diagram object with class, superclass and package objects.

the umbrello handler is registered in the Autodia.pm module, which contains a hash of language names and the name of their respective language - in this case:

=head1 SYNOPSIS

use Autodia::Handler::umbrello;

my $handler = Autodia::Handler::umbrello->New(\%Config);

$handler->Parse(filename); # where filename includes full or relative path.

=cut

use vars qw($VERSION @ISA @EXPORT);
use Autodia::Handler;

@ISA = ('Autodia::Handler' ,'Exporter');

use Autodia::Diagram;
use Data::Dumper;

use XML::Simple;

=head1 METHODS

=head2 CONSTRUCTION METHOD

use Autodia::Handler::umbrello;

my $handler = Autodia::Handler::umbrello->New(\%Config);
This creates a new handler using the Configuration hash to provide rules selected at the command line.

=head2 ACCESS METHODS

$handler->Parse(filename); # where filename includes full or relative path.

This parses the named file and returns 1 if successful or 0 if the file could not be opened.

=cut


#####################
# Constructor Methods

# new inherited from Autodia::Handler

#------------------------------------------------------------------------
# Access Methods

# parse_file inherited from Autodia::Handler

#-----------------------------------------------------------------------------
# Internal Methods

# _initialise inherited from Autodia::Handler

sub _parse {
  my $self     = shift;
  my $fh       = shift;
  my $filename = shift;

  my $Diagram  = $self->{Diagram};
  my $xmldoc = XMLin($filename, ForceArray => 1, ForceContent => 1);

  # get version
  my $version = $xmldoc->{'XMI.header'}[0]{'XMI.documentation'}[0]{'XMI.exporterVersion'}[0]{content};
  my $is_newstyle = 0;
  if ($version =~ /(\d\.\d).\d/) {
      $is_newstyle = 1 if ($1 > 1.1);
  }
  my $umlclasses_are_here = ( $is_newstyle ) ? 'UML:Model' : 'umlobjects' ;
  my @relationships;

  foreach my $classname (keys %{$xmldoc->{'XMI.content'}[0]{$umlclasses_are_here}[0]{'UML:Class'}}) {
      print "handling Class $classname : \n";
      my $class = $xmldoc->{'XMI.content'}[0]{$umlclasses_are_here}[0]{'UML:Class'}{$classname};
      my $Class = Autodia::Diagram::Class->new($classname);
      $Diagram->add_class($Class);

      foreach my $method ( @{get_methods($class)} ) {
	  $Class->add_operation($method);
      }
      foreach my $attribute (@{get_attributes($class)}) {
	  $Class->add_attribute( $attribute );
      }

      # get superclass / stereotype
      if ($class->{stereotype}) {
	  my $Superclass = Autodia::Diagram::Superclass->new($class->{stereotype});
	  # add superclass to diagram
	  my $exists_already = $Diagram->add_superclass($Superclass);
	  if (ref $exists_already) {
	      $Superclass = $exists_already;
	  }
	  # create new inheritance
	  my $Inheritance = Autodia::Diagram::Inheritance->new($Class, $Superclass);
	  # add inheritance to superclass
	  $Superclass->add_inheritance($Inheritance);
	  # add inheritance to class
	  $Class->add_inheritance($Inheritance);
	  # add inheritance to diagram
	  $Diagram->add_inheritance($Inheritance);
      }
  }
  return;
}


############################

sub get_methods {
  my $class = shift;
  my $return = [];

  foreach my $methodname (keys %{$class->{'UML:Operation'}}) {
      my $type = $class->{'UML:Operation'}{$methodname}{type};
      my $arguments = get_parameters($class->{'UML:Operation'}{$methodname}{'UML:Parameter'});
      push(@$return,{name=>$methodname,type=>$type,Params=>$arguments, visibility=>0});
  }
  return $return;
}

sub get_attributes {
  my $class = shift;
  my $return = [];
  foreach my $attrname (keys %{$class->{'UML:Attribute'}}) {
      my $type = $class->{'UML:Attribute'}{$attrname}{type};
      push(@$return,{name=>$attrname,type=>$type, visibility=>0});
  }
  return $return;
}


sub get_parameters {
  my $arguments = shift;
  my $return = [];
  if (ref $arguments) {
      @$return = map ( {Type=>$arguments->{$_}{type},Name=>$_}, keys %$arguments);
  }
  return $return;
}

###############################################################################

=head1 SEE ALSO

Autodia::Handler

Autodia::Diagram

=head1 AUTHOR

Aaron Trevena, E<lt>aaron.trevena@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2001-2007 by Aaron Trevena

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut


1;
