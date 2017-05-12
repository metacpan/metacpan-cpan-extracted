package Acme::OneHundredNotOut;
our $VERSION = "100";

=pod

=head1 NAME

Acme::OneHundredNotOut - A raise of the bat, a tip of the hat

=head1 TEXT

I have just released my 100th module to CPAN, the first time that anyone
has reached that target. As some of you may know, I am getting ready to
go back to college and reinvent myself from being a programmer into
being a missionary. I don't forsee that many more Perl modules coming
out of this.

Of course, this doesn't mean that I'm going to abjure usage of Perl
forever; any time there's a computer and something I need automated, out
will come the Swiss Army Chainsaw and the job will get done. In fact, we
recently needed to manipulate some text from a mission handbook to
translate it into Japanese, and Perl was there handling and collating
all that.

But 100 modules is a convenient place to stop and take stock, and I hope
that those of you who have benefitted from my modules, programs or
writing about Perl will forgive me a certain spot of self-indulgence as
I look back over my CPAN career, especially since I feel that the
diversity of modules that I've produced is a good indication of the
diversity of what can be done with Perl.

Let's begin, then, with some humble beginnings, and then catch up on
recent history.

=head2 The Embarrassing Past

Contrary to popular belief, I was not always a CPAN author. I started
writing modules in 1998, immediately after reading the first edition of
the Perl Cookbook - yes, you can blame Nat and Tom for all this. The
first module that I released was L<Tie::DiscoveryHash>, since I'd just
learnt about tied hashes. As with many of my modules, it was an integral
part of another software project which I actually never finished, and
now can't find. 

The first module that I ever B<wrote> (but, by a curious quirk of fate,
precisely the fiftieth module I released) was called L<String::Tokeniser>,
which is still a reasonably handy way of getting an iterator over
tokenising a string. (Someone recently released C<String::Tokenizer>,
which makes me laugh.) This too was for an abortive project, C<webperl>,
an application of Don Knuth's WEB system of structured documentation to
Perl. However, given the code quality of these two modules, it's perhaps
just as well that the projects never saw the light of day.

There are a few other modules I'd rather like to forget, too.
C<Devel::Pointer> was a sick joke that went badly wrong - it allowed
people to use pointers in Perl. Some people failed to notice that
referring to memory locations directly in an extremely high-level
language was a dangerous and silly thing to do, and actually used the
damned thing, and I started getting requests for support for it. Then at
some point in 2001, when I should really have known better, I developed
an interest in Microsoft's .NET and the C# language, which I still think
is pretty neat; but I decided it might be a good idea to translate the
Mono project's tokenizer and parser into Perl, ending up with
L<C::Sharp>. I never got around to doing the parser part, or indeed
anything else with it, and so it died a lonely death in a dark corner of
CPAN. L<GTK::HandyClist> was my foray into programming graphical
applications, which started and ended there. L<Bundle::SDK::SIMON> was
actually the slides from a talk on my top ten favourite CPAN modules -
except that this changes so quickly over time, it doesn't really make
much sense any more.

Finally, L<Array::FileReader> was an attempt to optimize a file access
process. Unfortunately, my "optimization" ended up introducing more
overheads than the naive solution. It all goes to show. Since then,
Mark-Jason Dominus, another huge influence in the development of my CPAN
career, has written C<Tie::File>, which not only has a better name but
is actually efficient too.

=head2 The Internals Phase

1999-2000 were disastrous years for me personally but magnificent years
Perl-sonally. Stuck in a boring job and a tiny flat in the middle of
Tokyo, I had plenty of time to get stuck into more Perl development. I
felt that getting involved with C<perl5-porters> would be a good way of
gettting to know more about Perl, and so I needed a hobby horse - an
issue of Perl's development that I cared about. Since I was in Japan and
working a lot with non-Latin text, Unicode support seemed a good thing
to work on, and so L<Unicode::Decompose> appeared, while I fixed up a
substantial part of the post-5.6 core Unicode support.

I'd recommend this way to anyone who wants to get more involved in the
Perl community, although I was very lucky in terms of who else happened
to be around at the time: Gurusamy Sarathy was extremely gracious in
helping me turn my fledgling C code into something fit for the Perl
core, and he also helped me understand the C<perl5-porters> etiquette
(yes, there was some at the time) and what makes a good patch, while
Jarkko Hietaniemi was always good for suggestions of interesting things
for keen people to work on. Seriously, get involved. If I can do it,
anyone can.

Anyway, this fixation with understanding the Perl 5 internals, and
especially the Perl 5 compiler, (due to yet another of my Perl
influences, the great Malcolm Beattie) led to quite a torrent of
modules, from L<ByteCache>, an implementation of just-in-time
compilation for Perl modules, through L<B::Flags> and L<B::Tree> to help
visualising the Perl op tree, to L<uninit>, L<B::Generate>, L<optimizer>
and L<B::Utils> for modifying it.

=head2 Perl About The House

Now we abandon chronological order somewhat and take a look at the
various areas in which I've used Perl. One of these areas has been the
automation of everyday life: checking my bank balance with
L<Finance::Bank::LloydsTSB> (the first Perl module to interface to
personal internet banking, no less) and my phone bill with a release of
Tony Bowden's L<Data::BT::PhoneBill>. 

L<Finance::Bank::LloydsTSB> was meant to go with L<Finance::QIF>, my
Quicken file parser, to produce another now-abandoned idea, a Perl
finances manager. It seemed that I'm only capable of producing modules,
not full standalone applications - or at least, it seemed that way until
I produced L<Bryar>, my blogging software, based on the concepts from
Rael Dornfest's C<blosxom> and beginning my adventures with Andy
Wardley's Template Toolkit. Bryar also tuned me in to the
Model-View-Controller framework idea, of which more later.

Another project I briefly played with was a personal robot, using the
C<Sphinx>/C<Festival> speech handling and recognition modules from
Cepstral and Kevin Lenzo. I didn't have X10, so I couldn't shout
"lights" into the air in a wonderfully scifi way, but I could shout
"mail" and have a summary of my inbox read to me, "news" to get the
latest BBC news headlines, and "time" to hear the time. Of course,
getting computers to tell the time nicely takes a little bit of work. I
don't like "It's eleven oh-three pee em", since that's not what someone
would say if you asked them the time. I wanted my robot to say "It's
just after eleven", and that's what L<Time::Human> does. Shame about the
localisation.

=head2 Messing About With Classes

One of the things that continues to amaze me about Perl is its
flexibility; the way you can change core parts of its operation, even
from pure Perl. This lead to quite a few modules, many of which were
mere proofs of concept.

L<Sub::Versive>, for instance, was the first module on CPAN to handle
pre- and post-hooks for a subroutine; it has since been joined by a
plethora of imitators. It was written, though, in response to a peculiar
scenario. I was writing a module (C<Safety::First>) which provided
additional built-in-like functions for Perl to encourage and facilitate
defensive programming and intelligible error reporting. ("Couldn't open
file? Why not?") These built-ins had to be available from every
package, which meant playing with C<UNIVERSAL::AUTOLOAD>. But what if
another package was already using C<UNIVERSAL::AUTOLOAD>? Hence,
C<Sub::Versive> wrapped it in a pre-hook. Of course, with the
interesting bit of the problem solved, C<Safety::First> was abandoned.

L<Class::Dynamic> was an interesting attempt to provide support for code
references in C<@ISA>, analogous to code references in C<@INC>. It
works, but of course I could never find any practical use for it.

L<Class::Wrap> was written as a lazy profiler. A certain application I
was writing for my employer of the time, Kasei, made use of the (IMHO
evil) C<Mail::Message> module. How do we isolate all calls to that
class? There are plenty of modules out there for instrumenting
individual methods, including of course C<Sub::Versive>. But the whole
class? C<Class::Wrap> takes a wonderfully brute-force but workable
approach to the problem. A real profiler, however, can be constructed
from L<Devel::DProfPP>, which is sort of a profiler toolkit.

I wrote a couple of other modules with Kasei in this category,
particularly while working on our Plucene port of the Lucene search
engine. (I guess I could claim C<Plucene> as one of my 100 modules, but
that would be to deny Marc Kerr the recognition he deserves for the work
he put in to packaging, documenting and providing tests for my insane
and scrambled code.) I wrote L<Bit::Vector::Minimal>, for instance, as I
ported C<org.apache.lucene.util.BitVector>; L<Tie::Array::Stored>, which
I'm amazed wasn't already implemented on CPAN, provided the Perl
equivalent of C<org.apache.lucene.util.PriorityQueue>.
L<Lucene::QueryParser>, of course, does what it says on the tin. (I also
produced a couple of add-ons for Plucene after leaving Kasei when I was
doing a bit of Plucene consultancy:
L<Plucene::Plugin::Analyzer::PorterAnalyzer> and
L<Plucene::Plugin::WeightedQueryParser>.)

Another module produced in the course of writing Plucene was
L<Class::HasA>, a handy little utility module which works well with Tony
Bowden's C<Class::Accessor> and merely dispatches certain method calls
to objects contained within your object.

And speaking of C<Class::Accessor>, L<Class::Accessor::Assert> would
have been a godsend while writing Plucene, as it's a version of accessor
handling which typechecks what you're putting into the accessor slots.
When you're converting a typed language into an untyped one, occasional
checks that you're handling the right kind of object don't go amiss. I
learnt my lesson eventually, though, and wrote the module after Plucene
was done.

Another Java-influenced module was C<Attribute::Final>, which was written 
for my book Advanced Perl Programming as an example of both attributes
and messing about with the class module - by marking some subtourines as
C<:final>, you get an error if a derived class attempts to override it.
As with many of my proof-of-concept modules, this isn't something I'd
ever use myself, but I know others have used it. I'll let you into a
secret - over the past few months I've settled on giving modules a
version number of C<0.x> if I've never used them myself and C<1.x> if I
have.

Java wasn't the only language to influence my Perl coding activities.
Ruby is a wonderful little language I first encountered in Japan, but
didn't really get into until around 2003. Of course, when you see
another language has dome good ideas, you steal them, which is what I
did with L<rubyisms>, L<SUPER>, and L<Class::SingletonMethod> - all of
which, by the way, are B<excellent> examples of what you can do to the
behaviour of Perl just from pure Perl. C<SUPER> is the kind of module
I've so often wanted to use in production code but never dared.

=head2 Smart Perl

My views on human-computer interface and computer usability have been
unchanged since I wrote C<Tie::DiscoveryHash> way back in the mists of
time. The underlying principle behind that module was simple: the user
should B<never> tell the computer anything it already knows or can
reasonably be expected to work out. C<Tie::DiscoveryHash> was all about
having the computer find out stuff for itself.

This has influenced a number of my modules, which have focussed on
trying to make everything as simple as possible for the user (or more
usually, for the programmer using my modules) and then a bit simpler.

So, for instance, I found the whole process of keeping values persistent
between runs of Perl a bit of a nightmare - I could never remember the
syntax for tying to C<DB_File>, and I would always forget to use the
extremely handy C<MLDBM> module. I just wanted to say "keep this
variable around". L<Attribute::Persistent> does just that, cleanly and
simply. It even works out a sensible place to put the database, so you
don't have to.

Similarly, L<Config::Auto> works out where your application might keep a
configuration file, works out what format it's in, parses it, and hands
you back a hash. No muss, no fuss. And more importantly, no need to even
think about writing a config file parser again. It's done once, forever.
L<Getopt::Auto> applies the same design principles to handling command
line arguments - I hate forgetting how to use C<Getopt::Long>.

Other attempts at making things simple for the end-user weren't that
successful. As part of writing my (first) mail archiving and indexing
program, C<Mail::Miner>, of which more later, I wanted a nice way for
users to specify a time period in which they're looking for mails - "a
week ago", "sometime last summer", "near the beginning of last month" -
and so on. L<Date::PeriodParser> would take these descriptions and turn
them into a start and end time in which to search. Except, of course,
that this is a very hard thing to do and requires a lot of heuristics,
and while I started off quite well, as ever, I got distracted with other
interesting and considerably more tractable problems.

=head2 Mail Handling

A good number of my Perl modules focussed on mail handling, so many that
I was actually able to get a job basically doing mail processing in
Perl. It all started with L<Mail::Audit>. I was introduced to
F<procmail> at University, and it was useful enough, but it kept having
locking problems and losing my mail, and I didn't really understand it,
to be honest, so I wanted to write my mail filtering rules in Perl.
C<Mail::Audit> worked well for a couple of years before it grew into an
obese monster. I actually only use a very old version of C<Mail::Audit>
on my production server.

As part of the attempt to slim it back down again, I abstracted out one
of the major parts of its functionality, delivering an email to a local
mailbox. Now I only use mbox files, so it was reasonably easy for me,
but people wanted me to add Maildir and whatever to C<Mail::Audit>, so I
kicked it all out to L<Mail::LocalDelivery> instead.

But I found that I still wasn't able to filter my mail adequately and
find the stuff I needed from it. Attachments were a big problem, since
they both made ordinary search with C<grep> or C<grepmail> much slower,
and they weren't always easy to find anyway. So I wrote something to
remove attachments from mail and stick them in a database, and while I'm
at it, index mail for quick retrieval. And then it grew to identifying
"interesting" features of an email and searching for them too, and then
L<Mail::Miner> was born.

Finally, I got into web display of archived email, and needed a way of
displaying threads. Amazingly, nobody had coded up JWZ's mail threading
algorithm in Perl yet, so I did that too: L<Mail::Thread>.

But then I decided that C<Mail::*> was in a very sick state. I had been
working with the mail handling modules from CPAN - including my own -
and grown to hate them; they were all too slow, too complicated, too
buggy or all three. It was time for action, and the Perl Email Project
was born. 

L<Email::Simple> was the first thing to come out of this, and is 
a fantastic way of just getting at the bits you need from an email. It's
much simpler, and therefore much faster, than its more fully-featured
cousins on CPAN. L<Email::MIME> was its natural successor, which added
rudimentary MIME handling, and spawned two subsidiary modules,
L<Email::MIME::ContentType> and L<Email::MIME::Encodings> in order to
keep C<Email::MIME> itself focussed on the "do one thing and do it well"
principle.

Of course we then had to replace C<Mail::Audit>, so
L<Email::LocalDelivery> and L<Email::Filter> appeared. This is another
module I don't use, because my C<Mail::Audit> setup works and I'm
terrified of breaking it and losing all my mail. But I'm told that
C<Email::Filter> works just fine too.

By this stage, C<Mail::Miner> was getting crufty. It was replaced by a much
more modular and beautiful L<Email::Store>; this is extended with
plug-in modules like L<Email::Store::Summary>, L<Email::Store::Plucene>
and L<Email::Store::Thread>. I had to write the plug-in framework
myself, since neither C<Module::Pluggable> or C<Class::Trigger> did
quite what I wanted, and so the C<Email::Store> project also produced
L<Module::Pluggable::Ordered>.

Now C<Email::Store> naturally uses C<Email::Simple> objects, since
it's the most efficient mail representation class on CPAN.
Unfortunately, C<Email::Store> also wants to make use of some modules on
CPAN like C<Mail::ListDetector> which don't want to know about
C<Email::Simple> objects and want to talk C<Mail::Internet> or whatever.
To get around this, I wrote L<Email::Abstract> which provides module
writers with an interface to B<any> kind of mail object, so they don't
have to force a particular representation on their users. 

=head2 Linguistics

I'm actually a linguist by training, not a computer programmer,
graduating from the school of Oriental Studies with second and third
year options in Japanese linguistics. I'd like to think that my work at
Kasei was as much about linguistic and textual analysis as it was about
mail munging. With that in mind, I wrote a few language-related modules
during my time with them.

The first important module, which I started work on while I was playing
with C<Mail::Miner>, was L<Lingua::EN::Keywords>. This started life as a
relatively naive algorithm for picking common words out of a text in an
attempt to provide some keywords to describe what the text is "about", and
has matured into quite a handy little automatic topic recognition
module. Its natural counterpart is L<Lingua::EN::NamedEntity>, which
B<is> still a naive algorithm but sometimes those are the best ones.

This module has a bit of story behind it. While analysing mails we were
trying to find people, places, times, and other things we could link
together into a knowledge base. The technical term for this is named
entity extraction. I find a useful library to do this, called C<GATE>.
It's written in Java, which meant using C<Inline::Java>, and is
extremely slow and complex. At the same time, I was writing a chapter on
computational linguistics with Perl in Advanced Perl Programming, and
wanted to talk about named entity extraction. Unfortunately, I only had
one module which did this, L<GATE::ANNIE::Simple>, and it was a hack. If
you're going to talk about a subject, it makes sense to compare and
contrast different solutions, and Tony had already been saying "why
don't you just write something to pull out capitalized phrases, for
starters?" I did this, intending to use it as a baseline, but of course
it's much faster than C<GATE> and not noticably less accurate. Ho hum.

Another thing those wacky computational linguists do a lot of is
working with n-gram streams. In every discipline, there's a particular
hammer you can use to solve any given problem. In data mining, it's
called market basket analysis. In computational linguistics, it's
maximal entropy. You look at the past stream of n characters (that's an
n-gram) and work out how hard it is to see what's coming next. 

For instance, if I feed you the 4-gram C<xylo> the chances of a C<p>
next are very high. The chances of a C<e>, or indeed anything else, are
pretty low. Low entropy area. But if I feed you C<then>, it's really not
easy to guess the next letter, since we're likely to be at the end of a
word and the next word might be anything; high entropy. That's how you
use maximal entropy to find word breaks in unsegmented text, and there's
a huge amount of other cool stuff you can do with it. 

I swear the day I wrote L<Text::Ngram>, there were no other modules on
CPAN which extracted n-grams, but as soon as I released it it looked
like there were three or four there all along. (Including one from
Jarkko, no less.) Anyway, I wanted to see if I could still remember how
to write XS modules, especially since I'd just written a book about it.

L<Lingua::EN::Inflect::Number> is a terrible hack, but it works. I
needed it to make C<Class::DBI::Relationship> (of which more later)
more human-friendly. L<Lingua::EN::FindNumber> is another hack written
for APP; I was a little surprised that C<Lingua::EN::Words2Nums>, which
is a fantastic module in its own right, can turn English descriptions of
numbers into digits, but it can't actually pull the numbers out of a
text in the first place. So I fixed that.

=head2 Text Munging, and Some More Mail Stuff

Applying my linguistic experience to the problems of intelligent mail
indexing, searching and displaying led to churning out another set of
modules.

The first problem was what to do with search results. You know those
little snippets that Google and other search engines display when you
search for some terms? They contextualise the terms in the body of the
document and highlight them in a snippet that best represents how
they're used in the document. This is actually a really hard problem,
and it took me several goes to get L<Text::Context> right. It uses
L<Text::Context::EitherSide> as an "emergency" contextualizer if it
can't get anything right at all, but the algorithm itself is a bit of a
swine. I actually had to prototype this module in Ruby to get my
thinking clear enough to code it up in Perl...

L<Text::Quoted> was another mail display problem - it's nice to
display different layers of quoted text in an email in different
colours. Identifying the quoted text isn't that hard, but working out
a particular bit nests is also surprisingly tricky. So I sorted it out.

The next problem I had to solve lead on from this. Suppose you've got
some mail, which is plain text, and you're going to display it as HTML.
Along the way, you want to turn any URIs into links, (maybe using
something like L<URI::Find::Schemeless::Stricter> to find things which
look like URLs, but which doesn't think that numbered lists are IP
addresses) escape any non-HTML-safe characters, highlight search terms,
put different quoted regions in different colours, and maybe do other
things too. The thing is, you have to be very careful about the order in
which you do this. Once you've escaped the HTML, you might mess up your
colouring of quoted text, but if you've turned the URIs into links
first, you'll mess them up when you escape all the HTML entities.
L<Text::Decorator> allows you to do all these transformations in a nice,
safe way, "layering" things like URI escaping, highlighting, and so on,
and then rendering to text or HTML or whatever when all the layers have
been applied.

C<Text::Decorator> was written in a meta-programming system I wrote
called L<pool>, which I should probably use more. It writes the boring
bit of OO classes for you given a simple description of the methods and
attributes.

Oh, and if you're not contextualising search terms in a mail snippet,
you probably just want to display the original content rather than the
first few lines, which invariablely contain lots of quoting of another
message. L<Text::Original>, extracted from the code of the Mariachi
project and so actually only packaged by me and written by Richard Clamp
and Simon Wistor, does just this.

L<WWW::Hotmail> was an attempt to solve the problem of how to import all
the mail a user already has into our archiving program, a problem Gmail
is now dealing with. Actually, Gmail's currently dealing with pretty
much all the problems we looked at last year. It's quite funny, really.

=head2 SIMON Hits The Web

I hate web programming. HTML is boring, CGI is boring, and I tried
avoiding it for as long as I could. This stopped when I worked for
Oxford University, handling their webmail service, which lead to
L<Bundle::WING>. Also at Oxford, I had to work with C<AxKit>, which
caused me innumerable headaches but I finally got some working XSP
applications written, not without writing the
L<Apache::AxKit::Language::XSP::ObjectTaglib> and
L<AxKit::XSP::Minisession> helper modules. I also did some playing
around with C<mod_perl>, thanks to the rather wonderful I<mod_perl
Cookbook>, and came up with L<Apache::OneTimeURL> when, during a
particularly paranoid phase, I wanted to give out my physical address
in URLs that would self-destruct after a single reading.

After leaving, though, I discovered the C<Class::DBI>/Template Toolkit
pair which has dominated my web programming since then. If you haven't
played with these two modules yet, you really need to, since they
work so well together, and with other modules like C<CGI::Untaint>, that 
they simplify so much of web and database work. I extended
C<CGI::Untaint> with a bunch of extra patterns while at Kasei and
afterwards, including L<CGI::Untaint::ipaddress>,
L<CGI::Untaint::upload> and L<CGI::Untaint::html>, 
I also wrote a whole plethora of C<CDBI> extensions:
L<Class::DBI::AsForm>, L<Class::DBI::Plugin::Type>,
L<Class::DBI::Loader::GraphViz> (reflecting my penchant for data
visualization), and L<Class::DBI::Loader::Relationship>, which applies
the "as simple as possible and a bit simpler" approach to defining data
relationships.

The whole culmination of C<CDBI>, TT, and all these other technologies
came when I sat down and wrote L<Maypole>, a Model-View-Controller
framework with, again, emphasis on making things very simple to get
working. The Perl Foundation's sponsorship of Maypole development has
been one of the proudest achievements in my CPAN career, and lead not
only to a stonking big manual, loads of examples, but also
L<Maypole::Authentication::UserSessionCookie> and L<Maypole::Component>.

Template Toolkit and XML came back together again in a recent project
where I've had render some XML as part of a Maypole application.
Amazingly, there wasn't an XSLT filter for the Template Toolkit, so
L<Template::Plugin::XSLT> was born.

=head2 Games, Diversions and Toys

It was only when I got back from Japan that I learnt to play Go. How
stupid was that. For a year I had access to some of the best Go clubs
and professional teacher and players in the world, and then I only pick
the bloody game up when I get back to England. Anyway, any computer
programmer who learns to play go, and they all do soon or later,
eventually decides to do something about the pitiful state of computer
Go. It's quite ridiculous that the game's been around for thousands of
years and the best computer programs we've devised regularly get beaten
resoundingly by small children. Anyway, I did my bit, producing
L<Games::Go::GMP> and L<Games::Go::SGF> as utility libraries, before
working on L<Games::Goban> to represent the state of the game.

But then while working for Kasei we discovered another addictive
diversion: poker. Computer poker isn't that great either, and I wanted
to write some robots to play on the internet poker servers;
L<Games::Poker::HandEvaluator> was the first product there, with the
hard work done by a GNU library, and L<Games::Poker::OPP> being the
interface to the network protocol. The comments to that module contain a
large number of Prisoner references, for no apparent reason. C<OPP>
needed a way of representing the state of a poker game, so I wrote
L<Games::Poker::TexasHold'em> to do that. And also because it was a
fantastic abuse of the C<'> package separator.

Oh, and another of my early modules that refused to die was
L<Oxford::Calendar>, which converts between the academic calendar and
the rest of the world's. It all counts, you know.

=head2 The Future

I've had mixed feelings on Perl 6, starting with my very public
nightmare at its announcement in 1999, (Hey, I'd just written a book on
Perl 5 internals, and now they're telling me it's obsolete.) and then my
very public repentance in 2000, at which point I was very excited about
the whole thing. So much so, that I produced vast numbers of design
documents for the language, most of which now ignored, but that's OK,
and set to work helping Dan design the core of the interpreter too. In
fact, I somehow managed to do so much work on it that, after a hacking
session together at O'Reilly in Boston in 2001, Dan let me be the
release pumpking of L<parrot>, a job I did until life got busy in 2002.
I'm extremely happy to have been involved in that, and hope I didn't
start the project off on too much of a bad footing. It looks to be doing
fine now, at least.

I was still interested in how they're going to make the Perl 6 parser
work, (I still am, but don't have enough time to throw at the problem)
and with my linguistic background I've always been interested in writing
parsers in general. So early on I started trying to write a
L<Perl6::Tokener>, which is now unfortunately quite obsolete, with the
intention of writing a parser later on. For most of 2002, my whiteboard
at home was covered with sketches of the Perl 6 grammar. 

Then I found out that the parser is actually going to be dynamic - you
can reconfigure the grammar at runtime. Hey, I thought, that's going to
be fun. At this point, you can't use an ordinary state-table parser like
C<yacc>, as Perl has done so far, because that pre-computes the
transitions up front. Instead, you have to use a proper state machine
without pre-computed tables. But I couldn't find any parsers which
worked on that basis, so I wrote one, L<shishi>, prototyping it in Perl
with L<Shishi::Prototype> first. 

This work has been largely ignored, unfortunately, but that's because
mainly I haven't had the time to do interesting user-facing stuff on top
of it so that it can be shown off. I tried porting C<Parse::RecDescent>
to it (using L<Parse::RecDescent::Deparse> to figure out what C<P::RD>
was doing) to produce a much faster recursive descent parser, but when I
heard that Damian Conway was funded to work on C<Parse::FastDescent> and
C<Parse::Perl>, (yes, I have a prototype of that too) I decided to leave
him to it. After all, why should I do the work and have other people get
paid for it? These modules did not materialise, but then, a failure on
his part does not constitute necessity on mine.

While I was messing with Parrot, I wanted to get other languages running
on the VM too, including Python, so I wrote L<Python::Bytecode> to take
apart the Python bytecode format so that it can be reassembled as Parrot
IMCC. Thankfully, Dan's taken this over, updated it for the latest
version of Python, and seems to be making good use of it converting
Python libraries to Parrot.

=head2 And the final joke...

I'm fond of a good joke, the Parrot April Fool's Joke being my pinnacle,
but I have mixed feelings about the C<Acme::> namespace on CPAN. I don't
know why. The thing is that I'd prefer modules which are funny because
they're clever, rather than modules which claim to be funny because
they're copies of other modules that claim to be funny. So my
contributions to C<Acme::*> have been deadly serious.

L<Acme::Dot>, for instance, is another example of how much you can warp
Perl's syntax without resorting to source filters. You can call methods
Ruby-style with the dot operator. But it's still the dot operator. You
work that one out. 

And my other contribution to C<Acme::*> - and my hundredth module? Well,
you've just finished reading it.

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>.

=cut

"Thanks and blessings to you all. 
Goodbye, baby, and amen.";

