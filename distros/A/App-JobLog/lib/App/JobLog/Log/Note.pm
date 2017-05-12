package App::JobLog::Log::Note;
$App::JobLog::Log::Note::VERSION = '1.042';
# ABSTRACT: timestamped annotation in log


use Modern::Perl;
use Class::Autouse qw{DateTime};
use autouse 'App::JobLog::Time' => qw(now);
use autouse 'Carp'              => qw(carp);

# for debugging
use overload '""' => sub {
   $_[0]->data->to_string;
};
use overload 'bool' => sub { 1 };


sub new {
   my ( $class, $logline ) = @_;
   $class = ref $class || $class;
   my $self = bless { log => $logline }, $class;
   return $self;
}


sub clone {
   my ($self) = @_;
   my $clone = $self->new( $self->data->clone );
   return $clone;
}


sub data {
   $_[0]->{log};
}


sub start : lvalue {
   $_[0]->data->time;
}


sub tags : lvalue {
   $_[0]->data->{tags};
}


sub tagged { !!@{ $_[0]->tags } }


sub tag_list { @{ $_[0]->tags } }


sub describe {
   my ($self) = @_;
   join '; ', @{ $self->data->description };
}


sub exists_tag {
   my ( $self, @tags ) = @_;
   $self->data->exists_tag(@tags);
}


sub all_tags {
   my ( $self, @tags ) = @_;
   $self->data->all_tags(@tags);
}


sub cmp {
   my ( $self, $other ) = @_;
   carp 'argument must also be time' unless $other->isa(__PACKAGE__);

   # defer to subclass sort order if other is a subclass and self isn't
   return -$other->cmp($self)
     if ref $self eq __PACKAGE__ && ref $other ne __PACKAGE__;

   return DateTime->compare( $self->start, $other->start );
}


sub split_days {
   return $_[0];
}


sub intersects {
   my ( $self, $other ) = @_;
   if ( $other->can('end') ) {
      return $self->start >= $other->start && $self->start < $other->end;
   }
   return $self->start == $other->start;
}


sub is_note {
  shift->{log}->is_note
}


sub is_open { 0 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JobLog::Log::Note - timestamped annotation in log

=head1 VERSION

version 1.042

=head1 DESCRIPTION

A wrapper for a log line that represents a timestamped and optionally tagged note.

=head1 METHODS

=head2 new

Basic constructor. Expects single L<App::JobLog::Log::Line> argument. Can be called on
instance or class.

=head2 clone

Create a duplicate of this event.

=head2 data

Returns L<App::JobLog::Log::Line> object on which this event is based.

=head2 start

Start of event. Is lvalue method.

=head2 tags

Tags of event (array reference). Is lvalue method.

=head2 tagged

Whether there are any tags.

=head2 tag_list

Returns tags as list rather than reference.

=head2 describe

Returns the log line's description.

=head2 exists_tag

Expects a list of tags. Returns true if event contains any of them.

=head2 all_tags

Expects a list of tags. Returns whether event contains all of them.

=head2 cmp

Used to sort events. E.g.,

 my @sorted_events = sort { $a->cmp($b) } @unsorted;

=head2 split_days

Returns note itself. This method is overridden by the event object and used in
event summarization.

=head2 intersects

Whether this note overlaps the given period.

=head2 is_note

Whether this "note" (events are a subclass of note) is just a note.

=head2 is_open

Returns false: notes have no duration so they cannot be open.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
