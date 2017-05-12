package Chouette;

use common::sense;

use EV;
use AnyEvent;
use AnyEvent::Util;
use AnyEvent::Task::Client;
use AnyEvent::Task::Server;
use Feersum;
use Callback::Frame;
use Log::File::Rolling;
use Cwd;
use Regexp::Assemble;
use Session::Token;
use Data::Dumper;

use Chouette::Context;

our $VERSION = '0.102';



sub new {
    my ($class, $app_spec) = @_;

    my $self = {
        app_spec => $app_spec,
    };
    bless $self, $class;

    my $config = {};

    if ($app_spec->{config_file}) {
        require YAML;
        $config = YAML::LoadFile($app_spec->{config_file});
    }

    $self->{config} = {
        %{ $app_spec->{config_defaults} },
        %$config,
    };

    $self->{quiet} = $app_spec->{quiet};

    $self->_validate_config();

    $self->_compile_app();

    $self->{_done_gensym} = \'';

    return $self;
}




sub _validate_config {
    my ($self) = @_;

    die "var_dir $self->{config}->{var_dir} is not a directory" if !-e $self->{config}->{var_dir};
}


sub _compile_app {
    my ($self) = @_;

    ## Middleware

    foreach my $middleware_spec (@{ $self->{app_spec}->{middleware} }) {
        $middleware_spec = [ $middleware_spec ] if !ref($middleware_spec);
        $middleware_spec = [ @$middleware_spec ]; ## copy so don't destroy app_spec version

        my $pkg = $middleware_spec->[0];

        if ($pkg =~ m{^Plack::Middleware::}) {
            eval "require $pkg" || die "Couldn't require middleware $pkg\n\n$@";
        } else {
            if (!eval "require $pkg") {
                my $new_pkg = "Plack::Middleware::" . $pkg;
                eval "require $new_pkg" || die "Couldn't require middleware $pkg (or $new_pkg)";
                $middleware_spec->[0] = $new_pkg;
            }
        }

        push @{ $self->{middleware_specs} }, $middleware_spec;
    }


    ## Pre-route wrappers

    if (defined $self->{app_spec}->{pre_route}) {
        $self->{pre_route_cb} = $self->_load_function($self->{app_spec}->{pre_route}, "pre-route");
    }


    ## Routes

    $self->{route_regexp_assemble} = Regexp::Assemble->new->track(1);
    $self->{route_patterns} = {};

    my $routes = $self->{app_spec}->{routes};

    foreach my $route (keys %$routes) {
        my $re = '\A' . $route . '\z';

        $re =~ s{/}{\\/}g; ## Hack for Regexp::Assemble: https://github.com/ronsavage/Regexp-Assemble/issues/4

        $re =~ s{:([\w]+)}{(?<$1>[^/]+)};

        $self->{route_regexp_assemble}->add($re);

        my $methods = {};

        foreach my $method (keys %{ $routes->{$route} }) {
            $methods->{$method} = $self->_load_function($routes->{$route}->{$method}, "route: $method $route");
        }

        $self->{route_patterns}->{$re} = $methods;
    }

    $self->{route_regexp} = $self->{route_regexp_assemble}->re;


    ## Tasks

    foreach my $task_name (keys %{ $self->{app_spec}->{tasks} }) {
        die "invalid task name: $task_name" if $task_name !~ /\A\w+\z/;

        my $task = $self->{app_spec}->{tasks}->{$task_name};
        my $pkg = $task->{pkg};

        eval "require $pkg" || die "Couldn't require task package $pkg (required for task $task_name)\n\n$@";
        die "Couldn't find function new in $pkg (needed task $task_name)" if !defined &{ "${pkg}::new" };
    }
}



sub _load_function {
    my ($self, $spec, $needed_for) = @_;

    $needed_for = "(needed for $needed_for)" if defined $needed_for;

    if (ref $spec eq 'CODE') {
        return $spec;
    } elsif ($spec =~ /^(.*)::([^:]+)$/) {
        my ($pkg, $func_name) = ($1, $2);
        eval "require $pkg" || die "Couldn't require $pkg $needed_for\n\n$@";
        die "Couldn't find function $func_name in $pkg $needed_for" if !defined &{ "${pkg}::${func_name}" };
        my $func = \&{ "${pkg}::${func_name}" };
        return $func;
    } else {
        die "couldn't parse function: '$spec'";
    }
}



sub _listen {
    my ($self) = @_;

    my $listen = $self->{config}->{listen};

    my $socket;

    if ($listen =~ m{^unix:(.*)}) {
        my $socket_file = $1;

        require IO::Socket::UNIX;

        unlink($socket_file);

        $socket = IO::Socket::UNIX->new(
            Listen => 5,
            Type => IO::Socket::SOCK_STREAM(),
            Local => $socket_file,
        ) || die "unable to listen on $listen : $!";

        $self->{_friendly_socket_desc} = "http://[unix:$socket_file]";
    } else {
        my $local_addr = '0.0.0.0';
        my $port;

        if ($listen =~ m{^(.*):(\d+)$}) {
            $local_addr = $1;
            $port = $2;
        } elsif ($listen =~ m{^(\d+)$}) {
            $port = $1;
        } else {
            die "unable to parse listen param: '$listen'";
        }

        require IO::Socket::INET;

        $socket = IO::Socket::INET->new(
            Listen => 5,
            Proto => 'tcp',
            LocalAddr => $local_addr,
            LocalPort => $port,
            ReuseAddr => 1,
        ) || die "unable to listen on $listen : $!";

        $self->{_friendly_socket_desc} = "http://$local_addr:$port";
    }

    AnyEvent::Util::fh_nonblocking($socket, 1);

    $self->{accept_socket} = $socket;
}

sub _logging {
    my ($self) = @_;

    my $log_dir = "$self->{config}->{var_dir}/logs";

    if (!-e $log_dir) {
        mkdir($log_dir) || die "couldn't mkdir($log_dir): $!";
    }

    $log_dir = Cwd::abs_path($log_dir);

    my $app_name = $self->{config}->{logging}->{file_prefix} // 'app';

    my $curr_symlink = "$log_dir/$app_name.current.log";

    $self->{raw_logger} = Log::File::Rolling->new(
                              filename => "$log_dir/$app_name.%Y-%m-%dT%H.log",
                              current_symlink => $curr_symlink,
                              timezone => ($self->{config}->{logging}->{timezone} // 'gmtime'),
                          ) || die "Error creating Log::File::Rolling logger: $!";

    $self->{_friendly_current_logfile} = $curr_symlink;
}


sub _start_task_servers {
    my ($self) = @_;

    my $task_dir = "$self->{config}->{var_dir}/tasks";

    if ($self->{app_spec}->{tasks}) {
        if (!-e $task_dir) {
            mkdir($task_dir) || die "couldn't mkdir($task_dir): $!";
        }
    }

    foreach my $task_name (keys %{ $self->{app_spec}->{tasks} }) {
        my $task = $self->{app_spec}->{tasks}->{$task_name};
        my $pkg = $task->{pkg};

        my $obj;

        my $constructor_func = \&{ "${pkg}::new" };

        my $checkout_done;
        $checkout_done = \&{ "${pkg}::CHECKOUT_DONE" } if defined &{ "${pkg}::CHECKOUT_DONE" };

        AnyEvent::Task::Server::fork_task_server(
            name => $task_name,

            listen => ['unix/', "$task_dir/$task_name.socket"],

            setup => sub {
                $obj = $constructor_func->($pkg, $self->{config});
            },

            interface => sub {
                my ($method, @args) = @_;
                $obj->$method(@args);
            },

            $checkout_done ? (
                checkout_done => sub {
                    $checkout_done->($obj);
                },
            ) : (),

            %{ $task->{server} },
        );
    }
}


sub _start_task_clients {
    my ($self) = @_;

    my $task_dir = "$self->{config}->{var_dir}/tasks";

    foreach my $task_name (keys %{ $self->{app_spec}->{tasks} }) {
        my $task = $self->{app_spec}->{tasks}->{$task_name};

        $self->{task_clients}->{$task_name} = AnyEvent::Task::Client->new(
            connect => ['unix/', "$task_dir/$task_name.socket"],
            %{ $task->{client} },
        );

        $self->{task_checkout_caching}->{$task_name} = 1 if $self->{app_spec}->{tasks}->{$task_name}->{checkout_caching};
    }
}



sub serve {
    my ($self) = @_;

    $self->{_serving} = 1;

    $self->_start_task_servers();
    $self->_start_task_clients();
    $self->_listen();
    $self->_logging();

    $self->{feersum} = Feersum->endjinn;
    $self->{feersum}->use_socket($self->{accept_socket});

    my $app = sub {
        my $env = shift;

        return sub {
            my $responder = shift;

            my $c = Chouette::Context->new(
                        chouette => $self,
                        env => $env,
                        responder => $responder,
                    );

            $self->_handle_request($c);
        };
    };

    foreach my $middleware_spec (@{ $self->{middleware_specs} }) {
        my @s = @$middleware_spec;
        my $pkg = shift(@s);
        $app = $pkg->wrap($app, @s);
    }

    $self->{feersum}->psgi_request_handler($app);

    return if $self->{quiet};

    say "="x79;
    say;
    say "Chouette $VERSION";
    say;
    say "PID = $$";
    say "UID/GIDs = $</$(";
    say "Listening on: $self->{_friendly_socket_desc}";
    say;
    say "Follow log messages:";
    say "    log-defer-viz -F $self->{_friendly_current_logfile}";
    say;
    say "="x79;
}


sub run {
    my ($self) = @_;

    $self->serve unless $self->{_serving};

    AE::cv->recv;
}


sub _handle_request {
    my ($self, $c) = @_;

    my $req = $c->req;
    $c->logger->info("Request from " . $req->address . " : " . $req->method . " " . $req->path);

    frame_try {
        if ($self->{pre_route_cb}) {
            my $pre_route_cb = fub { $self->{pre_route_cb}->(@_) };
            $pre_route_cb->($c, fub { $self->_do_routing($c) });
        } else {
            $self->_do_routing($c);
        }
    } frame_catch {
        my $err = $@;

        return if ref($err) && ($err + 0 == $c->{chouette}->{_done_gensym} + 0);

        if ($err =~ /^(\d\d\d)\b(?:\s*:\s*)?(.*)/) {
            my $status = $1;
            my $msg = $2;

            my $body = {};

            if ($status < 200 || $status >= 400) {
                $c->logger->warn("threw $err");
                if (length($msg)) {
                    $msg =~ s/ at \S+ line \d+\.$//;
                    $body->{error} = $msg;
                } else {
                    $msg = "HTTP code $status";
                }
            } else {
                $msg =~ s/ at \S+ line \d+\.$//;
                $body->{ok} = $msg;
            }

            $c->respond($body, $status);
            return;
        }

        $c->logger->error($err);
        $c->logger->data->{stacktrace} = $_[0];

        $c->respond({ error => 'internal server error' }, 500);
    };
}


sub _do_routing {
    my ($self, $c) = @_;

    my $path = $c->{env}->{PATH_INFO};
    $path = '/' if $path eq '';

    die "404: Not Found" unless $path =~ $self->{route_regexp};

    my $route_params = \%+;

    my $methods = $self->{route_patterns}->{ $self->{route_regexp_assemble}->source($^R) };

    my $method = $c->{env}->{REQUEST_METHOD};

    my $func = $methods->{$method};

    die "405: Method Not Allowed" if !$func;

    $c->{route_params} = $route_params;

    $func->($c);
}



sub generate_token {
    state $generator = Session::Token->new;

    return $generator->get;
}

1;



__END__

=encoding utf-8

=head1 NAME

Chouette - REST API Framework

=head1 DESCRIPTION

L<Chouette> is a framework for making asynchronous HTTP services. It makes some opinionated design choices, but is otherwise fairly flexible.

L<AnyEvent> is used as the glue to connect all the asynchronous libraries, although Chouette depends on L<Feersum> and therefore L<EV> for its event loop. It uses L<Feersum> in PSGI mode so it can use L<Plack> for request parsing, and has support for L<Plack::Middleware> wrappers. L<Feersum> is the least conservative choice in the stack but there aren't very many alternatives (L<Twiggy> is a possibility but it is somewhat buggy and you need a hack to use unix sockets).

Chouette generally assumes that its input will be C<application/x-www-form-urlencoded>. L<Plack::Request::WithEncoding> is used so that text is properly decoded (we recommend UTF-8 of course). For output, the default is C<application/json> encoded with L<JSON::XS>. Both the input and output types can be modified, although this is only partially documented so far.

Chouette apps can optionally load a config file and its format is C<YAML>, loaded with the L<YAML> module. L<Regexp::Assemble> is used for efficient route-dispatch.

The above aside, Chouette's main purpose is to glue together several of my own modules into a cohesive whole. These modules have been designed to work together and I have used them to build numerous services, some of which handle a considerable amount of traffic and/or have very complicated requirements.

Chouette was extracted from some of these services I have built before, and I have put in the extra effort required so that all the modules work together in the ways they were designed:

=over

=item L<AnyEvent::Task>

Allows us to perform blocking operations without holding up other requests.

=item L<Callback::Frame>

Makes exception handling simple and convenient. You can C<die> anywhere and it will only affect the request being currently handled.

Important note: If you are using 3rd-party libraries that accept callbacks, please understand how L<Callback::Frame> works. You will usually need to pass C<fub {}> instead of C<sub {}> to these libraries. See the L<EXCEPTIONS> section for more details.

=item L<Session::Token>

For random identifiers such as session tokens (obviously).

=item L<Log::Defer>

Structured logging, properly integrated with L<AnyEvent::Task> so your tasks can log messages into the proper request log contexts.

Note that Chouette also depends on L<Log::Defer::Viz> so C<log-defer-viz> will be available for viewing logs.

=item L<Log::File::Rolling>

Store logs in files and rotate them periodically. Also maintains a current symlink so you can simply run the following in a shell and you'll always see the latest logs as you need them:

    $ log-defer-viz -F /var/myapi/logs/myapi.current.log

=back

Chouette will always depend on L<AnyEvent::Task>, L<Callback::Frame>, L<Session::Token>, and L<Log::Defer> so if your app also uses these modules then it is sufficient to depend on C<Chouette> alone.

Where does the name "Chouette" come from? A L<chouette|http://www.bkgm.com/variants/Chouette.html> is a multi-player, fast-paced backgammon game with lots of stuff going on at once, kind of like an asynchronous REST API server... Hmmm, a bit of a stretch isn't it? To be honest it's just a cool name and I love backgammon, especially chouettes with friends and beer. :)


=head1 CHOUETTE OBJECT

To start a server, create a C<Chouette> object. The constructor accepts a hash ref with the following parameters. Most are optional. See the C<bin/myapi> file below for a full example.

=over

=item C<config_defaults>

This hash is where you provide default config values. These values can be overridden by the config file.

You can use the config store for values specific to your application (it is accessible with the C<config> method of the context), but here are the values that C<Chouette> itself looks for:

C<var_dir> - This directory must exist and be writable. C<Chouette> will use this to store log files and L<AnyEvent::Task> sockets.

C<listen> - This is the location the Chouette server will listen on. Examples: C<8080> C<127.0.0.1:8080> C<unix:/var/myapi/myapi.socket>

C<logging.file_prefix> - The prefix for log file names (default is C<app>).

C<logging.timezone> - Either C<gmtime> or C<localtime> (C<gmtime> is default, see L<Log::File::Rolling>).

The only required config parameters are C<var_dir> and C<listen> (though these can be omitted from the defaults assuming they will be specified in the config file, see below).

=item C<config_file>

If you want a config file, this path is where it will be read from. The file's format is L<YAML>. The values in this file over-ride the values in C<config_defaults>. If this parameter is not provided then it will not attempt to load a config file and defaults will be used.

=item C<routes>

Routes are specified as a hash-ref of route paths, mapping to hash-refs of methods, mapping to package+function names or callbacks. For example:

    routes => {
        '/myapi/resource' => {
            POST => 'MyAPI::Resource::create',
            GET => 'MyAPI::Resource::get_all',
        },

        '/myapi/resource/:resource_id' => {
            GET => 'MyAPI::Resource::get_by_id',
            POST => sub {
                my $c = shift;
                die "400: can't update ID " . $c->route_params->{resource_id};
            },
        },

        '/myapi/upload' => {
            PUT => 'MyAPI::Upload::upload',
        }
    },

For each route, if a package+function name is used it will try to C<require> the package specified, and obtain the function specified for each HTTP method. If the package or function doesn't exists, an error will be thrown.

You can use C<:param> path elements in your routes to extract parameters from the path. They are accessible via the C<route_params> method of the context (see C<lib/MyAPI/Resource.pm> below).

Note that routes are combined with L<Regexp::Assemble> so we don't have to loop over every possible route for every request, in case you have a lot of routes. For example, here is the regexp used for the above routes:

    \A/myapi/(?:resource(?:/(?<resource_id>[^/]+)\z(?{2})|\z(?{1}))|upload\z(?{0}))

See the C<bin/myapi> file below for an example.

=item C<pre_route>

A package+function or callback that will be called with a context and a resume callback. If the function determines the request processing should continue, it should call the resume callback.

See the C<lib/MyAPI/Auth.pm> file below for an example of the function.

=item C<middleware>

Any array-ref of L<Plack::Middleware> packages. Each element is either a string representing a package+function, or an array-ref where the first element is the package+function and the rest of the elements are the arguments to the middleware.

The strings representing packages can either be prefixed with C<Plack::Middleware::> or not. If not, it will try to C<require> the package as is and if that doesn't exist, it will try again with the C<Plack::Middleware::> prefix.

    middleware => [
        'Plack::Middleware::ContentLength',
        'ETag',
        ['Plack::Middleware::CrossOrigin', origins => '*'],
    ],

=item C<tasks>

This is a hash-ref of L<AnyEvent::Task> servers/clients to create.

    tasks => {
        db => {
            pkg => 'LPAPI::Task::DB',
            checkout_caching => 1,
            client => {
                timeout => 20,
            },
            server => {
                hung_worker_timeout => 60,
            },
        },
    },

Route handlers can acquire checkouts by calling the C<task> method on the context object.

C<checkout_caching> means that if a checkout is obtained and released, it will be cached for the duration of the request so if another checkout for this task is obtained, then the original will be returned. This is useful for C<pre_route> handlers that use L<DBI> for example, because we want the authenticate handler to run in the same transaction as the handler (for both correctness and efficiency reasons).

Additional arguments to L<AnyEvent::Task::Client> and <AnyEvent::Task::Server> can be passed in via C<client> and C<server>.

See the C<bin/myapi>, C<lib/MyAPI/Task/PasswordHasher.pm>, and C<lib/MyAPI/Task/DB.pm> files for examples.

=item C<quiet>

If set, suppress the start-up message which looks like so:

    ===============================================================================

    Chouette 0.100

    PID = 31713
    UID/GIDs = 1000/1000 4 20 24 27 30 46 113 129 1000
    Listening on: http://0.0.0.0:8080

    Follow log messages:
        log-defer-viz -F /var/myapi/logs/myapi.current.log

    ===============================================================================

=back

After the C<Chouette> object is obtained, you should call C<serve> or C<run>. They are basically the same except C<serve> returns whereas C<run> enters the L<AnyEvent> event loop. These are equivalent:

    $chouette->run;

and

    $chouette->serve;
    AE::cv->recv;



=head1 CONTEXT OBJECT

For every request a C<Chouette::Context> object is created. This object is passed into the handler for the request. Typically we name the object C<$c>. Your code interacts with the request via the following methods on the context object:

=over

=item C<respond>

The respond method sends a JSON response, the contents of which are encoded from the first argument:

    $c->respond({ a => 1, b => 2, });

Note: After responding, this method returns and your code continues. This is useful if you wish to do additional work after sending the response. However, if you call C<respond> on this context again an error will logged. The second response will not be sent (it can't be since the connection is probably already closed).

If you wish to stop processing after sending the response, you can C<die> with the result from C<respond> since it returns a special object for this purpose:

    die $c->respond({ a => 1, });

See the L<EXCEPTIONS> section for more details on the use of exceptions in Chouette.

C<respond> takes an optional second argument which is the HTTP response code (defaults to 200):

    $c->respond({ error => "access denied" }, 403);

Note that processing continues here also. If you wish to terminate the processing right away, prefix with C<die> as above, or use the following shortcut:

    die "403: access denied";

The client will receive an HTTP response with the L<Feersum> default message ("Forbidden" in this case) and the JSON body will be C<{"error":"access denied"}>.

This works too, except the value of C<error> in the JSON body of the response will just be "HTTP code 403":

    die 403;

=item C<done>

If you wish to stop processing but not send a response:

    $c->done;

You will need to send a response later, usually from an async callback. Note: If the last reference to the context is destroyed without a response being sent, the message C<no response was sent, sending 500> will be logged and a 500 "internal server error" response will be sent.

You don't ever need to call C<done>. You can just C<return> from the handler instead. C<done> is only for convenience in case you are deeply nested in callbacks and don't want to worry about writing a bunch of nested returns.

=item C<respond_raw>

Similar to C<respond> except it doesn't assume JSON encoding:

    $c->respond_raw(200, 'text/plain', 'here is some plain text');

=item C<logger>

Returns the L<Log::Defer> object associated with the request:

    $c->logger->info("some stuff is happening");

    {
        my $timer = $c->logger->timer('doing big_computation');
        big_computation();
    }

See the L<Log::Defer> docs for more details. For viewing the log messages, check out L<Log::Defer::Viz>.

=item C<config>

Returns the C<config> hash. See the L<CHOUETTE OBJECT> section for details.

=item C<req>

Returns the L<Plack::Request> object created for this request.

    my $name = $c->req->parameters->{name};

=item C<res>

One would think this would return a L<Plack::Response> object. Unfortunately this isn't yet implemented and will instead throw an error.

=item C<generate_token>

Generates a random string using a default-config L<Session::Token> generator. The generator is created when the first token is needed so as to avoid a "cold" entropy pool immediately after a reboot (see the L<Session::Token> docs).

=item C<task>

Returns an L<AnyEvent::Task> checkout object for the task with the given name:

    $c->task('db')->selectrow_hashref(q{ SELECT * FROM sometable WHERE id = ? },
                                      undef, $id, sub {
        my ($dbh, $row) = @_;

        die $c->respond($row);
    });

Checkout options can be passed after the task name:

    $c->task('db', timeout => 5)->selectrow_hashref(...);

See L<AnyEvent::Task> for more details.

=back



=head1 EXCEPTIONS

Assuming you are familiar with asynchronous programming, most of L<Chouette> should feel straightforward. The only thing that might be unfamiliar is how exceptions are used.

=head2 ERROR HANDLING

The first unusual thing about how Chouette uses exceptions is that it uses them for error conditions, in contrast to many other asynchronous frameworks.

Most asynchronous frameworks are unable to use exceptions to signal errors since an error may occur in a callback being run from the event loop. If this callback throws an exception, there will be nothing to catch it, except perhaps a catch block installed by the event loop. Even if the event loop does catch it, it won't know which connection the exception is for, and therefore won't be able to send a 500 error to that connection or add a message to that connection's log.

Consider the L<AnyEvent::DBI> library. This is how its error handling works:

    $dbh->exec("SELECT * FROM no_such_table", sub {
        my ($dbh, $rows, $rv) = @_;

        if ($#_) {
            # success
        } else {
            # failure. error message is in $@
        }
    });

Even if C<exec> failed, the callback still gets called. Whether or not it succeeded is indicated by its parameters. You can think of this as a sort of "in-band" signalling. The fact that there was an error, and what exactly that error was, needs to be indicated by the callback's parameters in some way. Unfortunately every library does this slightly differently. Another alternative used by some libraries is to accept 2 callbacks, one of which is called in the success case, and the other in the failure case.

But with both of these methods, what should the callback do when it is notified of an error? It can't just C<die> because nothing will catch the exception. With the L<EV> event loop you will see this:

    EV: error in callback (ignoring): failure: ERROR:  relation "no_such_table" does not exist

Even if you wrap an C<eval> or a L<Try::Tiny> C<try {} catch {}> around the code the same thing happens. The try/catch is in effect while installing the callback, but not when the callback is called.

As a consequence of all this, asynchronous web frameworks usually cannot indicate errors with exceptions. Instead, they require you to respond to the client from inside the callback:

    $dbh->exec("SELECT * FROM no_such_table", sub {
        my ($dbh, $rows, $rv) = @_;

        if (!$#_) {
            $context->respond_500_error("DB error: $@");
            return;
        }

        # success
    });

There are several down-sides to this approach:

=over

=item *

The error must be handled locally in each callback, rather than once in a catch-all error handler.

=item *

Everywhere an error might occur needs to have access to the context object. This often requires passing it as an argument around everywhere.

=item *

You might forget to handle an error (or it might be too inconvenient so you don't bother) and your success-case code will run on garbage data.

=item *

Perhaps most importantly, if some unexpected exception is thrown by your callback (or something that it calls) then the event loop will receive an exception and nothing will get logged or replied to.

=back

For these reasons, Chouette uses L<Callback::Frame> to deal with exceptions. The idea is that the exception handling code is carried around with your callbacks. For instance, this is how you would accomplish the same thing with Chouette:

    my $dbh = $c->task('db');

    $dbh->selectrow_arrayref("SELECT * FROM no_such_table", undef, sub {
        my ($dbh, $rows) = @_;

        # success

        # Even if I can die here and it will get routed to the right request!
    });

The callback will only be invoked in the success case. If a failure occurs, an exception will be raised in the dynamic scope that was in effect when the callback was installed. Because Chouette installs a C<catch> handler for each request, an appropriate error will be sent to the client and added to the Chouette logs.

Important note: Libraries like L<AnyEvent::Task> (which is what C<task> in the above example uses) are L<Callback::Frame>-aware. This means that you can pass C<sub {}> callbacks into them and they will automatically convert them to C<fub {}> callbacks for you.

When using 3rd-party libraries, you must pass C<fub {}> instead. Also, you'll need to figure out how the library handles error cases, and throw exceptions as appropriate. For example, if you really wanted to use L<AnyEvent::DBI> (even though the L<AnyEvent::Task> version is superior in pretty much every way) this is what you would do:

    $dbh->exec("SELECT * FROM no_such_table", fub {
        my ($dbh, $rows, $rv) = @_;

        if (!$#_) {
            die "DB error: $@";
        }

        # success
    });

Note that the C<sub> has been changed to C<fub> and an exception is thrown for the error case.

In summary, when installing callbacks you must use C<fub> except when the library is L<Callback::Frame>-aware.

Please see the L<Callback::Frame> documentation for more specifics.


=head2 CONTROL FLOW

The other unusual thing about how Chouette uses exceptions is that it uses them for control flow as well as errors.

As you can see in the C<respond> method documentation of the L<CHOUETTE OBJECT> section, you can C<die> with the result of the C<respond> method:

    die $c->respond({ status => 'ok' });

This works because C<respond> returns a special object specifically intended for this purpose. When it gets an exception, the main catch block checks if it is this object. If so, it just ignores the exception. This lets you terminate your current callback without worrying about C<return>ing.

This catch block also checks if your exception starts with 3 digits followed by a word-break. If so, it considers this a special exception intended to send an HTTP response. For example, the following code will send a 404 Not Found response:

    die "404: no such resource";

The body of the response will be:

    {"error":"no such resource"}

You can even just throw a number:

    die 404;

Some people consider this usage of exceptions to be kind of a hack, but it does make for really nice code if you'll give it a chance.



=head1 EXAMPLE

These files represent a complete-ish Chouette application that I have extracted from a real-world app. Warning: untested!

=over

=item C<bin/myapi>

    #!/usr/bin/env perl

    use common::sense;

    use Chouette;

    my $chouette = Chouette->new({
        config_file => '/etc/myapi.conf',

        config_defaults => {
            var_dir => '/var/myapi',
            listen => '8080',

            logging => {
                file_prefix => 'myapi',
                timezone => 'localtime',
            },
        },

        middleware => [
            'Plack::Middleware::ContentLength',
        ],

        pre_route => 'MyAPI::Auth::authenticate',

        routes => {
            '/myapi/unauth/login' => {
                POST => 'MyAPI::User::login',
            },

            '/myapi/resource' => {
                POST => 'MyAPI::Resource::create',
                GET => 'MyAPI::Resource::get_all',
            },

            '/myapi/resource/:resource_id' => {
                GET => 'MyAPI::Resource::get_by_id',
            },
        },

        tasks => {
            passwd => {
                pkg => 'MyAPI::Task::PasswordHasher',
            },
            db => {
                pkg => 'MyAPI::Task::DB',
                checkout_caching => 1, ## so same dbh is used in authenticate and handler
            },
        },
    });

    $chouette->run;


=item C<lib/MyAPI/Auth.pm>

    package MyAPI::Auth;

    use common::sense;

    sub authenticate {
        my ($c, $cb) = @_;

        if ($c->{env}->{PATH_INFO} =~ m{^/myapi/unauth/}) {
            return $cb->();
        }

        my $session = $c->req->parameters->{session};

        $c->task('db')->selectrow_hashref(q{ SELECT user_id FROM session WHERE session_token = ? },
                                          undef, $session, sub {
            my ($dbh, $row) = @_;

            die 403 if !$row;

            $c->{user_id} = $row->{user_id};

            $cb->();
        });
    }

    1;


=item C<lib/MyAPI/User.pm>

    package MyAPI::User;

    use common::sense;

    sub login {
        my $c = shift;

        my $username = $c->req->parameters->{username};
        my $password = $c->req->parameters->{password};

        $c->task('db')->selectrow_hashref(q{ SELECT user_id, password_hashed FROM myuser WHERE username = ? }, undef, $username, sub {
            my ($dbh, $row) = @_;

            die 403 if !$row;

            $c->task('passwd')->verify_password($row->{password_hashed}, $password, sub {
                die 403 if !$_[1];

                my $session_token = $c->generate_token();

                $dbh->do(q{ INSERT INTO session (session_token, user_id) VALUES (?, ?) },
                         undef, $session_token, $row->{user_id}, sub {

                    $dbh->commit(sub {
                        die $c->respond({ sess => $session_token });
                    });
                });
            });
        });
    }

    1;



=item C<lib/MyAPI/Resource.pm>

    package MyAPI::Resource;

    use common::sense;

    sub create {
        my $c = shift;
        die "500 not implemented";
    }

    sub get_all {
        $c->logger->warn("denying access to get_all");
        die 403;
    }

    sub get_by_id {
        my $c = shift;
        my $resource_id = $c->route_params->{resource_id};
        die $c->respond({ resource_id => $resource_id, });
    }

    1;



=item C<lib/MyAPI/Task/PasswordHasher.pm>

    package MyAPI::Task::PasswordHasher;

    use common::sense;

    use Authen::Passphrase::BlowfishCrypt;
    use Encode;


    sub new {
        my ($class, %args) = @_;

        my $self = {};
        bless $self, $class;

        open($self->{dev_urandom}, '<:raw', '/dev/urandom') || die "open urandom: $!";

        setpriority(0, $$, 19); ## renice our process so we don't hold up more important processes

        return $self;
    }

    sub hash_password {
        my ($self, $plaintext_passwd) = @_;

        read($self->{dev_urandom}, my $salt, 16) == 16 || die "bad read from urandom";

        return Authen::Passphrase::BlowfishCrypt->new(cost => 10,
                                                      salt => $salt,
                                                      passphrase => encode_utf8($plaintext_passwd // ''))
                                                ->as_crypt;

    }

    sub verify_password {
        my ($self, $crypted_passwd, $plaintext_passwd) = @_;

        return Authen::Passphrase::BlowfishCrypt->from_crypt($crypted_passwd // '')
                                                ->match(encode_utf8($plaintext_passwd // ''));
    }

    1;



=item C<lib/MyAPI/Task/DB.pm>

    package MyAPI::Task::DB;

    use common::sense;

    use AnyEvent::Task::Logger;

    use DBI;


    sub new {
        my $config = shift;

        my $dbh = DBI->connect("dbi:Pg:dbname=myapi", '', '', {AutoCommit => 0, RaiseError => 1, PrintError => 0, })
            || die "couldn't connect to db";

        return $dbh;
    }


    sub CHECKOUT_DONE {
        my ($dbh) = @_;

        $dbh->rollback;
    }

    1;

=back



=head1 SEE ALSO

More documentation can be found in the modules linked in the L<DESCRIPTION> section.

L<Chouette github repo|https://github.com/hoytech/Chouette>

=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2017 Doug Hoyte.

This module is licensed under the same terms as perl itself.
