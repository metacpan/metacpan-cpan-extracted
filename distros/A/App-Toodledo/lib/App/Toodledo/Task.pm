package App::Toodledo::Task;
use strict;
use warnings;

our $VERSION = '1.02';

BEGIN { $PPI::XS_DISABLE = 1 }  # PPI::XS throws deprecation warnings in 5.16

use Carp;
use Moose;
use MooseX::Method::Signatures;
use App::Toodledo::TaskInternal;
use App::Toodledo::Util qw(toodledo_decode toodledo_encode);

use Moose::Util::TypeConstraints;
with 'MooseX::Log::Log4perl';
BEGIN { class_type 'App::Toodledo' };

extends 'App::Toodledo::InternalWrapper';

my %ENUM_STRING = ( status => {
		     0 => 'None',
		     1 => 'Next Action',
		     2 => 'Active',
		     3 => 'Planning',
		     4 => 'Delegated',
		     5 => 'Waiting',
		     6 => 'Hold',
		     7 => 'Postponed',
		     8 => 'Someday',
		     9 => 'Canceled',
		     10 => 'Reference',
		    },
		    priority => {
		      -1 => 'Negative',
		       0 => 'Low',
		       1 => 'Medium',
		       2 => 'High',
		       3 => 'Top',
		    }
		  );
my %ENUM_INDEX = (
		  status   => { reverse %{ $ENUM_STRING{status}   } },
		  priority => { reverse %{ $ENUM_STRING{priority} } },
		 );

# TODO: Figure out how to put this attribute in the wrapper:
has object => ( is => 'ro', isa => 'App::Toodledo::TaskInternal',
	        default => sub { App::Toodledo::TaskInternal->new },
	        handles => sub { __PACKAGE__->internal_attributes( $_[1] ) } );

method tag ( @args ) {
  toodledo_decode( $self->object->tag( @args ) );
}

method title ( @args ) {
  toodledo_decode( $self->object->title( @args ) );
}

method note ( @args ) {
  toodledo_decode( $self->object->note( @args ) );
}


method status_str ( Item $new_status? ) {
  $self->set_enum( status => $new_status );
}

method priority_str ( Item $new_priority? ) {
  $self->set_enum( priority => $new_priority );
}

method set_enum ( Str $type!, Item $new_value? ) {
  my @args;
  if ( $new_value )
  {
    defined( my $index = $ENUM_INDEX{$type}{$new_value} )
      or $self->log->logdie("$type $new_value not valid");
    push @args, $index;
  }
  my $index = $self->object->$type( @args );
  my $string = $ENUM_STRING{$type}{$index}
    or $self->log->logdie("Toodledo returned invalid $type index $index");
  $string;
}


# XXX Factor out duplication in next 4 methods
method folder_name ( App::Toodledo $todo!, Item $new_folder? ) {
  $self->set_name( $todo, folder => $new_folder );
}

method context_name ( App::Toodledo $todo!, Item $new_context? ) {
  $self->set_name( $todo, context => $new_context );
}

method goal_name ( App::Toodledo $todo!, Item $new_goal? ) {
  $self->set_name( $todo, goal => $new_goal );
}

method location_name ( App::Toodledo $todo!, Item $new_location? ) {
  $self->set_name( $todo, location => $new_location );
}


our $can_use_cache;  # See App::Toodledo::foreach()
my %cache;

method set_name( App::Toodledo $todo!, Str $type!, Item $new_string? ) {
  my @args;
  my $class = "App::Toodledo::\u$type";
  eval "require $class";
  my @objs;
  if ( $can_use_cache )
  {
    @objs = @{ $cache{$type} };
    $self->log->debug( "Using cached ${type}s\n" );
  }
  else
  {
    $self->log->debug( "Fetching ${type}s\n" );
    @objs = $todo->get( $type.'s' );
    $cache{$type} = \@objs;
    $can_use_cache = 0;
  }
  if ( defined $new_string )   # Find the new object in list of available
  {
    my $id;
    if ( $new_string eq '' )
    {
      $id = 0;
    }
    else
    {
      my ($obj) = grep { $_->name eq $new_string } @objs
	or $self->log->logdie("Could not find a $type with name '$new_string'");
      $id = $obj->id;
    }
    $self->object->$type( $id );
    return $new_string;
  }

  my $id = $self->$type or return '';
  my ($obj) = grep { $_->id == $id } @objs
    or $self->log->logdie( "Could not find existing $type $id in global list!");
  $obj->name;
}


method tags ( Str @new_tags ) {
  if ( @new_tags )
  {
    $self->tag( join ', ', @new_tags );
    return @new_tags;
  }
  split /,/, $self->tag;
}


method has_tag ( Str $tag! ) {
  grep { $_ eq $tag } $self->tags;
}


method add_tag ( Str $tag! ) {
  my $new_tag = $self->tag ? $self->tag . ", $tag" : $tag;
  $self->tag( $new_tag ) unless $self->has_tag( $tag );
}


method remove_tag ( Str $tag! ) {
  return unless $self->has_tag( $tag );
  my @new_tags = grep { $_ ne $tag } $self->tags;
  $self->tags( @new_tags );
}


# Return id of added task
method add ( App::Toodledo $todo! ) {
  my %param = %{ $self->object };
  $param{$_} = toodledo_encode( $param{$_} )
    for grep { $param{$_} } qw(title tag note);
  my $added_ref = $todo->call_func( tasks => add => { tasks => \%param } );
  $added_ref->[0]{id};
}


method optional_attributes ( $class: ) {
  my @attrs = $class->attribute_list;
  grep { ! /\A(?:id|title|modified|completed)\z/ } @attrs;
}


method edit ( App::Toodledo $todo!, App::Toodledo::Task @more ) {
  if ( @more )
  {
    my @edited = map { +{ %{ $_->object } } } ( $self, @more );
    my $edited_ref = $todo->call_func( tasks => edit => { tasks => \@edited } );
    return map { $_->{id} } @$edited_ref;
  }
  else
  {
    my %param = %{ $self->object };
    my $edited_ref = $todo->call_func( tasks => edit => { tasks => \%param } );
    return $edited_ref->[0]{id};
  }
}


method delete ( App::Toodledo $todo! ) {
  my $id = $self->id;
  my $deleted_ref = $todo->call_func( tasks => delete => { tasks => [$id] } );
  $deleted_ref->[0]{id} == $id or $self->log->logdie("Did not get ID back from delete");
}


1;

__END__

=head1 NAME

App::Toodledo::Task - class encapsulating a Toodledo task

=head1 SYNOPSIS

  $task = App::Toodledo::Task->new;
  $task->title( 'Put the cat out' );

=head1 DESCRIPTION

This class provides accessors for the properties of a Toodledo task.
The attributes of a task are defined in the L<App::Toodledo::TaskRole>
module.

=head1 METHODS

=head2 @tags = $task->tags( [@tags] )

Return the tags of the task as a list (splits the attribute on comma).
If a list is provided, set the tags to that list.

=head2 $task->has_tag( $tag )

Return true if the tag C<$tag> is in the list returned by C<tags()>.

=head2 $task->add_tag( $tag )

Add the given tag.  No-op if the task already has that tag.

=head2 $task->remove_tag( $tag )

Remove the given tag.  No-op if the task doesn't have that tag.

=head2 $task->edit( @tasks )

This is the method called by:

  App::Toodledo::edit( $task )

You can pass multiple tasks to it:

  $todo->edit( @tasks )

and they will all be updated.
The current maximum number of tasks you can send to Toodledo for
editing is 50.  B<This method does not check for that.>  (They
might raise the limit in the future.)  Bounds checking is the caller's
responsibility.

=head2 $task->status_str, $task->priority_str

Each of these methods operates on the string defined at
http://api.toodledo.com/2/tasks/index.php, not the integer.
The string will be turned into the integer going into Toodledo
and the integer will get turned into the string coming out.
Examples:

  $task->priority_str( 'Top' )
  $task->status_str eq 'Hold' and ...

Each method can be used in a App::Toodledo::select call.

=head2 $task->folder_name, $task->context_name, $task->location_name, $task->goal_name

Each of these methods returns and optionally sets the given attribute via
its name rather than the indirect ID that is stored in the task.  An
exception is thrown if no object with that name exists when setting it.
Examples:

  $task->folder_name( $todo, 'Later' );
  $task->context_name( $todo ) eq 'Home' and ...

If the value is null, returns the empty string rather than the Toodledo
display value of "No <Whatever>".

NOTE: An App::Toodledo object must be passed as the first parameter
so it can look up the mapping of objects to names.

=head1 CAVEAT

This is a very basic implementation of Toodledo tasks.  It is missing
much that would be helpful with dealing with repeating tasks.  Patches
welcome.

=head1 AUTHOR

Peter J. Scott, C<< <cpan at psdt.com> >>

=head1 SEE ALSO

Toodledo: L<http://www.toodledo.com/>.

Toodledo API documentation: L<http://www.toodledo.com/info/api_doc.php>.

=head1 COPYRIGHT & LICENSE

Copyright 2009-2011 Peter J. Scott, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
