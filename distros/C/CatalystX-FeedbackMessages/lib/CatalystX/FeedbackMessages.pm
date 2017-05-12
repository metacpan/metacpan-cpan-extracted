package CatalystX::FeedbackMessages;
use Moose::Role;

=head1 NAME

CatalystX::FeedbackMessages - Easy way to stuff "status" messages into your stash

=head1 VERSION

version 0.0603

=cut

=head1 SYNOPSIS

    use Catalyst qw/
        ...
    +CatalystX::FeedbackMessages
    /;

    # later...

    package MyApp::Controller::Blargh;
    ...

    sub fnargh : Local {
        my ($self, $c) = @_;
        ## do some form submission stuff
        if( $form_stuff_is_successful ) {
            $c->msg("Successful submission is successful!");
        }
    }


Open up your wrapper and add these lines:

    [% FOR message IN messages -%]
        [% message %]
    [% END -%]

(Add formatting as you please)

=cut

=head1 DESCRIPTION

This module was inspired while working with Mischa Spiegelmock on a Catalyst project.  He had put together a small plugin/mixin (astonishingly similar to this one :-)
that allowed you to add an arbitrary number of messages to C<$c->stash> via an arrayref which could be iterated through by L<Template::Toolkit>.

=cut

=head1 METHODS

msgs $message

  Push a message into the array

=cut


=head1 CONFIGURATION

None, yet.

=cut

=head1 AUTHORS

Devin Austin, <dhoss@cpan.org>

With thanks to Mischa Spiegelmock

=cut

=head1 TODO

Allow user to specify names for message keys

=cut

=head1 SEE ALSO

I dunno :-)

=cut

=head1 COPYRIGHT & LICENSE

	Copyright (c) 2005-2008 the aforementioned authors. All rights
	reserved. This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut

# ABSTRACT: Add "status messages" to your app, easy like!

our $VERSION = '0.0603'; 
sub msg {
    my ($c, $msg) = @_;
    $c->stash->{messages} ||= [];
    # I'm wondering if this can't be done more purdier
    push @{$c->stash->{messages}}, $msg if $msg;
}

1;