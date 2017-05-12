package CGI::Application::Plugin::MessageStack;

use CGI::Application 4.01;

use 5.006;
use warnings;
use strict;

=head1 NAME

CGI::Application::Plugin::MessageStack - A message stack for your CGI::Application

=head1 VERSION

Version 0.34

=cut

use vars qw( @ISA $VERSION @EXPORT %config );

@ISA = qw( Exporter AutoLoader );

@EXPORT = qw(
    push_message
    pop_message
    clear_messages
    messages
    capms_config
);

sub import {
    my $caller = scalar( caller );
    $caller->add_callback( 'load_tmpl' => \&_pass_in_messages );
    goto &Exporter::import;
}

$VERSION = '0.34';

=head1 SYNOPSIS

This plugin gives you a few support methods that you can call within your cgiapp
to pass along messages between requests for a given user.

 use CGI::Application::Plugin::Session;
 use CGI::Application::Plugin::MessageStack;

 sub mainpage {
   my $self = shift;
   my $template = $self->load_tmpl( 'mainpage.TMPL', 'die_on_bad_params' => 0 );
   # ...
   $template->output;
 }

 sub process {
   my $self = shift;
   $self->push_message(
       -scope          => 'mainpage',
       -message        => 'Your listing has been updated',
       -classification => 'INFO',
     );
   $self->forward( 'mainpage' );
 }

 sub cgiapp_init {
   # setup your session object as usual...
 }

Meanwhile, in your (HTML::Template) template code:

 ...
 <style type="text/css">
   .INFO {
     font-weight: bold;
   }
   .ERROR {
     color: red;
   }
 </style>
 ...
 <h1>Howdy!</h1>
 <!-- TMPL_LOOP NAME="CAP_Messages" -->
   <div class="<!-- TMPL_VAR NAME="classification" -->">
     <!-- TMPL_VAR NAME="message" -->
   </div>
 <!-- /TMPL_LOOP -->
 ...

It's a good idea to turn off 'die_on_bad_params' in HTML::Template - in case this plugin tries to put in the parameters and they're not available in your template.

Here's a quick TT example:

 <style type="text/css">
   .INFO {
     font-weight: bold;
   }
   .ERROR {
     color: red;
   }
 </style>
 ...
 <h1>Howdy!</h1>
 [% FOREACH CAP_Messages %]
    <div class="[% classification %]">[% message %]</div>
 [% END %]
 ...

If you use TT, I recommend using CAP-TT and a more recent version (0.09), which supports cgiapp's load_tmpl hook and then this plugin will automatically supply TT with the relevant messages.  Your runmode could be this simple:

 sub start {
     my $self = shift;
     my $session = $self->session;
     return $self->tt_process( 'output.tt' );
 }

I don't have the experience to weigh in on how you'd do this with other templates (HTDot, Petal), but basically, this plugin will put in a loop parameter called 'CAP_Messages'.  Within each element of that loop, you'll have two tags, 'classification' and 'message'.

NOTE: I have broken backwards compatibility with this release (0.30) and the loop parameter's default name is now 'CAP_Messages'.  If you used the old __CAP_Messages or want to use another name, feel free to use the capms_config to override the C<-loop_param_name>.

=head1 DESCRIPTION

This plugin by default needs a session object to tuck away the message(s).  It's recommended that you use this in conjunction with CGI::Application::Plugin::Session.  You can opt to not have the messages persist and thereby, not use CAP-Session by using the C<-dont_use_session> option in the C<capms_config> method.

This plugin hooks into cgiapp's load_tmpl method and if you've pushed any messages in the stack, will automatically add the message parameters.

In the functions, there are scope & classification keys and when they're used for either display or your API purposes (clearing, pop'ing, etc), the classification is an exclusive specification.  Meaning, if you ask for messages with the 'ERROR' classification, it will only deal with messages that you've pushed in with the 'ERROR' classification.  Any messages that have no classification aren't included.

The scope key is not exclusive, meaning that if you ask for messages with a 'mainpage' scope, it will deal with messages that you've pushed with that scope B<as well as> any messages that you've pushed in without a scope.

If you use both scope & classification, it blends both of those rules, first getting all matching messages with the same classification and then filtering out messages that are scoped and don't match the scope you're looking for.

This logic may change as I get feedback from more saavy developers.  What we may end up doing is have a plugin configuration where you can dictate the logic that's used.

=head1 FUNCTIONS

=head2 push_message

 $self->push_message(
     -scope          => 'mainpage',
     -message        => 'Your listing has been updated',
     -classification => 'INFO',
   );

You provide a hash to the push_message() method with three possible keys:

=over

=item * message - a text message.  You can put HTML in there - just make sure you don't use the ESCAPE=HTML in your HTML::Template code

=item * scope - which runmode(s) can this message appear?  If you want to specify just one, use a scalar assignment.  Otherwise, use an array reference with the list of runmodes.

=item * classification - a simple scalar name representing the classification of your message (i.e. 'ERROR', 'WARNING' ... ).  This is very useful for CSS styles (see template example above).

=back

The scope & classification keys are optional.  If you don't provide a scope, it will assume a global presence.

=cut

sub push_message {
    my $self = shift;
    my $session = _check_for_session( $self );
    my %message_hash = @_;
    if ( my $message_array = $session->param( '__CAP_MessageStack_Stack' ) ) {
        push @$message_array, \%message_hash;
        $session->param( '__CAP_MessageStack_Stack' => $message_array );
    } else {
        $session->param( '__CAP_MessageStack_Stack' => [ \%message_hash ] );
    }
}

=head2 messages

 my @messages = $self->messages();
 my @messages = $self->messages( -scope => 'mainpage' );
 my @messages = $self->messages( -scope => 'mainpage', -classification => 'ERROR' );
 my @messages = $self->messages( -classification => 'ERROR' );

If you want to take a gander at the message stack data structure, you can use this method.

Optionally, you can use a hash parameters to get a slice of the messages, using the same keys as specified in the push_message() method.

It will return an array reference of the matching messages or 'undef', if there's either no messages in the stack or no messages that match your specification(s).

=cut

sub messages {
    my $self = shift;
    my $session = _check_for_session( $self );
    my %limiting_params = @_;
    my $message_array = $session->param( '__CAP_MessageStack_Stack' ) || [];
    if ( $limiting_params{'-scope'} || $limiting_params{'-classification'} ) {
        $message_array = _filter_messages( $message_array, \%limiting_params )
    } else {
        # if the dev config'd different message or classification names, i need to do
        # 'em by hand here ... _filter_messages() would do that, but only if they
        # wanted a slice.  This is if they want everything.
        if ( my $class_key = $config{'-classification_param_name'} ) {
            map {
                    if ( $_->{'-classification'} ) {
                        $_->{$class_key} = $_->{'-classification'};
                        delete $_->{'-classification'};
                    }
                } @$message_array;
        }
        if ( my $message_key = $config{'-message_param_name'} ) {
            map {
                    if ( $_->{'-message'} ) {
                        $_->{$message_key} = $_->{'-message'};
                        delete $_->{'-message'};
                    }
                } @$message_array;
        }
    }

    return $message_array;
}

=head2 pop_message

 my $message = $self->pop_message();
 my $message = $self->pop_message( -scope => 'mainpage' );
 my $message = $self->pop_message( -scope => 'mainpage', -classification => 'WARNING' );
 my $message = $self->pop_message( -classification => 'ERROR' );

Pops off the last message from the stack and returns it.  Note that this just returns the -message part.

You can pop off an exact message, given a hash parameters, using the same keys as specified in the push_message() method.

Otherwise, it will pop off the message, given the current runmode and the last message added.

=cut

sub pop_message {
    my $self = shift;
    my $session = _check_for_session( $self );
    my %limiting_params = @_;
    my $message;
    my $message_array = $session->param( '__CAP_MessageStack_Stack' );

    if ( $config{'-dont_use_session'} ) {
        $session->param( '__CAP_MessageStack_Stack' => undef );
    } else {
        $session->clear( [ '__CAP_MessageStack_Stack' ] );
    }

    if ( $limiting_params{'-scope'} || $limiting_params{'-classification'} ) {
        my $index = scalar( @$message_array ) - 1;
        foreach my $message_hashref ( reverse @$message_array ) {
            # now we're looking for the first matching element ... if/when we find it,
            # set the $message and splice out the element from the $message_array
            my $match_found = 0;

            if ( $limiting_params{'-scope'} && $limiting_params{'-classification'} ) {
                if ( ( ! $message_hashref->{'-scope'} || ( ( ref( $message_hashref->{'-scope'} ) && grep { $_ eq $limiting_params{'-scope'} } @{$message_hashref->{'-scope'}}  ) || ( ! ref ( $message_hashref->{'-scope'} ) && $message_hashref->{'-scope'} eq $limiting_params{'-scope'} ) ) ) && ( $message_hashref->{'-classification'} && $message_hashref->{'-classification'} eq $limiting_params{'-classification'} ) ) {
                    $match_found = 1;
                    $message = $message_hashref->{'-message'};
                }
            } elsif ( $limiting_params{'-scope'} ) {
                if ( ! $message_hashref->{'-scope'} ) {
                    $match_found = 1;
                    $message = $message_hashref->{'-message'};
                } else {
		    if ( ref( $message_hashref->{'-scope'} ) ) {
		        if ( grep { $_ eq $limiting_params{'-scope'} } @{$message_hashref->{'-scope'}} ) {
			    $match_found = 1;
			    $message = $message_hashref->{'-message'};
			}
		    } else {
		        if ( $message_hashref->{'-scope'} eq $limiting_params{'-scope'} ) {
			    $match_found = 1;
			    $message = $message_hashref->{'-message'};
			}
		    }
		}
            } elsif ( $limiting_params{'-classification'} ) {
                if ( $message_hashref->{'-classification'} && $message_hashref->{'-classification'} eq $limiting_params{'-classification'} ) {
                    $match_found = 1;
                    $message = $message_hashref->{'-message'};
                }
            }

            if ( $match_found ) {
                splice( @$message_array, $index, 1 );
                last;
            }

            $index--;
        }
    } else {
        my $message_hashref = pop @$message_array;
        $message = $message_hashref->{'-message'};
    }

    $session->param( '__CAP_MessageStack_Stack' => $message_array );

    $message;
}

=head2 clear_messages

 $self->clear_messages();
 $self->clear_messages( -scope => 'mainpage' );
 $self->clear_messages( -scope => 'mainpage', -classification => 'ERROR' );
 $self->clear_messages( -classification => 'ERROR' );

Clears the message stack.

Optionally, you can clear particular slices of the message stack, given a hash parameters, using the same keys as specified in the push_message() method.

If you specify a scope, it will clear any messages that are either global or match that scope

If you specify a classification, it will clear any messages that have that classification (but not any messages that don't have any classification).

If you specify both, it will combine both that logic in an AND fashion.

=cut

sub clear_messages {
    my $self = shift;
    my $session = _check_for_session( $self );
    my %limiting_params = @_;
    if ( $limiting_params{'-scope'} || $limiting_params{'-classification'} ) {
        my $message_array = $session->param( '__CAP_MessageStack_Stack' );
        # can't use filter, b/c we need to invert that result...
        my $nonmatching_messages = [];
        if ( $limiting_params{'-classification'} && $limiting_params{'-scope'} ) {
            foreach my $message_hashref ( @$message_array ) {
                next if ( $message_hashref->{'-classification'} && $message_hashref->{'-classification'} eq $limiting_params{'-classification'} ) && ( !$message_hashref->{'-scope'} || ( ( ref( $message_hashref->{'-scope'} ) && grep { $_ eq $limiting_params{'-scope'} } @{$message_hashref->{'-scope'}} ) || ( ! ref( $message_hashref->{'-scope'} ) && $message_hashref->{'-scope'} eq $limiting_params{'-scope'} ) ) );
                push @$nonmatching_messages, $message_hashref;
            }
        } elsif ( $limiting_params{'-classification'} ) {
            foreach my $message_hashref ( @$message_array ) {
                next if $message_hashref->{'-classification'} && $message_hashref->{'-classification'} eq $limiting_params{'-classification'};
                push @$nonmatching_messages, $message_hashref;
            }
        } elsif ( $limiting_params{'-scope'} ) {
            foreach my $message_hashref ( @$message_array ) {
                next if ! $message_hashref->{'-scope'}; # taking out global scopes
		if ( ref( $message_hashref->{'-scope'} ) ) {
		    next if grep { $_ eq $limiting_params{'-scope'} } @{$message_hashref->{'-scope'}};
		} else {
                    next if $message_hashref->{'-scope'} eq $limiting_params{'-scope'}; # taking out matching scopes
		}
                push @$nonmatching_messages, $message_hashref;
            }
        }
        $session->param( '__CAP_MessageStack_Stack' => $nonmatching_messages );
    } else {
        if ( $config{'-dont_use_session'} ) {
            $session->param( '__CAP_MessageStack_Stack' => undef );
        } else {
            $session->clear( [ '__CAP_MessageStack_Stack' ] );
        }
    }
}

=head2 capms_config

 $self->capms_config(
     -automatic_clearing            => 1,
     -dont_use_session              => 1,
     -loop_param_name               => 'MyOwnLoopName',
     -message_param_name            => 'MyOwnMessageName',
     -classification_param_name     => 'MyOwnClassificationName',
   );

There is a configuration option that you, as the developer can specify:

=over

=item * -automatic_clearing: By default, this is turned off.  If you override it with a true value, it will call clear_messages() automatically after the messages are automatically put into template.

=item * -dont_use_session: This will override this Plugin's dependence on CGI::Application::Plugin::Session and instead, temporarily store the message data such that it will be available to templates within the same web request, but no further.  If you're running your cgiapp under a persistent state (mod_perl), we'll also make sure your messages are gone by the end of the request.

=item * -loop_param_name: This will override the default __CAP_Messages (or CAP_Messages for TT users) name for the loop of messages, which is only used for the C<load_tmpl> callback.  Meaning, this configuration will only impact your template code.  So if you use the 'MyOwnLoopName' above, then your template code (for HTML::Template users) should look like:

 <!-- TMPL_LOOP NAME="MyOwnLoopName" -->
 ...
 <!-- /TMPL_LOOP -->

=item * -message_param_name: This will override the default '-message' in both the template code B<as well as> the keys in each hashref of the arrayref that's returned by the messages() function.  So a call to messages() may return:

 [ { 'MyOwnMessageName' => 'this is just a test' }, ... ]

instead of:

 [ { '-message' => 'this is just a test' }, ... ]

Likewise, your templates will need to use your parameter name:

 <!-- TMPL_LOOP NAME="MyOwnLoopName" -->
   Here's the message: <!-- TMPL_VAR NAME="MyOwnMessageName" -->
 <!-- /TMPL_LOOP -->

=item * -classification_param_name: Just like the C<-message_param_name> parameter - this will override the default '-classification' key in both the template code B<as well as> the keys in each hashref of the arrayref that's returned by the messages() function.  So a call to messages() may return:

 [ { 'MyOwnClassificationName' => 'ERROR', 'MyOwnMessageName' => 'this is just a test' }, ... ]

instead of:

 [ { '-classification' => 'ERROR', '-message' => 'this is just a test' }, ... ]

Likewise, your templates will need to use your parameter name:

 <!-- TMPL_LOOP NAME="MyOwnLoopName" -->
    <div class="<!-- TMPL_VAR NAME="MyOwnClassificationName" -->">
       Here's the message: <!-- TMPL_VAR NAME="MyOwnMessageName" -->
    </div>
 <!-- /TMPL_LOOP -->

=back

=cut

sub capms_config {
    my $self = shift;
    %config = @_;
}

sub _filter_messages {
    my ( $messages, $limiting_params, $for_template ) = @_;

    my $matching_messages = [];
    my $class_key = $config{'-classification_param_name'} || 'classification';
    my $message_key = $config{'-message_param_name'} || 'message';

    if ( $limiting_params->{'-classification'} && $limiting_params->{'-scope'} ) {
        foreach my $message_hashref ( @$messages ) {
            next if !$message_hashref->{'-classification'} || $message_hashref->{'-classification'} ne $limiting_params->{'-classification'};
	    if ( ref( $message_hashref->{'-scope'} ) ) {
	        next if ! grep { $_ eq $limiting_params->{'-scope'} } @{$message_hashref->{'-scope'}};
	    } else {
                next if $message_hashref->{'-scope'} && $message_hashref->{'-scope'} ne $limiting_params->{'-scope'};
            }
            # i'm beginning to hate the dash now ... now i have to take 'em out
            # so the template code doesn't need/use 'em...
            if ( $for_template ) {
                push @$matching_messages, {
                        $class_key    => $message_hashref->{'-classification'},
                        $message_key  => $message_hashref->{'-message'},
                    };
            } else {
                push @$matching_messages, $message_hashref;
            }
        }
    } elsif ( $limiting_params->{'-classification'} ) {
        foreach my $message_hashref ( @$messages ) {
            next if !$message_hashref->{'-classification'} || $message_hashref->{'-classification'} ne $limiting_params->{'-classification'};
            if ( $for_template ) {
                push @$matching_messages, {
                        $class_key      => $message_hashref->{'-classification'},
                        $message_key    => $message_hashref->{'-message'},
                    };
            } else {
                push @$matching_messages, $message_hashref;
            }
        }
    } elsif ( $limiting_params->{'-scope'} ) {
        foreach my $message_hashref ( @$messages ) {
	    if ( ref( $message_hashref->{'-scope'} ) ) {
	        next if ! grep { $_ eq $limiting_params->{'-scope'} } @{$message_hashref->{'-scope'}};
	    } else {
                next if $message_hashref->{'-scope'} && $message_hashref->{'-scope'} ne $limiting_params->{'-scope'};
            }
            if ( $for_template ) {
                push @$matching_messages, {
                        $class_key    => $message_hashref->{'-classification'},
                        $message_key  => $message_hashref->{'-message'},
                    };
            } else {
                push @$matching_messages, $message_hashref;
            }
        }
    }

    return $matching_messages;
}

sub _pass_in_messages {
    my ( $self, undef, $tmpl_params, undef ) = @_;

    # get the proper messages and update $tmpl_params
    my $session = _check_for_session( $self );
    my $current_runmode = $self->get_current_runmode();
    my $message_stack = $session->param( '__CAP_MessageStack_Stack' );
    my $messages = _filter_messages( $message_stack, { -scope => $current_runmode }, 1 );
    my $loop_name = $config{'-loop_param_name'} || 'CAP_Messages';

    $tmpl_params->{ $loop_name } = $messages if scalar( @$messages );
    $self->clear_messages( -scope => $current_runmode ) if ( $config{'-automatic_clearing'} );
}

# This method will return an object, depending on if the developer wants to
# use a session (the default behavior) or just the cgiapp itself.
sub _check_for_session {
    my $self = shift;
    my $session_object = undef;

    if ( $config{'-dont_use_session'} ) {
        $session_object = $self;
    } else {
        # dynamic importing of CAP-Session
        eval {
            require CGI::Application::Plugin::Session;
            CGI::Application::Plugin::Session->import();
            $session_object = $self->session;
        };
        if ( $@ || ! $session_object ) {
            die "No session object!  This module depends on CGI::Application::Plugin::Session! (or you need to use the -dont_use_session config parameter)"
        }
    }
    return $session_object;
}

=head1 AUTHOR

Jason Purdy, C<< <Jason@Purdy.INFO> >>

=head1 SEE ALSO

L<CGI::Application> and L<CGI::Application::Plugin::Session>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-messagestack@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-MessageStack>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

I suspect that this code could use some expert guidance.  I hacked it together and I'd hate to think that it would be responsible for slowing templates down.  Please feel free to submit patches, guiding comments, etc.

=head1 ACKNOWLEDGEMENTS

Thanks to the guys on the #cgiapp channel

=head1 COPYRIGHT & LICENSE

Copyright 2005 Jason Purdy, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of CGI::Application::Plugin::MessageStack

__END__
