# Documenting Your Module with `Dist::Zilla`

We arrive at another hated but necessary developer task, writing documentation
for your distribution. While we have some basic documentation for the
`App::sayhi` it's far from adequate.

`Dist::Zilla` obviously can't document your entire module for you but it can
take a lot of the pain out of generating boilerplate and compiling information
that endus up in your documentation. Let's show you how.

## Using Blueprints to Generate Documentation

The obvious way to generate boilerplate documentation is to use a blueprint with
a module template file that contains the boilerplate documentation you desire.
You can then edit/delete/add to the module's documentation as you develop the
module. We've already done this to a limited degree with our existing
`Module.pm` template files. Let's improve upon what we have. Open the
`Module.pm` file in the `~/.dzil/profiles/app` directory and add the following
to the documentation:

```

=head1 SYNOPSIS

=for comment Brief examples of using the module.

=head1 DESCRIPTION

=for comment The module's description.

=head1 AUTHOR

{{ join "\n\n", @{$dist->authors} }}

=head1 COPYRIGHT AND LICENSE

{{$dist->license->notice}}

```

Now the next time you go to create a new workarea with an `app` profile, you'll
automatically have some of the content added to your module for you. Feel free
to add other sections you'd like to see in the template. Notice the use of the
substitutions in our template. Remember, the `Dist::Zilla` object has
configuration file variables and other information that your templates can
access and use to customize your docs. See the [`Dist::Zilla`
documentation](https://metacpan.org/pod/Dist::Zilla) for more details.

## PodWeaver for Power Users

`Pod::Weaver` is a Perl module with a library of plugins designed to work with
`Dist::Zilla` to generate documentation for your distribution. Written by the
same developer as `Dist::Zilla`, it works very similarly to it with its use of
bundles and discrete plugins. Several tutorials could be written about how to
leverage the `[PodWeaver]` plugins and the hundreds of PodWeaver modules that
you can use to extend basic `[PodWeaver]` functionality. We will just cover
enough to give you a good idea how it works and provide resources for exploring
more.

### Setting up PodWeaver

The `[PodWeaver]` plugin is powerful, but it's easy to get started using if you
just want to generate basic documentation using the default plugins. Just drop
a `[PodWeaver]` section into your `dist.ini` just before the `[ReadmeAnyFromPod]`. It's important to put it before the `[ReadmyAnyFromPod]` so the `[PodWeaver]` plugin has a chance create your documentation so its output will be placed in the `README` files. Now run:

`dzil build`

```

[PodWeaver]

```

You will now get one of two different errors.

If you don't have the `[PodWeaver]` plugin already installed you'll get an
error:

`Required plugin Dist::Zilla::Plugin::PodWeaver isn't installed.`

Run `dzil installdeps` if you installed the subcommand from the previous
tutorial. If not, do the more long-winded `dzil authordeps --missing | cpanm`.
Now run `dzil build` again.

With `[PodWeaver]` installed, you'll see a different error complaining that the
`sayhi` command has no documentation. The error says you can fix it by adding a
`# PODNAME` comment so let's do that, adding it near the top, like so:

```

#!/usr/bin/perl
# PODNAME: sayhi

```

Now take a look at the `README.md` file. You'll notice that it is a merge between
the inline documentation in your `lib/App/sayhi.pm` file and the
documentation the default `[PodWeaver]` plugins added, namely, the `VERSION`, `AUTHOR`, and
`COPYRIGHT AND LICENSE` sections.

You'll notice we have one annoying problem, at least in our slightly outdated
verss


