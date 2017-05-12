package Catalyst::Action::RenderView::ErrorHandler;
{
  $Catalyst::Action::RenderView::ErrorHandler::VERSION = '0.100166';
}
# ABSTRACT: Custom errorhandling in deployed applications

use warnings;
use strict;
use Carp;
use MRO::Compat;

use Class::Inspector;

use Moose;

extends 'Catalyst::Action::RenderView';

has 'handlers' => (is => 'rw', isa => 'ArrayRef', default => sub { [] });
has 'actions' => (is => 'rw', isa => 'HashRef', default => sub { {} });

sub action {
    my $self = shift;
    my $id = shift;
    return $self->actions->{$id};
}
sub execute {
    my $self = shift;
    my ($controller, $c) = @_;

    my $rv = $self->maybe::next::method(@_);
    return 1 unless (scalar(@{ $c->error }) or $c->res->status =~ /^4\d\d/);
    return 1 if ($c->debug and !$c->config->{'error_handler'}->{'enable'});
    $self->actions({});
    $self->handlers([]);
    $self->_parse_config($c);
    $self->handle($c);
}

sub handle {
    my $self = shift;
    my $c = shift;

    my $code = $c->res->status;
    my $has_errors = scalar( @{ $c->error } );
    if ($code == 200 and $has_errors) {
        $code = 500; # We default to 500 for errors unless something else has been set.
        $c->res->status($code);
    }
    my $body;
    foreach my $h (@{ $self->handlers }) {
        if ($code =~ $h->{decider}) {
            eval {
                $body = $self->render($c, $h->{render});
            };
            if ($@ and $@ =~ m/Error rendering/) {
                # we continue to next step
                next;
            } elsif ($@) {
                croak $@;
            }
            # We have successfully rendered something, so we clear errors
            # and set content
            $c->res->body($body);
            if($h->{actions}) {
                foreach my $a (@{ $h->{actions} }) {
                    next unless defined $a;
                    next if $a->ignore($c->req->path);
                    $a->perform($c);
                }
            }
            $c->clear_errors;

            # We have some actions to perform
            last ;
        }
    }
    if ($has_errors and $code =~ m/[23]\d{2}/) {
        $c->res->status(500); # We overwrite 2xx and 3xx with 500 if we had errors
    }
}
sub render {
    my $self = shift;
    my $c = shift;
    my $args = shift;

    if ($args->{static}) {
        my $file =  ($args->{static} !~ m|^/|)
            ? $c->path_to($args->{static})
            : $args->{static}
        ;
        open(my $fh, "<", $file) or croak "cannot read: $file";
        return $fh;
    } elsif ($args->{template}) {
        # We try to render it using the view, but will catch errors we hope
        my $content;
        my %data = $self->_render_stash( $c );
        $data{additional_template_paths} ||= [ $c->path_to('root') ]; #compatible w/ earlier version
        eval {
            $content = $c->view->render( $c, $args->{template}, \%data );
        };
        unless ($@) {
            return $content;
        } else {
            croak "Error rendering - TT error on template " . $args->{template};
        }
    } else {
        croak "Error rendering - no template or static";
    }
}


sub _render_stash {
    my $self = shift;
    my $c    = shift;
    return () if !exists $c->config->{'error_handler'}->{'expose_stash'};
    my $es = $c->config->{'error_handler'}->{'expose_stash'};
    return map { $_ =~ $es ? ($_ => $c->stash->{$_}) : () } keys %{$c->stash}
             if ( ref($es) eq 'Regexp' );
    return map { $_ => $c->stash->{$_} } @{$es} if ( ref($es) eq 'ARRAY' );
    return ( $es => $c->stash->{$es} ) if ( !ref($es) );
}

sub _parse_config {
    my $self = shift;
    my $c = shift;

    $self->_parse_actions($c, $c->config->{'error_handler'}->{'actions'});
    $self->_parse_handlers($c, $c->config->{'error_handler'}->{'handlers'});
}

sub _parse_actions {
    my $self = shift;
    my $c = shift;

    my $actions = shift;
    unless ($actions and scalar(@$actions)) {
        # We dont have any actions, lets create a default log action.
        my $action = {
            type => 'Log',
            id => 'default-log-error',
            level => 'error',
        };
        push @$actions, $action;
    }
    foreach my $action (@$actions) {
        $self->_expand($c, $action );
        my $class;
        if ($action->{'type'} and $action->{'type'} =~ /^\+/) {
            $class = $action->{'type'};
            $class =~ s/^\+//;
        } elsif($action->{'type'}) {
            $class = ref($self) . "::Action::" . $action->{'type'};
        } else {
            croak "No type specified";
        }

        unless(Class::Inspector->loaded($class)) {
            eval "require $class";
            if ($@) {
                croak "Could not load '$class': $@";
            }
        }
        my $act = $class->new(%$action);
        $self->actions->{$act->id} = $act;
    }
}

sub _parse_handlers {
    my $self = shift;
    my $c = shift;
    my $handlers = shift;
    my $codes = {};
    my $blocks = {};
    my $fallback = {
        render => { static => 'root/static/error.html' },
        decider => qr/./,
        actions => [ $self->action('default-log-error') ? $self->action('default-log-error') : undef  ]
    };
    foreach my $status (keys %$handlers) {
        my $handler = {
            actions => [map { $self->action($_) } @{ $handlers->{$status}->{actions}}],
            render => ($handlers->{$status}->{template}
                ? { template => $handlers->{$status}->{template} }
                : { static => $handlers->{$status}->{static} }
            ),
        };

        if ($status =~ m/\dxx/) {
            #codegroup
            my $decider = $status;
            $decider =~ s/x/\\d/g;
            $handler->{decider} = qr/$decider/;
            $blocks->{$status} = $handler;
        } elsif ($status =~ m/\d{3}/) {
            $handler->{decider} = qr/$status/;
            $codes->{$status} = $handler;
        } elsif ($status eq 'fallback') {
            $handler->{decider} = qr/./;
            $fallback = $handler;
        } else {
            carp "Wrong status: $status specified";
        }
    }
    my @handlers;
    push(@handlers, values(%$codes), values(%$blocks), $fallback);
    $self->handlers(\@handlers);
}

sub _expand {
    my $self = shift;
    my $c = shift;
    my $h = shift;

    foreach my $k (keys %$h) {
        my $v = $h->{$k};
        my $name = $c->config->{name};
        $v =~ s/__MYAPP__/$name/g;
        $h->{$k} = $v;
    }
}
1; # Magic true value required at end of module

__END__

=pod

=encoding utf-8

=head1 NAME

Catalyst::Action::RenderView::ErrorHandler - Custom errorhandling in deployed applications

=head1 VERSION

version 0.100166

=head1 SYNOPSIS

    sub end : ActionClass('RenderView::ErrorHandler') {}

=head1 DESCRIPTION

We all dread the Please come back later screen. Its uninformative, non-
helpful, and in general an awfull default thing to do.

This module lets the developer configure what happens in case of emergency.

=over 4

=item If you want the errors emailed to you? You can have it.

=item Want them logged somewhere as well? suresure, we will do it.

=item Custom errorpage that fits your design you say? Aw come on :)

=back

=head1 CONFIGURATION AND ENVIRONMENT

We take our configuration from C<< $c->config->{'error_handler'} >>. If you do no
configuration, the default is to look for the file 'root/static/error.html',
and serve that as a static file. If all you want is to show a custom, static,
error page, all you have to do is install the module and add it to your end
action.

=head2 OPTIONS

=head3 actions

Is an array of actions you want taken. Each value should be an hashref
with atleast the following keys:

=head4 enable

If this is true, we will act even in debug mode. Great for getting debug logs AND
error-handler templates rendered.

=head4 ignorePath (Optional)

If this regex matches C<< $c->req->path >>, the action will be skipped. Useful
if you want to exclude some paths from triggering emails for instance. Can be
used to ignore hacking attempts against PhpMyAdmin and such.

=head4 type

Can be Log for builtin, or you can prefix it with a +, then
we will use it as a fully qualified class name.

The most excellent Stefan Profanter wrote
L<Catalyst::Action::RenderView::ErrorHandler::Action::Email>, which lets you send
templated emails on errors.

=head4 id

The id you want to have for this action

=head4 expose_stash

Either a list of keys, a regexp for matching keys, or a simple string to denote
a single stash value.

stash keys that match will be available to template handlers

=head3 handlers

Configuration as to what to do when an error occurs. We always need
to show something to the user, so thats a given. Each handler represents
an error state, and a given handler can perform any given number of actions
in addition to rendering or sending something to the browser/client.

=over 4

=item HTTP status codes (404, 500 etc)

=item HTTP status code groups (4xx, 5xx etc)

=item "fallback" - default action taken on error.

=back

The action is decided in that order.

=head4 template

Will be sent to your default_view for processing. Can use c.errors as needed

=head4 static

Will be read and served as a static file. This is the only option for fallback,
since fallback will be used in case rendering a template failed for some reason.

If the given string begins with an '/', we treat it as an absolute path and try
to read it directly. If not, we pass it trough C<< $c->path_to() >> to get an
absolute path to read from.

=head2 EXAMPLE

    error_handler:
        actions:
            # Check out
            # L<Catalyst::Action::RenderView::ErrorHandler::Action::Email> if
            # you want to send email from an action
            - type: Email
              id: email-devel
              to: andreas@example.com
              subject: __MYAPP__ errors:
            - type: Log
              id: log-server
              level: error
        handlers:
            5xx:
                template: root/error/5xx.tt
                actions:
                    - email-devel
                    - log-server
            500:
                template: root/error/500.tt
                actions:
                    - log-server
            fallback:
                static: root/static/error.html
                actions:
                    - email-devel

=head1 INTERFACE

=head2 IMPLEMENTED METHODS

=head3 execute

Implemented to comply with L<Catalyst::Action> interface.

It checks if there are errors, if not it it simply returns, assuming
L<Catalyst::Action::RenderView> has handled the job. If there are errors
we parse the configuration and try to build our handlers.

Then it calls C<< $self->handle >>.

=head2 METHODS

=head3 handle

Handles a request, by finding the propper handler.

Once a handler is found, it calls render if there are statics or
templates, and then performs all actions (if any).

=head3 render

Given either a static file or a template, it will attempt to render
it and send it to C<< $context->res->body >>.

=head2 PRIVATE METHODS

=head3 _render_stash

return a list of rendering data in template from exposed stash

=head2 INHERITED METHODS

=head3 meta

Inherited from L<Moose>

=head1 DEPENDENCIES

L<Catalyst::Action::RenderView>

=head1 SEE ALSO

=over 4

=item L<Catalyst::Action::RenderView::ErrorHandler::Action::Email>

=back

=head1 Thanks

=over 4

=item zdk L<https://github.com/zdk>

=item Stefan Profanter L<https://metacpan.org/author/PROFANTER>

=back

=head1 AUTHOR

Andreas Marienborg <andremar@cpan.org>

=head1 CONTRIBUTORS

=over 4

=item *

Andreas Marienborg <andreas.marienborg@gmail.com>

=item *

Pinnapong Silpsakulsuk <ping@abctech-thailand.com>

=item *

zdk <nx2zdk@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andreas Marienborg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
