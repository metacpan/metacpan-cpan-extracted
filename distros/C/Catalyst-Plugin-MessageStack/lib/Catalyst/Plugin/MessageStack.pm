package Catalyst::Plugin::MessageStack;
{
  $Catalyst::Plugin::MessageStack::VERSION = '0.03';
}

# ABSTRACT: A Catalyst plugin for gracefully handling messaging (and more) that follows the Post/Redirect/Get pattern.

use warnings;
use strict;

use Message::Stack;
use MRO::Compat;
use Scalar::Util 'blessed';


sub message {
    my ( $c, $message ) = @_;
    my $config = $c->config->{'Plugin::MessageStack'};
    my $default   = $config->{default_type} || 'success';
    my $stash_key = $config->{stash_key} || 'messages';

    if ( not defined $c->stash->{$stash_key} ) {
        if ( $config->{model} ) {
            $c->stash->{$stash_key} = $c->model($config->{model})->messages;
        } else {
            $c->stash->{$stash_key} = Message::Stack->new;
        }
    }
    elsif ( not blessed $c->stash->{$stash_key} and
            not $c->stash->{$stash_key}->isa('Message::Stack') )
    {
        $c->log->error("Unable to add messages into the stash, the stash has data at $stash_key already, and it isn't a Message::Stack");
        return;
    }
    my $stash = $c->stash->{$stash_key};

    return $stash unless $message;

    if ( blessed $message ) {
        $stash->add($message);
    } else {
        my $s = { scope => 'global' };
        if ( ref $message ) {
            $s->{level}   = $message->{type} || $default;
            $s->{id}      = $message->{message};
            $s->{scope}   = $message->{scope} || 'global';
            $s->{subject} = $message->{subject} if($message->{subject});
            $s->{params}  = $message->{params} if($message->{params});
        } else {
            $s->{level}   = $default;
            $s->{id}      = $message;
        }
        $stash->add($s);
    }

    $c->stash->{$stash_key} = $stash;

    return $stash;
}


sub has_messages {
    my ( $c, $scope ) = @_;

    my $stash_key = $c->config->{'Plugin::MessageStack'}->{stash_key} || 'messages';
    my $stack = $c->stash->{$stash_key};
    return 0 unless defined $stack;

    if ( $scope ) {
        return $stack->for_scope($scope)->has_messages;
    }
    return $stack->has_messages;
}

sub reset_messages {
    my ( $c, $scope ) = @_;

    my $stash_key = $c->config->{'Plugin::MessageStack'}->{stash_key} || 'messages';
    my $stack = $c->stash->{$stash_key};
    return 0 unless defined $stack;

    my $count = $stack->count;
    if ( $scope ) {
        $count = $stack->for_scope($scope)->count;
        $stack->reset_scope($scope);
    } else {
        $stack->reset;
    }
    return $count;

}

sub dispatch {
    my $c   = shift;

    my $config = $c->config->{'Plugin::MessageStack'};
    my $stash_key  = $config->{stash_key} || 'messages';
    my $flash_key  = $config->{flash_key} || '_messages';
    my $rflash_key = $config->{results_flash_key} || '_results';
    my $rstash_key = $config->{results_stash_key} || 'results';

    # Copy to the stash
    if ( $c->can('flash') and $c->flash->{$flash_key} ) {
        $c->stash->{$stash_key} = delete $c->flash->{$flash_key};
    }

    if ( $c->can('flash') and $c->flash->{$rflash_key} ) {
        $c->stash->{$rstash_key} = delete $c->flash->{$rflash_key};
    }


    my $ret = $c->next::method(@_);

    return $ret unless defined $c->res->location;

    # Redirect?
    
    my $messages = $c->stash->{$stash_key};

    # No messages in stash, but check if we have something in the Data::Manager
    # model.
    if ( not $messages and $config->{model} ) {
        $messages = $c->model($config->{model})->messages;
    }

    return $ret unless defined $messages;

    if ( $messages->has_messages and $c->response->location) {
        $c->flash->{$flash_key}    = $messages;
        $c->keep_flash($flash_key);
        if ( $config->{model} ) {
            $c->flash->{$rflash_key} ||= $c->model($config->{model})->results;
            $c->keep_flash($rflash_key);
        }
    }
    return $ret;
}

1;

__END__
=pod

=head1 NAME

Catalyst::Plugin::MessageStack - A Catalyst plugin for gracefully handling messaging (and more) that follows the Post/Redirect/Get pattern.

=head1 VERSION

version 0.03

=head1 DESCRIPTION

This plugin offers persistent messaging (requiring L<Catalyst::Plugin::Session>
or something with a compatible API, and preferably a model based on
L<Data::Manager>.

The messaging gracefully handles any redirects (so you can happily use the
recommended Post/Redirect/Get pattern. See
http://en.wikipedia.org/wiki/Post/Redirect/Get for more information.

The L<Message::Stack> is always accessible via the stash while the view is
rendered, regardless of redirects.

=head1 METHODS

=head2 message($message)

Add a new message to the stack.  The message can be a simple scalar value, which
is created as an informational type.  Alternatively, if you want a different
type attriute, simply call C<< $c->message >> in this form:

    $c->message({
        type    => 'error', # Corresponds to a message stack 'level'
        message => 'Your message string here'
    });

Called without any arguments, it simply returns the current message stack.

You can also pass in a L<Message::Stack::Message>

    $c->message(
        Message::Stack::Message->new(
            scope => 'some_scope', level => 'info',
            msgid => 'some msg id'
        )
    );

=head2 has_messages

Returns a true value if there are messages present in the stack. If you want
to limit by scope, pass in the scope and it checks that.

=head1 CONFIGURATION

For message storage, there are two configuration options: C<stash_key> and 
C<flash_key>.  This define the locations in the stash to place the messages.

To define the default type of message set the 'default_type' configuration key.

Use is very simple:

    $c->message('This is a message of the default type');
    $c->message({ type => 'error', message => 'This is an error message' });

Configuring is relatively straight forward, here are the defaults:

    package MyApp;

    use Catalyst qw/MessageStack/;

    __PACKAGE__->config({
        'Plugin::MessageStack' => {
            stash_key    => 'messages',
            flash_key    => '_message',
            default_type => 'warning',
            model        => 'DataManager', # optional, but will merge messages
        }
    });

=head1 INTEGRATION WITH DATA::MANAGER

L<Data::Manager> is an optional tool that this plugin plays well with. If you
have a Data::Manager model in your application, set the model configuration
key.

Then, the messages that happen between Data::Manager and your application are
unified and merged into the same stack.

Additionally, the results from Data::Manager are preserved so you can continue
the Post/Redirect/Get pattern.

What this allows is very simple controller actions that look like:

    sub handle_post : Local {
        my ( $self, $c ) = @_;

        # Always redirect, set it here.
        $c->res->redirect( $c->uri_for_action('/my/object') );

        my $results = $c->model('DataManager')
            ->verify('my_scope', $c->req->params);

        unless ( $results->success ) {
            $c->message({
                type => 'error',
                message => 'You made a mistake on the form, fix it!'
            });
            $c->detach; # Halt! Go no further.
        }

        # Pass the valid and vetted values to your model:
        $c->model('MyModel')->do_stuff({ $results->valid_values });
        $c->message('Everything went swimmingly. Rejoice!');
    }

If results fail and you integrate Data::Manager, the results are present as
well as messaging (defined by the scope, in the case above that is C<my_scope>).

Results are stored in the stash, keyed by scope. It looks something like this:

    $c->stash->{results} = {
        my_scope => Data::Verifier::Results->new(
                ... # results, the fields and what not ...
            )
    };

You have two distinct options in accessing the values. Either the originally
supplied values or the values after filtering, munging, coercion from
L<Data::Verifier>.  The two methods are listed below:

    $c->stash->{results}->{$scope}->get_original_value($field);
    $c->stash->{results}->{$scope}->get_value($field);

=head1 AUTHOR

J. Shirley <jshirley@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

