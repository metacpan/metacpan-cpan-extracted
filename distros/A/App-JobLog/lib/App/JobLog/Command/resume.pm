package App::JobLog::Command::resume;
$App::JobLog::Command::resume::VERSION = '1.042';
# ABSTRACT: resume last closed task

use App::JobLog -command;
use Modern::Perl;
use Class::Autouse 'App::JobLog::Log';
use autouse 'App::JobLog::Time' => qw(now);

sub execute {
   my ( $self, $opt, $args ) = @_;

   # construct event test
   my %must   = map { $_ => 1 } @{ $opt->tag     || [] };
   my %mustnt = map { $_ => 1 } @{ $opt->without || [] };
   my $test   = sub {
      my $event = shift;
      return if $event->is_note;
      my @tags  = @{ $event->tags };
      my %tags  = map { $_ => 1 } @tags;
      my $good  = 1;
      if (%must) {
         if ( $opt->any ) {
            $good = 0;
            for my $tag (@tags) {
               if ( $must{$tag} ) {
                  $good = 1;
                  last;
               }
            }
         }
         else {
            for my $tag ( keys %must ) {
               unless ( $tags{$tag} ) {
                  $good = 0;
                  last;
               }
            }
         }
      }
      if ( $good && %mustnt ) {
         if ( $opt->some ) {
            $good = 0;
            for my $tag ( keys %mustnt ) {
               unless ( $tags{$tag} ) {
                  $good = 1;
                  last;
               }
            }
         }
         else {
            for my $tag (@tags) {
               if ( $mustnt{$tag} ) {
                  $good = 0;
                  last;
               }
            }
         }
      }
      return $good;
   };

   # find event
   my $log = App::JobLog::Log->new;
   my ( $i, $count, $e ) = ( $log->reverse_iterator, 0 );
   while ( $e = $i->() ) {
      $count++;
      last if $test->($e);
   }

   $self->usage_error('empty log')         unless $count;
   $self->usage_error('no matching event') unless $e;
   $self->usage_error('event ongoing')     unless $e->is_closed;

   my $ll = $e->data->clone;
   $ll->time = now;
   $log->append_event($ll);
   print "resuming " . $e->describe;
   print ' (tags: ', join( ', ', sort $e->tag_list ), ')' if $e->tagged;
   print "\n";
}

sub usage_desc { '%c ' . __PACKAGE__->name . ' %o' }

sub abstract { 'resume last task' }

sub full_description {
   <<END
Starts a new task with an identical description and tags to the last
task in the log. If some restriction by tag is specified, it is the last
task with the given tags.
END
}

sub options {
   return (
      [
         'tag|t=s@',
         'resume the last event with all of these tags; '
           . 'multiple tags may be specified'
      ],
      [ 'any|a', 'require only that one of the --tag tags be present' ],
      [
         'without|w=s@',
         'resume the last event which does not have any of these tags; '
           . 'multiple tags may be specified'
      ],
      [
         'some|s', 'require only that some one of the --without tags be absent'
      ],
   );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JobLog::Command::resume - resume last closed task

=head1 VERSION

version 1.042

=head1 SYNOPSIS

 houghton@NorthernSpy:~$ job last
 Sunday,  6 March, 2011
   7:36 - 7:37 pm  0.01  bar, foo  something to add; and still more

   TOTAL HOURS 0.01
   bar         0.01
   foo         0.01
 houghton@NorthernSpy:~$ job resume
 houghton@NorthernSpy:~$ job today
 Monday,  7 March, 2011
   8:01 am - ongoing  0.00  bar, foo  something to add; and still more

   TOTAL HOURS 0.00
   bar         0.00
   foo         0.00

=head1 DESCRIPTION

Without options specified B<App::JobLog::Command::resume> lets you begin a new event identical in
tags and description to the last one. If the most recent task is ongoing an error message is emitted.

You may specify tags to look for or avoid, in which case a new event is added to the log identical
in tags and description to the most recent event matching the tag restriction.

=head1 SEE ALSO

L<App::JobLog::Command::last>, L<App::JobLog::Command::add>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
