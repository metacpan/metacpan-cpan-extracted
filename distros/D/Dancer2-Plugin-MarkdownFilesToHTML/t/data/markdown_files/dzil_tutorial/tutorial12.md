# Prerequisite Plugins

A big part of `Dist::Zilla`'s job is to create installer programs that install
your modules on other machines. A big part of the installer's job is to ensure
that your module has the modules it needs to work on the machine it's getting
installed to. The modules your module relies on are called **prerequisites** or
**dependencies.** We need a way to tell the installer about these prerequisites.
This is the job of the prerequisite plugins that we introduce in this tutorial.

As we saw, the `[@Starter]` module provides the `[Test::ReportPrereqs`] plugin
to test and report whether a machine has all the necessary modules to install,
test, configure and execute your module. However, this report is incomplete. By
default, the report only includes modules that the plugins need to function but
it doesn't know anything about your module's prerequisites. For example, the
`[MakeMaker]` plugin adds a module requirement for the `ExtUtils::MakeMaker`
module to the report but the report says nothing about the `Greetings` module
your module needs to work.

We use the prerequisite plugins to tell `Dist::Zilla` about our module's
dependencies. It uses the information from these plugins to make the appropriate
modifications to the dstribution's installer (usually `Makefile.PL`) and META
files.

## The `[Prereqs]` Plugin

With the `[Prereqs]` plugin, you manullay tell `[Dist::Zilla]` what your
module's dependencies are by giving it a list of prequisites in the `dist.ini`
file as a simple list of key value pairs. The name of the prerequisite is the
key and the minimum version number for the prerequisite is the value. With this
in mind, add these two lines to the `dist.ini` file in your `App::sayhi` work
area:

```

[Prereqs]
Greetings = 0.002

```

If you don't care what version of a module is used, set the value to 0. But you
may recall we created two versions of the `Greetings` module, the second one
provided our `hw_shout` function which we need. So we set our version to `0.002`
to make sure that function is available. Now let's check our
`[Test::ReportPrereqs]` report:

`dzil test`

You'll now see a new section in the report:

```

# === Runtime Requires ===
#
#     Module     Want  Have
#     --------- ----- -----
#     Greetings 0.002 undef

```

You'll also see this warning at the end of the report:

```

# *** WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING ***
#
# The following REQUIRED prerequisites were not satisfied:
#
# Greetings version 'undef' is not in required range '0.002'

```

Zilla monster is grumbling. What's wrong? The problem is that `Dist::Zilla` has
no way of determining what version our `Greetings` module is. But wait, didn't
we add the version in the `dist.ini` file in `Greetings`? We did, this is true,
but that version number does not make its way into our actual distribution and
that's why it is reported as "undefined." The version number was used by
`Dist::Zilla` to generate the name of distribution's directory and the related
tarball but that's it.

So how do we give the `Greetings` the ability to tell the world about its
version? We need to go back and improve how our `Greetings` module handles
versioning.

### Setting Your Module's Distribution Version

You can set the `Greetings` distribution version by adding the following line
directly into the `lib/Greetings.pm` file just below the `package Greetings`
line:

`our $VERSION = '0.002';`

After you make the change, install this version of the `Greetings` module:

`dzil install`

Now move over to `App::sayhi` to check our prerequisite report:

`dzil test`

Zilla monster is doing a happy dance for us again and the report tells us the
prerequisite for the `Greetings` module is satisfied.

OK, but now you're unhappy because you are stuck having to change the version
number in two different places: `dist.ini` and the module. We will address this
issue in a future tutorial.

There is a bit more to the `[Prereqs]` module. For example, you can report other
details like whether the dependency is needed for testing only or it's a hard
and fast prerequisite or only a recommendation. We don't need to concern
ourselves about that now.

## The `[AutoPrereqs]` Plugin

An alternative approach to manually adding prerequisites with the `[Prereqs]`
plugin is to use the `[AutoPrereqs]` plugin which will scan your module's code
and attempt to determine your module's dependencies. Modify your `dist.ini` file
by removing the parameter to the `[Prereqs]` plugin and replace the `[Prereqs]`
plugin name with `[AutoPrereqs]`. Run:

`dzil test`

Look at the `Runtime Requires` section of the prerequisite report now:

```

# === Runtime Requires ===
#
#     Module           Want  Have
#     ---------------- ---- -----
#     App::Cmd::Simple  any 0.331
#     Greetings         any 0.002
#     base              any  2.23
#     strict            any  1.11
#     warnings          any  1.36

```

Cool. Not only has our `Greetings` prerequisite been found, it also identified
that we need `App::Cmd::Simple` and some other modules as well.

What's not so cool is that it says "any" version of the `Greetings` module will
do but this isn't the case. How do we fix that? We simply add the `[Prereqs]`
plugin back into the `dist.ini` file:

```

[Prereqs]
Greetings = 0.002

```

And now we have the best of both worlds.

A word of caution, however. Using `[AutoPrereqs]` may have some downsides. For
example, it my start falsely identify modules in your test library as
prerequisites when they really aren't. And developers with more complicated
dependency needs may have an easier time managing their dependencies without
`[AutoPrereqs]` plugin. However, for simpler modules, using `[AutoPrereqs]` will
not usually present a problem.

## The `[Prereqs::FromCPANfile]` Plugin

The last plugin commonly used to generate the prerequisites is the
`[Prereqs::FromCPANFile]`. As you can probably guess by the name, this plugin
reads the CPANfile that may accompany your module. If you aren't using a
CPANfile with your module, this plugin is not for you.

You can learn more about what a CPANfile is by reading it's
[documentation](https://metacpan.org/pod/Module::CPANfile).
