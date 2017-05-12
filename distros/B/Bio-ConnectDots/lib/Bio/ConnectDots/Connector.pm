package Bio::ConnectDots::Connector;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS);
use strict;
use Class::AutoClass;
@ISA = qw(Class::AutoClass); # AutoClass must be first!!

@AUTO_ATTRIBUTES=qw(connectorset dots db_id
		    _dots);
@OTHER_ATTRIBUTES=qw();
%SYNONYMS=();
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  my $connectorset=$self->connectorset;
  my $dots_hash=$args->dots_hash || ($connectorset && $connectorset->dots_hash);
  $self->put_dots($dots_hash) if $dots_hash;
}
sub name {
  my($self)=@_;
  $self->connectorset->name;
}
sub put {
  my($self,$label,$dot)=@_;
  my $dots=$self->dots || $self->dots({});
  my $dot_list=$dots->{$label} || ($dots->{$label}=[]);
  push(@$dot_list,$dot);
}
sub labels {
  my($self)=@_;
  my $dots=$self->dots || $self->dots({});
  my @labels=keys %$dots;
  wantarray? @labels: \@labels;
}
sub get_dots {
  my($self,$label)=@_;
  my $dots=$self->dots || $self->dots({});
  my $dots_list=$dots->{$label} || [];
  unless (defined $dots_list) {
    print "break here\n";
  }
  wantarray? @$dots_list: $dots_list;
}

sub put_dots {
  my $self=shift;
  return {} unless @_;
  my $dots_hash=@_==1? $_[0]: {@_};
  my $connectorset=$self->connectorset;
  my $label2dotset=$connectorset->label2dotset;
  while (my($label,$ids)=each %$dots_hash) {
    my $dotset=$label2dotset->{$label};
    $self->throw("label $label not valid for ConnectorSet ".$connectorset->name) unless $dotset;
    $ids=[$ids] unless 'ARRAY' eq ref $ids;
    my $dots;
    for my $id (@$ids) {
      my $dot=$dotset->lookup($id);
      $dot->put($self);
      $self->put($label,$dot);
    }
  }
}
1;
__END__

=head1 NAME

Bio::ConnectDots::Connector -- one connection entry for 'connect-the-dots'

=head1 SYNOPSIS

  use Bio::ConnectDots::Connector;
  my $locuslink = ...;		# set to LocusLink connector somehow
  my $connector = new Bio::ConnectDots::Connector;
  $connector->dots({LocusID=>$locus_dot,UniGeneID=>$unigene_dot,...});	
  $locuslink->put($connector);	# add to LocusLink connector object

=head1 DESCRIPTION

This class connects multiple objects (called 'Dots') based on information in a data source. 

=head1 KNOWN BUGS AND CAVEATS

This is still a work in progress.  This documentation is out of date.
In any case, this class is no longer used in normal processing

=head2 Bugs, Caveats, and ToDos

  TBD

=head1 AUTHOR - David Burdick, Nat Goodman

Email dburdick@systemsbiology.org, natg@shore.net

=head1 COPYRIGHT

Copyright (c) 2005 Institute for Systems Biology (ISB). All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 APPENDIX

The rest of the documentation describes the methods.

=head2 Constructors

 Title   : new
 Usage   : my $connector = new Bio::ConnectDots::Connector;
 Function: Create empty connector object
 Returns : Bio::ConnectDots::Connector object

=head2 Simple attributes

These are methods for getting and setting the values of simple
attributes. Each of these can be set in the argument list to new, if
desired.  Some of these should be read-only (more precisely, should
only be written by code internal to the obkect), but this is not
enforced. We assume, Perl-style, that programmers will behave nicely
and not complain too loudly if the software lets them do something
stupid.

Methods have the same name as the attribute.  To get the value of
attribute xxx, just say $xxx=$object->xxx; To set it, say
$object->xxx($new_value); To clear it, say $object->xxx(undef);

 Attr    : dots
 Function: Hash ref of connected objects. The keys are the Dot names
 Access  : read-write

=head2 Retrieving Dots (ie, objects connected by the connector)

 Title   : get_dot
 Usage   : my $connector=$locuslink->get_next;
           my $locusid=$connector->get_dot('LocusID');
           my @locusid=$connector->get_dot('LocusID');
 Args    : Name of Dot (ie, connected object) to retrieve
 Returns : In a scalar context: 
             Returns the connected dot, if there's only one of the given type
             If there are multiple connected dots, returns an arbitray one
           In a list context, returns a list of the connected dots of the 
           given type.

 Title   : get_dots
 Usage   : my $connector=$locuslink->get_next;
           my $aliases=$connector->get_dots('Alias');
           my @aliases=$connector->get_dots('Alias');
 Args    : Type of Dot (ie, connected object) to retrieve
           These can be names or objects
 Returns : In a scalar context, returns a list ref of the connected dots 
           of the given type.
           In a list context, returns a list of the connected dots of the 
           given type.
=cut
