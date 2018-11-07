# `[@Starter]` Me Up

A dirty secret in the `Dist::Zilla` community that no one likes to talk about
[(we kid)](http://blogs.perl.org/users/grinnz/2016/07/distzilla---why-you-should-use-starter-instead-of-basic.html)
is that the `[@Basic]` bundle is pretty badly outdated. A better, more modern
bundle to use is the `[@Starter]` bundle. So let's modify our `dist.ini` file by
deleting all the individual plugins we created in the last tutorial and replace
them with:

`[@Starter]`

In addition to being more modern, `[@Starter]`'s plugins are much more
configurable than the plugins that ship with `[@Basic]`. And, at the end of the
day, configurability is what `Dist::Zilla` is all about. When you do begin
exploring `Dist::Zilla` on your own, we highly recommend using `[@Starter]` as
your starting point until you get more comfortable creating a custom `dist.ini`
file.

The `[@Starter]` plugin bundle is not part of the `Dist::Zilla` distribution so
we have to install it on our system from CPAN. If you use `cpanm`, simply run:

`cpanm Dist::Zilla::PluginBundle::Starter`

Grab a cup of coffee as the `[@Starter]` bundle may take some time installing
all the modules it needs. When it finishes, build your module again with the
standard command:

`dzil build`

After the command finishes, inspect your distribution's directory and you'll
probably notice some differences compared to what the `[@Basic]` plugins
generated.

First, we now have a `META.json` file which CPAN will use to help tell the world
about your module. And if you open the `README` file, you'll see that it's
blank. Did we break something? Not at all. We'll tackle this problem in a
moment. `[@Starter]` also makes a lot of other technical changes to the process
that aren't necessary to cover now. Or, if you are brave, you can always check
out `[@Starter]`'s documentation for the nitty gritty details.

Suffice it to say here that changing the bundle can drastically change how your
module gets packaged by using different machines (plugins) on the assembly line.
As a result, even though we started with the same raw product coming from our
workbench area, our product was wrapped differently. Makes sense, right?

## Supplying a `README` File Using `[@Starter]`

No one except true, professional, detail-oriented software developers will read
it, but just like a `LICENSE` file, it's important to include a `README` file
with your distribution so you'll look like a true, professional,
detail-oriented software developer.

The `[@Basic]` bundle employed the `[Readme]` plugin to generate a typically
useless `README` file for your distribution. The `[@Starter]` bundle gives you
two different options for creating a much more useful `README` document using
either the `[ReadmeAnyFromPod]` plugin or the `[Pod2Readme]` plugin. Both of
these plugins were installed for you when you installed `[@Starter]` on your
system. By default, `[@Starter]` uses the `[ReadmeAnyFromPod]` plugin so we'll
start with that one.

But what will the `[@Starter]` bundle put into your `README` file? Is there some
powerful AI underlying `ReadmeAnyFromPod` to write it for us? Unfortunately,
no. We still have to do the hard work of documenting our module using Perl's
Plain Old Documentation (POD) because that is what the `[@Starer]` bundle uses
to generate your `README` file.

## Starting Your Module's Documentation

We haven't yet written any documentation for your module yet and that is
precisely why our `README` file is blank. So let's fix that. We don't want you
to have a reputation as a lazy developer that doesn't document their work. Add
some documentation to your `Greetings.pm` by adding these lines to the bottom of
the `lib/Greetings.pm` module:

```prettyprint

=head1 NAME

Greetings - Quick Greetings for the world

More documentation coming soon, we promise.

```

Interestingly, now that we have added the `NAME` section to our documentation,
`Dist::Zilla` can successfully build our module without the `# ABSTRACT` comment
that we had you create in the first tutorial. So go ahead and delete that
comment from your module.

Save your work and issue the `dzil build` command and check out the README file
now in your distribution and you should see that your module's POD was inserted
into the README file. Nice. Go bake yourself a well-deserved cookie.

## Double Your Pleasure with Two `README` Files

So now you've got a plain old text file for reading your module's plain old
documentation. Kind of boring. All the cool kids are using GitHub these days and
the preferred format for `REAMDE` files there is markdown. We don't want you
looking like a stick in the mud, so let's hook you up with a fancy markdown
version of your `README` file by adding the following to the end of your
`dist.ini` file:

```

[ReadmeAnyFromPod]
type = markdown
filename = README.md

```

Run the `build` command:

`dzil build`

Look inside your distribution. Awesome, you now have a plain text `README` file
and a fancier, markdown version `README.md` automatically generated for you
without having to know a lick of markdown syntax.

Let's take a moment to understand what you added to the `dist.ini` file. The
first line in brackets is, of course, the name of the plugin. In `.ini` file
parlance, bracketed text starts a new **section** in the `dist.ini` file.

Below and within this section you supplied two **parameters,** using the standard
key/value pair `.ini` syntax. Because they are in the section our plugin is
named after, they got passed to the plugin. Think of the parameters as custom
commands given to our `README` insertion robot on the assembly line. As you
might assume by looking at the parameters, you instructed the
`[@ReadmeAnyFromPod]` plugin to generate a `README.md` file using the `markdown`
syntax. Each plugin has different parameters that it will accept which you can
discover by carefully reading its documentation.

As we saw earlier, the `[@Starter]` bundle automatically generated the plain
text `README` file using the `[ReadmeAnyFromPod]` plugins. So what we are doing
here is telling `dist.ini` to run the `[ReadmeAnyFromPod]` plugin a **second
time** to generate the markdown version of our `README.md` file.

But the purists out there believe a markdown file has no business being on CPAN.
No problem! You can direct `[ReadmeAnyFromPod]` to save the markdown version to
the top level of your `Dist::Zilla` directory instead of inside your
distribution by adding the following line to the `[ReadmeAnyFromPod]` section of
your `dist.ini` file:

`location = root`

Try it out and run the `build` command and you'll see your `README.md` file
output alongside your distribution's directory instead of inside it:

`dist.ini  Greetings-0.002  Greetings-0.002.tar.gz  lib  README.md`

Now your CPAN repository will remain unpolluted by those new-fangled markdown
files, keeping the purists happy.

Alright, we've given you a very tiny taste for how to gain more control over how
your plugins work. We'll show you many more powerful and useful tricks later.
Now it's time to take a break from the world of plugins and start talking about
another fundamental area of knowledge `Dist::Zilla` calls "minting profiles" but
that we call "blueprints."
