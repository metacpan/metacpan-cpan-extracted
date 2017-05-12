package CGI::Application::Dispatch::PSGI;
use strict;
use warnings;
use Carp 'carp';
use HTTP::Exception;

our $VERSION = '3.12';
our $DEBUG   = 0;

=pod

=head1 NAME

CGI::Application::Dispatch::PSGI - Dispatch requests to
CGI::Application based objects using PSGI

=head1 SYNOPSIS

=head2 Out of Box

Under mod_perl:

  # change "Apache1" to "Apache2" as needed.

  <Location />
  SetHandler perl-script
  PerlHandler Plack::Handler::Apache1
  PerlSetVar psgi_app /path/to/app.psgi
  </Location>

  <Perl>
  use Plack::Handler::Apache1;
  Plack::Handler::Apache1->preload("/path/to/app.psgi");
  </Perl>

Under CGI:

This would be the instance script for your application, such
as /cgi-bin/dispatch.cgi:

    ### in your dispatch.psgi:
    # ( in a persistent environment, use FindBin::Real instead. )
    use FindBin 'Bin';
    use lib "$Bin/../perllib';
    use Your::Application::Dispatch;
    Your::Application::Dispatch->as_psgi;

    ### In Your::Application::Dispatch;
    package Your::Application::Dispatch;
    use base 'CGI::Application::Dispatch::PSGI';


=head2 With a dispatch table

    package MyApp::Dispatch;
    use base 'CGI::Application::Dispatch::PSGI';

    sub dispatch_args {
        return {
            prefix  => 'MyApp',
            table   => [
                ''                => { app => 'Welcome', rm => 'start' },
                ':app/:rm'        => { },
                'admin/:app/:rm'  => { prefix   => 'MyApp::Admin' },
            ],
        };
    }

The C<< .psgi >> file is constructed as above.

=head2 With a custom query object

If you want to supply your own PSGI object, something like this in
your .psgi file will work:

    sub {
        my $env = shift;
        my $app = CGI::Application::Dispatch::PSGI->as_psgi(
            table => [
                '/:rm'    =>    { app => 'TestApp' }
            ],
            args_to_new => {
                QUERY    => CGI::PSGI->new($env)
            }
        );
        return $app->($env);
    }


=head1 DESCRIPTION

This module provides a way to look at the path (as returned by C<<
$env->{PATH_INFO} >>) of the incoming request, parse off the desired
module and its run mode, create an instance of that module and run it.

It will translate a URI like this (in a persistent environment)

    /app/module_name/run_mode

or this (vanilla CGI)

    /app/index.cgi/module_name/run_mode

into something that will be functionally similar to this

    my $app = Module::Name->new(..);
    $app->mode_param(sub {'run_mode'}); #this will set the run mode

=head1 METHODS

=cut

sub as_psgi {
    my ($self, %args) = @_;

    # merge dispatch_args() and %args with %args taking precendence
    my $dispatch_args = $self->dispatch_args(\%args);
    for my $arg (keys %$dispatch_args) {

        # args_to_new should be merged
        if($arg eq 'args_to_new') {
            $args{args_to_new} ||= {};

            # merge the PARAMS hash
            if($dispatch_args->{args_to_new}->{PARAMS}) {

                # merge the hashes
                $args{args_to_new}->{PARAMS} = {
                    %{$dispatch_args->{args_to_new}->{PARAMS}},
                    %{$args{args_to_new}->{PARAMS} || {}},
                };
            }

            # combine any TMPL_PATHs
            if($dispatch_args->{args_to_new}->{TMPL_PATH}) {

                # make sure the orginial is an array ref
                if($args{args_to_new}->{TMPL_PATH}) {
                    if(!ref $args{args_to_new}->{TMPL_PATH}) {
                        $args{args_to_new}->{TMPL_PATH} = [$args{args_to_new}->{TMPL_PATH}];
                    }
                } else {
                    $args{args_to_new}->{TMPL_PATH} = [];
                }

                # now add the rest to the end
                if(ref $dispatch_args->{args_to_new}->{TMPL_PATH}) {
                    push(
                        @{$args{args_to_new}->{TMPL_PATH}},
                        @{$dispatch_args->{args_to_new}->{TMPL_PATH}},
                    );
                } else {
                    push(
                        @{$args{args_to_new}->{TMPL_PATH}},
                        $dispatch_args->{args_to_new}->{TMPL_PATH},
                    );
                }
            }

            # now merge the args_to_new hashes
            $args{args_to_new} = {%{$dispatch_args->{args_to_new}}, %{$args{args_to_new}},};
        } else {

            # anything else should override
            $args{$arg} = $dispatch_args->{$arg} unless exists $args{$arg};
        }
    }

    $DEBUG = $args{debug} ? 1 : 0;

    # check for extra args (for backwards compatibility)
    for (keys %args) {
        next
          if(  $_ eq 'prefix'
            or $_ eq 'default'
            or $_ eq 'debug'
            or $_ eq 'rm'
            or $_ eq 'args_to_new'
            or $_ eq 'table'
            or $_ eq 'auto_rest'
            or $_ eq 'auto_rest_lc');
        die "Passing extra args ('$_') to as_psgi() is not supported! Did you mean to use 'args_to_new' ?";
        $args{args_to_new}->{$_} = delete $args{$_};
    }

    return sub {
        my $env = shift;

        # get the PATH_INFO
        my $path_info = $env->{PATH_INFO};

        # use the 'default' if we need to
        $path_info = $args{default} || '' if(!$path_info || $path_info eq '/');

        # make sure they all start and end with a '/', to correspond
        # with the RE we'll make
        $path_info = "/$path_info" unless(index($path_info, '/') == 0);
        $path_info = "$path_info/" unless(substr($path_info, -1) eq '/');

        my ($module, $rm, $local_prefix, $local_args_to_new);
        # take args from path
        my $named_args;
        eval {
            $named_args = $self->_parse_path($path_info, $args{table},$env)
                or HTTP::Exception->throw(404, status_message => 'Resource not found');
        };
        if (my $e = HTTP::Exception->caught) {
            return $self->http_error($e);
        }

        if($DEBUG) {
            require Data::Dumper;
            warn "[Dispatch] Named args from match: " . Data::Dumper::Dumper($named_args) . "\n";
        }

        if(exists($named_args->{PARAMS}) || exists($named_args->{TMPL_PATH})) {
            carp "PARAMS and TMPL_PATH are not allowed here. Did you mean to use args_to_new?";
            HTTP::Exception->throw(500, status_message => 'PARAMS and TMPL_PATH not allowed');
        }

        # eval and catch any exceptions that might be thrown
        my ($output, @final_dispatch_args);
        my $psgi_app;
        eval {
            ($module, $local_prefix, $rm, $local_args_to_new) =
            delete @{$named_args}{qw(app prefix rm args_to_new)};

            # If another name for dispatch_url_remainder has been set move
            # the value to the requested name
            if($$named_args{'*'}) {
                $$named_args{$$named_args{'*'}} = $$named_args{'dispatch_url_remainder'};
                delete $$named_args{'*'};
                delete $$named_args{'dispatch_url_remainder'};
            }

            $module or HTTP::Exception->throw(500, status_message => 'App not defined');
            $module = $self->translate_module_name($module);

            $local_prefix ||= $args{prefix};
            $module = $local_prefix . '::' . $module if($local_prefix);

            $local_args_to_new ||= $args{args_to_new};

            # add the rest of the named_args to PARAMS
            @{$local_args_to_new->{PARAMS}}{keys %$named_args} = values %$named_args;

            my $auto_rest =
            defined $named_args->{auto_rest} ? $named_args->{auto_rest} : $args{auto_rest};
            if($auto_rest && defined $rm && length $rm) {
                my $method_lc =
                defined $named_args->{auto_rest_lc}
                ? $named_args->{auto_rest_lc}
                : $args{auto_rest_lc};
                my $http_method = $env->{REQUEST_METHOD};
                $http_method = lc $http_method if $method_lc;
                $rm .= "_$http_method";
            }
            # load and run the module
            @final_dispatch_args = ($module, $rm, $local_args_to_new);
            $self->require_module($module);
            $psgi_app =  $self->_run_app($module, $rm, $local_args_to_new,$env);
        };
        if (my $e = HTTP::Exception->caught) {
            return $self->http_error($e);
        }
        elsif ($e = Exception::Class->caught) {
            ref $e ? $e->rethrow : die $e;
        }
        return $psgi_app;
    }
}

=head2 as_psgi(%args)

This is the primary method used during dispatch.

    #!/usr/bin/perl
    use strict;
    use CGI::Application::Dispatch::PSGI;

    CGI::Application::Dispatch::PSGI->as_psgi(
        prefix  => 'MyApp',
        default => 'module_name',
    );

This method accepts the following name value pairs:

=over

=item default

Specify a value to use for the path if one is not available.
This could be the case if the default page is selected (eg: "/" ).

=item prefix

This option will set the string that will be prepended to the name of
the application module before it is loaded and created. So to use our
previous example request of

    /app/index.cgi/module_name/run_mode

This would by default load and create a module named
'Module::Name'. But let's say that you have all of your application
specific modules under the 'My' namespace. If you set this option to
'My' then it would instead load the 'My::Module::Name' application
module instead.

=item args_to_new

This is a hash of arguments that are passed into the C<new()>
constructor of the application.

=item table

In most cases, simply using Dispatch with the C<default> and C<prefix>
is enough to simplify your application and your URLs, but there are
many cases where you want more power. Enter the dispatch table. Since
this table can be slightly complicated, a whole section exists on its
use. Please see the L<DISPATCH TABLE> section.

=item debug

Set to a true value to send debugging output for this module to
STDERR. Off by default.

=item auto_rest

This tells Dispatch that you are using REST by default and that you
care about which HTTP method is being used. Dispatch will append the
HTTP method name (upper case by default) to the run mode that is
determined after finding the appropriate dispatch rule. So a GET
request that translates into C<< MyApp::Module->foo >> will become
C<< MyApp::Module->foo_GET >>.

This can be overridden on a per-rule basis in a custom dispatch table.

=item auto_rest_lc

In combinaion with L<auto_rest> this tells Dispatch that you prefer
lower cased HTTP method names.  So instead of C<foo_POST> and
C<foo_GET> you'll have C<foo_post> and C<foo_get>.

=back

=cut

sub http_error {
    my ($self, $e) = @_;

    warn '[Dispatch] ERROR'
      . ($ENV{REQUEST_URI} ? " for request '$ENV{REQUEST_URI}': " : ': ')
      . $e->error . "\n";

    my $errno  = $e->isa('HTTP::Exception::Base') ? $e->code           : 500;
    my $output = $e->isa('HTTP::Exception::Base') ? $e->status_message : "Internal Server Error";

    # The custom status message was most useful for logging. Return
    # generic messages to the user.
    $output = 'Not Found'             if ($e->code == 404);
    $output = 'Internal Server Error' if ($e->code == 500);


    return [ $errno, [], [ $output ] ];
}

# protected method - designed to be used by sub classes, not by end users
sub _parse_path {
    my ($self, $path, $table, $env) = @_;

    # get the module name from the table
    return unless defined($path);

    unless(ref($table) eq 'ARRAY') {
        warn "[Dispatch] Invalid or no dispatch table!\n";
        return;
    }

    # look at each rule and stop when we get a match
    for(my $i = 0 ; $i < scalar(@$table) ; $i += 2) {

        my $rule = $table->[$i];

        # are we trying to dispatch based on HTTP_METHOD?
        my $http_method_regex = qr/\[([^\]]+)\]$/;
        if($rule =~ /$http_method_regex/) {
            my $http_method = $1;

            # go ahead to the next rule
            next unless lc($1) eq lc($env->{REQUEST_METHOD});

            # remove the method portion from the rule
            $rule =~ s/$http_method_regex//;
        }

        # make sure they start and end with a '/' to match how
        # PATH_INFO is formatted
        $rule = "/$rule" unless(index($rule, '/') == 0);
        $rule = "$rule/" if(substr($rule, -1) ne '/');

        my @names = ();

        # translate the rule into a regular expression, but remember
        # where the named args are
        # '/:foo' will become '/([^\/]*)'
        # and
        # '/:bar?' will become '/?([^\/]*)?'
        # and then remember which position it matches

        $rule =~ s{
            (^|/)                 # beginning or a /
            (:([^/\?]+)(\?)?)     # stuff in between
        }{
            push(@names, $3);
            $1 . ($4 ? '?([^/]*)?' : '([^/]*)')
        }gxe;

        # '/*/' will become '/(.*)/$' the end / is added to the end of
        # both $rule and $path elsewhere
        if($rule =~ m{/\*/$}) {
            $rule =~ s{/\*/$}{/(.*)/\$};
            push(@names, 'dispatch_url_remainder');
        }

        warn
          "[Dispatch] Trying to match '${path}' against rule '$table->[$i]' using regex '${rule}'\n"
          if $DEBUG;

        # if we found a match, then run with it
        if(my @values = ($path =~ m#^$rule$#)) {

            warn "[Dispatch] Matched!\n" if $DEBUG;

            my %named_args = %{$table->[++$i]};
            @named_args{@names} = @values if @names;

            return \%named_args;
        }
    }

    return;
}

sub _run_app {
    my ($self, $module, $rm, $args,$env) = @_;

    if($DEBUG) {
        require Data::Dumper;
        warn "[Dispatch] Final args to pass to new(): " . Data::Dumper::Dumper($args) . "\n";
    }

    if($rm) {

        # check runmode name
        ($rm) = ($rm =~ /^([a-zA-Z_][\w']+)$/);
        HTTP::Exception->throw(400, status_message => "Invalid characters in runmode name") unless $rm;

    }

    # now create and run then application object
    warn "[Dispatch] creating instance of $module\n" if($DEBUG);

    my $psgi;
    eval {
        my $app = do {
            if (ref($args) eq 'HASH' and not defined $args->{QUERY}) {
                require CGI::PSGI;
                $args->{QUERY} = CGI::PSGI->new($env);
                $module->new($args);
            }
            elsif (ref($args) eq 'HASH') {
                $module->new($args);
            }
            else {
                $module->new();
            }
        };
        $app->mode_param(sub { return $rm }) if($rm);
        $psgi = $app->run_as_psgi;
    };

    # App threw an HTTP::Exception? Cool. Bubble it up.
    my $e;
    if ($e = HTTP::Exception->caught) {
        $e->rethrow;   
    } 
    else {
          $e = Exception::Class->caught();

          # catch invalid run-mode stuff
          if (not ref $e and  $e =~ /No such run mode/) {
              HTTP::Exception->throw(404, status_message => "RM '$rm' not found");
          }
          # otherwise, it's an internal server error.
          elsif (defined $e and length $e) {
              HTTP::Exception->throw(500, status_message => "Unknown error: $e");
              #return $psgi;
          }
          else {
              # no exception
              return $psgi;
          }
    }
}

=head2 dispatch_args()

Returns a hashref of args that will be passed to L<dispatch>(). It
will return the following structure by default.

    {
        prefix      => '',
        args_to_new => {},
        table       => [
            ':app'      => {},
            ':app/:rm'  => {},
        ],
    }

This is the perfect place to override when creating a subclass to
provide a richer dispatch L<table>.

When called, it receives 1 argument, which is a reference to the hash
of args passed into L<dispatch>.

=cut

sub dispatch_args {
    my ($self, $args) = @_;
    return {
        default     => ($args->{default}     || ''),
        prefix      => ($args->{prefix}      || ''),
        args_to_new => ($args->{args_to_new} || {}),
        table       => [
            ':app'     => {},
            ':app/:rm' => {},
        ],
    };
}

=head2 translate_module_name($input)

This method is used to control how the module name is translated from
the matching section of the path (see L<"Path Parsing">.  The main
reason that this method exists is so that it can be overridden if it
doesn't do exactly what you want.

The following transformations are performed on the input:

=over

=item The text is split on '_'s (underscores)
and each word has its first letter capitalized. The words are then joined
back together and each instance of an underscore is replaced by '::'.


=item The text is split on '-'s (hyphens)
and each word has its first letter capitalized. The words are then joined
back together and each instance of a hyphen removed.

=back

Here are some examples to make it even clearer:

    module_name         => Module::Name
    module-name         => ModuleName
    admin_top-scores    => Admin::TopScores

=cut

sub translate_module_name {
    my ($self, $input) = @_;

    $input = join('::', map { ucfirst($_) } split(/_/, $input));
    $input = join('',   map { ucfirst($_) } split(/-/, $input));

    return $input;
}

=head2 require_module($module_name)

This class method is used internally to take a module name (supplied
by L<get_module_name>) and require it in a secure fashion. It is
provided as a public class method so that if you override other
functionality of this module, you can still safely require user
specified modules. If there are any problems requiring the named
module, then we will C<croak>.

    CGI::Application::Dispatch::PSGI->require_module('MyApp::Module::Name');

=cut

sub require_module {
    my ($self, $module) = @_;

    $module or HTTP::Exception->throw(404, status_message => "Can't define module name");

    #untaint the module name
    ($module) = ($module =~ /^([A-Za-z][A-Za-z0-9_\-\:\']+)$/);

    unless($module) {
        HTTP::Exception->throw(400, status_message => "Invalid characters in module name");
    }

    warn "[Dispatch] loading module $module\n" if($DEBUG);
    eval "require $module";
    return unless $@;

    my $module_path = $module;
    $module_path =~ s/::/\//g;

    if($@ =~ /Can't locate $module_path.pm/) {
        HTTP::Exception->throw(404, status_message => "Can't find module $module");
    }
    else {
        HTTP::Exception->throw(500, status_message => "Unable to load module '$module': $@");
    }
}

1;

__END__

=head1 DISPATCH TABLE

Sometimes it's easiest to explain with an example, so here you go:

  CGI::Application::Dispatch::PSGI->as_psgi(
    prefix      => 'MyApp',
    args_to_new => {
        TMPL_PATH => 'myapp/templates'
    },
    table       => [
        ''                         => { app => 'Blog', rm => 'recent'},
        'posts/:category'          => { app => 'Blog', rm => 'posts' },
        ':app/:rm/:id'             => { app => 'Blog' },
        'date/:year/:month?/:day?' => {
            app         => 'Blog',
            rm          => 'by_date',
            args_to_new => { TMPL_PATH => "events/" },
        },
    ]
  );

So first, this call to L<as_psgi> sets the L<prefix> and passes a C<TMPL_PATH>
into L<args_to_new>. Next it sets the L<table>.


=head2 VOCABULARY

Just so we all understand what we're talking about....

A table is an array where the elements are gouped as pairs (similar to
a hash's key-value pairs, but as an array to preserve order). The
first element of each pair is called a C<rule>. The second element in
the pair is called the rule's C<arg list>.  Inside a rule there are
slashes C</>. Anything set of characters between slashes is called a
C<token>.

=head2 URL MATCHING

When a URL comes in, Dispatch tries to match it against each rule in
the table in the order in which the rules are given. The first one to
match wins.

A rule consists of slashes and tokens. A token can one of the following types:

=over

=item literal

Any token which does not start with a colon (C<:>) is taken to be a literal
string and must appear exactly as-is in the URL in order to match. In the rule

    'posts/:category'

C<posts> is a literal token.

=item variable

Any token which begins with a colon (C<:>) is a variable token. These
are simply wild-card place holders in the rule that will match
anything in the URL that isn't a slash. These variables can later be
referred to by using the C<< $self->param >> mechanism. In the rule

    'posts/:category'

C<:category> is a variable token. If the URL matched this rule, then
you could the value of that token from whithin your application like
so:

    my $category = $self->param('category');

There are some variable tokens which are special. These can be used to
further customize the dispatching.

=over

=item :app

This is the module name of the application. The value of this token
will be sent to the L<translate_module_name> method and then prefixed
with the L<prefix> if there is one.

=item :rm

This is the run mode of the application. The value of this token will be the
actual name of the run mode used. The run mode can be optional, as
noted below. Example:

    /foo/:rm?

If no run mode is found, it will default to using the C<< start_mode() >>, just like
invoking CGI::Application directly. Both of these URLs would end up dispatching
to the start mode associated with /foo:

    /foo/
    /foo

=back

=item optional-variable

Any token which begins with a colon (C<:>) and ends with a question
mark (<?>) is considered optional. If the rest of the URL matches the
rest of the rule, then it doesn't matter whether it contains this
token or not. It's best to only include optional-variable tokens at
the end of your rule. In the rule

    'date/:year/:month?/:day?'

C<:month?> and C<:day?> are optional-variable tokens.

Just like with L<variable> tokens, optional-variable tokens' values
can also be retrieved by the application, if they existed in the URL.

    if( defined $self->param('month') ) {
        ...
    }

=item wildcard

The wildcard token "*" allows for partial matches. The token MUST
appear at the end of the rule.

  'posts/list/*'

By default, the C<dispatch_url_remainder> param is set to the
remainder of the URL matched by the *. The name of the param can be
changed by setting "*" argument in the L<ARG LIST>.

  'posts/list/*' => { '*' => 'post_list_filter' }

=item method

You can also dispatch based on HTTP method. This is similar to using
L<auto_rest> but offers more fine grained control. You include the
method (case insensitive) at the end of the rule and enclose it in
square brackets.

  ':app/news[post]'   => { rm => 'add_news'    },
  ':app/news[get]'    => { rm => 'news'        },
  ':app/news[delete]' => { rm => 'delete_news' },

=back

The main reason that we don't use regular expressions for dispatch
rules is that regular expressions provide no mechanism for named back
references, like variable tokens do.

=head2 ARG LIST

Each rule can have an accompanying arg-list. This arg list can contain
special arguments that override something set higher up in L<dispatch>
for this particular URL, or just have additional args passed available
in C<< $self->param() >>

For instance, if you want to override L<prefix> for a specific rule,
then you can do so.

    'admin/:app/:rm' => { prefix => 'MyApp::Admin' },

=head1 Path Parsing

This section will describe how the application module and run mode are
determined from the path if no L<DISPATCH TABLE> is present, and what
options you have to customize the process.  The value for the path to
be parsed is retrieved from C<< $env->{PATH_INFO} >>.

=head2 Getting the module name

To get the name of the application module the path is split on
backslahes (C</>).  The second element of the returned list (the first
is empty) is used to create the application module. So if we have a
path of

    /module_name/mode1

then the string 'module_name' is used. This is passed through the
L<translate_module_name> method. Then if there is a C<prefix> (and
there should always be a L<prefix>) it is added to the beginning of
this new module name with a double colon C<::> separating the two.

If you don't like the exact way that this is done, don't fret you do
have a couple of options.  First, you can specify a L<DISPATCH TABLE>
which is much more powerful and flexible (in fact this default
behavior is actually implemented internally with a dispatch table).
Or if you want something a little simpler, you can simply subclass and
extend the L<translate_module_name> method.

=head2 Getting the run mode

Just like the module name is retrieved from splitting the path on
slashes, so is the run mode. Only instead of using the second element
of the resulting list, we use the third as the run mode. So, using the
same example, if we have a path of

    /module_name/mode2

Then the string 'mode2' is used as the run mode.

=head1 Exception Handling

A CGI::Application object can throw an exception up to C<<
CGI::Application::Dispatch::PSGI >> if no C<error_mode()> is implemented or if
the error_mode itself throws an exception. In these cases we generally return a
generic "500" response, and log some details for the developer with a warning.

However, we will check to see if the exception thrown is an HTTP::Exception
object. If that's the case, we will rethrow it, and you can handle it yourself using
something like L<Plack::Middleware::HTTPExceptions>.

=head1 MISC NOTES

=over 8

=item * CGI query strings

CGI query strings are unaffected by the use of C<PATH_INFO> to obtain
the module name and run mode.  This means that any other modules you
use to get access to you query argument (ie, L<CGI>,
L<Apache::Request>) should not be affected. But, since the run mode
may be determined by CGI::Application::Dispatch::PSGI having a query
argument named 'rm' will be ignored by your application module.

=back

=head1 CLEAN URLS WITH MOD_REWRITE

With a dispatch script, you can fairly clean URLS like this:

 /cgi-bin/dispatch.cgi/module_name/run_mode

However, including "/cgi-bin/dispatch.cgi" in ever URL doesn't add any
value to the URL, so it's nice to remove it. This is easily done if
you are using the Apache web server with C<mod_rewrite>
available. Adding the following to a C<.htaccess> file would allow you
to simply use:

 /module_name/run_mode

If you have problems with mod_rewrite, turn on debugging to see
exactly what's happening:

 RewriteLog /home/project/logs/alpha-rewrite.log
 RewriteLogLevel 9

=head2 mod_rewrite related code in the dispatch script.

This seemed necessary to put in the dispatch script to make mod_rewrite happy.
Perhaps it's specific to using C<RewriteBase>.

  # mod_rewrite alters the PATH_INFO by turning it into a file system path,
  # so we repair it.
  $ENV{PATH_INFO} =~ s/^$ENV{DOCUMENT_ROOT}// if defined $ENV{PATH_INFO};

=head2 Simple Apache Example

  RewriteEngine On

  # You may want to change the base if you are using the dispatcher within a
  # specific directory.
  RewriteBase /

  # If an actual file or directory is requested, serve directly
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d

  # Otherwise, pass everything through to the dispatcher
  RewriteRule ^(.*)$ /cgi-bin/dispatch.cgi/$1 [L,QSA]

=head2 More complex rewrite: dispatching "/" and multiple developers

Here is a more complex example that dispatches "/", which would otherwise
be treated as a directory, and also supports multiple developer directories,
so C</~mark> has its own separate dispatching system beneath it.

Note that order matters here! The Location block for "/" needs to come
before the user blocks.

  <Location />
    RewriteEngine On
    RewriteBase /

    # Run "/" through the dispatcher
    RewriteRule ^home/project/www/$ /cgi-bin/dispatch.cgi [L,QSA]

    # Don't apply this rule to the users sub directories.
    RewriteCond %{REQUEST_URI} !^/~.*$
    # If an actual file or directory is requested, serve directly
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    # Otherwise, pass everything through to the dispatcher
    RewriteRule ^(.*)$ /cgi-bin/dispatch.cgi/$1 [L,QSA]
  </Location>

  <Location /~mark>
    RewriteEngine On
    RewriteBase /~mark

    # Run "/" through the dispatcher
    RewriteRule ^/home/mark/www/$ /~mark/cgi-bin/dispatch.cgi [L,QSA]

    # Otherwise, if an actual file or directory is requested, serve directly
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d

    # Otherwise, pass everything through to the dispatcher
    RewriteRule ^(.*)$ /~mark/cgi-bin/dispatch.cgi/$1 [L,QSA]

    # These examples may also be helpful, but are unrelated to dispatching.
    SetEnv DEVMODE mark
    SetEnv PERL5LIB /home/mark/perllib:/home/mark/config
    ErrorDocument 404 /~mark/errdocs/404.html
    ErrorDocument 500 /~mark/errdocs/500.html
  </Location>

=head1 SUBCLASSING

While Dispatch tries to be flexible, it won't be able to do everything
that people want. Hopefully we've made it flexible enough so that if
it doesn't do I<The Right Thing> you can easily subclass it.

=cut

#=head2 PROTECTED METHODS
#
#The following methods are intended to be overridden by subclasses if
#necessary. They are not part of the public API since end users will
#never touch them. However, to ensure that your subclass of Dispatch
#does not break with a new release, they are documented here and are
#considered to be part of the API and will not be changed without very
#good reasons.

=head1 AUTHORS

Mark Stosberg <mark@summersault.com>

Heavily based on CGI::Application::Dispatch, written by Michael Peters
<mpeters@plusthree.com> and others

=head1 COMMUNITY

This module is a part of the larger L<CGI::Application> community. If
you have questions or comments about this module then please join us
on the cgiapp mailing list by sending a blank message to
"cgiapp-subscribe@lists.erlbaum.net". There is also a community wiki
located at L<http://www.cgi-app.org/>

=head1 SOURCE CODE REPOSITORY

A public source code repository for this project is hosted here:

https://github.com/markstos/CGI--Application--Dispatch

=head1 SECURITY

Since C::A::Dispatch::PSGI will dynamically choose which modules to use as the
content generators, it may give someone the ability to execute random modules
on your system if those modules can be found in you path. Of course those
modules would have to behave like L<CGI::Application> based modules, but that
still opens up the door more than most want. This should only be a problem if
you don't use a L<prefix>. By using this option you are only allowing Dispatch
to pick from a namespace of modules to run.

=head1 Backwards Compatibility

Versions 0.2 and earlier of this module injected the "as_psgi" method into
CGI::Application::Dispatch, creating a syntax like this:

   ### in your dispatch.psgi:
   use Your::Application::Dispatch;
   use CGI::Application::Dispatch::PSGI;
   Your::Application::Dispatch->as_psgi;

   ### In Your::Application::Dispatch;
   use base 'CGI::Application::Dispatch::PSGI';

In the current design, the C<< as_pgsi >> method is directly in this module, so
a couple of lines of code need to be changed:

   ### in your dispatch.psgi:
   use Your::Application::Dispatch;
   Your::Application::Dispatch->as_psgi;

   ### In Your::Application::Dispatch;
   use base 'CGI::Application::Dispatch::PSGI';


=head1 Differences with CGI::Application::Dispatch

=over 4

=item dispatch()

Use C<< as_psgi() >> instead.

Note that the C<error_document> key is not supported here. Use the
L<Plack::Middleware::ErrorDocument> or another PSGI solution instead.

=item dispatch_path()

The dispatch_path() method is not supported. The alternative is to
reference C<< $env->{PATH_INFO} >> which is available per the PSGI
spec.

=item handler()

This provided an Apache-specific handler. Other PSGI components like
L<Plack::Handler::Apache2> provide Apache handlers now instead.

=item _http_method()

This method has been eliminated. Check C<< $env->{REQUEST_METHOD} >>
directly instead.

=item _parse_path()

The private _parse_path() method now accepts an additional argument,
the PSGI C<< $env >> hash.

=item _run_app()

The private _run_app() method now accepts an additional argument, the
PSGI C<< $env >> hash.

=item _r()

This method has been eliminated. It does not apply in PSGI.

=back

=head1 SEE ALSO

L<CGI::Application>, L<Apache::Dispatch>

=head1 COPYRIGHT & LICENSE

Copyright Michael Peters and Mark Stosberg 2008-2010, all rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
