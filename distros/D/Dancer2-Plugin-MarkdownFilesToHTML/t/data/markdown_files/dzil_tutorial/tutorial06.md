# `Dist::Zilla` ~~Minting Profiles~~ Blueprints

We've all been there. We fire up a text editor with the dreaded blank screen
staring back at us and we start dutifully typing:

`!#/usr/bin/perl`

Oops. No wait. SHA-bang...

```prettyprint

#!/usr/bin/perl
use strict;
use warnings;
use Carp;

# plus the other usual boilerplate

```

You've done it 100 times and 95 times you have throught to yourself "I really
need to automate this." If you consider yourself a decent Perl developer, you're
probably already using a templating system for kicking off a project or even
rolled your own. Maybe they're adequate but odds are you are really missing out
on what `Dist::Zilla` can offer.

`Dist::Zilla` has one of the most powerful, customizable module templating
systems available. Unfortunately, the official documentation refers to them as
**minting profiles.** We hate the name and think it's confusing. Presumably the
term's aim is to get us thinking about "minting" coins. In any case, we will
avoid using the official terminology where possible with the hope the analogy
we've invented to conceptualize how `Dist::Zilla` works catches on.

## A Better Name Than "Minting Profiles"

Previously, we used the analogy of a "work area" and imagined the `dzil new`
command set up a new work area on your factory floor for forging your module.
Each time you issue the `new` command, you set up a new work area in a new
directory on your computer for creating and distributing a new module.

But it gets even better than that. You can control not just what your work area
will initially look like but what manufacturing process will be used to package
your module with a custom `dist.ini` file. This is a powerful feature of
`Dist::Zilla` that takes you well beyond what you can do with a more typical
distribution generation systems using plain templates.

None of this really sounds like what goes into stamping out nickels so...

...instead of "minting profiles," we encourage you to think of them instead as
"blueprints" to better capture the essence of what the `new` command does: it
sets up and configures your module and the processes that will work on it
according to a plan. Where we use the term "profile" below, **mentally** replace
it with "blueprint" instead. Of course, if we have you type in `profile`, make
sure you actually type in `profile.`

## Creating Your First Factory Blueprint

You first need to esablish a storage area for your default blueprint. The
default blueprint is what's used unless we specify a custom blueprint with the
`new` command.

First, create a default directory in the special directory `.dzil` created for
for storing ~~profiles~~ blueprints:

`mkdir ~/.dzil/profiles/default`

Inside the default directory, create a `profile.ini` file (which we cannot call
`blueprint.ini`). The primary job of this file is to tell `Dist::Zilla` how to
establish your work area. The file works very similarly to how the `dist.ini`
file works. But instead of processing modules, it sets up the template for your
main module, generates other supporting files, if any, and assembles your
`dist.ini` file.

Create the following `profile.ini` file in the `default` directory:

```

[TemplateModule/:DefaultModuleMaker]
template = Module.pm

[DistINI]
append_file = dist_ini.txt

[GatherDir::Template]
root = skel

```

The `profile.ini` file has three sections, one for each plugin that we use. We
pass in one parameter to each plugin. Don't worry exactly what it all means just
yet. We will explain it all when the time comes.

Next add the file that will act as a template for your new module.  Create a
file called `Module.pm` which, you'll notice, happens to be the name used for
the `template` parameter above. Add the following lines to the file:

```prettyprint

package {{$name}};
use strict;
use warnings;

# Module implementation goes here

1;

=head1 NAME

{{$name}} - Add the module abstract here

```

Don't be concern yourself with the funny-looking curly brackes now–more on
templates later.

Lastly, we are going to add the `dist_ini.txt` file to your blueprint, the file
mentioned in the `[DistINI]` section of your `profile.ini` configuration file.
Create the `dist_ini.txt` file and add the following lines to it, which should
look familiar to you:

```

[@Starter]
[ReadmeAnyFromPod]
type = markdown
filename = README.md
location = root

```

If you guessed that the contents of `dist_ini.txt` will end up inside your
`dist.ini` file, you guessed right.

You should now have three files in the `default` directory. Together, they
comprise your first factory blueprint. Let's see if you cut and paste everything
correctly. Do a `cd ~/dzil_projects` and try creating a new work area:

`dzil new Super::Greetings`

If you see a new `Super-Greetings` directory and `Dist::Zilla` didn't throw any
errors at you, congratulations, you've successfully ~~minted~~ drafted and
processed your first ~~profile~~ blueprint. If something went wrong, go back and
inspect your three blueprint files for errors and try again.

## Exploring Your New Factory

Look inside your new work area and you'll see that your `dist.ini` has all the
plugins and parameters you supplied in your `plugins.ini` file. The global
configuration parameters at the top of of the `dist.ini` file were added for you
as well. You might also notice something missing, though. More on that in a bit.

Now open the `lib` directory where your module lives. Inside of that directory is
the `Super` directory and inside of that directory is a `Greetings` directory
and inside of that directory we finally see your `Greetings.pm` module file.
`Dist::Zilla` created this nested directory structure from the name of your
module, `Super::Greetings`. Sweet.

Everything seems to be in place. See if you can build a distribution with the
blueprint:

`dzil build`

Oops, Zilla monster not happy:

```

[DZ] beginning to build Super-Greetings
[DZ] no version was ever set
[DZ] no version was ever set at inline delegation in Dist::Zilla for
logger->log_fatal (attribute declared in
/usr/local/share/perl/5.20.2/Dist/Zilla.pm at line 768) line 18.

```

## Fixing Your Blueprint

It looks like your blueprint has a fatal flaw, thanks to our bad advice. What
went wrong, exactly?

Remember back when you added the `# ABSTRACT` comment to your module in the very
first tutorial? We added that to give the installer software an esssential bit
of information it needs in order to work. But instead of adding an `# ABSTRACT`
comment into the module, your new blueprint kept the installer happy by
supplying the `NAME` section in your documentation that `Dist::Zilla` used to
generate the `ABSTRACT` our installer required. This way, your blueprint killed
two birds with one stone by giving your module some documenation and keeping the
installer happy.

Though your installer now has an abstract, it is now demanding that we feed it a
version. What's the best way to do that? One way is to edit the module and add a
version number there, similar to the way we added the `# ABSTRACT` comment. But
since we're using `Dist::Zilla`, we'll add in `version = 0.001` directly to the
`dist.ini` because it's easy.

However, this doesn't fix the real source of the problem, your flawed blueprint.
So the next time we create a new module, we are going to run into the same
issue. So let's also be sure to fix the blueprint, too. Open the `dist_ini.txt`
file in the default profile and add the following line to the top of it:

`version = 0.001`

Once you've fixed up both files, try to build the distribution again. If you did
everything right, Zilla monster will please you with a new distribution. Super
duper!

OK, let's plow forward with our exploration of blueprints in the next section of
the tutorial.
