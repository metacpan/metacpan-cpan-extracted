package AnyEvent::WebService::Tracks::Project;

use strict;
use warnings;
use parent 'AnyEvent::WebService::Tracks::Resource';

use Carp qw(croak);

use namespace::clean;

our $VERSION = '0.02';

__PACKAGE__->readonly(qw/completed_at created_at id updated_at/);
__PACKAGE__->accessor(qw/description name position/);

# here, but not actually accessible: default_context_id state

sub resource_path {
    return 'projects';
}

sub xml_root {
    return 'project';
}

sub is_complete {
    my ( $self ) = @_;

    return $self->{'state'} eq 'completed'
}

sub is_active {
    my ( $self ) = @_;

    return $self->{'state'} eq 'active';
}

sub is_hidden {
    my ( $self ) = @_;

    return $self->{'state'} eq 'hidden';
}

sub default_context {
    my ( $self, $cb_or_ctx ) = @_;

    if(ref($cb_or_ctx) eq 'CODE') {
        my $id = $self->{'default_context_id'};
        if(defined $id) {
            $self->{'parent'}->fetch_single('contexts', $id,
                'AnyEvent::WebService::Tracks::Context', $cb_or_ctx);
        } else {
            $cb_or_ctx->(undef);
        }
    } elsif(ref($cb_or_ctx) eq 'AnyEvent::WebService::Tracks::Context') {
        $self->{'default_context_id'} = $cb_or_ctx->id;
        $self->{'_dirty'}{'default_context_id'} = 1;
    } elsif(! defined($cb_or_ctx)) {
        $self->{'default_context_id'} = undef;
        $self->{'_dirty'}{'default_context_id'} = 1;
    } else {
        croak "AnyEvent::WebService::Tracks::Project::default_context accepts either a CODE reference or an AnyEvent::WebService::Tracks::Context";
    }
}

sub complete {
    my ( $self ) = @_;

    $self->{'state'}           = 'completed';
    $self->{'_dirty'}{'state'} = 1;
}

sub activate {
    my ( $self ) = @_;

    $self->{'state'}           = 'active';
    $self->{'_dirty'}{'state'} = 1;
}

sub hide {
    my ( $self ) = @_;

    $self->{'state'}           = 'hidden';
    $self->{'_dirty'}{'state'} = 1;
}

sub todos {
    my ( $self, $cb ) = @_;

    my $id = $self->id;
    $self->{'parent'}->fetch_multiple("projects/$id/todos",
        'AnyEvent::WebService::Tracks::Todo', $cb);
}

1;

__END__

=head1 NAME

AnyEvent::WebService::Tracks::Project - Tracks project objects

=head1 VERSION

0.02

=head1 SYNOPSIS

  $tracks->create_project($name, sub {
    my ( $project ) = @_;

    say $project->name;
  });

=head1 DESCRIPTION

AnyEvent::WebService::Tracks::Project objects represent GTD projects
in a Tracks installation.

=head1 READ-ONLY ATTRIBUTES

=head2 completed_at

When the project was completed.

=head2 created_at

When the project was created.

=head2 id

The Tracks ID of this project.

=head2 updated_at

When the project was last updated.

=head2 is_complete

Whether or not the project is complete.

=head2 is_active

Whether or not the project is complete.

=head2 is_hidden

Whether or not the project is hidden.

=head1 WRITABLE ATTRIBUTES

=head2 description

A description of this project.

=head2 name

This project's name (must be unique).

=head2 position

This project's position in the list of projects.

=head2 default_context($ctx_or_cb)

This functions a little bit differently than the other
accessors; it takes either a Context object, a callback,
or undef.  If a Context object or undef is provided, that
will be the new default context on the next update.  If
a callback is provided, a call is made to Tracks to retrieve
the context object, which is then provided to the callback.

=head1 METHODS

Most useful methods in this class come from its superclass,
L<AnyEvent::WebService::Tracks::Resource>.

=head2 $project->complete

Marks the project as complete on this project's next update.

=head2 $project->activate

Marks the project as active on this project's next update.

=head2 $project->hide

Marks the project as hidden on this project's next update.

=head2 $project->todos($cb)

Retrieves the list of todos under this project and calls C<$cb> with an
array reference containing them.

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
