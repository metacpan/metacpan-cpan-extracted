package AI::Evolve::Befunge;
use strict;
use warnings;

our $VERSION = "0.03";

=head1 NAME

    AI::Evolve::Befunge - practical evolution of Befunge AI programs


=head1 SYNOPSIS

    use aliased 'AI::Evolve::Befunge::Population' => 'Population';
    use AI::Evolve::Befunge::Util qw(v nonquiet);

    $pop = Population->new();

    while(1) {
        my $gen  = $pop->generation;
        nonquiet("generation $gen\n");
        $pop->fight();
        $pop->breed();
        $pop->migrate();
        $pop->save();
        $pop->generation($gen+1);
    }


=head1 DESCRIPTION

This software project provides all of the necessary tools to grow a
population of AI creatures which are fit to perform a task.

Normally, end users can use the "evolve" script as a frontend.  If
that's what you're after, please see the documentation contained
within that script.  Otherwise, read on.

This particular file (AI/Evolve/Befunge.pm) does not contain any code;
it exists mainly to provide a version number to keep Build.PL happy.
The rest of this file acts as a quick-start guide to the rest of the
codebase.

The important bits from a user's standpoint are the Population object
(which drives the main process of evolving AI), and the Physics plugin
(which implements the rules of the universe those AI live in).  There
are sections below containing more detail on what these two things
are, and how they work.


=head1 POPULATIONS

The Population object is the main user interface to this project.
Basically you just keep running it over and over, and presumably, the
result gets better and better.

The important thing to remember here is that the results take time -
it will probably take several weeks of solid processing time before you
begin to see any promising results at all.  It takes a lot of random
code generation before it starts to generate code that does what you
want it to do.

If you don't know anything about Befunge, I recommend you read up on
that first, before trying to understand how this works.

The individuals of this population (which we call Critters) may be of
various sizes, and may make heavy or light use of threads and stacks.
Each one is issued a certain number of "tokens" (which you can think
of as blood sugar or battery power).  Just being born takes a certain
number of tokens, depending on the code size.  After that, doing things
(like executing a befunge command, pushing a value to the stack,
spawning a thread) all take a certain number of tokens to accomplish.
When the number of tokens drops to 0, the critter dies.  So it had
better accomplish its task before that happens.

After a population fights it out for a while, the winners are chosen
(who continue to live) and everyone else dies.  Then a new population
is generated from the winners, some random mutation (random
generation of code, as well as potentially resizing the codebase)
occurs, and the whole process starts over for the next generation.


=head1 PHYSICS

At the other end of all of this is the Physics plugin.  The Physics
plugin implements the rules of the universe inhabited by these AI
creatures.  It provides a scoring mechanism through which multiple
critters may be weighed against eachother.  It provides a set of
commands which may be used by the critters to do useful things within
its universe (such as make a move in a board game, do a spellcheck,
or request a google search).

Physics engines register themselves with the Physics database (which
is managed by Physics.pm).  The arguments they pass to
register_physics() get wrapped up in a hash reference, which is copied
for you whenever you call Physics->new("pluginname").  The "commands"
argument is particularly important: this is where you add special
befunge commands and provide references to callback functions to
implement them.

One special attribute, "generations", is set by the Population code
and can determine some of the parameters for more complex Physics
plugins.  For instance, a "Go" game might wish to increase the board
size, or enable more complex rules, once a certain amount of evolution
has occurred.

Rather than describing the entire API in detail, I suggest you read
through the "othello" and "ttt" modules provided along with this
distribution.  They are small and simple, and should make good
examples.


=head1 MIGRATION

Further performance may be improved through the use of migration.

Migration is a very simple form of parallel processing.  It should scale
nearly linearly, and is a very effective means of increasing performance.

The idea is, you run multiple populations on multiple machines (one per
machine).  The only requirement is that each Population has a different
"hostname" setting.  And that's not really a requirement, it's just useful
for tracking down which host a critter came from.

When a Population object has finished processing a generation, there is
a chance that one or more (up to 3) of the surviving critters will be
written out to a special directory (which acts as an "outbox").

A separate networking program (implemented by Migrator.pm and spawned
automatically when creating a Population object) may pick up these
critters and broadcast them to some or all of the other nodes in a cluster
(deleting them from the "outbox" folder at the same time).  The instances
of this networking program on the other nodes will receive them, and write
them out to another special directory (which acts as an "inbox").

When a Population object has finished processing a generation, another
thing it does is checks the "inbox" directory for any new incoming
critters.  If they are detected, they are imported into the population
(and deleted from the "inbox").

Imported critters will compete in the next generation.  If they win,
they will be involved in the reproduction process and may contribute to
the local gene pool.

On the server end, a script called "migrationd" is provided to accept
connections and distribute critters between nodes.  The config file
specifies which server to connect to.  See the CONFIG FILE section,
below.


=head1 PRACTICAL APPLICATION

So, the purpose is to evolve some nice smart critters, but you're
probably wondering, once you get them, what do you do with them?
Well, once you get some critters that perform well, you can always
write up a production program which creates the Physics and Critter
objects and runs them directly, over and over and over to your heart's
content.  After you have reached your goal, you need not continue to
evolve or test new critters.


=head1 CONFIG FILE

You can find an example config file ("example.conf") in the source
tarball.  It contains all of the variables with their default values,
and descriptions of each.  It lets you configure many important
parameters about how the evolutionary process works, so you probably
want to copy and edit it.

This file can be copied to ".ai-evolve-befunge" in your home
directory, or "/etc/ai-evolve-befunge.conf" for sitewide use.  If both
files exist, they are both loaded, in such a way that the homedir
settings supercede the ones from /etc.  If the "AIEVOLVEBEFUNGE"
environment variable is set, that too is loaded as a config file, and
its settings take priority over the other files (if any).

=cut

1;
