# The `dist.ini` File

In the previous chapter, we analogized `Dist::Zilla` to a factory for producing
module distributions, imagining the various plugins deployed by `Dist::Zilla` as
robots which do some pre-defined bit of work on the module as it travels down
the assembly line, shaping it into a finished produce ready for distribution.

If `Dist::Zilla` is a factory, then the `dist.ini` file is the equivalent of a
factory floor plan. The `dist.ini` file tells `Dist::Zilla` which robots
(plugins) to use and in what order they should do their work.

## Inspecting the `dist.ini` File

So let's take a closer took at the the `dist.ini` file created automatically for
you by `Dist::Zilla` in the earlier part of the tutorial.

```

name  = Greetings
author = Your Name <your@email.com>
license = Perl_5
copyright_holder = Your Name
copyright_year  = 2018

version = 0.001

[@Basic]

```

The first five configuration lines are self explanatory. They contain the
information we supplied when we configured `Dist::Zilla` with the `setup` and
`new` commands. As is standard in a `.ini` file each of these lines is a
configuration setting with keys on the left, followed by an equals sign, and the
corresponding values on the right.

`Dist::Zilla` makes these configuration settings available to your plugin if
they need them. For example, if you look at the `README` file, you'll see it
directly substitutes the `author`, `copyright_holder` and `copyright_year`
values into its contents.

You can also probably guess what the `version = 0.001` line does. This is the
decimal value was tacked on to the end of our module distribution's name
automatically to indicate the module's version number.

The only non-obvious bit is at the very end where you see `[@Basic]`. This is
called a **plugin bundle.** There is quite a bit to of code lying behind this
simple line, so let's examine it closely.

## Plugin Bundles

As mentioned, the `dist.ini` file tells `Dist::Zilla` which plugins should be
deployed to build our distribution. You can list these modules one-by-one in the
`dist.ini` or, as a convenience, you can use plugin bundles.

A bundle is nothing more than a pre-defined set of plugins. Rather than typing
all the separate plugins into the `dist.ini` file, you just drop in a bundle
name as a stand-in for a list of plugins. Bundles can also modify the behavior
of plugins but this is a minor detail you can brush aside for now.

To use a bundle, slap an `@` sign in front of the bundle name and throw square
brackets around it to tell `Dist::Zilla` that you want to use a bundle.

And so the `[@Basic]` command you see in `dist.ini` is a bundle representing the
following list of plugins that all come pre-installed with `Dist::Zilla`:

```

Dist::Zilla::Plugin::GatherDir
Dist::Zilla::Plugin::PruneCruft
Dist::Zilla::Plugin::ManifestSkip
Dist::Zilla::Plugin::MetaYAML
Dist::Zilla::Plugin::License
Dist::Zilla::Plugin::Readme
Dist::Zilla::Plugin::ExtraTests
Dist::Zilla::Plugin::ExecDir
Dist::Zilla::Plugin::ShareDir
Dist::Zilla::Plugin::MakeMaker
Dist::Zilla::Plugin::Manifest
Dist::Zilla::Plugin::TestRelease
Dist::Zilla::Plugin::ConfirmRelease
Dist::Zilla::Plugin::UploadToCPAN

```

As you can see, each plugin is nothing more than a name of a perl module. The
`Basic` bundle is itself a Perl module named `Dist::Zilla::PluginBundle::Basic`.

Each of the modules/plugins added by the `Basic` bundle will process your
module, one at a time, in the order they are listed above. From the names of the
plugins, you might get a rough idea of each plugin's job. For example, you can
probably guess that `Dist::Zilla::Plugin::License` probably has something to do
with generating the text file containing the legal agreement that accompanies
your module. But don't get too fixated on what each plugin does or how they work
now. We will cover all the more interesting ones later.

### A Quick Note on Phases

Before moving on, we want to briefly call you attention to the very last plugin
listed above, `UploadToCPAN`, which unsurprisingly, uploads your module to CPAN.
But why didn't this happen when you ran the `build` command back in the first
turtorial?

The answer is that the `build` command will only run the plugins that are
assigned to the manufacturing phases under its control. `UploadToCPAN` is a
release phase process (or, going back to our analogy, a "shipping" process) and
doesn't go to work until we issue a `dzil release` command. If this is
confusing, don't worry about it. We will explore the idea of phases more later.
Just file it away as something to remember because it's an important idea you
should understand, especially if you want to write your own plugins.

OK, let's get our hands dirty again now that we have a clearer idea of how to
begin tinkering with our distribution's factory.
