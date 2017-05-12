package ConditionSystem;
BEGIN {
  $ConditionSystem::VERSION = '0.02';
}
# ABSTRACT: A Common Lisp like condition/restart system for exceptions

use strict;
use warnings FATAL => 'all';

use Scope::Upper qw( unwind :words );
use Scalar::Util 'blessed';
use Try::Tiny;

use Sub::Exporter -setup => {
    exports => [qw( restart with_handlers bind_continue handle restart_case )],
    groups => {
        default => [qw( restart with_handlers bind_continue handle restart_case )]
    }
};


our %handlers;
our %cases;

BEGIN {
    no strict 'refs';
    *{'CORE::GLOBAL::die'} = sub {
        my $err = shift;
        for my $handles (keys %handlers) {
            if($err->isa($handles)) {
                my $handler = $handlers{$handles};
                $handler = ${$handler}
                    if blessed($handler) && $handler->isa('Try::Tiny::Catch');
                unwind $handler->($err) => UP UP HERE;
                return "Well, it should never get here...";
            }
        }
    };
};


sub with_handlers (&@) {
    my ($code, %handles) = @_;
    %handlers = %handles; # XXX Should push onto each handler as a queue
    my @ret = $code->();
    %handlers = ();
    return @ret;
}


sub continue_with (&) {
    my @vals = @_;
    return sub { @vals }
}


sub restart {
    my $name = shift;
    my @args = @_;
    return sub {
        $cases{$name}->(@args)
    };
}


sub restart_case (&@) {
    my $error = shift->();
    %cases = @_;
    die $error;
}

# Nom. Sugarz


sub handle {
    my ($handles, $code) = @_;
    return $handles => $code;
}


sub bind_continue {
    my ($restart, $code) = @_;
    return $restart => $code;
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

ConditionSystem - A Common Lisp like condition/restart system for exceptions

=head1 SYNOPSIS

{
    package MalformedLogEntry;
    use Moose;
    extends 'Throwable::Error';

    has bad_data => ( is => 'ro' );

    package LogParser;
    use Conditions;
    sub parse_log_entry {
        my $entry = shift or die "Must specify entry";
        if($entry =~ /(\d+-\d+-\d+) (\d+:\d+:\d+) (\w+) (.*)/) {
            return ($1, $2, $3, $4);
        }
        else {
            restart_case {
                MalformedLogEntry->new($entry),
            }
            bind_continue(use_value => sub { return shift }),
            bind_continue(log => sub {
                warn "*** Invalid entry: $entry";
                return undef;
            });
        }
    };

    package MyApp;
    use Conditions;
    my @logs = with_handlers {
        [ parse_log_entry('2010-01-01 10:09:5 WARN Test') ],
        [ parse_log_entry('Oh no bad data') ],
        [ parse_log_entry('2010-10-12 12:11:03 INFO Notice it still carries on!') ];
    }
    handle(MalformedLogEntry => restart('log'));

    # @logs contains 3 logs, the 2nd of which is 'undef'
    # A single warning will have been printed to STDERR as well.
};

=head1 DESCRIPTION

This distribution implements a Common Lisp-like approach to exception handling,
providing both a mechanism for throwing/catching exceptions, but also a
mechanism for continuing on from an exception via a non-local exit. This
essentially allows you "fix" the code that was throwing an exception from
outside that code itself, rather than trying to handle stuff when it's already
too late.

For a good introduction to the condition system (that this was all inspired by),
I highly recommend L<Practical Common Lisp|http://gigamonkeys.com/book/>, in
particular the chapter
L<Beyond Exception Handling|http://gigamonkeys.com/book/beyond-exception-handling-conditions-and-restarts.html>

B<HALT!> This module is both very new, and does some fairly crazy things, and
as such may not be ready for prime time usage. However, the basic test cases
do pass, so maybe you will have some luck. I encourage the usage of this module
for a bit of fun, and exploration for now. Hopefully it will mature into a 
production ready module, but it's not there yet. But with your help, it can be
so... please submit patches, bug reports and all that goodness.

=head1 FUNCTIONS

=head2 with_handlers

Run a block of code, and if any exception is raised, try and invoke one of the
handlers.

    with_handlers {
        # Dangerous code...
    }
    handle(ExceptionType => sub {
        # Recovery
    });

=head2 continue_with

Return from a restart with a specific value.

    with_handlers {
        my $foo = restart_case {
            Exception->new
        }
        # foo is 500
    }
    handle(Exception => continue_with { 500 });

=head2 restart

Invoke a restart with a specific name, and pass extra arguments through.

with_handlers {
    restart_case {
        Exception->new
    }
    bind_restart(Log => sub {
        warn "An Exception was raised";
    });
} handle(Exception => restart('Log'))

=head2 restart_case

Throw an exception (from a specified block) with pre-defined strategies on
how to resume execution later.

    restart_case { Exception->new }
    bind_restart(delegate_responsibility => sub {
        Boss->email($bug_report)
    })

The body of C<restart_case> must yield an exception, and will be when the
restart case is invoked. There may be 0 to many restarts provided. Restarts
are invoked by L<restart>, called from a handler set up with L<with_handlers>.

=head2 handle

Create a handler for a given exception type, and associated code reference:

    handle('Exception::Class' => sub {
        # Handle exception here...
    });

=head2 bind_continue

Bind a restart for the scope of a restart_case block, with a given name and
code reference:

    bind_continue(panic => sub {
        warn "OMG OMG OMG OMG";
    });

=head1 AUTHOR

Oliver Charles

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Oliver Charles <oliver.g.charles@googlemail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

