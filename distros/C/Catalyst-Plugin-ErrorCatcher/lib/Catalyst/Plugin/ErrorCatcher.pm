package Catalyst::Plugin::ErrorCatcher;
$Catalyst::Plugin::ErrorCatcher::VERSION = '0.0.8.18';
{
  $Catalyst::Plugin::ErrorCatcher::DIST = 'Catalyst-Plugin-ErrorCatcher';
}
# ABSTRACT: Catch application errors and emit them somewhere
use Moose;
    with 'Catalyst::ClassData';
use 5.008004;
use File::Type;
use IO::File;
use Module::Pluggable::Object;

__PACKAGE__->mk_classdata('_errorcatcher');
__PACKAGE__->mk_classdata('_errorcatcher_msg');
__PACKAGE__->mk_classdata('_errorcatcher_cfg');
__PACKAGE__->mk_classdata('_errorcatcher_c_cfg');
__PACKAGE__->mk_classdata('_errorcatcher_first_frame');
__PACKAGE__->mk_classdata('_errorcatcher_emitter_of');

__PACKAGE__->meta()->make_immutable();
no Moose;

sub setup {
    my $c = shift @_;

    # make sure other modules (e.g. ConfigLoader) work their magic
    $c->maybe::next::method(@_);

    # store the whole config (so plugins have a method to access it)
    $c->_errorcatcher_c_cfg( $c->config );

    # get our plugin config
    my $config = $c->config->{'Plugin::ErrorCatcher'} || {};

    # set some defaults
    $config->{context}            ||= 4;
    $config->{verbose}            ||= 0;
    $config->{always_log}         ||= 0;
    $config->{include_session}    ||= 0;
    $config->{user_identified_by} ||= 'id';
    
    # start with an empty hash
    $c->_errorcatcher_emitter_of({});

    # store our plugin config
    $c->_errorcatcher_cfg( $config );

    # some annoying emitters want a new() to be called
    $c->emitters_init;

    return 1;
}

# implementation borrowed from ABERLIN
sub finalize_error {
    my $c = shift;
    my $conf = $c->_errorcatcher_cfg;

    # finalize_error is only called when we have $c->error, so no need to test
    # for it

    # this should let ::StackTrace do some of our heavy-lifting
    # and prepare the Devel::StackTrace frames for us to re-use
    $c->maybe::next::method(@_);

    # don't run if user is certain we shouldn't
    if (
        # the config file insists we DO NOT run
        defined $conf->{enable} && not $conf->{enable}
    ) {
        return;
    }

    # run if required
    if (
        # the config file insists we run
        defined $conf->{enable} && $conf->{enable}
            or
        # we're in debug mode
        !defined $conf->{enable} && $c->debug
    ) {
        $c->my_finalize_error;
    }

    return;
}

sub my_finalize_error {
    my $c = shift;
    $c->_keep_frames;
    $c->_prepare_message;
    $c->_emit_message;
    return;
}

sub emitters_init {
    my $c = shift;

    if (defined (my $emit_list = $c->_errorcatcher_cfg->{emit_module})) {
        my @emit_list;
        # one item or a list?
        if (defined ref($emit_list) and 'ARRAY' eq ref($emit_list)) {
            @emit_list = @{ $emit_list };
        }
        elsif (not ref($emit_list)) {
            @emit_list = ( $emit_list );
        }

        foreach my $emitter (@emit_list) {
            $c->_require_and_new($emitter);
        }
    }
}

sub _require_and_new {
    my $c = shift;
    my $emitter_name = shift;
    my $output = shift;
    my $conf = $c->_errorcatcher_cfg;

    # make sure our emitter loads
    eval "require $emitter_name";
    if ($@) {
        $c->log->error($@);
        return;
    }
    # make sure it "can" new()
    if ($emitter_name->can('new')) {
        my ($e, $e_cfg);
        $e_cfg = $c->config->{$emitter_name} || {}; 

        eval {
            $e = $emitter_name->new({c=>$c});
        };
        if ($@) {
            $c->log->error($@);
            return;
        }
        # store the object
        $c->_errorcatcher_emitter_of->{$emitter_name} = $e;

        $c->log->debug(
                $emitter_name
            . q{: initialised without errors}
        ) if $conf->{verbose} > 1;

        # we are happy when they emitted without incident
        return 1;
    }

    # default is, "no we didn't mit anything"
    return;
}
sub _emit_message {
    my $c = shift;
    my $conf = $c->_errorcatcher_cfg;
    my $emitted_count = 0;

    return
        unless defined($c->_errorcatcher_msg);

    # use a custom emit method?
    if (defined (my $emit_list = $c->_errorcatcher_cfg->{emit_module})) {
        my @emit_list;
        # one item or a list?
        if (defined ref($emit_list) and 'ARRAY' eq ref($emit_list)) {
            @emit_list = @{ $emit_list };
        }
        elsif (not ref($emit_list)) {
            @emit_list = ( $emit_list );
        }

        foreach my $emitter (@emit_list) {
            $c->log->debug(
                  q{Trying to use custom emitter: }
                . $emitter
            ) if $conf->{verbose};

            # require, and call methods
            my $emitted_ok = $c->_require_and_emit(
                $emitter, $c->_errorcatcher_msg
            );
            if ($emitted_ok) {
                $emitted_count++;
                $c->log->debug(
                      $emitter
                    . q{: OK}
                ) if $conf->{verbose};
            }
            else {
                $c->log->debug(
                      $emitter
                    . q{: FAILED}
                ) if $conf->{verbose};
            }
        }
    }

    # by default use $c->log
    if (
        not $emitted_count
            or
        $c->_errorcatcher_cfg->{always_log}
    ) {
        $c->log->info(
            $c->_errorcatcher_msg
        );
    }

    return;
}

sub _require_and_emit {
    my $c = shift;
    my $emitter_name = shift;
    my $output = shift;
    my $conf = $c->_errorcatcher_cfg;
    my $emitter;

    # if we've preloaded an emitter [because it nas new()]
    # call that object
    if (defined (my $e=$c->_errorcatcher_emitter_of->{$emitter_name})) {
        # make sure it's "the right thing"
        if ($emitter_name eq ref($e)) {
            $emitter = $e;
        }
        else {
            die "$emitter isn't a $emitter";
        }
    }

    # if we haven't set the emitter (from a preloaded object)
    # require it ...
    if (not defined $emitter) {
        # make sure our emitter loads
        eval "require $emitter_name";
        if ($@) {
            $c->log->error($@);
            return;
        }

        $emitter = $emitter_name;
    }

    # make sure it "can" emit
    if ($emitter->can('emit')) {
        eval {
            $emitter->emit(
                $c, $output
            );
        };
        if ($@) {
            $c->log->error($@);
            return;
        }

        $c->log->debug(
                $emitter_name
            . q{: emitted without errors}
        ) if $conf->{verbose} > 1;

        # we are happy when they emitted without incident
        return 1;
    }
    else {
        $c->log->debug(
                $emitter_name
            . q{ does not have an emit() method}
        ) if $conf->{verbose};
    }

    # default is, "no we didn't emit anything"
    return;
}

sub _cleaned_error_message {
    my $error_message = shift;

    # load message cleaning plugins
    my %opts = (
        require     => 1,
        search_path => ['Catalyst::Plugin::ErrorCatcher::Plugin'],
    );
    my $finder = Module::Pluggable::Object->new(%opts);

    # loop through plugins and let them do some message tidying
    foreach my $plugin ($finder->plugins) {
        $plugin->tidy_message(\$error_message)
            if $plugin->can('tidy_message');
    }

    # get rid of annoying newlines and return a potentially clean error
    # message
    chomp $error_message;
    return $error_message;
}

sub append_feedback {
    my $fb_ref = shift;
    my $data   = shift;
    $$fb_ref ||= q{};
    $$fb_ref  .= $data . qq{\n};
}

sub append_feedback_emptyline {
    append_feedback($_[0], q[]);
}

sub append_feedback_keyvalue {
    # don't add undefined values
    return
        unless defined $_[2];
    my $padding = $_[3] || 8;
    append_feedback(
        $_[0],
        sprintf("%${padding}s: %s", $_[1], $_[2])
    );
    return;
}

sub sanitise_param {
    my $value   = shift;

    # stolen from Data::Dumper::qquote
    my $dumped_value;
    {
        my %esc = (
            "\a" => "\\a",
            "\b" => "\\b",
            "\t" => "\\t",
            "\n" => "\\n",
            "\f" => "\\f",
            "\r" => "\\r",
            "\e" => "\\e",
        );
        ($dumped_value = $value) =~ s{([\a\b\t\n\f\r\e])}{$esc{$1}}g;
    }

    # if it's short, just show it
    return $dumped_value
        if (length($value) < 40);

    # make a guess at a possible filetype
    my $ft      = File::Type->new();
    my $type    = $ft->checktype_contents( $value );

    # if our mimetype isn't application/octet-stream just report what was
    # submitted
    if ($type ne 'application/octet-stream') {
        return $type;
    }

    # getting here means we're 'application/octet-stream'
    # we could make guesses if we're really text/plain but for now
    # ... we're long, return a substring of ourseld
    # (if this gives troublesome results we'll tweak accordingly)
    return sprintf(
        '%s...[truncated]',
        substr($dumped_value, 0, 40)
    );
}

sub append_output_params {
    my $fb_ref = shift;
    my ($label,$params) = @_;
    return unless keys %$params;
    # work out the longest key
    # (http://www.webmasterkb.com/Uwe/Forum.aspx/perl/7596/Maximum-length-of-hash-key)
    my $l; $l|=$_ foreach keys %$params; $l=length $l;
    # give the next set of output a header
    append_feedback($fb_ref, "Params ($label):");
    # output the key-value pairs
    foreach my $k (sort keys %{$params}) {
        my $processed_value = sanitise_param($params->{$k});
        append_feedback_keyvalue($fb_ref, $k, $processed_value, $l+2);
    }
    append_feedback_emptyline($fb_ref);
}

sub _prepare_message {
    my $c = shift;
    my ($feedback, $full_error, $parsed_error);

    # get the (list of) error(s)
    for my $error (@{ $c->error }) {
        $full_error .= qq{$error\n\n};
    }
    # trim out some extra fluff from the full message
    $parsed_error = _cleaned_error_message($full_error);

    # A title for the feedback
    append_feedback(\$feedback, qq{Exception caught:} );
    append_feedback_emptyline(\$feedback);

    # the (parsed) error
    append_feedback_keyvalue(\$feedback, "Error", $parsed_error);

    # general request information
    # some of these aren't always defined...
    append_feedback_keyvalue(\$feedback, "Time", scalar(localtime));

    # TODO use append_...() method
    $feedback .= "  Client: " . $c->request->address
        if (defined $c->request->address);
    if (defined $c->request->hostname) {
        $feedback .=        " (" . $c->request->hostname . ")\n"
    }
    else {
        $feedback .= "\n";
    }

    append_feedback_keyvalue(\$feedback, 'Agent',   $c->request->user_agent);
    append_feedback_keyvalue(\$feedback, 'URI',    ($c->request->uri    || q{n/a}));
    append_feedback_keyvalue(\$feedback, 'Method', ($c->request->method || q{n/a}));
    append_feedback_keyvalue(\$feedback, 'Referer', $c->request->referer);

    # TODO use append_...() method
    my $user_identifier_method =
        $c->_errorcatcher_cfg->{user_identified_by};
    # if we have a logged-in user, add to the feedback
    if (
           $c->can('user_exists')
        && $c->user_exists
        && $c->user->can($user_identifier_method)
    ) {
        $feedback .= "    User: " . $c->user->$user_identifier_method;
        $feedback .= " [$user_identifier_method]";
        if (ref $c->user) {
            $feedback .= " (" . ref($c->user) . ")\n";
        }
        else {
            $feedback .= "\n";
        }
    }

    my $params; # share with body-param and query-param output
    append_feedback_emptyline(\$feedback);
    # output any query params
    append_output_params(\$feedback, 'QUERY', $c->request->query_parameters);

    # output any body params
    append_output_params(\$feedback, 'BODY', $c->request->body_parameters);

    if ('ARRAY' eq ref($c->_errorcatcher)) {
        # push on information and context
        for my $frame ( @{$c->_errorcatcher} ) {
            # clean up the common filename of
            # .../MyApp/script/../lib/...
            if ( $frame->{file} =~ /../ ) {
                $frame->{file} =~ s{script/../}{};
            }

            # if we haven't stored a frame, do so now
            # this is useful for easy access to the filename, line, etc
            if (not defined $c->_errorcatcher_first_frame) {
                $c->_errorcatcher_first_frame($frame);
            }

            my $pkg  = $frame->{pkg};
            my $line = $frame->{line};
            my $file = $frame->{file};
            my $code_preview = _print_context(
                $frame->{file},
                $frame->{line},
                $c->_errorcatcher_cfg->{context}
            );

            append_feedback_keyvalue(\$feedback, 'Package', $pkg);
            append_feedback_keyvalue(\$feedback, 'Line',    $line);
            append_feedback_keyvalue(\$feedback, 'File',    $file);
            append_feedback_emptyline(\$feedback);
            append_feedback(\$feedback, $code_preview);
        }
    }
    else {
        append_feedback_emptyline(\$feedback);
        append_feedback(\$feedback, "Stack trace unavailable - use and enable Catalyst::Plugin::StackTrace");
    }

    # RT-64492 - add session data if requested
    if (
        $c->_errorcatcher_cfg->{include_session}
        and defined $c->session
    ) {
        eval { require Data::Dump };
        if (my $e=$@) {
            append_feedback(\$feedback, 'Session data requested but failed to require Data::Dump:');
            append_feedback(\$feedback, "  $e");
        }
        else {
            append_feedback(\$feedback, 'Session Data');
            append_feedback(\$feedback,  Data::Dump::pp($c->session));
        }
    }

    # in case we bugger up the s/// on the original error message
    if ($full_error) {
        append_feedback(\$feedback, 'Original Error:');
        append_feedback_emptyline(\$feedback);
        append_feedback(\$feedback, $full_error);
    }

    # store it, otherwise we've done the above for mothing
    if (defined $feedback) {
        $c->_errorcatcher_msg($feedback);
    }

    return;
}

# we don't have to do much here now that we're relying on ::StackTrace to do
# the work for us
sub _keep_frames {
    my $c = shift;
    my $conf = $c->_errorcatcher_cfg;
    my $stacktrace;

    eval {
        $stacktrace = $c->_stacktrace;
    };

    if (defined $stacktrace) {
        $c->_errorcatcher( $stacktrace );
    }
    else {
        $c->_errorcatcher( undef );
        $c->log->debug(
                __PACKAGE__
            . q{ has no stack-trace information}
        ) if $conf->{verbose} > 1;
    }
    return;
}

# borrowed heavily from Catalyst::Plugin::StackTrace
sub _print_context {
    my ( $file, $linenum, $context ) = @_;

    my $code;
    if ( -f $file ) {
        my $start = $linenum - $context;
        my $end   = $linenum + $context;
        $start = $start < 1 ? 1 : $start;
        if ( my $fh = IO::File->new( $file, 'r' ) ) {
            my $cur_line = 0;
            while ( my $line = <$fh> ) {
                ++$cur_line;
                last if $cur_line > $end;
                next if $cur_line < $start;
                my @tag = $cur_line == $linenum ? ('-->', q{}) : (q{   }, q{});
                $code .= sprintf(
                    '%s%5d: %s%s',
                        $tag[0],
                        $cur_line,
                        $line ? $line : q{},
                        $tag[1],
                );
            }
        }
    }
    return $code;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Plugin::ErrorCatcher - Catch application errors and emit them somewhere

=head1 VERSION

version 0.0.8.18

=head1 SYNOPSIS

  use Catalyst qw/-Debug StackTrace ErrorCatcher/;

=head1 DESCRIPTION

This plugin allows you to do More Stuff with the information that would
normally only be seen on the Catalyst Error Screen courtesy of the
L<Catalyst::Plugin::StackTrace> plugin.

=head2 setup($c, $@)

Prepare the plugin for use.

=head2 finalize_error($c)

If configured, and needed, deal with raised errors.

=head2 my_finalize_error($c)

This is the method that's called by C<finalize_error> when we do want to use ErrorCatcher
to format and emit some information.

=head2 emitters_init($c)

This routine initialises the emitters enabled in the configuration for the plugin.

=head2 append_feedback($stringref, $data)

This is a small utility method that simplifies some of the work needed to
add some data to a string-reference, including some basic checks and initialisation.

=head2 append_feedback_emptyline

Add an empty-line to the string-reference of data being built.

=head2 append_feedback_keyvalue($ref, $key, $value, $keypadding)

Add:

    {key}: value

to the feedback data being prepared.

C<$keypadding> is optional. If omitted, defaults to 8.

=head2 sanitise_param($value)

Local implementation of L<Data::Dumper/qquote> and general sanity checks and
transformations of the data in a given piece of data.

=head2 append_output_params($ref, $label, $params)

Given a hashref of related items, C<$params>, and a C<$label> for the grouping,
add sensibly formatted output to the feedback data being constructed.

=head1 CONFIGURATION

The plugin is configured in a similar manner to other Catalyst plugins:

  <Plugin::ErrorCatcher>
      enable                1
      context               5
      always_log            0
      include_session       0
      user_identified_by    username

      emit_module           A::Module
  </Plugin::ErrorCatcher>

=over 4

=item B<enable>

Setting this to I<true> forces the module to work its voodoo.

It's also enabled if the value is unset and you're running Catalyst in
debug-mode.

=item B<context>

When there is stack-trace information to share, how many lines of context to
show around the line that caused the error.

=item B<emit_module>

This specifies which module to use for custom output behaviour.

You can chain multiple modules by specifying a line in the config for each
module you'd like used:

    emit_module A::Module
    emit_module Another::Module
    emit_module Yet::Another::Module

If none are specified, or all that are specified fail, the default behaviour
is to log the prepared message at the INFO level via C<$c-E<gt>log()>.

For details on how to implement a custom emitter see L</"CUSTOM EMIT CLASSES">
in this documentation.

=item B<always_log>

The default plugin behaviour when using one or more emitter modules is to
suppress the I<info> log message if one or more of them succeeded.

If you wish to log the information, via C<$c-E<gt>log()> then set this value
to 1.

=item B<include_session>

The default behaviour is to suppress potentially sensitive and revealing
session-data in the error report.

If you feel that this information is useful in your investigations set the
value to I<true>.

When set to 1 the report will include a C<Data::Dump::pp()> representation of
the request's session. 

=item B<user_identified_by>

If there's a logged-in user use the specified value as the method to identify
the user.

If the specified value is invalid the module defaults to using I<id>.

If unspecified the value defaults to I<id>.

=back

=head1 STACKTRACE IN REPORTS WHEN NOT RUNNING IN DEBUG MODE

It is possible to run your application in non-Debug mode, and still have
errors reported with a stack-trace.

Include the StackTrace and ErrorCatcher plugins in MyApp.pm:

  use Catalyst qw<
    ErrorCatcher
    StackTrace
  >;

Set up your C<myapp.conf> to include the following:

  <stacktrace>
    enable      1
  </stacktrace>

  <Plugin::ErrorCatcher>
    enable      1
    # include other options here
  <Plugin::ErrorCatcher>

Any exceptions should now show your user the I<"Please come back later">
screen whilst still capturing and emitting a report with stack-trace.

=head1 PROVIDED EMIT CLASSES

=head2 Catalyst::Plugin::ErrorCatcher::Email

This module uses L<MIME::Lite> to send the prepared output to a specified
email address.

See L<Catalyst::Plugin::ErrorCatcher::Email> for usage and configuration
details.

=head1 CUSTOM EMIT CLASSES

A custom emit class takes the following format:

  package A::Module;
  # vim: ts=8 sts=4 et sw=4 sr sta
  use strict;
  use warnings;
  
  sub emit {
    my ($class, $c, $output) = @_;
  
    $c->log->info(
      'IGNORING OUTPUT FROM Catalyst::Plugin::ErrorCatcher'
    );
  
    return;
  }
  
  1;
  __END__

The only requirement is that you have a sub called C<emit>.

C<Catalyst::Plugin::ErrorCatcher> passes the following parameters in the call
to C<emit()>:

=over 4

=item B<$class>

The package name

=item B<$c>

A L<Context|Catalyst::Manual::Intro/"Context"> object

=item B<$output>

The processed output from C<Catalyst::Plugin::ErrorCatcher>

=back

If you want to use the original error message you should use:

  my @error = @{ $c->error };

You may use and abuse any Catalyst methods, or other Perl modules as you see
fit.

=head1 KNOWN ISSUES

=over 4

=item BODY tests failing (Catalyst >=5.90008)

Summary: https://github.com/chiselwright/catalyst-plugin-errorcatcher/pull/1

Bug report: https://rt.cpan.org/Public/Bug/Display.html?id=75607

=back

=head1 SEE ALSO

L<Catalyst>,
L<Catalyst::Plugin::StackTrace>

=head1 THANKS

The authors of L<Catalyst::Plugin::StackTrace>, from which a lot of
code was used.

Ash Berlin for guiding me in the right direction after a known hacky first
implementation.

=head1 CONTRIBUTORS

Fitz Elliot L<https://github.com/felliott/>

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


# vim: ts=8 sts=4 et sw=4 sr sta
