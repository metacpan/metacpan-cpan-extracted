package Callback::Frame;

use strict;

our $VERSION = '1.102';

require Exporter;
use base 'Exporter';
our @EXPORT = qw(frame fub frame_try frame_try_void frame_catch frame_local frame_void);

use Scalar::Util;
use Carp qw/croak/;
use Guard;


our $top_of_stack;
our $active_frames = {};


sub frame {
  my ($name, $code, $catcher, $locals, $existing_frame);

  while ((my $k, my $v, @_) = @_) {
    if ($k eq 'name') {
      $name = $v;
    } elsif ($k eq 'code') {
      $code = $v;
    } elsif ($k eq 'catch') {
      $catcher = $v;
    } elsif ($k eq 'local') {
      $locals->{$v} = undef;
    } elsif ($k eq 'existing_frame') {
      $existing_frame = $v;
    } else {
      croak "Unknown frame option: $k";
    }

    croak "value missing for key $k" if !defined $v;
  }

  $name ||= 'ANONYMOUS FRAME';
  my ($package, $filename, $line) = caller;
  ($package, $filename, $line) = caller(1) if $package eq __PACKAGE__; ## if we're called from fub or frame_try
  $name = "$filename:$line - $name";

  defined $code || croak "frame needs a 'code' callback";

  my $existing_top_of_stack;
  if (defined $existing_frame) {
    $existing_top_of_stack = $active_frames->{"$existing_frame"};
    croak "existing_frame isn't a frame" unless $existing_top_of_stack;
    croak "can't install new catcher if using existing_frame" if defined $catcher;
    croak "can't install new local if using existing_frame" if defined $locals;
  }


  my ($ret_cb, $internal_cb);

  $ret_cb = sub {
    return $internal_cb->(@_);
  };

  my $cb_address = "$ret_cb";

  my $new_frame;

  if ($existing_top_of_stack) {
    $new_frame = $existing_top_of_stack;
  } else {
    $new_frame = {
      name => $name,
      down => $top_of_stack,
      guard => guard {
        undef $ret_cb;
        delete $active_frames->{$cb_address};
      },
    };

    $new_frame->{catcher} = $catcher if defined $catcher;
    $new_frame->{locals} = $locals if defined $locals;

    $active_frames->{$cb_address} = $new_frame;
    Scalar::Util::weaken($active_frames->{$cb_address});
  }

  $internal_cb = sub {
    my $orig_error = $@;

    local $top_of_stack = $new_frame;

    my $frame_i = $top_of_stack;

    my $val = eval {
      ## Find applicable local vars

      my $local_refs = {};
      my $temp_copies = {};

      for(; $frame_i; $frame_i = $frame_i->{down}) {
        next unless exists $frame_i->{locals};
        foreach my $k (keys %{$frame_i->{locals}}) {
          next if exists $local_refs->{$k};
          $local_refs->{$k} = \$frame_i->{locals}->{$k};
        }
      }

      ## Backup local vars

      foreach my $var (keys %$local_refs) {
        no strict qw/refs/;
        $temp_copies->{$var} = $$var;
        $$var = ${$local_refs->{$var}};
      }

      ## Install code that will restore local vars

      scope_guard {
        foreach my $var (keys %$local_refs) {
          no strict qw/refs/;
          ${$local_refs->{$var}} = $$var;
          $$var = $temp_copies->{$var};
        }
      };

      ## Actually run the callback

      $@ = $orig_error;

      $code->(@_);
    };

    my $err = $@;

    if ($err) {
      my $trace = generate_trace($top_of_stack, $err);

      for (my $frame_i = $top_of_stack; $frame_i; $frame_i = $frame_i->{down}) {
        next unless exists $frame_i->{catcher};

        my $val = eval {
          $@ = $err;
          $frame_i->{catcher}->($trace);
          1
        };

        return if defined $val && $val == 1;

        $err = $@;
      }

      ## No catcher available: just re-throw error
      die $err;
    }

    return $val;
  };

  my $final_cb = $ret_cb;
  Scalar::Util::weaken($ret_cb);

  return $final_cb;
}


sub fub (&@) {
  my ($code, @args) = @_;

  return frame(code => $code, @args);
}


sub is_frame {
  my $coderef = shift;

  return 0 unless ref $coderef;

  return 1 if exists $active_frames->{$coderef};

  return 0;
}


sub generate_trace {
  my ($frame_pointer, $err) = @_;

  my $err_str = "$err";
  chomp $err_str;
  my $trace = "$err_str\n----- Callback::Frame stack-trace -----\n";

  for (my $frame_i = $frame_pointer; $frame_i; $frame_i = $frame_i->{down}) {
    $trace .= "$frame_i->{name}\n";
  }

  return $trace;
}


sub frame_void (&) {
  my ($block) = @_;

  local $top_of_stack;
  local $active_frames = {};

  $block->();
}

sub frame_try (&;@) {
  my ($try_block, $catch_block) = @_;

  return frame(code => $try_block, catch => $catch_block)->();
}

sub frame_try_void (&;@) {
  my ($try_block, $catch_block) = @_;

  local $top_of_stack;
  local $active_frames = {};

  return frame(code => $try_block, catch => $catch_block)->();
}

sub frame_catch (&) {
  my ($block) = @_;

  croak "Useless bare frame_catch" unless wantarray;

  return $block;
}

sub frame_local ($&) {
  my ($local, $block) = @_;

  return frame(code => $block, local => $local)->();
}


1;


__END__

=encoding utf-8

=head1 NAME

Callback::Frame - Preserve error handlers and "local" variables across callbacks

=head1 SYNOPSIS

    use Callback::Frame;

    my $callback;

    frame_try {
      $callback = fub {
                    die "some error";
                  };
    } frame_catch {
       my $stack_trace = shift;
       print $stack_trace;
       ## Also, $@ is set to "some error at ..."
    };

    $callback->();

This will print something like:

    some error at tp.pl line 7.
    ----- Callback::Frame stack-trace -----
    synopsis.pl:8 - ANONYMOUS FRAME
    synopsis.pl:13 - ANONYMOUS FRAME


=head1 BACKGROUND

When programming with callbacks in perl, you create anonymous functions with C<sub { ... }>. These functions are especially useful because when they are called they will preserve their surrounding lexical environment.

In other words, the following bit of code

    my $callback;
    {
      my $var = 123;
      $callback = sub { $var };
    }
    print $callback->();

will print C<123> even though C<$var> is no longer in scope when the callback is invoked.

Sometimes people call these anonymous functions that reference variables in their surrounding lexical scope "closures". Whatever you call them, they are essential for convenient and efficient asynchronous programming. 

For many applications we really like straightforward callback style. The goal of Callback::Frame is to simplify the management of dynamic environments (defined below) while leaving callback style alone.


=head1 DESCRIPTION

The problem that this module solves is that although closures preserve their lexical environment, they don't preserve error handlers or C<local> variables.

Consider the following piece of B<broken> code:

    use AnyEvent;

    eval {
      $watcher = AE::timer 0.1, 0,
        sub {
          die "some error";
        };
    };

    ## broken!
    if ($@) {
      print STDERR "Oops: $@";
    }

    AE::cv->recv;

The intent behind the C<eval> above is obviously to catch any exceptions thrown by the callback. However, this will not work because the C<eval> will only be in effect while installing the callback in the event loop, not while running the callback. When the event loop calls the callback, it will probably wrap its own C<eval> around the callback and you will see something like this:

    EV: error in callback (ignoring): some error at broken.pl line 6.

(The above applies to L<EV> which is a well-designed event loop. Other event loops may fail more catastrophically.)

The root of the problem is that the dynamic environment has not been preserved. In this case it is the dynamic exception handlers that we would like to preserve. In some other cases we would like to preserve dynamically scoped (aka "local") variables (see below).

By the way, "lexical" and "dynamic" are the lisp terms. When it applies to variables, perl confusingly calls dynamic scoping "local" scoping, even though the scope is temporal, not local.

Here is how we could fix the code above using L<Callback::Frame>:

    use AnyEvent;
    use Callback::Frame;

    frame_try {
      $watcher = AE::timer 0.1, 0, fub {
                                     die "some error";
                                   };
    } frame_catch {
      print STDERR "Oops: $@";
    };

    AE::cv->recv;

Now we see the desired error message:

    Oops: some error at fixed.pl line 8.

We created two frames to accomplish this: A root frame with C<frame_try> which contains the exception handler, and a nested frame with C<fub> to use as a callback. Unlike C<fub>, C<frame_try> immediately executes its frame. Because the nested callback frame is created while the root frame is executing, the callback will preserve the dynamic environment (including the exception handler) of the root frame.



=head1 USAGE

This module exports the following subs: C<frame>, C<fub>, C<frame_try>, C<frame_catch>, C<frame_local>, and C<frame_void>.

C<frame> is the general interface. The other subs are just syntactic sugar around C<frame>. C<frame> requires at least a C<code> argument which should be a coderef (a function or a closure). It will return another coderef that "wraps" the coderef you passed in. When this wrapped codref is run, it will reinstate the dynamic environment that was present when the frame was created, and then run the coderef that you passed in as C<code>.

C<frame> also accepts C<catch>, C<local>, C<existing_frame>, and C<name> parameters which are described below.

C<fub> simplifies the conversion of existing callback code into Callback::Frame enabled code. For example, given the following L<AnyEvent> statement:

    $watcher = AE::io $sock, 0, sub { do_stuff() };

In order for the callback to have its dynamic environment maintained, you just need to change it to this:

    $watcher = AE::io $sock, 0, fub { do_stuff() };

B<IMPORTANT NOTE>: All callbacks that may be invoked outside the dynamic environment of the current frame should be created with C<frame> or C<fub> so that the dynamic environment will be correctly re-applied when the callback is invoked.

The C<frame_try> and C<frame_catch> subs are equivalent to a call to C<frame> with C<code> and C<catch> parameters. However, unlike with C<frame>, the frame is executed immediately.

C<frame_void> takes a single callback argument. This can be useful if you wish to kick off an unassociated asynchronous action while handling. If the action is run in void context, there is no way for it to throw an exception that will affect your request, or to access its local variables. Note that you probably should install a separate C<frame_catch> in case the unassociated operation throws exceptions.

Libraries that wrap callbacks in frames can use the C<Callback::Frame::is_frame()> function to determine if a given callback is already wrapped in a frame. It returns true if the callback is wrapped in a frame and is therefore suitable for use with C<existing_frame>. Sometimes libraries like to automatically wrap a callback in a frame unless it already is one:

    if (!Callback::Frame::is_frame($callback)) {
      $callback = frame(code => $callback);
    }

If you wish to run a coderef inside an existing frame's dynamic environment, when creating a frame you can pass in an existing frame as the C<existing_frame> parameter. When this frame is executed, the C<code> of the frame will be run inside C<existing_frame>'s dynamic environment. This is useful for throwing exceptions from within some given callback's environment (timeouts for example):

    frame(existing_frame => $callback, code => sub {
      die "request timed out";
    })->();

C<existing_frame> is also useful for extracting/setting a callback's local variables.

Although you should never need to, the internal frame stack can be accessed at C<$Callback::Frame::top_of_stack>. When this variable is defined, a frame is currently being executed.



=head1 NESTING AND STACK-TRACES

Callback::Frame tries to make adding error handling support to an existing asynchronous application as easy as possible by not forcing you to pass extra parameters around. It should also make life easier because as a side effect of adding error checking it also can be made to produce detailed and useful "stack traces" that track the callback history of some connection or transaction.

Frames can be nested. When an exception is raised, the most deeply nested C<catch> handler is invoked. If this handler itself throws an error, the next most deeply nested handler is invoked with the new exception but the original stack trace. If the last C<catch> handler re-throws the error, the error will be thrown in whatever dynamic environment was in place when the callback was called, usually the event loop's top-level handler (probably not what you want).

When a C<catch> handler is called, not only is C<$@> set, but also a stack-trace string is passed in as the first argument. All frames will be listed in this stack-trace, starting with the most deeply nested frame.

If you want you can use simple frame names like C<"accepted"> but if you are recording error messages in a log you might find it useful to name your frames things like C<"accepted connection from $ip:$port at $time"> and C<"connecting to $host (timeout = $timeout seconds)">.

All frames you omit the name from will be shown as C<"ANONYMOUS FRAME"> in stack-traces.

Since multiple frames can be created within the same parent frame and therefore multiple child frames can be active at once, frames aren't necessarily arranged in terms of a stack. Really, the frame "stack" is more of a tree data structure (known in lisp as a "spaghetti stack"). This occurs most often when two asynchronous request frames are started up concurrently while the same frame is in effect. At this point the "stack" has essentially branched. If you are ever surprised by an exception handler being called twice, this is probably what is happening.



=head1 "LOCAL" VARIABLES

In the same way that using C<frame_catch> or the C<catch> parameter to C<frame> preserves the dynamic environment of error handlers, the C<frame_local> function or C<local> parameter to C<frame> can be used to preserve the dynamic environment of local variables. Of course, the scope of these bindings is not actually local in the physical sense of the word, only in the perl sense.

Technically, perl's C<local> maintains the dynamic environment of B<bindings>. The distinction between variables and bindings is subtle but important. See, when a lexical binding is created, it is there "forever" -- or at least until it is no longer reachable by your program according to the rules of lexical scoping. Therefore, bindings are statically mapped to lexical variables and it is redundant to distinguish between the two.

However, with dynamic variables the same variable accessed in the same part of your code can refer to different bindings at different times. That's why they are called "dynamic" and lexical variables are sometimes called "static".

Because any code in any file, function, or package can access a dynamic variable, they are the opposite of local. They are global. However, the bindings are only global for a little while at a time. After a while they go out of scope and then they are no longer visible at all. Or sometimes they will get "shadowed" by some other binding and will come back again later. Because when they are accessed determines which binding is referenced, dynamic variables are actually temporally scoped, not locally scoped (perl nomenclature notwithstanding).

To make all this concrete, consider how the binding containing C<2> is lost forever in this bit of code:

    our $foo = 1;
    my $cb;

    {
      local $foo;
      $foo = 2;
      $cb = sub {
        return $foo;
      };
    }

    say $foo;     # 1
    say $cb->();  # 1  <- not 2!
    say $foo;     # 1

Here's a way to "fix" that using Callback::Frame:

    our $foo = 1;
    my $cb;

    frame_local __PACKAGE__.'::foo', sub {
      $foo = 2;
      $cb = fub {
        return $foo;
      };
    };

    say $foo;     # 1
    say $cb->();  # 2  <- hooray!
    say $foo;     # 1

Don't be fooled into thinking that this is a lexical binding though. While the callback C<$cb> is executing, all parts of the program will see the binding containing C<2>:

    our $foo = 1;
    my $cb;

    sub global_foo_getter {
      return $foo;
    }

    frame_local __PACKAGE__.'::foo', sub {
      $foo = 2;
      $cb = fub {
        return global_foo_getter();
      };
    };

    say $foo;     # 1
    say $cb->();  # 2  <- still 2
    say $foo;     # 1

You can install multiple local variables in the same frame with the C<frame> interface:

    frame(local => __PACKAGE__.'::foo',
          local => 'main::bar',
          code => { })->();

Note that if you have both C<catch> and C<local> elements in a frame, in the event of an error the local bindings will B<not> be present inside the C<catch> handler (use a nested frame if you need this).

Variable names must be fully package qualified. The best way to do this for variables in your current package is to use the ugly C<__PACKAGE__> technique.

Objects stored in local bindings managed by Callback::Frame will not be destroyed until all references to the frame-wrapped callback that contains the binding are destroyed, along with all references to any deeper frames.



=head1 SEE ALSO

L<The Callback::Frame github repo|https://github.com/hoytech/Callback-Frame>

L<AnyEvent::Task> uses Callback::Frame and its docs have more discussion on exception handling in async apps.

This module's C<catch> syntax is of course modeled after "normal language" style exception handling as implemented by L<Try::Tiny> and similar.

This module depends on L<Guard> to maintain the C<$Callback::Frame::active_frames> datastructure and to ensure that C<local> binding updates aren't lost even when exceptions or other non-local returns occur.

L<AnyEvent::Debug> provides an interactive debugger for AnyEvent applications and uses some of the same techniques that Callback::Frame does. L<AnyEvent::Callback> and L<AnyEvent::CallbackStack> sort of solve the dynamic error handler problem. Unlike these modules, Callback::Frame is not related at all to L<AnyEvent>, except that it happens to be useful in AnyEvent libraries and applications (among other things).

L<Promises> and L<Future> are similar modules but they solve a slightly different problem. In the area of exception handling they require a more drastic restructuring of your async code because you need to pass "promise/future" objects around to maintain context. Callback::Frame is context-less (or rather the context is implicit in the dynamic state). That said, both of these modules should be compatible with Callback::Frame.

Miscellaneous other modules: L<IO::Lambda::Backtrace>, L<POE::Filter::ErrorProof>

Python Tornado's L<StackContext|http://www.tornadoweb.org/en/branch2.3/stack_context.html> and C<async_callback>

L<Let Over Lambda, Chapter 2|http://letoverlambda.com/index.cl/guest/chap2.html>

L<UNWIND-PROTECT vs. Continuations|http://www.nhplace.com/kent/PFAQ/unwind-protect-vs-continuations-original.html>



=head1 BUGS

For now, C<local> bindings can only be created in the scalar namespace. Also, none of the other nifty things that L<local> can do (like localising a hash table value) are supported yet.



=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012-2016 Doug Hoyte.

This module is licensed under the same terms as perl itself.

=cut



TODO:

  * frame_try should check to see what context it is being called on and preserve this for its try callback
