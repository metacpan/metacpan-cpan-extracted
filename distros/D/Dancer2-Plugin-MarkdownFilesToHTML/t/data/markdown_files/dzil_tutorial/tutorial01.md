# Distributing Your First Perl Module with Dist::Zilla

## Sharing Your Work

Imagining new programmers the world over are tired of typing out `print "Hello,
World!\n"`, you create the following module to ease their pain:

```prettyprint

# Greetings.pm file
package Greetings;

sub hw {
  print "Hello, World!\n";
}

```

You are eager to share your module with others on CPAN so they can take
advantage of its goodness. In other words, you want to create a distribution for
your module. But where do you start?

## Tools for Getting Your Distribution Started

The hard way involves creating all the directories, files, tests, installers,
documentation, meta files, etc. that go into creating a distribution from
scratch. If you are a masochist, this is the recommended approach.

For non-masochists, existing tools are available to automate the creation of
distributions. For example, you can use the `h2xs` command line tool that ships
with Perl to get your distribution started. Drop into any empty directory on
your system and run the following command:

`h2xs -AX -n Greetings;`

Take a peek inside the resultant `Greetings` directory and you'll see the
command generated a minimal distribution for your `Greetings` module. Now you
can go in and edit this "skeleton" or "bare-bones" distribution and add some flesh
to it with custom code, tests, documentation, etc. But what `h2xs` generated for
you without any modifications could technically be installed to your local
machine as a distribution, albeit a rather useless one.

Another widely used tool for starting distributions is the more straightfowardly
named, `Module::Starter` which provides more command line options than `h2xs`
and the convenience of using a config file. We will leave it as an exercise for
the reader to find and tinker with these other tools. But it would be worthwhile
to take some time to get familiar with them and examine the files they generate
to enhance your appreciation of what `Dist::Zilla` does for you.

## Generating a Distribution with `Dist::Zilla`

Now let's take `Dist::Zilla` for a spin now and see how it differs from `h2xs`.
Make sure you have `Dist::Zilla` installed on your machine and create a
direcotry on your home drive for tutorial projects:

`mkdir ~/dzil_projects`

`cd` into this directory and issue your first `Dist::Zilla` command:

`dzil setup`

`Dist::Zilla` will prompt you for your name, email address and ask some basic
questions about how your software will be released. Finally, it will ask you for
your credentials for your PAUSE account. If you don't have a PAUSE account or
don't know what one is, answer "no" and move on. You can always configure this
later. As we'll see, `Dist::Zilla` uses the configuration information you enter
and adds it to the appropriate files in your distribution.

### The `dzil new` Command

OK, now we are ready to start a distribution similar to the way we created one
with `h2xs`, by issuing a command:

`dzil new Greetings`

`dzil` will dutifully keep us informed of its progress:

```

[DZ] making target dir /home/steve/dzil_projects/Greetings
[DZ] writing files to /home/steve/dzil_projects/Greetings
[DZ] dist minted in ./Greetings

```

Like `h2xs`, `dzil new` generated a directory with some files inside of it.
`Dist::Zilla` also reported that it has "minted" a "dist" for us. We'll come
back to this crypticism later. Enter the `Greetings` directory and see the
magic `dzil` has pulled off for us:

```

cd Greetings
ls

```

Ouch! There's barely anything here. Just a mysterious `dist.ini` file and a
`lib` directory with a minimal `Greetings.pm` file inside of that. This doesn't
seem very impressive compared to the `h2xs` tool.

`Dist::Zilla` works a lot differently than `h2xs`. Its `new` subcommand doesn't
generate a distribution, it simply sets up a directory that will eventually
store the module's code and distributions. But before we get ahead of ourselves,
let's make the module useful by editing the `lib/Greetings.pm` module file that
`dzil` generated and add this function to the file:

```prettyprint

sub hw {
  print "Hello, World!\n";
}

```

For reasons we don't need to worry about now, we have to add a brief abstract,
with the folowing line so `Dist::Zilla` won't complain:

`# ABSTRACT: Quick Greetings for the world`

So your `Greetings.pm` file should look like this:

```prettyprint

use strict;
use warnings;
package Greetings;

sub hw {
  print "Hello, World!\n";
}

1;
# ABSTRACT: Quick Greetings for the world

```

### The `dzil build` Command

Now we are ready to generate a distribution with `dzil`'s
`build` command from the top level of the `Greetings` distribution:

`dzil build`

OK! It looks like we are getting somewhere now. The `dist` command has reported
that is has created a new tarball and a directory, `Greetings-0.001` for us.
The files in this directory are a fully functional distribution that can
actually be installed. If you look inside the `Greetings-0.001`, you'll see
something that looks much closer to what we generated with the `h2xs` command.

### The `dzil install` Command

A tarballed version of the `Greetings-0.001` directory was also generously
created by `Dist::Zilla` to save you the step of having to create it yourself.
You can easily install this tarball into to your local perl library with the
following command:

`dzil install`

You should see something like this output to the terminal:

```

[DZ] building distribution under .build/NG8bhY4qL6 for installation
[DZ] beginning to build Greetings
[DZ] guessing dist's main_module is lib/Greetings.pm
[DZ] writing Greetings in .build/NG8bhY4qL6
--> Working on .
Configuring Greetings-0.001 ... OK
Building and testing Greetings-0.001 ... OK
Successfully installed Greetings-0.001
1 distribution installed
[DZ] all's well; removing .build/NG8bhY4qL6

```

Nice, now the module is available to use anywhere on your system. So congrats,
you've successfully built your very first distribution with `Dist::Zilla` and
distributed it, even if only to yourself. But feel free to email the tarball to
your friends and astonish them with what your new module can do. Much later in
the tutorial, we will show you how to upload your work to CPAN so you can find
an even wider audience for your modules.

You now have a rudimentary understanding of how to use `dzil`, along with some
of its subcommands, to automate the process of generating a distribution. Let's
take a quick look at some other important subcommands to see what else
`Dist:Zilla` does.
