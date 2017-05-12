package App::TracksBot;

use strict;
use warnings;
use feature 'say';
use feature 'switch';

use AnyEvent::WebService::Tracks;
use AnyEvent::XMPP::IM::Connection;
use AnyEvent::XMPP::Util qw(bare_jid);
use List::MoreUtils qw(first_value);
use YAML qw(LoadFile);

our $VERSION = '0.01';

my $tracks;
my $default_context;
my %whitelist;

sub setup_xmpp {
    my ( $config ) = @_;

    $config = $config->{'xmpp'};
    my %params;

    if(delete $config->{'google_talk'}) {
        $params{'domain'}        = 'gmail.com';
        $params{'host'}          = 'talk.google.com';
        $params{'old_style_ssl'} = 1;
        $params{'port'}          = 5223;
    }
    @params{keys %$config} = values %$config;

    return AnyEvent::XMPP::IM::Connection->new(%params);
}

sub setup_tracks {
    my ( $config ) = @_;

    $config = $config->{'tracks'};

    return AnyEvent::WebService::Tracks->new(%$config);
}

sub handle_error {
    my ( undef, $error ) = @_;

    say $error->string;
}

sub send_reply {
    my ( $msg, $body ) = @_;

    my $reply = $msg->make_reply;
    $reply->type('chat');
    $reply->add_body($body);
    $reply->send;
}

sub get_help {
    return <<HELP;

add              - Create a new todo item.
create context   - Create a new context.
create project   - Create a new project.
create todo      - Create a new todo item.
contexts         - List available contexts.
help             - Display this help.
projects         - List available projects.
todos            - List available todos.
todos in context - Lists todos in the given context.
todos in project - Lists todos in the given project.
HELP
}

sub create_todo {
    my ( $msg, $tracks, $description ) = @_;

    $tracks->create_todo($description, $default_context, sub {
        my ( $todo, $error ) = @_;

        if($todo) {
            send_reply($msg, "Created a new todo '$description' as todo #" . $todo->id);
        } else {
            send_reply($msg, "An error occurred when creating a new todo: $error");
        }
    });
}

sub create_context {
    my ( $msg, $tracks, $name ) = @_;

    $tracks->create_context($name, sub {
        my ( $context, $error ) = @_;

        if($context) {
            send_reply($msg, "Created a new context '$name' as context #" . $context->id);
        } else {
            send_reply($msg, "An error occurred when creating a new context: $error");
        }
    });
}

sub create_project {
    my ( $msg, $tracks, $name ) = @_;

    $tracks->create_project($name, sub {
        my ( $project, $error ) = @_;

        if($project) {
            send_reply($msg, "Created a new project '$name' as project #" . $project->id);
        } else {
            send_reply($msg, "An error occurred when creating a new project $error");
        }
    });
}

sub show_contexts {
    my ( $msg, $tracks ) = @_;

    $tracks->contexts(sub {
        my ( $contexts, $error ) = @_;

        if($contexts) {
            if(@$contexts) {
                send_reply($msg, join('', map { "\n" . $_->name } @$contexts));
            } else {
                send_reply($msg, 'No contexts');
            }
        } else {
            send_reply($msg, "An error occurred when fetching the list of contexts: $error");
        }
    });
}

sub show_projects {
    my ( $msg, $tracks ) = @_;

    $tracks->projects(sub {
        my ( $projects, $error ) = @_;

        if($projects) {
            if(@$projects) {
                send_reply($msg, join('', map { "\n" . $_->name } @$projects));
            } else {
                send_reply($msg, 'No projects');
            }
        } else {
            send_reply($msg, "An error occurred when fetching the list of projects: $error");
        }
    });
}

sub show_todos {
    my ( $msg, $tracks ) = @_;

    $tracks->todos(sub {
        my ( $todos, $error ) = @_;

        if($todos) {
            if(@$todos) {
                send_reply($msg, join('', map { "\n" . $_->description } @$todos));
            } else {
                send_reply($msg, 'No todos');
            }
        } else {
            send_reply($msg, "An error occurred when fetching the list of todos $error");
        }
    });
}

sub show_todos_in_context {
    my ( $msg, $tracks, $name ) = @_;

    $tracks->contexts(sub {
        my ( $contexts, $error ) = @_;

        if($contexts) {
            my $context = first_value { $_->name eq $name } @$contexts;

            if($context) {
                $context->todos(sub {
                    my ( $todos, $error ) = @_;

                    if($todos) {
                        if(@$todos) {
                            send_reply($msg, join('', map { "\n" . $_->description } @$todos));
                        } else {
                            send_reply($msg, "No todos in context '$name'");
                        }
                    } else {
                        send_reply($msg, "An error occurred when fetching the list of todos: $error");
                    }
                });
            } else {
                send_reply($msg, "There is no context named '$name'");
            }
        } else {
            send_reply($msg, "An error occurred when fetching the list of contexts: $error");
        }
    });
}

sub show_todos_in_project {
    my ( $msg, $tracks, $name ) = @_;

    $tracks->projects(sub {
        my ( $projects, $error ) = @_;

        if($projects) {
            my $project = first_value { $_->name eq $name } @$projects;

            if($project) {
                $project->todos(sub {
                    my ( $todos, $error ) = @_;

                    if($todos) {
                        if(@$todos) {
                            send_reply($msg, join('', map { "\n" . $_->description } @$todos));
                        } else {
                            send_reply($msg, "No todos in project '$name'");
                        }
                    } else {
                        send_reply($msg, "An error occurred when fetching the list of todos: $error");
                    }
                });
            } else {
                send_reply($msg, "There is no project named '$name'");
            }
        } else {
            send_reply($msg, "An error occurred when fetching the list of projects: $error");
        }
    });
}

sub dispatch_body {
    my ( $msg, $body ) = @_;

    given($body) {
        when(/^add\s+(?<description>.*)\s*$/) {
            create_todo($msg, $tracks, $+{'description'});
        }
        when(/^create\s+context\s+(?<name>.*)\s*$/) {
            create_context($msg, $tracks, $+{'name'});
        }
        when(/^create\s+project\s+(?<name>.*)\s*$/) {
            create_project($msg, $tracks, $+{'name'});
        }
        when(/^create\s+todo\s+(?<description>.*)\s*$/) {
            create_todo($msg, $tracks, $+{'description'});
        }
        when('contexts') {
            show_contexts($msg, $tracks);
        }
        when('help') {
            send_reply($msg, get_help);
        }
        when('projects') {
            show_projects($msg, $tracks);
        }
        when('todos') {
            show_todos($msg, $tracks);
        }
        when(/^todos\s+in\s+context\s+(?<name>.*)\s*$/) {
            show_todos_in_context($msg, $tracks, $+{'name'});
        }
        when(/^todos\s+in\s+project\s+(?<name>.*)\s*$/) {
            show_todos_in_project($msg, $tracks, $+{'name'});
        }
        default {
            send_reply($msg, "I don't understand; try 'help'");
        }
    }
}

sub handle_message {
    my ( undef, $msg ) = @_;

    my $from = bare_jid($msg->from);
    my $body = $msg->body;

    return unless $body;
    unless(exists $whitelist{$from}) {
        send_reply($msg, "I'm not supposed to talk to strangers!");
        return;
    }

    dispatch_body($msg, $body);
}

sub run {
    shift;
    die "usage: $0 [config file]\n" unless @_;

    my ( $config ) = @_;
    $config    = LoadFile($config);
    my $conn   = setup_xmpp($config);
    %whitelist = map { $_ => 1 } @{ $config->{'whitelist'} };
    $tracks    = setup_tracks($config);
    my $cond   = AnyEvent->condvar;

    $conn->reg_cb(
        error   => \&handle_error,
        message => \&handle_message,
    );

    $tracks->contexts(sub {
        my ( $contexts, $error ) = @_;

        my $name = $config->{'tracks'}{'default_context'};
        die "No default context specified\n" unless defined $name;

        if($contexts) {
            $default_context = first_value { $_->name eq $name } @$contexts;
            die "Default context '$name' not found\n" unless $default_context;
            $conn->connect;
        } else {
            die "An error occurred: $error\n";
        }
    });

    $cond->recv;
}

1;

__END__

=head1 NAME

App::TracksBot - An XMPP-based chatbot for interacting with a Tracks
installation

=head1 VERSION

0.01

=head1 SYNOPSIS

  use App::TracksBot;

  App::TracksBot->run($yaml_file_name);

=head1 DESCRIPTION

This module provides the logic behind the tracks-bot program.

=head1 METHODS

=head2 App::TracksBot->run($config_file)

Runs the bot, using configuration provided by C<$config_file>.
C<$config_file> must use the YAML format.

=head1 CONFIGURATION

Tracks-bot is configured using a single YAML configuration file (a sample can
be found in the module distribution, under tracks-bot-sample.yaml).  The
configuration consists of several sections:

=head2 xmpp

The xmpp section contains configuration for the XMPP connection.  All
attributes are passed as-is into AnyEvent::XMPP::IM::Connection->new.
If the boolean attribute 'google_talk' is provided and true, several
attributes are added to automatically connect to Google Talk, so if you
provide this attribute, you'll probably only need to provide your username
and password as well.

=head2 whitelist

The whitelist section is a list of bare JIDS that are allowed to talk to your
chatbot.

=head2 tracks

The tracks section contains configuration for the Tracks connection.  All
attributes are passed as-is into AnyEvent::WebService::Tracks->new, except
for the default_context attribute, which is the name of the context that
todos created with the chatbot should go into.

=head1 AUTHOR

Rob Hoelz, C<< rob at hoelz.ro >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-App-TracksBot at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-TracksBot>. I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2011 Rob Hoelz.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<http://getontracks.org>,
L<tracks-bot>,
L<AnyEvent::WebService::Tracks>,
L<AnyEvent::XMPP>

=begin comment

=over

=item create_context
=item create_project
=item create_todo
=item dispatch_body
=item get_help
=item handle_error
=item handle_message
=item send_reply
=item setup_tracks
=item setup_xmpp
=item show_contexts
=item show_projects
=item show_todos
=item show_todos_in_context
=item show_todos_in_project

=back

=end comment

=cut
