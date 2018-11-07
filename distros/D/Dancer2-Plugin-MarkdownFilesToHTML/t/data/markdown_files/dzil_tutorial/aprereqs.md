# Who This Tutorial is For

This tutorial is aimed at:

* Beginning developers interested in making contributions to CPAN with no or
  limited experience creating a distribution and are interested in learning
  `Dist::Zilla` to automate the creation of their distributions.
* Developers having some experience releasing distributions using the simpler
  tools and looking to step up their game.
* Existing `Dist::Zilla` users who may not have a firm grasp on all of its
  moving parts and are looking for a bit of enlightenment.

## `Dist::Zilla`: For Experts Only?

We've heard it argued that a module like `Dist::Zilla` is overkill for beginning
developers. We disagree. We think if beginners are provided with documenation
targeted to their skill level, `Dist::Zilla` can be a great boon to them.
Powerful tools become a lot more useful and less confusing with good guidance.

Yes, `Dist::Zilla` is a very powerful, flexible tool. Like any advanced tool, it
is best wielded by those who have a good understanding of how to properly build
a perl distribution using more traditional approaches. `Dist::Zilla` does not
eliminate the need to know about build systems, tests, and other basic concepts
and practices that are employed for distribution creation. And so beginners who
are completely new to perl module distributions are often discouraged from
diving into `Dist::Zilla` without a solid understanding of what goes into the
proper building of a perl module distribution.

We hope to change that.

This tutorial attempts to give newer developers a gentle introduction to both
`Dist::Zilla` and provide basic insights into what a Perl software distribution
requires. We think `Dist::Zilla`, if properly introduced, can be a great tool
for learning how to release high quality, distributable Perl software.

## Software Prerequisites for this Tutorial

You should have a relatively modern release of Perl installed on your machine.
Anything newer than 5.20 should be adequate.

The tutorial will have you install modules with the the `cpanm` command so you
should take a moment to install it with `cpan App::cpanminus` if it's is not
already installed on your machine.

Finally, you'll also need a copy of `Dist::Zilla` installed. If it's not, you
know what to do.
