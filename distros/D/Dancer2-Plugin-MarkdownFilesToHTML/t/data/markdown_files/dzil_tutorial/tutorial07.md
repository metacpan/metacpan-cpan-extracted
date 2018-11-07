# A More Useful `Dist::Zilla` Blueprint

You can create an entire library of blueprints customized for the different
kinds of modules and distributions you wish to create. For example, you might
set up a blueprint that generates boilerplate for Moose modules and another for
standalone perl scripts. You can also set up blueprints that create a git
repository for your module as well as generate a remote repository for you on
GitHub and that will automatically push commits out to it (we'll cover this in
future tutorial). There's lots of latent power underlying the `new` command.
This part of the tutorial will give you a better taste for how to tap into it.

To keep focused on the basics, the last blueprint was trivial. The one presented
in this tutorial might be one you'll want to add to your blueprint library, so
consider following along closely and doing all the steps below.

A quick word of caution: don't get too hung up on the technical details of the
slightly more advanced techniques used in this tutorial. If all you learn from
this tutorial is how to set up a new blueprint and use it to generate new
distributions, that's fine. It's more important that you follow the instructions
carefully to make sure you have a functional module at the end of this tutorial.

## Drafting a New Blueprint

Our blueprint will generate a work area for simple command line apps. To save
some labor, copy an existing blueprint similar to the new one we want to create.
In this case, that's the `default` blueprint, the only one we have:

```

cd ~/.dzil/profiles
cp -r default app

```

And now you can go to work making the necessary modifications to your new `app`
blueprint. First create the executable command that, by convention, is usually
stored in the `bin` directory of a distribution.

### Modifying Your Blueprint Copy

How do you design a blueprint that adds a `bin` directory and places a command
inside of it? You ask good questions. And as we answer them, you'll get to see
some of `Dist::Zilla`'s more powerful templating features.

Part of our answer is in the `profile.ini` file. Open it and look for the last
section with the following two lines:

```

[GatherDir::Template]
root = skel

```

We see the plugin name in brackets. But what's with the double colon sandwiched
in the name? This syntax means the `Template` plugin is a sublcass of the
`[GatherDir]` plugin. In other words, it is a plugin that does the same thing as
the `[GatherDir]` plugin with some additional capabilities.

So what does the plugin do, exactly?

#### The `[GatherDir]` and `[GatherDir::Template]` Plugins

You might recall seeing the `[GatherDir]` plugin from when you manually added
the individual plugins used by the `[@Basic]` bundle to the `dist.ini` file. The
`[GatherDir]` plugin is in all `dist.ini` files because it plays a critical role
in the distribution generation process.

When we issue a `dzil build` command, the `[GatherDir]` plugin gathers the files
from your work area and places them on the assembly line. It does a similar job
when we issue the `dzil new` command except it collects files from a directory
on your hard drive–usually within your blueprint directory–and adds them to your
work area. Before saving them there, though, `[GatherDir]` stores the files in
your computer's memory in case they need more processing.

The `Template` subclass tells `Dist::Zilla` to treat the collected files as
templates and, if any substitutions are found inside the files, it will replace
them with a string. You'll see this in action shortly.

#### Adding a Skeleton Directory for Your Module

The `root` parameter in the `[GatherDir::Template]` tells the plugin which
directory to gather the files from. In this case, it's the `skel` directory
inside the blueprint directory. There is nothing special about the "skel" name
which is short for "skeleton." We could call the directory anything we want.

But the `skel` directory doesn't exist yet so let's fix that. Making sure you
are inside the `command` blueprint directory, issue this command:

`mkdir skel`

Now add a `bin` directory inside the `skel` directory. As mentioned, the
`bin` directory is where the module's command goes.

`mkdir skel/bin`

#### Adding the Command Template

Next, create template file for the command inside the `bin` directory. The
template gets transformed into the command script in the work area when the
`dzil new` command gets issued. Open a new file called `skel/bin/the_command`
and paste in this code:

```prettyprint

#!/usr/bin/perl
use {{$dist->name =~ s/-/::/gr}};

{{$dist->name =~ s/-/::/gr}}->run;

=head1 NAME

{{$dist->name =~ s/-/::/gr}} - Add the command abstract here

```

Take a moment to study the template. Notice the code inside the double set of
curly braces. The double curly braces tell the templating system `Dist::Zilla`
uses to replace the curly braces and the code inside them with the result of the
expression between the curly braces.

So what is this bit of code doing, exactly?

To understand it, you have to know that `$dist->name` is the same name as the
string you provide for the distribution when you use the `dzil new` command
except that instad of `::` to delimit module directories, it uses a `-`
character. So, for example, if we create a new distribution called `App::sayhi`
(which we will do shortly), `$dist->name` is `App-sayhi`. The regular expression
inside the curly braces replace the dash in the name with a `::`.  As
mentioned, it's the job of the `[GatherDir::Template]` to perform the
substitutions found in this template.

In case you're wondering, `$dist` is the `Dist::Zilla` object overseeing
everything and `name`, of course, is the method for generating the name of our
distribution.

The command template is modeled after the example in the `App::Cmd::Simple`
module documentation, the module you are using to create this app. The `run`
method we see in the template file is provided by this module. Refer to the
`App::Cmd::Simple` documentation for more details.

OK, now save the command file to `skel/bin/the_command`. `the_command` file name
is arbitrary and acts as a placeholder in the blueprint. When it comes time to
process the blueprint, you'll want the name of this file to change to the name
of the command.

#### Changing the Command Name

To make that happen, we use of the `rename` parameter that
`[GatherDir::Template]` accepts. Reopen your `profile.ini` command and add the
following line to the end of the `[GatherDir::Template]` section and save the
file:

`rename.the_command = $dist->name =~ s/^App-//r`

This snippet tells the plugin to change the name of any file named `the_command`
to the last part of the distribution name. As pointed out alredy, the
`$dist->name` is the same as the distribution name we supplied to the `dzil new`
command except with dashes in place of `::`. The first part of of `$dist-name`
gets stripped away and what's left behind is used as the command's name.

### Modifying the Module Template

Your remaining task modifies the blueprint's module template file. Replace the
existing `Module.pm` file in the `command` blueprint directory with this code:

```prettyprint

package {{$name}};
use strict;
use warnings;
use base qw(App::Cmd::Simple);

sub opt_spec {
  return (
    [ "option1|a",  "do option 1" ],
  );
}

sub validate_args {
  my ($self, $opt, $args) = @_;

  # no args allowed but options
  $self->usage_error("No args allowed") if @$args;
}

sub execute {
  my ($self, $opt, $args) = @_;

  if ($opt->{option1}) {
      # do option 1 stuff
  } else {
      # do regular stuff
  }
}

1;

=head1 NAME

{{$name}} - Add the module abstract here

```

Notice, the use of the `{{$name}}` in the template. The `$name` variable is the
same as the distribution name provided to `dzil new` precisely as it was input
on the command line with the `::` in tact. As for how the rest of the code
works, take a look at the `App::Cmd::Simple` documentation.

## Set Up Your Work Area with the `new` Command and the `-p` Argument

It's time to see if you accurately followed instructions. Jump to the
`~/dzil_tutorial` directory and issue the following command:

`dzil new App::sayhi -p app`

This tells `dzil` to set up a new module work area with the distribution name
"App::sayhi".  The `-p` option supplies the `app` ~~profile~~ blueprint to the
command to use it to generate a new work area and populate it with files
according to your blueprint's instructions.

If you see errors after running the command, read them carefully and resolve
them.

## Getting `sayhi` to Say "Hi"

Now that `Dist::Zilla` has generated the work area, only a few simple changes
are required to get a useful command. Fire up your text editor to edit the
`lib/sayhi.pm` module to add/modify the following lines (or just cut and paste
the entire code listing further down):

* Add `use Greetings;` somewhere near the top

In the `opt_spec` function:

* replace `option1|a` with `shout|s`
* replace `do option 1` to `shout it`

In the `execute` funciton:

* change `$opt->{option1}` to `$opt->{shout}`
* replace `#do option 1 stuff` with `&Greetings::shout_hw;`
* replace `#do regular stuff` with `&Greetings::hw;`

In the pod:

* change `Add the module abstract here` to `Backend interface for the 'sayhi'
  command`

Here is the entire finished module for your copy and paste convenience:

```prettyprint

package App::sayhi;
use strict;
use warnings;
use Greetings;
use base qw(App::Cmd::Simple);

sub opt_spec {
  return (
    [ "shout|s",  "shout it" ],
  );
}

sub validate_args {
  my ($self, $opt, $args) = @_;

  # no args allowed but options!
  $self->usage_error("No args allowed") if @$args;
}

sub execute {
  my ($self, $opt, $args) = @_;

  if ($opt->{shout}) {
    &Greetings::shout_hw;
  } else {
    &Greetings::hw;
  }
}

1;

=head1 NAME

App::sayhi - Backend interface for the 'sayhi' command

```

Change the documentation in the `bin/sayhi` file so the abstract reads:

`command line greetings`

Finally, you may also need to install the `App::Cmd` module:

`cpanm App::Cmd`

Now test your module to make sure there are no errors:

`dzil test`

We will talk about testing in much more detail soon. If you didn't get an `All
tests successful` message near the bottom of the test output, review the
instructions above and double check your blueprint and module modifications. The
errors can help you track down the problem.

If the tests all passed, install the module with:

`dzil install`

Notice there is no need to issue the `build` or `release` subcommand first. You
can just go right ahead and install it.

If you installed the `Greetings` module from the earlier tutorial, you can have
hours of endless fun printing "Hello, World!" right from the command line. To
print a standard greeting, issue the `sayhi` command with no arguments. To shout
it, do `sayhi --shout` or `sayhi -s`. If you forget how the command works,
just use the `-h` option for a quick reminder.
