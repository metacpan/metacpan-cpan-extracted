# Controlling Your Distribution Production Factory with the `dist.ini` File

Crack open the `dist.ini` file in your favorite text editor and let's see what
we can break in the name of science and understanding.

First, as much as we appreciate the convenience of bundles, the first thing we
are going to do is scrap the `[@Basic]` command and bust it out into the
individual plugin names to gain more control over the factory floor plan.

Adding an individual plugin to `dist.ini` is a breeze. Just take everything
after the `Dist::Zilla::Plugin::` part of the plugin's package name, surround it
with square brackets, and add it on its own line in the file. So if the plugin's
package full name is `Dist::Zilla::Plugin::License`, you are going to add
`[License]` to a line in your `dist.ini` file. The order of the plugins is
important so make sure you add the plugins in the same order as the listing in
the previous tutorial.

Or if you're smart, just delete the `[@Basic]` command from your `dist.ini` file
and copy and paste the following list in its place:

```

[GatherDir]
[PruneCruft]
[ManifestSkip]
[MetaYAML]
[License]
[Readme]
[ExtraTests]
[ExecDir]
[ShareDir]
[MakeMaker]
[Manifest]
[TestRelease]
[ConfirmRelease]
[UploadToCPAN]

```

Now let's make a small change to our `dist.ini` file by throwing a semicolon in
front of our `[License]` plugin listing, like so:

`;[License]`

This is how you comment out a line in a `.ini` file. And so you have effectively
shutdown the robot in charge of slipping license agreements into our
distribution.

Can you guess what will happen when we build our module now? We bet you can! But
we are going to annoy you anyway and step you through the process, on the
outside chance you're wrong.

After commenting out the `[License]` plugin, save the `dist.ini` file and run:

`dzil build`

And now:

`ls Greetings-0.001`

Which should show:

`dist.ini  lib  Makefile.PL  MANIFEST  META.yml  README`

Sure enough, our module lacks a `LICENSE` file with our license agreement. Good
thing no one reads those things anyway. Of course, some fancy pants lawyer might
find a way to bring us to financial ruin over our careless omission so let's go
back in and uncomment our our `[License]` plugin and then run:

`dzil build`

Now double check just to make sure with `ls Greetings-0.001`:

`dist.ini  lib  LICENSE  Makefile.PL  MANIFEST  META.yml  README`

Awesome. We're back in good legal standing with the software gods and, more
importantly, our distribution will look like it was created by a real software
pro.

## Keeping It Clean

You'll notice we didn't run `dzil clean` after each build. There is no need to
because `Dist::Zilla` will overwrite existing builds with newer builds so long
as they have the same version number. But as we add new versions, our older
distributions will accumulate in our factory and we will want to sweep them out
from time to time with the `clean` subcommand.

## Changing Your Module's Version Number

Speaking of versions, how do we add a new version of our module? Glad you asked!

Let's first add a mind-blowing new feature to our next version by adding a new
function to `Greetings.pm`:

```prettyprint

sub shout_hw {
  print uc "Hello, World!\n";
}

```

Now edit the `dist.ini` file to update the `version` value from `0.001` to
`0.002` and then again run:

`dzil build`

Cool! Now you have a new version of your module to really annoy friends and
family by shouting "HELLO, WORLD!" at them.

Notice that version 0.001 is still laying around. You can quickly clean things
up with `dzil clean` and then run `dzil build` again to get version 0.002 back.
Then run `dzil install` so the other modules on your machine can take advantage
of your new "shout_hw" funciton. We are going to use this module later so make
sure you install it.

Are you impressed with `Dist::Zilla`, yet? Maybe if you are brand new to
distribution building you are excited but the truth is this is all pretty ho-hum
stuff to more experienced developers. Don't worry, we'll cover more impressive
tricks soon. We have to ensure everyone can walk before teaching them to run.

## Some Deeply Profound and Meaningful Reflections on Taming the `Dist::Zilla` Beast

At this point, we want to mention that even though `Dist::Zilla` is designed to
automate things for you, it makes few demands on how you do the actual
automation. `Dist::Zilla` is designed to be a very open-ended framework.

For example, there are many different approaches to handling your module's
version number which is more complicated than we let on here. You can use the
`[VersionFromModule]` plugin to get the the version number from your module
instead of from `dist.ini`. Or, you can use the `[AutoVersion]` plugin to
generate a version number based on the current date. If you use git to manage
your module's releases, you can use `[Git::NextVersion]` to automatically
generate the next version number in sequential order. There are also other ways
to generate your module's version that are more "developer friendly" than the
technique we showed you here.

The point is TIMTOWTDI and there are hundreds of `Dist::Zilla` plugins out there
to prove it. You can also write your own plugins to satisfy your inner control
freak.

But `Dist::Zilla`'s maze of plugins and flexibility is both a blessing and a
curse. It's a blessing for developers who demand precise control over their
distributions while avoiding a lot of repetitive work. But it's a curse for
newcomers wrestling with `Dist::Zilla` to get it to do what they want and who
may not know the best practices for using it. `Dist::Zilla` was named after a
monster for good reason.

The goal of these tutorials is to try to ease the pain of learning your way
around `Dist::Zilla` and make solid recommendations for using it well. So try to
restrain your urge to explore on your own. We still have a lot more basic stuff
to cover before you should unleash yourself.

With the obligatory Zen programming stuff out of the way, we will dive down a
level deeper and learn how to gain more control over how the indvidual plugins
do their jobs.
