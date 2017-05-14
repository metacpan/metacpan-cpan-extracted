use strict;
use warnings;
package Conclave::OTK;
# ABSTRACT: Conclave Ontology Toolkit

use Conclave::OTK::Queries;
use File::HomeDir;
use File::Spec;

sub new {
  my ($class, $base_uri, %opts) = @_;
  my $self = bless({}, $class);

  # set defaults
  my $backend = 'File';

  # attempt to read conf file
  unless ($opts{ignoreconfigfile}) {
    my $conf = File::Spec->catfile(File::HomeDir->my_home, '.conc-otk.conf');
    if (-e $conf) {
      open my $fh, '<', $conf;
      while (my $line = <$fh>) {
        chomp $line;
        my ($k, $v) = split /\s*=\s*/, $line;
        next unless ($k and $v);
        $opts{$k} = $v unless exists $opts{$k};
      }
      close $fh;
    }
  }

  $backend = $opts{backend} if $opts{backend};
  my $module = "Conclave::OTK::Backend::$backend";
  if ($module =~ m/^([\w:]+)$/) {
    eval "use $1";
  }

  my $format = 'OWL';  # default queries underlying format

  $self->{base_uri} = $base_uri;
  $self->{graph} = $base_uri;

  $self->{backend} = $module->new($base_uri, %opts);
  $self->{prefixes} = {
      'rdf'  => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
      'owl'  => 'http://www.w3.org/2002/07/owl#',
      'xsd'  => 'http://www.w3.org/2001/XMLSchema#',
      'rdfs' => 'http://www.w3.org/2000/01/rdf-schema#',
    };

  $self->{queries} = Conclave::OTK::Queries->new($format);

  return $self;
}

sub init {
  my ($self, $rdfxml) = @_;

  $self->{backend}->init($rdfxml);
}

sub delete {
  my ($self) = @_;

  $self->{backend}->delete;
}

sub add_class {
  my ($self, $name, @parents) = @_;

  my $vars = {
      'name'     => $self->full_uri($name),
      'graph'    => $self->{graph},
      'prefixes' => $self->{prefixes},
      'parents'  => [map {$self->full_uri($_)} @parents],
    };
  my $sparql = $self->{queries}->process('add_class', $vars);

  my $result = $self->{backend}->update($sparql);
  return $result;
}

sub get_classes {
  my ($self) = @_;

  my $vars = {
      'prefixes' => $self->{prefixes},
      'graph'    => $self->{graph},
    };
  my $sparql = $self->{queries}->process('get_classes', $vars);

  my @classes = $self->{backend}->query($sparql);
  return @classes;
}

sub get_subclasses {
  my ($self, $class) = @_;

  my $vars = {
      'prefixes' => $self->{prefixes},
      'graph'    => $self->{graph},
      'class'    => $self->full_uri($class),
    };
  my $sparql = $self->{queries}->process('get_subclasses', $vars);

  my @classes = $self->{backend}->query($sparql);
  return @classes;
}

sub get_all_subclasses {
  my ($self, $class) = @_;

  my %result;
  my @classes = $self->get_subclasses($class);
  foreach (@classes) { $result{$_}++ }

  foreach (keys %result) {
    my @classes = $self->get_subclasses($_);
    foreach (@classes) { $result{$_}++ }
  }

  my @result = keys %result;
  return @result;
}

sub get_instance_classes {
  my ($self, $i) = @_;

  my $vars = {
      'prefixes' => $self->{prefixes},
      'graph'    => $self->{graph},
      'i'        => $self->full_uri($i),
    };
  my $sparql = $self->{queries}->process('get_instance_classes', $vars);

  my @classes = $self->{backend}->query($sparql);
  return @classes;
}

sub add_instance {
  my ($self, $name, $class) = @_;

  my $vars = {
      'name'     => $self->full_uri($name),
      'class'    => $self->full_uri($class),
      'graph'    => $self->{graph},
      'prefixes' => $self->{prefixes},
    };
  my $sparql = $self->{queries}->process('add_instance', $vars);


  my $result = $self->{backend}->update($sparql);
  return $result;
}

sub get_instances {
  my ($self, $class) = @_;

  my $vars = {
      'prefixes' => $self->{prefixes},
      'graph'    => $self->{graph},
      'class'    => $self->full_uri($class),
    };
  my $sparql = $self->{queries}->process('get_instances', $vars);


  my @classes = $self->{backend}->query($sparql);
  return @classes;
}

sub add_obj_prop {
  my ($self, $subject, $relation, $target) = @_;

  my $vars = {
      'subject'  => $self->full_uri($subject),
      'relation' => $self->full_uri($relation),
      'target'   => $self->full_uri($target),
      'graph'    => $self->{graph},
      'prefixes' => $self->{prefixes},
    };
  my $sparql = $self->{queries}->process('add_obj_prop', $vars);


  my $result = $self->{backend}->update($sparql);
  return $result;
}

sub get_obj_props {
  my ($self, $instance) = @_;

  # XXX some backends return str(?n) with < >
  $instance = $self->full_uri($instance);
  $instance =~ s/^<//;
  $instance =~ s/>$//;

  my $vars = {
      'prefixes' => $self->{prefixes},
      'graph'    => $self->{graph},
      'instance' => $instance,
    };
  my $sparql = $self->{queries}->process('get_obj_props', $vars);

  my @props = $self->{backend}->query($sparql);
  return @props;
}

sub get_obj_props_for {
  my ($self, $rel, $el) = @_;

  my $vars = {
      'prefixes' => $self->{prefixes},
      'graph'    => $self->{graph},
      'rel'      => $self->full_uri($rel),
      'el'       => $self->full_uri($el),
    };
  my $sparql = $self->{queries}->process('get_obj_props_for', $vars);

  my @els = $self->{backend}->query($sparql);
  return @els;
}

sub get_ranges {
  my ($self) = @_;

  my $vars = {
      'prefixes' => $self->{prefixes},
      'graph'    => $self->{graph},
    };
  my $sparql = $self->{queries}->process('get_ranges', $vars);

  my @ranges = $self->{backend}->query($sparql);
  return @ranges;
}

sub get_data_props {
  my ($self, $instance) = @_;
  $instance = $self->full_uri($instance);

  my $vars = {
      'prefixes' => $self->{prefixes},
      'graph'    => $self->{graph},
      'instance' => $instance,
    };
  my $sparql = $self->{queries}->process('get_data_props', $vars);


  my @props = $self->{backend}->query($sparql);
  return @props;
}

sub add_data_prop {
  my ($self, $subject, $relation, $target, $type) = @_;
  $type = 'string' unless $type;

  my $vars = {
      'subject'  => $self->full_uri($subject),
      'relation' => $self->full_uri($relation),
      'target'   => $target,
      'type'     => $type,
      'graph'    => $self->{graph},
      'prefixes' => $self->{prefixes},
    };
  my $sparql = $self->{queries}->process('add_data_prop', $vars);

  my $result = $self->{backend}->update($sparql);
  return $result;
}

sub full_uri {
  my ($self, $name) = @_;
  return $name if $name =~ m/^<.*>$/;
  return "<$name>" if $name =~ m/^http:\/\//;

  return '<'.$self->{base_uri}.'#'.$name.'>';
}

sub shorten_uri {
  my ($self, $uri) = @_;
  return $uri unless ($uri =~ m/^</ and $uri =~ m/>$/);

  $uri =~ s/^<//;
  $uri =~ s/>$//;
  return $1 if ($uri =~ m/.*?#(.*?)/);
  
  return $uri;
}

sub get_class_tree {
  my ($self, $parent, $flag) = @_;
  $parent = 'http://www.w3.org/2002/07/owl#Thing' unless ($parent);
  $flag = 0 unless $flag;

  my $curr;
  my @child = $self->get_subclasses("<$parent>");
  foreach (@child) {
    $curr->{$_} = $self->get_class_tree($_,1);
  }

  return $flag ? $curr : { $parent => $curr };
}

sub draw_graph {
  my ($self) = @_;

  my $vars = {
      'graph'    => $self->{graph},
      'prefixes' => $self->{prefixes},
    };
  my $sparql = $self->{queries}->process('select_from_graph', $vars);

  my @result = $self->{backend}->query($sparql);

  my $dot = "digraph g {\n  rankdir=LR;\n";
  foreach (@result) {
    $dot .= sprintf("  \"%s\" -> \"%s\" [ label = \"%s\" ];\n",
              $_->[0], $_->[2], $_->[1]);
  }
  $dot .= "}\n";

  return $dot;
}

# FIXME move this somewhere else?
sub empty_owl {
  my ($base_uri) = (@_);

  my $rdfxml =<<"EOR";
<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE rdf:RDF [
    <!ENTITY owl "http://www.w3.org/2002/07/owl#" >
    <!ENTITY xsd "http://www.w3.org/2001/XMLSchema#" >
    <!ENTITY example "http://local/example" >
    <!ENTITY rdfs "http://www.w3.org/2000/01/rdf-schema#" >
    <!ENTITY rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#" >
]>

<rdf:RDF xmlns="$base_uri"
     xml:base="$base_uri"
     xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
     xmlns:empty="$base_uri"
     xmlns:owl="http://www.w3.org/2002/07/owl#"
     xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
     xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <owl:Ontology rdf:about="http://local/example"/>
</rdf:RDF>
EOR

  return $rdfxml;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Conclave::OTK - Conclave Ontology Toolkit

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Conclave::OTK;

    my $onto = Conclave::OTK->new($base_uri);

    $onto->add_class($class_name);
    $onto->add_obj_prop($class1, $relation, $class2);
    $onto->add_data_prop($class, $relation, $value, $type);
      # default type is string

=head1 DESCRIPTION

OTK implements a set of operations to handle ontologies. Its' main goal
is to provide an ORM-style API, but for RDF documents, to implement
ontology oriented applications.

This module is under developement, and things still change often.

=head1 METHODS

=head2 new

=head2 init

=head2 delete

=head2 add_class

=head2 get_classes

=head2 get_subclasses

=head2 get_all_subclasses

=head2 get_instance_classes

=head2 add_instance

=head2 get_instances

=head2 add_obj_prop

=head2 get_obj_props

=head2 get_obj_props_for

=head2 get_ranges

=head2 get_data_props

=head2 add_data_prop

=head2 full_uri

=head2 get_class_tree

=head2 draw_graph

=head1 AUTHOR

Nuno Carvalho <smash@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2015 by Nuno Carvalho <smash@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
