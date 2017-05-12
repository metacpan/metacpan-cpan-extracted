package AnyEvent::WebService::Tracks::Todo;

use strict;
use warnings;
use parent 'AnyEvent::WebService::Tracks::Resource';

use Carp qw(croak);
use Scalar::Util qw(looks_like_number);

use namespace::clean;

our $VERSION = '0.02';

__PACKAGE__->readonly(qw/completed_at created_at id recurring_todo_id updated_at/);
__PACKAGE__->accessor(qw/description due notes show_from/);

# here, but not actually accessible: context_id project_id state

sub resource_path {
    return 'todos';
}

sub xml_root {
    return 'todo';
}

sub is_complete {
    my ( $self ) = @_;

    return $self->{'state'} eq 'completed';
}

sub is_active {
    my ( $self ) = @_;

    return $self->{'state'} eq 'active';
}

sub is_project_hidden {
    my ( $self ) = @_;

    return $self->{'state'} eq 'project_hidden';
}

sub is_deferred {
    my ( $self ) = @_;

    return $self->{'state'} eq 'deferred';
}

sub complete {
    my ( $self ) = @_;

    $self->{'state'}           = 'completed';
    $self->{'_dirty'}{'state'} = 1;

    if(defined $self->{'show_from'}) {
        undef $self->{'show_from'};
        $self->{'_dirty'}{'show_from'} = 1;
    }
}

sub activate {
    my ( $self ) = @_;

    $self->{'state'}           = 'active';
    $self->{'_dirty'}{'state'} = 1;

    if(defined $self->{'show_from'}) {
        undef $self->{'show_from'};
        $self->{'_dirty'}{'show_from'} = 1;
    }
}

sub defer {
    my ( $self, $amount ) = @_;

    my $show_from;

    if(! ref($amount)) {
        $show_from = DateTime->now->add(days => $amount);
    } elsif(ref($amount) eq 'DateTime') {
        $show_from = $amount;
    } elsif(ref($amount) eq 'DateTime::Duration') {
        $show_from = DateTime->now->add_duration($amount);
    }

    $self->{'show_from'}           = $show_from;
    $self->{'_dirty'}{'show_from'} = 1;
}

sub context {
    my ( $self, $cb_or_ctx ) = @_;

    if(ref($cb_or_ctx) eq 'CODE') {
        my $id = $self->{'context_id'};
        if(defined $id) {
            $self->{'parent'}->fetch_single('contexts', $id,
                'AnyEvent::WebService::Tracks::Context', $cb_or_ctx);
        } else {
            $cb_or_ctx->(undef);
        }
    } else {
        $self->{'context_id'} = $cb_or_ctx->id;
        $self->{'_dirty'}{'context_id'} = 1;
    }
}

sub project {
    my ( $self, $cb_or_proj ) = @_;

    if(ref($cb_or_proj) eq 'CODE') {
        my $id = $self->{'project_id'};
        if(defined $id) {
            $self->{'parent'}->fetch_single('projects', $id,
                'AnyEvent::WebService::Tracks::Project', $cb_or_proj);
        } else {
            $cb_or_proj->(undef);
        }
    } else {
        if(defined $cb_or_proj) {
            $self->{'project_id'} = $cb_or_proj->id;
        } else {
            $self->{'project_id'} = undef;
        }
        $self->{'_dirty'}{'project_id'} = 1;
    }
}

1;

__END__

=head1 NAME

AnyEvent::WebService::Tracks::Todo - Tracks todo objects

=head1 VERSION

0.02

=head1 SYNOPSIS

  $tracks->create_todo($description, $context, sub {
    my ( $todo ) = @_;

    say $todo->description;
  });

=head1 DESCRIPTION

AnyEvent::WebService::Tracks::Todo objects represent GTD todo items
in a Tracks installation.

=head1 READ-ONLY ATTRIBUTES

=head2 completed_at

When the todo was completed.

=head2 created_at

When the todo was created.

=head2 id

The Tracks ID of this todo item.

=head2 recurring_todo_id

Unused by this library for now.

=head2 updated_at

When the todo was last updated.

=head2 is_complete

Whether or not the todo item is complete.

=head2 is_active

Whether or not the todo item is active.

=head2 is_project_hidden

Whether or not the todo item's project is hidden.

=head2 is_deferred

Whether or not the todo item has been deferred.

=head1 WRITABLE ATTRIBUTES

=head2 description

A description of this todo item.

=head2 due

When this todo item is due.

=head2 notes

Any notes attached to this todo item.

=head2 show_from

When to start showing the todo item.

=head2 context($ctx_or_cb)

This functions a little bit differently than the other
accessors; it takes either a Context object, a callback,
or undef.  If a Context object or undef is provided, that
will be the new context for this todo item on the next update.
If a callback is provided, a call is made to Tracks to retreve
the context object, which is then provided to the callback.

=head2 project($proj_or_cb)

This functions a little bit differently than the other
accessors; it takes either a Project object, a callback,
or undef.  If a Project object or undef is provided, that
will be the new project for this todo item on the next update.
If a callback is provided, a call is made to Tracks to retreve
the project object, which is then provided to the callback.

=head1 METHODS

Most useful methods in this class come from its superclass,
L<AnyEvent::WebService::Tracks::Resource>.

=head2 $todo->complete

Mark this todo item as complete on its next update.

=head2 $todo->activate

Mark this todo item as active on its next update.

=head2 $todo->defer($amount)

Defer this todo item.  C<$amount> can be a DateTime, a
DateTime::Duration, or simply an integer (which is interpreted
as the number of days to defer the item.)

=head1 AUTHOR

Rob Hoelz, C<< rob at hoelz.ro >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-AnyEvent-WebService-Tracks at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AnyEvent-WebService-Tracks>. I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2011 Rob Hoelz.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<AnyEvent::WebService::Tracks::Resource>, L<AnyEvent::WebService::Tracks>

=begin comment

Undocumented methods (for Pod::Coverage)

=over

=item resource_path
=item xml_root

=back

=end comment

=cut
