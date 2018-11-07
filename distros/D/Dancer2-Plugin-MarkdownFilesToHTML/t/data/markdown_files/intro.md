# A 35,000 Foot View of `Dist::Zilla` and Software Distributions

## Introduction

The `Dist::Zilla` module creates software distributions for perl modules. What
exactly does that mean, however? Most of us are generally familiar with the
concept of a “software distribution” but don’t give it much more than a passing
thought. So let's briefly introduce this concept to lay the groundwork for a
discussion specific to Perl module distributions and figure out where the
`Dist::Zilla` module fits into Perl landscape from a jet plane's perspective.

## In the Beginning...

At the dawn of the information age, the best way to move computer code around the
physical world was with dead trees. You typed your code into a keypunch machine
that cut holes into rectangular cards that you bundled into boxes and walked down
to the computer room to load into a hulking machine that magically translated the
holes into executable, electronic signals to perform your desired computing task.
You were likely the only person to ever run your code, the only person likely to
install it, and there was only one machine your code would ever execute on. And
so although crude, dead trees got the job of software distribution done just
fine under these simple circumstances.

## Modern Software Distribution Demands More From Developers

As technology evolved, cheap and compact magentic storage mediums arrived
in the form of tapes and disks, making it easier to copy, reproduce and
distribute computer code. Magnetic media made commercially available software
available to a mass audience possible. For the first time, you could drive to
your local computer store, plunk down 40 bucks for a box with 5 1/4” floppies
inside containing the text adventure game, Zork, and then trek back to deliver
the code to your awaiting microcomputer. If you accidentally bought the disks
for a Commodore 64 when you owned an Apple ][e, you had to go back to the store
and make an exchange.

The internet totally revolutionized how we distributed software. Physical media
is now invisible to us and exists only as an abstract notion we refer to as “the
cloud.” We can now easily download software with a few taps on our device
screens while resting in our easy chairs in the ugliest clothes imaginable.

Though the internet transcended the physical limitations of software
distribution, it's created new challenges for developers looking to distribute
their software to users of varying skill level and on a wide variety of
machines.

### Helping Users Install Your Software

Most users won't know the obscure commands required to load and execute your
software on their machines. Even if they did, it’s a boring task and one that
can be automated. And so almost all software of any substantial complexity is
accompanied by “installers,” programs designed to make it easy–or at least as
easy as possible–to install, configure and run your software.

### Making Sure Your Code Runs on Different Machines

Many software applications run on many different machine architectures with
drastically different software environements. So your distribution should supply
a suite of tests to ensure that your module will work as advertised on as many
different systems as practical. You can program the installer to take the
appropriate action if there is a problem with any of the tests. Hopefully, the
problem can be resolved automatically or at least allow for partial installation
of your software. The installer should alert the users if any problems were
encountered and help users fix them, if possible.

### Helping Users Find and Use Your Software

Our more modern age of computing has also introduced less obvious jobs for
software distributions but that are just as important if you expect your
software to be widely adopted. First, you'll want users to discover your
software. If it sits on some obscure server no one knows about, it'll get
ignored. Similarly, if your software has no manual and users have to
guess at how use it, users will likely get frustrated and never run it again.

### Helping Users Update Their Software

Finally, your distribution should give users a way to update to the latest
version of your software to take advantage of bug fixes and new features. All
but the most trivial or extremely mature software programs need to constantly
improve to stay relevant and keep users happy. And developers have to keep in
mind that if it isn't easy to update, it probably won't be.

### Summary of Key Software Distribution Functions

Now we have a clearer picture of what a software distribution is and does. It
contains the following six key components and features:

* your software that the end user will run
* a way for users to discover your software and get a copy of it
* an installer to make it easy to load your software
* tests to ensure your software will actually work when executed
* end user documentation for the software
* a convenient way to update the software

With these components in mind, let's look specifically at Perl module
distributions and the role `Dist::Zilla` plays in their creation.

## Perl Gives You the Tools for Building Your Distribution

Let's say you’ve written a Perl module that shaves people's armpits. While
that's amazing and was probably a lot of work, you are still missing 5 out of
the 6 essential ingredients for a proper distribution. Until you build the
software distribution, your software is practically useless for anyone but you.
Fortunately, the Perl community already provides many tools to for building a
complete software distribution.

First and foremost, there is the free-to-use CPAN (the Comprehensive Perl
Archive Network) which developers can use to distribute the latest releases of
their Perl modules. CPAN raises awareness about your module by providing a
well-known, publicly available and searchable interface for reading your
module’s documentation, source code and other useful information for users so
they can determine if your module suits their needs. To document your module,
you may leverage the inline documentation feature, know as Plain Old
Documentation (POD) that the Perl language supplies, to display your
documentation on the CPAN website as well as offline to your users on their
local machines. Perl also has a suite of tools, called build systems, to
automate the process of creating installation software for your module. And Perl
has another set of tools and modules for creating and running tests to ensure
your module will actually work as designed on your machine and others.  Finally,
the Perl community has a large team of volunteer “smoke testers” that will
automatically download your module from CPAN, install it, and test it on a wide
variety of of machines and report their findings to you. All of this is
available to you for free. Amazing!

## Software Distributions Still Require Lots of Work

Despite all the wonderful resources the Perl community provides, creating your
distribution will still require a considerable amount of work, especially if your
goal is to deliver high quality software. Writing clear, concise documentation
will always be difficult. Writing tests that ensure your software works well and
will run across many different platforms will always have some challenges. And AI
is nowhere close to being able to replace all the conscientious effort that goes
into maintaining and updating your distribution with regular fixes and
improvements. 

There are dozens, if not hundreds, of little chores that go into building your
software distribution. Though none of these tasks are particularly hard, few of
them are interesting. And collectively, they can be a real burden and
intimidating for those new to the world of perl distributions. And if you've
written dozens of different modules that you have to keep on top of, you are in
for a world of pain.

## Dist::Zilla Makes Producing Perl Module Software Distributions Easier

With that understanding, we can begin to appreciate what the `Dist::Zilla`
module brings to the table. Its goal is to make the creation of perl module
distributions much less tedious by automating the many existing tools used to
create, maintain and release a perl module distribution.

For example, though not an installer itself, `Dist::Zilla` automates the
creation of installers that you bundle with your distribution. `Dist::Zilla` can
also assemble your POD quickly and effortlessly. `Dist::Zilla` does not market
your app for you but can definitely ease the pain of generating a distribution
suitable for delivery on CPAN. And `Dist::Zilla` obviously can’t write your
module for you but it can set up your module’s directory structure and populate
your modules with boilerplate code to get you started. `Dist::Zilla` will not be
able to write all of your tests but it will ensure that they are run before you
release your code. `Dist::Zilla` won't track your repository changes for you,
but it will make updating and distributing your code repository much easier.

In short, `Dist::Zilla` can eliminate a ton of repetitive, mindless tasks to make
the distribution creation process much smoother, faster and more worry-free by
automating other automation tools for building your perl software distribution.

It’s impossible to catalogue everything `Dist::Zilla` can do. Aside from what
the core `Dist::Zilla` module does, there are hundreds of `Dist::Zilla` plugins
that you can install and configure to automate any number of common as well as
very obscure distribution chores. What you choose to automate is entirely up to
you. You can use a small subset of `Dist::Zilla`’s tools to handle only
rudimentary tasks or you can create an almost totally automated beast that can
create, generate, modify, build, test, document, release, push, upload and
update your distribution with a few keystrokes.

