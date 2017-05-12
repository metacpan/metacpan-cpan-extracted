package DBIx::Class::QueryLog::WithStackTrace;

use Moose;

extends 'DBIx::Class::QueryLog';

use DBIx::Class::QueryLog::WithStackTrace::Query;
use Devel::StackTrace;

our $VERSION = '1.0';

=head1 NAME

DBIx::Class::QueryLog::WithStackTrace

=head1 DESCRIPTION

A subclass of DBIx::Class::QueryLog that adds a stacktrace to the logs

=head1 METHOD

There are only two methods implemented, everything else is inherited from
DBIx::Class::QueryLog.

=head2 query_start

Exactly the same as the parent class's implementation, except that it also
adds a 'stacktrace' key to the objects representing queries.

The stacktrace is a Devel::StackTrace object.  Ideally the stacktrace will
start at the point with the DBIx::Class method that your code called, but
you will sometimes see one or two of its internal methods before that.  Sorry,
this is a limitation of Devel::StackTrace.

=head2 query_class

An implementation detail, returns 'DBIx::Class::QueryLog::WithStackTrace::Query'.
See L<DBIx::Class::QueryLog> for details.

=cut

sub query_class { 'DBIx::Class::QueryLog::WithStackTrace::Query' }

sub query_start {
    my $self = shift;
    $self->SUPER::query_start(@_);

    my $trace = Devel::StackTrace->new(
        no_refs => 1,
        frame_filter => sub {
            return $_[0]->{caller}->[0] =~ /^DBIx::Class($|::)/ ? 0 : 1;
        }
    );
    $self->current_query()->stacktrace($trace);

    # my @frames = $trace->frames();
    # foreach my $frame (reverse @frames) {
    #     unshift @{$self->current_query()->{stacktrace}}, $frame->as_string();
    #     last if($frame->subroutine() =~ /^DBIx::Class/);
    # }
}

=head1 FEEDBACK

I welcome feedback about my code, especially constructive criticism.

=head1 AUTHOR, COPYRIGHT and LICENCE

Copyright 2012 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence. It's
up to you which one you use. The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

1;
