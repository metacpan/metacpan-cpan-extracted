package Bio::ConnectDots::Dot;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS);
use strict;
use Class::AutoClass;
@ISA = qw(Class::AutoClass); # AutoClass must be first!!

@AUTO_ATTRIBUTES=qw(id dot_set db_id
		    _connectors);
@OTHER_ATTRIBUTES=qw();
%SYNONYMS=();
Class::AutoClass::declare(__PACKAGE__,\@AUTO_ATTRIBUTES,\%SYNONYMS);

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
}
sub connectors {
  my $self= shift;
  my $connectors=$self->_connectors || $self->_connectors([]);
  push(@$connectors,@_) if @_;
  wantarray? @$connectors: $connectors;
}
sub put {
  my ($self,$connector) = @_;
  $self->connectors($connector);
  $connector;
}
1;
__END__

=head1 NAME

Bio::ConnectDots::Dot -- one dot entry for 'connect-the-dots'

=head1 SYNOPSIS

  use Bio::ConnectDots::Dot;
  my $locuslink = ...;		#??? set to LocusLink dot somehow
  my $Dot = new Bio::ConnectDots::Dot;
  ???$dot->connectors({LocusID,UniGene,...});	
  ???$locuslink->put($connector);	# add to LocusLink connector object

=head1 DESCRIPTION

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
 Usage   : my $dot = new Bio::ConnectDots::Dot;
 Function: Create empty dot object
 Returns : Bio::ConnectDots::Dot object

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

 Attr    : connectors
 Function: Hash ref of connected objects. The keys are the Connector names
 Access  : read-write

=head2 Retrieving Dots (ie, objects connected by the connector)

 Title   : get_connector
 Usage   : ??? my $dot=$locuslink->get_next;
           my $locusid=$dot->get_connector('LocusID');
           my @locusid=$dot->get_connector('LocusID');
 Args    : Name of Connector (ie, connected object) to retrieve
 Returns : In a scalar context: 
             Returns the connected connector, if there's only one of the given type
             If there are multiple connected dots, returns an arbitray one
           In a list context, returns a list of the connected connectors of the 
           given type.

 Title   : get_dots
 Usage   : ????my $dot=$locuslink->get_next;
           my $aliases=$dot->get_connectors('Alias');
           my @aliases=$dot->get_connectors('Alias');
 Args    : Type of Connector (ie, connected object) to retrieve
           These can be names or objects
 Returns : In a scalar context, returns a list ref of the connected connectors
           of the given type.
           In a list context, returns a list of the connected dots of the 
           given type.
=cut

