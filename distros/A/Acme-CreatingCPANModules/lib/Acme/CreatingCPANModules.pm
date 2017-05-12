package Acme::CreatingCPANModules;

use warnings;
use strict;

=head1 NAME

Acme::CreatingCPANModules - Created during a talk in London

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module doesn't actually *do* anything...

It does have a new constructor, and a set and a get method, just so
you can do some tests.

    use Acme::CreatingCPANModules;

    my $foo = Acme::CreatingCPANModules->new();

    $foo->set( 3 );

    my $bar = $foo->get();

=head1 THE TALK

[give or take a word]

[the slides that accompanied this talk are available through
http://jose-castro.org]

[we start at the first slide and you'll see a slide tag each time the
slide is supposed to change (just press enter for that)]

Hello!

First of all... [slide]

Good :-)

My name is José and I'm here to take you along the creation of a CPAN
module.

The first thing I'l like to tell you is this: do not bother taking
notes!

These slides are already online, and so is my speech (give or take a
word), and by the end of this talk I'll be giving you the link you can
use to get them.

Also, don't bother noting down links... apart from the last one, of
course, because with that one you'll get to the slides and you'll be
able to get the other links from there.

[slide] And now we're going to create a CPAN module.

[slide] We assume you're here either because [slide] you want to be a
CPAN contributor, [slide] you want to be a better CPAN contributor, or
[slide] you have absolutely no idea what a lexical attribute is and
couldn't care less [at the same time, Abigail was giving his talk on
Lexical Attributes in the advanced room].

[slide] So let's get started, with [slide] C<Module::Starter>.

Now, you should know that there are other ways to create a CPAN
module, and no way is the true way. They all have some advantages and
some disadvantages. Anyway, for the purpose of this talk, we'll be
using C<Module::Starter>, and if there's time by the end I'll talk a
bit about the other alternatives.

So let's get started!

Just install C<Module::Starter> (if you don't know how to do that you
can talk to me later on) and you'll be provided the C<module-starter>
command.

Type it and you'll see [slide] WHOAA!!!

[slide] OK, relax :-)

C<Module::Starter> has a bunch of options you can use, but the most
important three ones are these: --module for the module name, --author
for the author's name (you) and --email for the author's email address
(it's always good to allow users to contact you).

[slide] So let's exemplify this (we'll do this in the slides and then
we'll move on to a terminal and try all this again).

[slide] I'm going to create the module C<Acme::CreatingCPANModules>,
[slide] with the author "Jose Castro" (that's me, in case you didn't
notice... my name is also in the bottom right corner of the slides...
:-) ) [slide] and my email address: cog at cpan dot org.

[slide] There. Module created!

No, it doesn't do anything yet, but it already exists!

[slide] So let's see what happened and exactly what was created.

With the `tree` command [If your system doesn't provide the `tree`
command tool you can try installing C<Filesys::Tree>]!

[slide] OK, then...

OK, let's go through this step by step...

Here on the bottom we have a t/ directory, which is the directory
where you put your test files (it's a convention). Inside it are a few
.t files (that's also a convention for test files). We'll get to these
in a while.

You'll also notice the .pm file. That's your module!

Everybody knows what a README is, but we'll also get to that.

The Makefile.PL is what's going to be used to install your module, and
MANIFEST contains the list of files the distribution includes... don't
try to think to hard about all this, we'll get to all this in a
moment.

And then there's the Changes file, where you're supposed to write down
the changes you made to your module each new version.

Let's look at the files in detail.

[slide] Here's a Changes file.

Note that the order of the changes is chronologically inversed. Why?
Because the purporse of a changes file is (among others) to let the
user know what you changed from the last version, so that he can
decide if he wants to install your module.

Hence, and since browsers and editors usually open files in their
beginning, it's only reasonable that you put the most recent changes
on the top of the file.

As for what you put in here, it's kind of up to you, but you don't
need to be too technical. If you added some tests, just say "added
some tests". You don't really need to specify which ones and the
purpose of each of them.

[slide] Next up we have the MANIFEST. This is the file that lists
everything that goes into your distribution.

Why? Because this way you're able to put more stuff in the directory
and not have the final step of creating the distribution include those
files.

If you're thinking "why would I put things in that directory if they
weren't part of the distribution", think, for instance, in a test file
that only runs in your machine.

One of my modules has tests with two files that take almost 200M each.
I don't think the users wouldn't want to download a 400M distribution
when they can do with a 20K one.

Hence, those files of mine are in that directory but not listed in the
MANIFEST.

The drawback on this is that whenever you add a file to the
distribution you have to remember to update the MANIFEST.

[slide] Next up, we have Makefile.PL

Now, you really don't need to understand what's in here, but it's
still quite self-explanatory.

There's the name of the of the distribution, the author, etc. Do note
the C<PREREQ_PM> parameter. If your distribution requires another
module to be installed, that's where you defined that. Just add the
name of the module to that hash and put the minimum version number of
the module that you require.

[slide] Next we have the README. What you put in the README is, once
again, up to you. I always put the same documentation from the main
module, some people just put a template README in all their
distributions.

Whatever you do, don't forget to update the README at least once, as
it's the file many users look at and the default documentation can be
kind of... embarassing ;-)

[slide] And now we finally have our module!

The module is comprised of two things: code and documentation.

Both are equally important.

I can't stress how much.

Whether you put your documentation at the beginning or at the end of
the file, or perhaps entwined with the code, is, again, up to you.

We're not staying for a long time at this slide because we'll have the
time to do so in the demo, right after this.

[slide] And now we're at the first test file.

Currently, through C<Test::More>, it checks to see if the module loads
correctly. It also diagnoses what it's doing.

[slide] Then we have another test file, which was recently introduced,
to check if files like README and Changes have content written by you
or are just the default templates.

[slide] The next one is checks if you're documenting all your public
functions. It assumes that if you have a private function (that is, a
function that's not meant for the public but rather to be used by your
other functions) you will name it something commencing with an
underscore.

This means that you need a section with the name of each function that
doesn't begin with an underscore.

[slide] And this one over here ensures that your POD is valid.

[slide] So let's go through it one more time: Changes for the list
of changes, MANIFEST with the list of files, Makefile.PL to be used
for installation, README, your module, and a bunch of tests.

[slide] Very well, then. Time for the live demo!

[I change to the next workspace and we're set] You know what they say
about live demos? They say "Don't!" O:-)

OK, then, first we'll create our module. [I type `module-starter
--module=Acme::CreatingCPANModules --author='Jose Castro'
--email=cog@cpan.org`]

There, done.

Now, the first I'm gonna do is get rid of C<boilerplate.t>. Well, not
really getting rid of it, I'll just put it aside for the time being
and I'll explain you later why I'm doing it. [`cd
Acme-CreatingCPANModules` and `mv t/boilerplate .`]

Now we're set.

Suppose we were installing this module.

The first thing to do it `perl Makefile.PL` [`perl Makefile.PL` and ls
-al]. As you can see, this has created C<Makefile>.

This now allows us to do things like this [`make`]. And now we can
test our distribution [`make test`].

As you can see, all our tests have passed... but that's simply because
we still don't have anything interesting in our module...

Let's add some code. [I add the code for new(), set() and get(), as
follows:

  sub new {
    my $self = shift;
    my $foo = shift;
    bless \$foo, $self;
  }

  sub set {
    my $self = shift;
    my $newfoo = shift;
    defined $newfoo or return undef;
    $$self = $newfoo;
    return $self->get();
  }

  sub get {
    my $self = shift;
    return $$self;
  }

and some documentation for these methods]

Now, let's run the tests again. [`make test`]

OK, so we haven't broken anything yet, good :-)

Now, let's add some more tests [`cp t/00-load.t t/01-basic.t`].

As you can see, [`make test`] running the tests again runs this new file.

Now let's change a few things in this new file of ours. [`vim
t/01-basic.t`, remove the last line and add instead:

  my $object = Acme::CreatingCPANModules->new();

  isa_ok( $object, 'Acme::CreatingCPANModules' );
]

This is going to ensure that creating a new Acme::CreatingCPANModules
object actually creates one.

Now, what do you think will happen if I run the tests again?

[`make test`] See? If complains that you ran one more test than
expected. Have a look to the test file again.

See right over there? You're saying that you're going to run one test
[point to third line], but you actually run two [point to use_ok and
to isa_ok].

What you'd have to do is to change that 1 to a 2, but I'll tell you a
little secret of mine: just use C<Test::More> with 'no_plan' [change
the third line in the test file to:

  use Test::More 'no_plan';#tests => 1;
].

OK, so let's add some more tests.

[add, at the bottom of the file:

  $object->set( 5 );

  is( $object->get(), 5 );
]

Now let's run the tests [`make test`].

See? Just like that!

What do we have to now? We have to update the MANIFEST and the Changes
file. [`vim MANIFEST` and remove the boilerplate.t line and add
t/01-basic.t`, `vim Changes`, in Changes, add the date/time]

Now let's create our distribution. How do you do that? With `make
dist` [`perl Makefile.PL`, `make`, `make test`, `make dist`, `ls -al`]

Now, you have to create your Makefile again, because you change the
files. When in doubt, you can always run these four steps.

As you can see, we now have a distribution, ready to be uploaded.

How do you upload something to CPAN? [cut to screenshots of
pause.perl.org]

[first picture]

This is the PAUSE. The Perl Authors Upload Server.

This is what we use to upload distributions.

First, you need an account. You can request one here [point to
"Request PAUSE account"].

[second picture]

To be given a PAUSE account you have to fill in your name, email
address, the desired ID and one or two more things. You also have to
explain what you're planning to contribute.

This is not so someone judges whether your contribution is worth it or
not. It's just so you can tell the real people from the trolls.

You have a few days (because the PAUSE administrators aren't many and
they might be busy) and eventually you'll get an answer. There's a
slight chance (just slight) that your request doesn't get looked at.
If you don't get an answer, try again about a week later, but this is
really not common, I'm just warning you :-)

[third picture]

Once you're in, you get a lot to choose from.

[fourth picture]

Uploading a distribution, for instance, is really simple. Just press
the button [point to "Upload a file to CPAN"],

[fifth picture]

Select your tgz file and press the button [point to "Upload this file
from my disk"]

This pretty much sums up the important things you need to know, but,
of course, there's a lot more [back to slides].

[slide]

There's a lot of basic and advanced stuff we didn't cover in this
talk.

[slide]

What next?

I'd like to point you to another article I wrote a while ago, which is
available on Perlmonks.

There's also a very good book on the subject, which covers a lot more
than what we talked about here. The book is "Writing Perl Modules for
CPAN", by Sam Tregar, and it's free, as in "you can download it".

You can subscribe the C<module-authors@perl.org> mailing list if you
need more help (you can also contact me).

If you need to contact a PAUSE admin, send an email to
C<modules@perl.org> (you can't subscribe that list, you can only send
mail to it).

The slides for this talk are inside a module called
C<Acme::CreatingCPANModules>, available on CPAN. You can get to this
module from my homepage, http://jose-castro.org/

It's really simple because it's my name and it's been in every slide
so far! :-) Bottom right corner, Jose Castro, can't miss it! :-)

Somewhere on that page you'll be able to find these slides. I think
currently their at the top right corner. That might change in the
future, and they may go under the "Talks" section, but they'll be
there and they'll be easy to find.

So thank you very much for your time, get C<Module::Starter> on your
machine and start a module today.

Don't be afraid of uploading it to CPAN. People will help you when you
do something wrong :-)

[slide]

Thank you.

Any questions? [email me at cog@cpan.org if you have any :-) ]

I'll leave the previous slide with the links while I answer questions.
[and back to the previous slide]

=head1 EXPORT

This module is OO, so it doesn't export anything...

=head1 FUNCTIONS

=head2 new

Creates a new Acme::CreatingCPANModules object.

=cut

sub new {
  my $self = shift;
  my $foo = shift;
  bless \$foo, $self;
}

=head2 set

Sets the new value of the object.

=cut

sub set {
  my $self = shift;
  my $newfoo = shift;
  defined $newfoo or return undef;
  $$self = $newfoo;
  return $self->get();
}

=head2 get

Gets the current value of the object.

=cut

sub get {
  my $self = shift;
  return $$self;
}

=head1 AUTHOR

Jose Castro, C<< <cog at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-creatingcpanmodules at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-CreatingCPANModules>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::CreatingCPANModules

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-CreatingCPANModules>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-CreatingCPANModules>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-CreatingCPANModules>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-CreatingCPANModules>

=back

=head1 SEE ALSO

http://jose-castro.org for the slides that accompany this talk.

=head1 ACKNOWLEDGEMENTS

The audience at the London Perl Workshop 2005.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Jose Castro, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Acme::CreatingCPANModules
