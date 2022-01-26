---
title: 'Tutorial: a to-do application'
layout: default
---

# Tutorial: a to-do application

In this tutorial we will take a look at an example application, i.e. a
small to-do application to manage tasks from the command line. This is
the same application that is available inside the `eg` sub-directory of
the [App::Easer][] package.

## Boilerplate and high level structure

Let's start with setting up the skeleton for our application:

```perl
#!/usr/bin/env perl
use v5.24;
use warnings;
use experimental 'signatures';
no warnings 'experimental::signatures';
use App::Easer 'run';
 
my $application = {
   factory       => {prefixes => {'#' => 'TuDu#'}},
   configuration => {
      'auto-leaves'    => 1,
      'help-on-stderr' => 1,
   },
   commands => {
      MAIN   => { ... },
      dump   => { ... },
      list   => { ... },
      show   => { ... },
      cat    => { ... },
      add    => { ... },
      edit   => { ... },
      done   => { ... },
      wait   => { ... },
      resume => { ... },
      remove => { ... },
   },
};
exit run($application, [@ARGV]);

package TuDu;
use Path::Tiny 'path';
use POSIX 'strftime';
...
```

The `factory` top level configuration lays the ground for putting the
implementation inside a separate package `TuDu`. That particular prefix
setting is used as follows:

- a name like `#foobar` will be turned into `TuDu#foobar`;
- this will be resolved into function `TuDu::foobar` (i.e. function
  `foobar` inside package `TuDu`.

As a result, we have a shortcut to point towards functions inside the
`TuDu` package for our implementations.

We are setting a couple of high-level configurations:

- `auto-leaves`: every command without explicit children will be treated
  as a leaf command, so it will not get a `help` and a `commands`
  sub-commands;
- `help-on-stderr`: help messages (from `help` and `commands`) will be
  printed on standard error instead of standard output. This makes it
  more difficult to pipe them through a pager (like `more` or `less`),
  but avoids that the help messages might be accidentally considered
  part of the "real" output of the command.

The rest of the `$application` hash reference is initialized with a
skeleton of all the sub-commands that we aim to support. The structure
is pretty flat - all "real" sub-commands are in fact children to the
`MAIN` entry point.

## Setting the MAIN entry point

Let's flesh out the `MAIN` entry point. This will collect the *global*
configuration options (e.g. where the configuration file is placed,
where to place the tasks, etc.) as well as doing some housekeeping to
ease the work of the "real" commands:

```perl
# inside hash at $application->{commands}:
MAIN => {
   help        => 'to-do application',
   description => 'A simple to-do application',

   children => [qw< list show cat add edit done wait resume remove >],

   sources        => '+SourcesWithFiles',
   'config-files' => ["$ENV{HOME}/.tudu.conf", '/etc/tudu.conf'],
   options     => [
      {
         help        => 'path to the configuration file',
         getopt      => 'config|c=s',
         environment => 'TUDU_CONFIG',
      },
      {
         help        => 'base directory where tasks are kept',
         getopt      => 'basedir|dir|d=s',
         environment => 'TUDU_BASEDIR',
         default     => "$ENV{HOME}/.tudu",
      },
      {
         help   => 'max number of attempts to find non-colliding id',
         getopt => 'attempts|max-attempts|M=i',
         default => 9,
      },
   ],

   commit         => '#ensure_basedir',
},
```

The `help` and `descriptions` are useful ways to provide clues to the
users about how to use this command. Of the two, `help` is used where a
concise description is needed, while `description` is used in the help
page regarding the command itself, so it's generally more verbose.

As anticipated, `children` points to all sub-commands, because this
specific application has a flat hierarchy. For fancier hierarchies,
[Defining commands hierarchy][] is the tutorial to look for.

The next section deals with managing input options. The `sources`
key points to `+SourcesWithFiles`, which means that the following
sources will be used for gathering options, in order:

- the command line;
- the environment;
- any JSON configuration file coming from option `config`;
- any configuration file from those specified in the array pointed by
  key `config-files`;
- default values.

The `options` key points to the array of actual options that are
supported at this level. There are three of them, all without an
explicit `name` key, which means they get their name from the `getopt`
key instead:

- option `config`:
    - can be provided through the command line as `-c` or `--config`;
    - can be provided through the environment variable `TUDU_CONFIG`;
- option `basedir`:
    - can be provided through the command line as `-d`, `--dir`, or
      `--basedir`;
    - can be provided through the environment variable `TUDU_BASEDIR`;
    - defaults to file `.tudu` in the home directory;
- option `attempts`:
    - can be provided through the command line as `-M`,
      `--max-attempts`, or `--attempts`;
    - defaults to value 9.

The last part of the specification is the `commit` key, which points to
the *executable* `#ensure_basedir`. As we saw, this executable is
resolved into function `ensure_basedir` inside package `TuDu`:

```
...
package TuDu;
...
sub ensure_basedir ($main, $spec, $args) {
   my $path = path($main->{configs}[-1]{basedir});
   $path->mkpath;
   $path->child($_)->mkpath for qw< ongoing waiting done >;
   return;
} ## end sub ensure_basedir
```

This function makes sure that whatever directory has been set for option
`basedir` actually exists and has the right internal shape
(sub-directories `ongoing`, `waiting`, and `done`).

The `commit` key is used whenever some action is needed at any command
level just after the configuration has been assembled for that level,
but before any actual command execution happens. In this case, then, we
set it in the `MAIN` command, because it does *not* have anything to
execute ("real" actions are carried over by sub-commands only), but
still there's some setup housekeeping that is common to all
sub-commands.


## Simple sub-commands without options

Many of the commands that we implement through our toy `tudu`
application take no input parameters and share the same structure, so we
will define and describe all together:

```
# inside hash at $application->{commands}:
show => {
   help        => 'print one task',
   description => 'Print one whole task',
   supports    => [qw< show print get >],
   execute     => '#show',
},
cat => {
   help        => 'print one task (no delimiters)',
   description => 'Print one whole task, without adding delimiters',
   supports    => [qw< cat >],
   execute     => '#cat',
},
...
done => {
   help        => 'mark a task as completed',
   description => 'Archive a task as completed',
   execute     => '#done',
   supports    => [qw< done tick yay >],
},
wait => {
   help        => 'mark a task as waiting',
   description => 'Set a task as waiting for external action',
   supports    => [qw< waiting wait >],
   execute     => '#waiting',
},
resume => {
   help        => 'mark a task as ongoing',
   description => 'Set a task in active mode (from done or waiting)',
   supports    => [qw< resume active restart ongoing >],
   execute     => '#resume',
},
remove => {
   help        => 'delete a task',
   description => 'Get rid of a task (definitively)',
   supports    => [qw< remove rm delete del >],
   execute     => '#remove',
},
...
```

In addition to the `help` and `description` that we already saw for
`MAIN`, we have two additional keys.

The first is `supports`, which provides a list of *aliases* that can be
used to invoke the sub-command. In other terms, to delete a to-do task
we can use any of the following:

```
$ tudu remove ...

$ tudu rm ...

$ tudu delete ...

$ tudu del ...
```

The other key is `execute`, which points to an *executable* function. As
we already saw, each executable is resolved to a corresponding function
inside the `TuDu` package, for example this for command `done`:

```perl
sub done ($m, $config, $args) { move_task($config, $args, 'done') }
```

We will not get into the details of the implementation, but we can take
anyway a look at `move_task` (which is also used from other
*executables*):

```perl
sub move_task ($config, $src, $category) {
   $src = $src->[0] if 'ARRAY' eq ref $src;
   my $child = resolve($config, $src);
   my $parent = $child->parent;
   if ($parent->basename eq $category) {
      notice("task is already $category");
      return 0;
   }
   my $dest = $parent->sibling($category)->child($child->basename);
   add_file($config, $dest, $child->slurp_utf8);
   $child->remove;
   return 0;
} ## end sub move_task
```

The function receives the overall configuration and something to figure
out *which* task it has to operate on. We can see that in `sub done` we
are passing the input `$args`, that is the unparsed arguments list as an
array; for this reason, this input `$src` is transformed into the first
item in the array, should it be an array (like when called from `done`).

The `resolve` function makes sure to turn the `$src` specification into
an actionable `$child` task, which is basically a [Path::Tiny][] object
pointing to the file of the task itself.

```perl
use Path::Tiny 'path';
...
sub resolve ($config, $oid) {
   ...
   my $child;
   ...
      $child = path($config->{basedir})->child($type, $id);
   ...
   return $child;
} ## end sub resolve
```

## Complex sub-command

The "complex" sub-commands are actually very similar to the simple ones
described above, with the exception that they accept additional
command-line options.

As an example, let's consider command `add`, to track a new task:

```perl
# inside hash at $application->{commands}:
add => {
   help        => 'add a task',
   description => 'Add a task, optionally setting it as waiting',
   supports    => [qw< add new post >],
   options     => [
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
   ],
   execute => '#add',
},
```

Keys `help`, `description`, `supports`, and `execute` are exacty as
before.

Options are no surprise too: we already saw them in detail for the
`MAIN` entry point command. The difference here is that, by default,
options are taken from the command line, then the environment, then the
parent command, then the defaults; there is no loading of additional
options from files. This is also what the user expects, anyway.

Other sub-commands `list` and `edit` share the same structure.


## The dump outlier

The example `tudu` application also contains an *outlier* sub-command
`dump`, which is normally excluded from the children list (we would have
to set it explicitly in `MAIN`'s `children` in case).

```perl
# inside hash at $application->{commands}:
dump => { # this child is normally excluded!
   help => 'dump configuration',
   execute => sub ($m, $c, $a) {
      require Data::Dumper;
      warn Data::Dumper::Dumper({config => $c, args => $a});
      return 0;
   },
},
```

In this case we don't need to hand the execution over to `TuDu`, but can
provide it right off the bat with a `sub` reference. This gives us an
idea of how flexible we can be with the *executables*, ranging from
in-site implementation, to reference to other subs, up to putting stuff
in different packages and, possibly, different module files.

## Getting all pieces together

The whole program for our toy `tudu` application is the following,
including all the implementation functions placed in the `TuDu` package:

```
#!/usr/bin/env perl
use v5.24;
use warnings;
use experimental 'signatures';
no warnings 'experimental::signatures';
use App::Easer 'run';

my $application = {
   factory       => {prefixes => {'#' => 'TuDu#'}},
   configuration => {
      'auto-leaves'    => 1,
      'help-on-stderr' => 1,
   },
   commands => {
      MAIN => {
         help        => 'to-do application',
         description => 'A simple to-do application',
         options     => [
            {
               help        => 'path to the configuration file',
               getopt      => 'config|c=s',
               environment => 'TUDU_CONFIG',
            },
            {
               help        => 'base directory where tasks are kept',
               getopt      => 'basedir|dir|d=s',
               environment => 'TUDU_BASEDIR',
               default     => "$ENV{HOME}/.tudu",
            },
            {
               help   => 'max number of attempts to find non-colliding id',
               getopt => 'attempts|max-attempts|M=i',
               default => 9,
            },
         ],
         sources        => '+SourcesWithFiles',
         'config-files' => ["$ENV{HOME}/.tudu.conf", '/etc/tudu.conf'],
         commit         => '#ensure_basedir',
         children => [qw< list show cat add edit done wait resume remove >],
      },
      dump => { # this child is normally excluded!
         help => 'dump configuration',
         execute => sub ($m, $c, $a) {
            require Data::Dumper;
            warn Data::Dumper::Dumper({config => $c, args => $a});
            return 0;
         },
      },
      list => {
         help        => 'list tasks',
         description => 'Get full or partial list of tasks',
         supports    => [qw< list ls >],
         options     => [
            {
               help => 'include all tasks (including done) '
                 . '(exclusion is not honored)',
               getopt => 'all|A!',
            },
            {
               help => 'include(/exclude) all active tasks '
                 . '(ongoing and waiting)',
               getopt => 'active|a!',
            },
            {
               help   => 'include(/exclude) done tasks',
               getopt => 'done|d!',
            },
            {
               help   => 'include(/exclude) ongoing tasks',
               getopt => 'ongoing|o!',
            },
            {
               help   => 'include(/exclude) waiting tasks',
               getopt => 'waiting|w!',
            },
            {
               help   => 'use extended, unique identifiers',
               getopt => 'id|i!',
            },
            {
               help => 'limit up to n items for each category (0 -> inf)',
               getopt => 'n=i'
            },
         ],
         execute => '#list',
      },
      show => {
         help        => 'print one task',
         description => 'Print one whole task',
         supports    => [qw< show print get >],
         execute     => '#show',
      },
      cat => {
         help        => 'print one task (no delimiters)',
         description => 'Print one whole task, without adding delimiters',
         supports    => [qw< cat >],
         execute     => '#cat',
      },
      add => {
         help        => 'add a task',
         description => 'Add a task, optionally setting it as waiting',
         supports    => [qw< add new post >],
         options     => [
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
         ],
         execute => '#add',
      },
      edit => {
         help        => 'edit a task',
         description => 'Start an editor to modify the task',
         supports    => [qw< edit modify change update >],
         options     => [
            {
               help   => 'set the editor for adding the task, if needed',
               getopt => 'editor|visual|e=s',
               environment => 'VISUAL',
               default     => 'vi',
            }
         ],
         execute => '#edit',
      },
      done => {
         help        => 'mark a task as completed',
         description => 'Archive a task as completed',
         execute     => '#done',
         supports    => [qw< done tick yay >],
      },
      wait => {
         help        => 'mark a task as waiting',
         description => 'Set a task as waiting for external action',
         supports    => [qw< waiting wait >],
         execute     => '#waiting',
      },
      resume => {
         help        => 'mark a task as ongoing',
         description => 'Set a task in active mode (from done or waiting)',
         supports    => [qw< resume active restart ongoing >],
         execute     => '#resume',
      },
      remove => {
         help        => 'delete a task',
         description => 'Get rid of a task (definitively)',
         supports    => [qw< remove rm delete del >],
         execute     => '#remove',
      },
   },
};
exit run($application, [@ARGV]);

package TuDu;
use Path::Tiny 'path';
use POSIX 'strftime';

sub ensure_basedir ($main, $spec, $args) {
   my $path = path($main->{configs}[-1]{basedir});
   $path->mkpath;
   $path->child($_)->mkpath for qw< ongoing waiting done >;
   return;
} ## end sub ensure_basedir

sub list_category ($config, $category) {
   my $dir = path($config->{basedir})->child($category);
   return reverse sort { $a cmp $b } $dir->children;
}

sub list ($main, $config, $args) {
   my @active = qw< ongoing waiting >;
   my @candidates = (@active, 'done');
   my %included;

   # Add stuff
   if ($config->{all}) {
      @included{@candidates} = (1) x @candidates;
   }
   for my $option (@candidates) {
      $included{$option} = 1 if $config->{$option};
   }
   if ($config->{active} || !scalar keys %included) {
      @included{@active} = (1) x @active;
   }

   # Remove stuff
   delete @included{@active}
     if exists $config->{active} && !$config->{active};
   for my $option (@candidates) {
      delete $included{$option}
        if exists $config->{$option} && !$config->{$option};
   }

   my $basedir = path($config->{basedir});
   my (%cf, %pf);
   my $limit = $config->{n};
   for my $source (@candidates) {
      next unless $included{$source};
      for my $file (list_category($config, $source)) {
         my $title = get_title($file);
         my $sid = $config->{id} ? '-' . $file->basename : ++$cf{$source};
         my $id = substr($source, 0, 1) . $sid;
         say "$id [$source] $title";
         last if $limit && ++$pf{$source} >= $limit;
      } ## end for my $file (list_category...)
   } ## end for my $source (@candidates)

   return 0;
} ## end sub list

sub resolve ($config, $oid) {
   fatal("no identifier provided") unless defined $oid;
   my $id = $oid;

   my %name_for = (o => 'ongoing', d => 'done', w => 'waiting');
   my $first = substr $id, 0, 1, '';
   my $type = $name_for{$first} // fatal("invalid identifier '$oid'");

   my $child;
   if ($id =~ s{\A -}{}mxs) {    # exact id
      $child = path($config->{basedir})->child($type, $id);
      fatal("unknown identifier '$oid'") unless -r $child;
   }
   else {
      fatal("invalid identifier '$oid'")
        unless $id =~ m{\A [1-9]\d* \z}mxs;
      my @children = list_category($config, $type);
      fatal(
"invalid identifier '$oid' (too high, max $first@{[scalar @children]})"
      ) if $id > @children;
      $child = $children[$id - 1];
   } ## end else [ if ($id =~ s{\A -}{}mxs)]

   return $child;
} ## end sub resolve

sub show ($main, $config, $args) {
   my $child = resolve($config, $args->[0]);
   my $contents = $child->slurp_utf8;
   $contents =~ s{\n\z}{}mxs;
   say "----\n$contents\n----";
   return 0;
} ## end sub show

sub cat ($main, $config, $args) {
   my $child = resolve($config, $args->[0]);
   print {*STDOUT} $child->slurp_utf8;
   return 0;
} ## end sub show

sub fatal ($message) { die join(' ', @_) . "\n" }
sub notice ($message) { warn join(' ', @_) . "\n" }

sub add_file ($config, $hint, $contents) {
   my $attempts = 0;
   my $file     = path($hint);
   while ('necessary') {
      eval {
         my $fh =
           $file->filehandle({exclusive => 1}, '>', ':encoding(UTF-8)');
         print {$fh} $contents;
         close $fh;
      } && return $file;
      ++$attempts;
      last if $config->{attempts} && $attempts >= $config->{attempts};
      $file = $hint->sibling($hint->basename . "-$attempts");
   } ## end while ('necessary')
   fatal("cannot save file '$hint' or variants");
} ## end sub add_file

sub move_task ($config, $src, $category) {
   $src = $src->[0] if 'ARRAY' eq ref $src;
   my $child = resolve($config, $src);
   my $parent = $child->parent;
   if ($parent->basename eq $category) {
      notice("task is already $category");
      return 0;
   }
   my $dest = $parent->sibling($category)->child($child->basename);
   add_file($config, $dest, $child->slurp_utf8);
   $child->remove;
   return 0;
} ## end sub move_task

sub done ($m, $config, $args) { move_task($config, $args, 'done') }
sub resume ($m, $config, $args) { move_task($config, $args, 'ongoing') }
sub waiting ($m, $config, $args) { move_task($config, $args, 'waiting') }

sub remove ($main, $config, $args) {
   resolve($config, $args->[0])->remove;
   return 0;
}

sub get_title ($path) {
   my ($title) = $path->lines({count => 1});
   ($title // '') =~ s{\A\s+|\s+\z}{}grmxs;
}

sub add ($main, $config, $args) {
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
} ## end sub add

sub edit_file ($config, $path) {
   my $editor = $config->{editor};
   my $outcome = system {$editor} $editor, $path->stringify;
   return $outcome == 0;
}

sub edit ($main, $config, $args) {
   my $target = resolve($config, $args->[0]);
   my $previous = $target->slurp_utf8;
   return 0 if edit_file($config, $target) && length get_title($target);
   $target->spew_utf8($previous);
   fatal("bailing out editing task");
}

1;
```

[App::Easer]: https://metacpan.org/pod/App::Easer
[Path::Tiny]: https://metacpan.org/pod/Path::Tiny
[Defining commands hierarchy]: {{ '/docs/30-commands-hierarchy.html' | relative_url }}
