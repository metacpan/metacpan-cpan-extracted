---
title: 'Cookbook'
layout: default
---

# Cookbook

Some quick answers to common needs.

## Define the application structure in JSON

It might be a good idea to define the application's structure through
a JSON file. In this case, there are several ways to use it, all through
the `run` command.

If the specification is inside a standalone JSON file, just pass the path
to the file:

```perl
run('/path/to/app.json', \@ARGV);
```

If the specification is in a variable as a string, pass a reference to that string:

```perl
run(\$app_definition_in_json, \@ARGV);
```

## Partition code into multiple files

If your application definition grows a lot, it can make sense to break it into
multiple files, especially the implementation parts. This can be done
out of the box in [App::Easer][], even though there are some tricks that
can make the process smoother.

We will concentrate on an example about the `execute` callback, but this
is generally applied to all other *executables* as well.

An executable can be a string, in which case it is resolved into
a function. At a basic level, it's sufficient to provide the name of
a package, and [App::Easer][] will do the heavy-lifting:

```perl
my $app = {
    commands => {
        foo => {
            execute => 'MyApp::Foo',
        }
    }
};
```

By default, [App::Easer][] will look for a function that matches the
specific callback it is resolving:

```
Callback name | Searched function
--------------+------------------
collect       | collect   
commit        | commit    
dispatch      | dispatch  
execute       | execute   
fallback      | fallback  
merge         | merge     
validate      | validate  
```

It is possible to set a different name like this:

```perl
my $app = {
    commands => {
        foo => {
            execute => 'MyApp::Foo#execute_this',
        }
    }
};
```

It is also possible to simplify the specification by setting a prefix
expansion, like the following example:

```perl
my $app = {
    factor => { prefixes => { '@' => 'MyApp::' } },
    commands => {
        foo => {
            execute => '@Foo',
        }
    }
};
```

Try to avoid the `+` prefix because it is already used by
[App::Easer][].

The two can be put together, of course:

```perl
my $app = {
    factor => { prefixes => { '@' => 'MyApp::' } },
    commands => {
        foo => {
            execute => '@Foo#execute_this',
        }
    }
};
```


## Partition the definition into multiple files

To keep the definition parts together with the implementation, the
*configuration* `specfetch` instructs [App::Easer][] about where to find the
specifications (in addition to the specification hash):

```perl
my $app = {
    configuration => {
        specfetch => '+SpecFromHashOrModule',
        ...
    }
};
```

To trigger loading the command specification from an external module,
set the `children` with hints to get the specification, e.g.:

```perl
my $app = {
    ...
    commands => {
        MAIN => {
            children => [qw< MyApp::Foo MyApp::Bar >],
            ...
        },
    }
};
```

In the examples above, sub-command `foo` is defined inside `MyApp::Foo`,
in particular inside its function `spec`:

```perl
package Foo;

# get the command specification, built according to App::Easer rules
# for commands inside the commands hash.
sub spec {
    return {
        supports => [qw< foo Foo FOO >],
        ...
    }
}

1;
```

When configuration `specfetch` is set to `+SpecFromHashOrModule` (which
is actually a shortcut for [App::Easer][]'s own internal function
`stock_SpecFromHashOrModule`), for all matters the child name is treated
as an *executable* unless there's already a definition in the `commands`
sub-hash. As such, it's possible to use all tricks explained in
[Partition code into multiple
files](#partition-code-into-multiple-files), like setting a custom name
for the function to be called, or ease life through prefixes.



[App::Easer]: https://metacpan.org/pod/App::Easer
[Installing Perl Modules]: https://github.polettix.it/ETOOBUSY/2020/01/04/installing-perl-modules/
[Perl]: https://www.perl.org/
[App::FatPacker]: https://metacpan.org/pod/App::FatPacker
[latest]: https://raw.githubusercontent.com/polettix/App-Easer/main/lib/App/Easer.pm
[download]: {{ '/assets/template.pl' | prepend: site.baseurl }}
