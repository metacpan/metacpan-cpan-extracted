# Ch-Ch-Changes

A few sections back, one of the Kwalitee tests failed because the distribution
lacked a `Changes` file. Let's address this deficiency and show you how to use
`Dist::Zilla` to generate this file and add it to the distribution.

The `Changes` file can assist end users with answering the question: "Does the
new version of this module have new features or bug fixes that are worth the
risk of upgrading?" If your new version offers only minor document changes, they
might choose to pass. But if the module can now brush their teeth for them while
they sleep, they might bite.

A `Changes` file should be a simple log with each new release of your
distribution constituting three components:

* the version number of the new release
* the date of the release
* a summary of changes of interest to end users

The version and date of the release can be easily automated. The summary of
changes **can** be automated with a simple dump of your git commit log (assuming
you are using git). Whether this is something you **should** do is up to you. If
your typical end user is tecnically inclined, this may be fine. Or if you write
your commit messages with the end user in mind, you might be able to get away
with this though your `Changes` file might be a lot to wade through.

Ideally, however, you will craft each version summary with all the love and
attention you can muster so you stand out as the conscientious developer
that you are. As such a developer, this tutorial will not bother showing you how
to generate your Change log from git. If you are too lazy as to not want
to write summaries for your end users, you can seek out another tutorial for
that. Rant over. At least you know where we stand on this matter.

## Automating a Distribution's Version Numbers

Before tackling how to create the Change log, we need to implement automated
versioning in our `App::sayhi` module.

### Upgrade the `[@Starter]` Bundle's Capabilities

For that, we'll tap and old friend, the `[@Starter]` bundle. Before doing that,
though, you'll need to imbue it with newer capabilities than it currently has.
In the `dist.ini` file for the `App::sayhi` distribution, add two lines directly
after the section for the `[@Starter]` bundle like so:

```

[@Starter] ;already in your dist.ini file
; add the next two lines below
revision = 3
managed_versions = 1

```

Up until now, you have been using revision 1 of the `[@Starter]` bundle.
Revision 3, along with the `managed_versions` option, adds new plugins to the
bundle that we will use to automate the version numbers and generate the Change
log. Namely, they are the `[RewriteVersion]`, `[NextRelease]` and
`[BumpVersionAfterRelease]` plugins.

### Add `$VERSION` to the Module

Just as you did for the `Greetings` module, you need to add the `$VERSION`
variable to the `App::Sayhi` module which you should place just under the
module's package delcaration so it's easy to find:

`our $VERSION = '0.001';`

See if the distribution can build with that in place:

`dzil build`

Ugh. What's Zill monster angry about now? Let's see:

```

[DZ] attempted to set version twice
[DZ] attempted to set version twice at inline delegation in Dist::Zilla for logger->log_fatal (attribute declared in /home/steve/perl5/lib/perl5/Dist/Zilla.pm at line 768) line 18.

```

### Remove `version` from `dist.ini`

The problem is version is getting set twice now, once in our module and once in
`dist.ini`. Let's fix this by deleting the following line from `dist.ini`:

`version = 0.001`

And let's see if that fixes things for us:

`dzil build`

```

[@Starter/NextRelease] failed to find Changes in the distribution
[@Starter/NextRelease] failed to find Changes in the distribution at inline delegation in Dist::Zilla::Plugin::NextRelease for logger->log_fatal (attribute declared in /home/steve/perl5/lib/perl5/Dist/Zilla/Role/Plugin.pm at line 59) line 18.

```

Oops again.

### Add the `Changes` File

Zilla monster has found something else to stomp his feet about. As you see from
the error, the `[NextRelease]` plugin is complaining about not having a
`Changes` file. This is easy to fix. From the command line, issue:

```

touch Changes

```

This will create a blank Changes file for us. OK, third time's a charm, they say:

`dzil build`

### Adding Automated Content to the `Changes` File

And now Zilla monster is finally appeased. Obviously he doesn't care much about
blank change log files but our users do. So let's make the change log useful.
Add the following to the top of `Changes` file:

```

{{$NEXT}}

```

Let's see what this generates:

```

dzil build
cat lib/App/sayhi.pm

```

Cool, the `[NextRelease]` replaced `{{$NEXT}}` with the version number and a
timestamp. All that's missing is a summary of version changes, which should be
bulleted and indented. Add the summary below the `{{$NEXT}}` template
variable:

```

  - Initial release
  - Greet the world with they `sayhi` command
  - See `sayhi -h` for available options

```

And now:

```

dzil build
cat lib/App/sayhi.com

```

You now have a simple Change log for end users and an automated versioning
system in place to boot. The log format in our example is very basic. Notice we
added some simple markdown syntax with the backticks. If you are interested in
tricking it out more, consult the [`[NextRelease]`
documentation](https://metacpan.org/pod/Dist::Zilla::Plugin::NextRelease) for
additional options and template variables you can add to the `Changes` file. We
also recommend Neil Bowers' [blog post on Change log
conventions](http://blogs.perl.org/users/neilb/2013/09/a-convention-for-changes-files.html)
for inspiration. And before going too crazy, you should consult the [CPAN
spec](https://metacpan.org/pod/CPAN::Changes::Spec) for the Changes file
to ensure you comply with the simple requirements for the Changes log.

There is a bit more to cover with the Change log with the
`[BumpVersionAfterRelease]` plugin which we will cover when the time comes for
discussing releasing our distribution to the world.

## Updating the Blueprint to Reflect Your Improvements

When you set up a new work area with `Dist::Zilla`, you don't want to have to
remember to pop in `our $VERSION = 0.001;` and set up a new Changes file and
modify the `dist.ini` each. To save yourself future tedious work, you should go
back and edit the blueprint for the `app` profile in `~/.dzil/profiles/app` to
set up module that has automated versioning and a Change log ready to go out of
the box. That way, you'll never have to think about these tasks again. While
doing that, you may also want to consider adding in the prerequisite sections
(without the parameters) discussed in the previous chapter, as well. The more
you can automate with your blueprint, the more painless it will be to set up a
new distribution.
