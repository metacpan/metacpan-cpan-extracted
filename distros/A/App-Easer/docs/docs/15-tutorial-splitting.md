---
title: 'Tutorial: splitting onto multiple modules'
layout: default
---

# Tutorial: splitting onto multiple modules

In the first [Tutorial: a to-do application][to-do-app] we took a look
at a basic example of a program with a nice, flat hierarchy whose
commands could benefit from a rather simple implementation (being mostly
centered around moving files).

Alas, life is not always that easy, and in many cases we might end up in
the need to cope with more complicated stuff. In this cases, a good
strategy is to break the problem down and try to address the different
parts one by one.

This breaking, sometimes, is meant *almost* phisically. I mean, it's
good to *break* the code into multiple files, so that we can concentrate
on one or another aspect at any time.

Depending on the style of implementation, this might be done by setting
up small execution callbacks towards more generic libraries, or calling
stuff in those libraries directly. At the end of the day, it's a matter
of size and preferences.

For this reason, in this tutorial we will try to break the `tudu`
application down in many different sub-modules, possibly in anticipation
that, one day, they will grow independently big.

## The main program

[App::Easer][] allows us to keep the very minimum inside the main
program, and spread most of the things over to modules. This includes
code as well as data.

This will be our main program:

```perl
#!/usr/bin/env perl
use v5.24;
use warnings;
use experimental 'signatures';
no warnings 'experimental::signatures';
use Path::Tiny 'path';
use App::Easer 'run';

my $application = {
   factory       => {prefixes => {'^' => 'MuDu::Command::'}},
   configuration => {
      name      => 'mudu',
      specfetch => '+SpecFromHashOrModule',
   },
   commands => {
      MAIN => {
         help        => 'to-do application',
         description => 'A simple to-do application, spread on files',

         sources        => '+SourcesWithFiles',
         'config-files' => ["$ENV{HOME}/.tudu.conf", '/etc/tudu.conf'],
         options     => [
            {
               help        => 'path to the configuration file',
               getopt      => 'config|c=s',
               environment => 1,
            },
            {
               help        => 'base directory where tasks are kept',
               getopt      => 'basedir|dir|d=s',
               environment => 1,
               default     => "$ENV{HOME}/.tudu",
            },
            {
               help   => 'max number of attempts to find non-colliding id',
               getopt => 'attempts|max-attempts|M=i',
               default => 9,
            },
         ],
         commit => \&ensure_basedir,

         children => [qw<
            ^List
            ^Show
            ^Cat
            ^Add
            ^Edit
            ^Done
            ^Wait
            ^Resume
            ^Remove
         >],
      }
   }
};
exit run($application, [@ARGV]);

sub ensure_basedir ($main, $spec, $args) {
   my $path = path($main->{configs}[-1]{basedir});
   $path->mkpath;
   $path->child($_)->mkpath for qw< ongoing waiting done >;
   return;
} ## end sub ensure_basedir
```

As we can see, we only left the `MAIN` command definition and the
`ensure_basedir` sub (moved from `TuDu` into `main`).

The prefixes have been changed to use `^` and make [App::Easer][]
eventually look for modules under the `MuDu::Command` namespace. The
list of `children` has been adapted accordingly, e.g. `^List` becomes
`MuDu::Command::List`.

We can note that the configuration file names have been kept the same as
`tudu`. This is by design: we want cooperation between the two tools!

## Common code

The common code from the previous implementation (inside the `TuDu`
namespace) can be moved in a common library that can be loaded from all
commands implementation modules. In the case of the `mudu` example, this
file is `MuDu::Utils`:

```perl
package MuDu::Utils;
use v5.24;
use warnings;
use experimental 'signatures';
no warnings 'experimental::signatures';
use Path::Tiny 'path';
use Exporter 'import';

our @EXPORT = qw< add_file autospec edit_file fatal get_title list_category
   move_task notice path resolve >;

...
```

For simplicity, we're exporting *all* subs.

## Moving a command, basic

Let's start taking a look at the command modules, beginning with the one
for the `done` sub-command:

```perl
package MuDu::Command::Done;
use v5.24;
use warnings;
use experimental 'signatures';
no warnings 'experimental::signatures';

use MuDu::Utils;

sub spec {
   return {
      help        => 'mark a task as completed',
      description => 'Archive a task as completed',
      supports    => [qw< done tick yay >],
      execute     => \&execute,
   }
}

sub execute ($m, $config, $args) { move_task($config, $args, 'done') }

1;
```

It's basically taking the command specification from the old global
hash, and putting it inside the `spec` function. The implementation in
`execute` is then linked directly, by taking a reference to it.


## Need a different style?

People used to other systems might prefer to have a different functions
for the different attributes inside the specification hash, like having
a sub for `help`, one for `description`, etc.

This can be easily accomplished by using a small helper function, put in
`MuDu::Utils` so that's automatically imported:

```perl
sub autospec ($package, %direct) {
   for my $key (qw< description help options supports >) {
      next if exists $direct{$key};
      my $sub = $package->can($key) or next;
      $direct{$key} = $sub->();
   }
   $direct{execute} //= $package;
   return \%direct;
}
```

The `execute` key is (conditionally) set to the package name. When
provided with a package name, the resolution process in [App::Easer][]
looks for a sub called `execute` inside that package, so it will suffice
to call our command implementation `sub execute`.

The specific way `autospec` is implemented (i.e. accepting an input hash
`%direct`) allows us to adopt different degrees of shifting stuff from
the hash to the functions. As an example, we go full-on with the
implementation for sub-command `add`:

```perl
package MuDu::Command::Add;
use v5.24;
use warnings;
use experimental 'signatures';
no warnings 'experimental::signatures';
use POSIX 'strftime';

use MuDu::Utils;

sub spec { __PACKAGE__->autospec() }
sub help        { return 'add a task' }
sub description { return 'Add a task, optionally setting it as waiting' }
sub supports    { return [qw< add new post >] }
sub options {
   return [
      {
         help   => 'add the tasks as waiting',
         getopt => 'waiting|w!'
      },
      {
         help   => 'set the editor for adding the task, if needed',
         getopt => 'editor|visual|e=s',
         environment => 'VISUAL',
         default     => 'vi',
      }
   ];
}
sub execute ($main, $config, $args) {
   my $id = strftime('%Y%m%d-%H%M%S', localtime);
   my $category = $config->{waiting} ? 'waiting' : 'ongoing';
   my $hint = path($config->{basedir})->child($category, $id);
   my $target = add_file($config, $hint, '');
   if ($args->@*) {
      $target->spew_utf8(join(' ', $args->@*) . "\n");
      return 0;
   }
   return 0 if edit_file($config, $target) && length get_title($target);
   $target->remove if -e $target;
   fatal("bailing out creating new task");
}

1;
```

As we can see, the `spec` function is implemented to call `autospec`,
this time only passing the `__PACKAGE__` name as the first parameter.

In sub-command `cat`, instead, we can opt for a midway and partially use
the hash input parameter for `autospec` and part the functions:

```perl
package MuDu::Command::Cat;
use v5.24;
use warnings;
use experimental 'signatures';
no warnings 'experimental::signatures';

use MuDu::Utils;

sub spec { __PACKAGE__->autospec(help => 'print one task (no delimiters)') }
sub description { return 'Print one whole task, without adding delimiters' }
sub supports    { return [qw< cat >] }
sub execute ($main, $config, $args) {
   my $child = resolve($config, $args->[0]);
   print {*STDOUT} $child->slurp_utf8;
   return 0;
}

1;
```

Here the `help` string is set directly in the arguments provided to
`autospec`, while letting it figure out the rest from the functions.

## Conclusions

All this is to show that different styles can be adopted, not that all
of them should be adopted at the same time of course. Some people prefer
to treat data as... data, and keep it tight (up to separating it into a
JSON file, for example); other people might have grown used to diffent
styles, where the different bits of information come from different
functions.

The full implementation of the to-do program can be found as `mudu` in
sub-directory `eg`, inside the [App::Easer][] distribution package.

[to-do-app]: {{ '/docs/10-tutorial-base' | relative_url }}
[App::Easer]: https://metacpan.org/pod/App::Easer
