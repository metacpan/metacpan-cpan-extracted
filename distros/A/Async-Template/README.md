# NAME

Async::Template - Async Template Toolkit

# SYNOPSIS

    use Async::Template (tt);

    my $cv = AnyEvent->condvar;

    my $tt = Async::Template->new({
       # ... any Template options (see Template::Manual::Config)
       INCLUDE_PATH => $src,
       ENCODING => 'utf8',

       # additional options provided by Async::Template

       # optional blocker if only one blocking tt instance is required
       # default AnyEvent blocker is enabled if no DONE handler is provided
       BLOCKER => sub{ $cv->recv; },

       # done handler - called when template process is finished
       # default event loop and blocker is enabled if DONE is not specified
       # may be redefined at the process() function
       DONE => sub{ my $output = shift; $cv->send; },
    }) || die Async::Template->error();


    # single blocked process

    my $tt = Async::Template->new({}) || die Async::Template->error();
    $tt->process($template, $vars, \$output)


    # nonblocked multiple procesess

    my $cv = AnyEvent->condvar;
    $cv->begin;
    my $tt2 = Async::Template->new({
       DONE => sub{ my $output = shift; $cv->end; },
    }) || die Async::Template->error();
    $cv->begin;
    AnyEvent->timer(after => 10, cb => sub { $cv->end; });
    $cv->recv


    # usage in perl code for async processes

    my $vars = {
      some_async_fn => sub {
         my ($param, $callback) = @_;
         $callback->(error, result);
      },
      api => SomeObj->new({}),
    }

    tt $vars, << 'END',
       USE timeout = Second;
       AWAIT timeout.start(10)

       r = AWAIT api.call('endpoint', {param = 'val'});
       error = ERROR(r);
       result = RESULT(r);
       RETURN IF ERROR(r);

       p2 = ASYNC some_async_fn('param');
       p1 = ASYNC api.call('endpoint', {});
       AWAIT p1;
       AWAIT p2;
       RETURN IF RESULT(r);
     END
     sub{
        use Data::Dumper; warn Dumper \@_;
        die $_[0] if($_[0]);
        print 'result: ', $_[1];
     };

# DESCRIPTION

Async::Template is the same as Template Toolkit with asynchronous interface and
with asynchronous operators ASYNC/AWAIT which can be used with any event
management system (like [AnyEvent](https://metacpan.org/pod/AnyEvent)).

To refer Template Toolkit language syntax, configure options, params and other
documentation folow this link [Template](https://metacpan.org/pod/Template).

Operators like ASYNC/AWAIT itself is not an function or something wich applied
locally at the place where it is used in the code. Such operators affect all
the code generation and the execution sequences. Any block of code cease to be
a block if at least one async operator is exists in it. Loops, blocks,
conditions, switches, and so on become different in synchronous and asynchronous
implementations.

For example a synchronous loop is continuous sequence which at the end of loop
has a transition to the begin of the loop. But the asynchronous loop is not
a continuos sequence and to do transition to the begin of loop typical loop
operators can not be used because begin and end of loop located in different
unjoined betwen each other code sequences (in a different fuctions).
This is because at the middle of the loop at the place of async operator
presents a finish of the execution and return. This return must be supported
by each of parent block statement. Execution must be returned to the very top
of the execution - to the event loop. And after awaited event condition is
reached the execution must continue from that place from which it was returned.

Therefore to develop a compiler with asynchronous operators it need to have
different synchronous and asynchronous implementation for each block operator of
language and many more. And for synchronous an asynchronous function call. This
library represent itself compiler with modified grammar based on Template
Toolkit. This library provides implementation of asynchronous operators and the
code generation and asynchronous stack management and so on, uses itself as
library for asynchronous sequences and uses Template Toolkit as library for
execution generic synchronous sequences and also uses parts modified to be
asynchronous.

## SYNC AND ASYNC BLOCKS 

Continuous sequence of execution is tÐµaring at the place of AWAIT operator.
The block is not only BLOCK operator statement but also IF, WHILE and etc...

Any block become asynchronous if it have at least one AWAIT operator or
another asynchronous block.

Any block is synchronous if it does not contain AWAIT operator or another
asynchronous block even if it has any amount of ASYNC opeartor

Any block does not become asynchronous if it has ASYNC operator inside
(if it has no AWAIT operator nor one or more asynchronous block).

## TODO

As mentioned above, each block of code must be implemented differently
therefore this library has asynchronous implementation for most of block
operators of Template Toolkit language but not all yet.

The block operators which is not implemented as asynchronous will work anyway
with synchronous sequences (i.e. without AWAIT operator inside of it). 

Here the list of Template Toolkit operators async implementation of which does
not checked and/or implemented:

NEXT LAST STOP

MACRO FILTER

TRY / THROW / CATCH / FINAL

PERL / RAWPERL

# AUTHOR

Serguei Okladnikov <oklaspec@gmail.com>

This [Async::Template](https://metacpan.org/pod/Async%3A%3ATemplate) package uses "Template Toolkit" ([Template](https://metacpan.org/pod/Template))
as dependency and contains small amount modified parts of "Template Toolkit"
(modified grammar and continuous synchronous code which was necessary
to split for execution asynchronous sequences). The "Template Toolkit" was
written by Andy Wardley <abw@wardley.org> and contributors, see
Template::Manual::Credits for details and repos contributors sections.

# LICENSE 

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 285:

    Non-ASCII character seen before =encoding in 'tÐµaring'. Assuming CP1252
