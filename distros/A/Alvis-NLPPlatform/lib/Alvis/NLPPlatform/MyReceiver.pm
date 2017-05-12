package Alvis::NLPPlatform::MyReceiver;
#use Data::Dumper;


use strict;
use warnings;

use XML::Parser::PerlSAX;
# use utf8;

use Alvis::NLPPlatform::XMLEntities;

use Data::Dumper;

our $VERSION=$Alvis::NLPPlatform::VERSION;

###
### Package
###


my $data;

sub start_document {
#  print Dumper($tab_object);
}

sub end_document {
#  print Dumper($tab_object);
}

#
# init object
#

sub new {
  my $type = shift;

  my @stack_elements = ();
  my $tab_objet = {};
  my $is_in_ann;
#   my $data;
  return bless {"tab_object" => {} , "stack_elements" => \@stack_elements, "is_in_ann" => $is_in_ann, "counter_id" => 0 } , $type;
}

#
# process <..>
#


sub start_element {
  my ($self,$properties) = @_;

  if ($self->{"is_in_ann"}) {
      if ($self->is_empty()) { # new element
	  my $elem = {};
	  push(@{$self->{"stack_elements"}},$elem);
	  $elem->{'kind'} = 'simple';
      } else {
	  my $father = $self->top_stack();
	  my $elem;
	  if ($properties->{'Name'} =~ /^list/) { # detects that it is a list
	      $elem = {}; # hashtable par défaut
	      $elem->{'kind'} = 'list';
	      $elem->{'values'} = []; # tableau
	  } else {
	      $elem = {}; # hashtable par défaut
	      $elem->{'kind'} = 'simple';	
	  }
	  if ($father->{'kind'} eq 'list') {
	      my $tab = $father->{'values'};
	  } else { # complex or simple
	      $father->{'kind'} = 'complex';
	      $father->{$properties->{'Name'}} = $elem;
	  }
	  $elem->{'datatype'} = $properties->{'Name'};
	  push(@{$self->{"stack_elements"}},$elem);
      }
  } else {
      $self->{"is_in_ann"} = $properties->{'Name'} eq 'linguisticAnalysis';

  }
  $data='';
}

sub end_element {
    my ($self,$properties) = @_;
    my $field;
    my $father;
    if ($self->{"is_in_ann"}) {
	$self->{"is_in_ann"} = $properties->{'Name'} ne 'linguisticAnalysis';
	if ($self->{"is_in_ann"}) {
	    my $size=$#{$self->{"stack_elements"}};
	    my $elem = $self->top_stack();
	    if ($size >= 1) {
		if ($properties->{'Name'} eq "named_entity") {
		    if (!exists($elem->{'id'})) {
			my $ftab = $elem->{'values'};
			push (@$ftab, "named_entity" . $self->{"counter_id"});
			$elem->{'id'} = "named_entity" . $self->{"counter_id"};
			$field = 'id';
			$data = "semantic_unit" . $self->{"counter_id"};
			$self->{"counter_id"}++;
		    }  else {
 			$field = $elem->{'datatype'};
 		    }
		    $father = {'named_entity'=> $elem, 'datatype' => 'semantic_unit'};
		} else {
		    $field = $elem->{'datatype'};
		    $father = $self->snd_stack();
		    if ((exists $father->{'datatype'}) && ($father->{'datatype'} eq "named_entity") && ($field eq "id")) {
			$father->{'id'} = $data;
			$father = {'named_entity'=> $father, 'datatype' => 'semantic_unit'};
			$elem->{'kind'} = 'complex';
 			$data =~ /([0-9]+)$/;
 			$data = "semantic_unit$1";
			
		    }
		}
		
		if ((exists $father->{'kind'}) && ($father->{'kind'} eq 'list')) {
		    my $tab = $father->{'values'};
		    if ((exists $elem->{'kind'}) && ($elem->{'kind'} eq 'simple')) {
			push(@$tab,$data);
		    } else {
			push(@$tab,$elem);
		    }
		} else {
		    if ((exists $elem->{'kind'}) && ($elem->{'kind'} eq 'simple')) {
			$father->{$field} = $data; # replace hashtable that has been created by default
		    }
		}
		if ($field eq 'id') {
		    $self->{"tab_object"}->{$data} = $father;
		    #print Dumper($tab_object);
		}
		if ($elem->{'kind'} eq 'list') {
		    # replace : list-xxx=>{'value'=>[...]}
		    # by      : list-xxx=>[...]
		    $father->{$elem->{'datatype'}} = $elem->{'values'};
		}
	    }
	    delete($elem->{'kind'});	# kind is only used by process
	    #delete($elem->{'datatype'}); # optionnal
	    pop(@{$self->{"stack_elements"}});
	}
    }
}

# Function "characters" corrected by Julien Deriviere
# (September 11th, 2004)

sub characters {
  my ($self,$properties) = @_;
#  $data = $properties->{'Data'};
  $data = $data.$properties->{'Data'}; # CORRECTION - Julien
}

sub comment {

}

sub processing_instruction {
}

# Function "entity_reference" corrected by Julien
# (September 14th, 2004)

sub entity_reference {
    my($self,$event)=@_;
    # Name et Value
    # traduction de l'entité
    my $entity={};
    my $par=$event->{Parameter}?'%':'&';
    $entity->{'Data'}=$par.$event->{Name}.";";

    $self->characters($entity);
}

sub top_stack {
    my ($self) = @_;
  return $self->{"stack_elements"}->[-1];
}

sub snd_stack {
    my ($self) = @_;
  return $self->{"stack_elements"}->[-2];
}

sub is_empty {
    my ($self) = @_;
  return $#{$self->{"stack_elements"}} == -1;
}


1;

__END__

=head1 NAME

Alvis::NLPPlatform::MyReceiver - Internal Perl extension for analysing XML
documents in the Alvis format

=head1 SYNOPSIS

use Alvis::NLPPlatform::MyReceiver;

my $myreceiver = Alvis::NLPPlatform::MyReceiver->new();

my $parser = XML::Parser::PerlSAX->new(Handler => $myreceiver);

=head1 DESCRIPTION

This module is the handler needed to parse a XML document, when using
the parser C<Parser::PerlSAX>. The associated methods are the standard
ones. See C<Parser::PerlSAX> for futher information.

=head1 SEE ALSO

C<Alvis::NLPPlatform>

Alvis web site: http://www.alvis.info

=head1 AUTHORS

Guillaume Vauvert <guillaume.vauvert@lipn.univ-paris13.fr>

Currently maintained by Julien Deriviere <julien.deriviere@lipn.univ-paris13.fr> and Thierry Hamon <thierry.hamon@lipn.univ-paris13.fr>

=head1 LICENSE

Copyright (C) 2004 by Guillaume Vauvert, Thierry Hamon and Julien Deriviere

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
