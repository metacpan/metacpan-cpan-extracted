# `Dist::Zilla` Subcommands

Now that you've gotten your hands grimy operating some of `Dist::Zilla`'s
machinery, let's zoom out a bit and take a factory floor level look at
`Dist::Zilla` with an overview of some other subcommands `Dist::Zilla` provides
out of the box.

## The `dzil new` Command

After installing and configuring `Dist::Zilla`, you issued the `dzil new`
command to get the process started. If you think of `Dist::Zilla` as a module
distribution production factory, then the `new` command establishes a new work
area on the factory floor for assembling the raw product (the module) before
assembling, packaging and shipping it.

The work area you set up for the `Greetings` module used `Dist::Zilla`'s default
profile that, as you saw, was very sparse and bare-bones. You will learn how to
teach `Dist::Zilla` to establish highly customized work areas by, in the jargon
of `Dist::Zilla`, "minting a custom profile." More on this later.

## The `dzil build` Command

After writing your one-function module, you issued the `dzil build` command. The
`build` command generated a copy of your distribution and placed a copy of it in
your work area along with a tarballed version of it.

An excellent way to think about the `build` command is to imagine it as a button
that activates an assembly line. Your raw product, the module, is loaded onto
the beginning of the assembly line. As your module moves down the line, an
ordered series of robots, called **plugins,** work their magic to transform your
module into a finished, fully packaged distribution at the end of the line
that, if all goes well, it's ready for you to ship to the rest of the world.

Many plugins come pre-packaged with `Dist::Zilla` but there are hundreds more
available on CPAN. You can also write your own plugins to build your
distribution in highly speciaized ways. Plugins are an important topic which we
will cover in more detail, shortly.

## The `dzil release` Command

You didn't issue this command in the previous chapter of our tutorial but this
is the command that will "box" and "ship" your finished distribution to whatever
destination you want to deliver it to. Common destinations include a remote git
repository and CPAN. As you'll see, you can customize this process just like you
can the `build` process. And similar to the `build` process, the `release`
process relies on a series of discrete plugins to get your product out the door.
This command will be covered much later in the tutorial.

## The `dzil test` Command

This is another command we didn't cover in the first chapter but as you might
guess, it's used to run the tests on your module. This command will come in
handy as as you develop your module to see if it passes the tests. We will
discuss this command as well as automated testing in future tutorials.

## The `dzil install` Command

As you already saw, you use this command to install a distribution to your local
machine. Once installed, other modules on your system can easily load it with a
`use` statement.

## The `dzil clean` Command

No one likes working in a dirty environment so it's a good idea to sweep away
all the debris that accumulates on your shop floor while you work. Go ahead and
issue this command now to see what happens:

`dzil clean`

Both the tarball file and the distribution directory are now gone and only the
files we had after issuing the `new` command are left behind. But don't worry,
you can easily get them back by issuing the `dzil build` command.

## Other `dzil` Commands

There are other, minor `dzil` subcommands but since this is a tutorial and not a
manual, we will encourage you to take some time and explore the other commands
with `dzil --help` and `dzil <subcommand> --help`. We will cover some of these
other command later in the tutorial.

We now turn your attention to a very important topic, the `dist.ini` file.
