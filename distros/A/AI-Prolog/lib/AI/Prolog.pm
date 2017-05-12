package AI::Prolog;
$VERSION = '0.741';    ## no critic
use strict;
use Carp qw( confess carp croak );

use Hash::Util 'lock_keys';
use Exporter::Tidy shortcuts => [qw/Parser Term Engine/];

use aliased 'AI::Prolog::Parser';
use aliased 'AI::Prolog::Term';
use aliased 'AI::Prolog::Engine';

use Text::Quote;
use Regexp::Common;

# they don't want pretty printed strings if they're using this interface
Engine->formatted(0);

# Until (and unless) we figure out the weird bug that prevents some values
# binding in the external interface, we need to stick with this as the default
Engine->raw_results(1);

sub new {
    my ( $class, $program ) = @_;
    my $self = bless {
        _prog   => Parser->consult($program),
        _query  => undef,
        _engine => undef,
    } => $class;
    lock_keys %$self;
    return $self;
}

sub do {
    my ( $self, $query ) = @_;
    $self->query($query);
    1 while $self->results;
    $self;
}

sub query {
    my ( $self, $query ) = @_;

    # make that final period optional
    $query .= '.' unless $query =~ /\.$/;
    $self->{_query} = Term->new($query);
    unless ( defined $self->{_engine} ) {

        # prime the pump
        $self->{_engine} = Engine->new( @{$self}{qw/_query _prog/} );
    }
    $self->{_engine}->query( $self->{_query} );
    return $self;
}

sub results {
    my $self = shift;
    unless ( defined $self->{_query} ) {
        croak "You can't fetch results because you have not set a query";
    }
    $self->{_engine}->results;
}

sub trace {
    my $self = shift;
    if (@_) {
        $self->{_engine}->trace(shift);
        return $self;
    }
    return $self->{_engine}->trace;
}

sub raw_results {
    my $class = shift;
    if (@_) {
        Engine->raw_results(shift);
        return $class;
    }
    return Engine->raw_results;
}

my $QUOTER;

sub quote {
    my ( $proto, $string ) = @_;
    $QUOTER = Text::Quote->new unless $QUOTER;
    return $QUOTER->quote_simple($string);
}

sub list {
    my $proto = shift;
    return
        join ", " => map { /^$RE{num}{real}$/ ? $_ : $proto->quote($_) } @_;
}

sub continue {
    my $self = shift;
    return 1 unless $self->{_engine};    # we haven't started yet!
    !$self->{_engine}->halt;
}

1;

__END__

=head1 NAME

AI::Prolog - Perl extension for logic programming.

=head1 SYNOPSIS

 use AI::Prolog;
 use Data::Dumper;

 my $database = <<'END_PROLOG';
   append([], X, X).
   append([W|X],Y,[W|Z]) :- append(X,Y,Z).
 END_PROLOG

 my $prolog = AI::Prolog->new($database);
 
 my $list   = $prolog->list(qw/a b c d/);
 $prolog->query("append(X,Y,[$list]).");
 while (my $result = $prolog->results) {
     print Dumper $result;
 }

=head1 ABSTRACT

 AI::Prolog is merely a convenient wrapper for a pure Perl Prolog compiler.
 Regrettably, at the current time, this requires you to know Prolog.  That will
 change in the future.

=head1 EXECUTIVE SUMMARY

In Perl, we traditionally tell the language how to find a solution.  In logic
programming, we describe what a solution would look like and let the language
find it for us.

=head1 QUICKSTART

For those who like to just dive right in, this distribution contains a Prolog
shell called C<aiprolog> and two short adventure games, C<spider.pro> and
C<sleepy.pro>.  If you have installed the C<aiprolog> shell, you can run
either game with the command:

 aiprolog data/spider.pro
 aiprolog data/sleepy.pro

When the C<aiprolog> shell starts, you can type C<start.> to see how to play
the game.  Typing C<halt.> and hitting return twice will allow you to exit.

See the C<bin/> and C<data/> directories in the distribution.

Additionally, you can read L<AI::Prolog::Article> for a better description of
how to use C<AI::Prolog>.  This document is an article originally published in
The Perl Review (L<http://www.theperlreview.com/>) and which they have
graciously allowed me to redistribute.

See also Robert Pratte's perl.com article, "Logic Programming with Perl and
Prolog" (L<http://www.perl.com/pub/a/2005/12/15/perl_prolog.html>) for more
more examples.

=head1 DESCRIPTION

C<AI::Prolog> is a pure Perl predicate logic engine.  In predicate logic,
instead of telling the computer how to do something, you tell the computer what
something is and let it figure out how to do it.  Conceptually this is similar
to regular expressions.

 my @matches = $string =~ /XX(YY?)ZZ/g

If the string contains data that will satisfy the pattern, C<@matches> will
contain a bunch of "YY" and "Y"s.  Note that you're not telling the program how
to find those matches.  Instead, you supply it with a pattern and it goes off
and does its thing.

To learn more about Prolog, see Roman BartE<225>k's "Guide to Prolog
Programming" at L<http://kti.ms.mff.cuni.cz/~bartak/prolog/index.html>.
Amongst other things, his course uses the Java applet that C<AI::Prolog> was
ported from, so his examples will generally work with this module.

Fortunately, Prolog is fairly easy to learn.  Mastering it, on the other hand,
can be a challenge.

=head1 USING AI::Prolog

There are three basic steps to using C<AI::Prolog>.

=over 4

=item Create the Prolog program.

=item Create a query.

=item Run the query.

=back

For quick examples of how that works, see the C<examples/> directory with this
distribution.  Feel free to contribute more.

=head2 Creating a logic program

This module is actually remarkable easy to use.  To create a Prolog program,
you simply pass the Prolog code as a string to the constructor:

 my $prolog = AI::Prolog->new(<<'END_PROLOG');
    steals(PERP, STUFF) :-
        thief(PERP),
        valuable(STUFF),
        owns(VICTIM,STUFF),
        not(knows(PERP,VICTIM)).
    thief(badguy).
    valuable(gold).
    valuable(rubies).
    owns(merlyn,gold).
    owns(ovid,rubies).
    knows(badguy,merlyn).
 END_PROLOG

Side note:  in Prolog, programs are often referred to as databases.

=head2 Creating a query

To create a query for the database, use C<query>.

  $prolog->query("steals(badguy,X).");

=head2 Running a query

Call the C<results> method and inspect the C<results> object:

  while (my $result = $prolog->results) {
      # $result = [ 'steals', 'badguy', $x ]
      print "badguy steals $result->[2]\n";
  }

=head1 BUILTINS

See L<AI::Prolog::Builtins|AI::Prolog::Builtins> for the built in predicates.

=head1 CLASS METHODS

=head2 C<new($program)>

This is the constructor.  It takes a string representing a Prolog program:

 my $prolog = AI::Prolog->new($program_text);

See L<AI::Prolog::Builtins|AI::Prolog::Builtins> and the C<examples/> directory
included with this distribution for more details on the program text.

Returns an C<AI::Prolog> object.

=head2 C<trace([$boolean])>

One can "trace" the program execution by setting this property to a true value
before fetching engine results:

 AI::Prolog->trace(1);
 while (my $result = $engine->results) {
     # do something with results
 }

This sends trace information to C<STDOUT> and allows you to see how the engine
is trying to satify your goals.  Naturally, this slows things down quite a bit.

Calling C<trace> without an argument returns the current C<trace> value.

=head2 C<raw_results([$boolean])>

You can get access to the full, raw results by setting C<raw_results> to true.
In this mode, the results are returned as an array reference with the functor
as the first element and an additional element for each term.  Lists are
represented as array references.

 AI::Prolog->raw_results(1);
 $prolog->query('steals(badguy, STUFF, VICTIM)');
 while (my $r = $prolog->results) {
     # do stuff with $r in the form:
     # ['steals', 'badguy', $STUFF, $VICTIM]
 }

Calling C<raw_results> without an argument returns the current C<raw_results>
value.

This is the default behavior.

=head2 C<quote($string)>.

This method quotes a Perl string to allow C<AI::Prolog> to treat it as a proper
Prolog term (and not worry about it accidentally being treated as a variable if
it begins with an upper-case letter).

 my $perl6 = AI::Prolog->quote('Perl 6'); # returns 'Perl 6' (with quotes)
 $prolog->query(qq'can_program("ovid",$perl6).');

At the present time, quoted strings may use single or double quotes as strings.
This is somewhat different from standard Prolog which treats a double-quoted
string as a list of characters.

Maybe called on an instance (the behavior is unchanged).

=head2 C<list(@list)>.

Turns a Perl list into a Prolog list and makes it suitable for embedding into
a program.  This will quote individual variables, unless it thinks they are
a number.  If you wish numbers to be quoted with this method, you will need to
quote them manually.

This method does not add the list brackets.

 my $list = AI::Prolog->list(qw/foo Bar 7 baz/);
 # returns:  'foo', 'Bar', 7, 'baz'
 $prolog->query(qq/append(X,Y,[$list])./);

May be called on an instance (the behavior is unchanged).

=head1 INSTANCE METHODS

=head2 C<do($query_string)>

This method is useful when you wish to combine the C<query()> and C<results()>
methods but don't care about the results returned.  Most often used with the
C<assert(X)> and C<retract(X)> predicates.

 $prolog->do('assert(loves(ovid,perl)).');

This is a shorthand for:

 $prolog->query('assert(loves(ovid,perl)).');
 1 while $prolog->results;

This is important because the C<query()> method merely builds the query.  Not
until the C<results()> method is called is the command actually executed.

=head2 C<query($query_string)>

After instantiating an C<AI::Prolog> object, use this method to query it.
Queries currently take the form of a valid prolog query but the final period
is optional:

 $prolog->query('grandfather(Ancestor, julie).');

This method returns C<$self>.

=head2 C<results>

After a query has been issued, this method will return results satisfying the
query.  When no more results are available, this method returns C<undef>.

 while (my $result = $prolog->results) {
     # [ 'grandfather', $ancestor, 'julie' ]
     print "$result->[1] is a grandfather of julie.\n";
 }

If C<raw_results> is false, the return value will be a "result" object with
methods corresponding to the variables.  This is currently implemented as a
L<Hash::AsObject|Hash::AsObject> so the caveats with that module apply.

Please note that this interface is experimental and may change.

 $prolog->query('steals("Bad guy", STUFF, VICTIM)');
 while (my $r = $prolog->results) {
     print "Bad guy steals %s from %s\n", $r->STUFF, $r->VICTIM;
 }

See C<raw_results> for an alternate way of generating output.

=head1 BUGS

See L<AI::Prolog::Builtins|AI::Prolog::Builtins> and
L<AI::Prolog::Engine|AI::Prolog::Engine> for known bugs and limitations.  Let
me know if (when) you find them.  See the built-ins TODO list before that,
though.

=head1 TODO

=over 4

=item * Why does this take so long to run?

 perl examples/path.pl 3

On my Mac that takes over an hour to complete.

=item * Support for more builtins.

=item * Performance improvements.

I have a number of ideas for this, but it's pretty low-priority until things
are stabilized.

=item * Add "sugar" interface.

=item * Better docs.

=item * Tutorial.

=item * Data structure cookbook.

=item * Better error reporting.

=back

=head1 EXPORT

None by default.  However, for convenience, you can choose ":all" functions to
be exported.  That will provide you with C<Term>, C<Parser>, and C<Engine>
classes.  This is not recommended and most support and documentation will now
target the C<AI::Prolog> interface.

If you choose not to export the functions, you may use the fully qualified
package names instead:

 use AI::Prolog;
 my $database = AI::Prolog::Parser->consult(<<'END_PROLOG');
 append([], X, X).
 append([W|X],Y,[W|Z]) :- append(X,Y,Z).
 END_PROLOG

 my $query  = AI::Prolog::Term->new("append(X,Y,[a,b,c,d]).");
 my $engine = AI::Prolog::Engine->new($query,$database);
 while (my $result = $engine->results) {
     print "$result\n";
 }

=head1 SEE ALSO

L<AI::Prolog::Introduction>

L<AI::Prolog::Builtins>

W-Prolog:  L<http://goanna.cs.rmit.edu.au/~winikoff/wp/>

X-Prolog:  L<http://www.iro.umontreal.ca/~vaucher/XProlog/>

Roman BartE<225>k's online guide to programming Prolog:
L<http://kti.ms.mff.cuni.cz/~bartak/prolog/index.html>

=head1 AUTHOR

Curtis "Ovid" Poe, E<lt>moc tod oohay ta eop_divo_sitrucE<gt>

Reverse the name to email me.

This work is based on W-Prolog, L<http://goanna.cs.rmit.edu.au/~winikoff/wp/>,
by Dr. Michael Winikoff.  Many thanks to Dr. Winikoff for granting me
permission to port this.

Many features also borrowed from X-Prolog L<http://www.iro.umontreal.ca/~vaucher/XProlog/>
with Dr. Jean Vaucher's permission.

=head1 ACKNOWLEDGEMENTS

Patches and other help has also been provided by: Joshua ben Jore and
Sean O'Rourke.

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Curtis "Ovid" Poe

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
