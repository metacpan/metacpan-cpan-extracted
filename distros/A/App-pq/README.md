# NAME

App::pq - Like jq and gq, but with Perl

# SYNOPSIS

With no arguments, dump the JSON data structure from STDIN as a Perl data structure.

```perl
$ echo '{"foo":[1,2,3],"bar":"blee"}' | pq
$VAR1 = {
          'bar' => 'blee',
          'foo' => [
                     1,
                     2,
                     3
                   ]
        };
```

With an argument, process the argument as code with $j as the perl data structure.

```
$ echo '{"foo":[1,2,3],"bar":"blee"}' | pq 'print join "\n",  keys %$j'
foo
bar
```

# AUTHOR

Kaitlyn Parkhurst (SymKat) _<symkat@symkat.com>_ ( Blog: [http://symkat.com/](http://symkat.com/) )

# COPYRIGHT

Copyright (c) 2022 the WebService::WsScreenshot ["AUTHOR"](#author), ["CONTRIBUTORS"](#contributors), and ["SPONSORS"](#sponsors) as listed above.

# LICENSE

This library is free software and may be distributed under the same terms as perl itself.

# AVAILABILITY

The most current version of App::pq can be found at [https://github.com/symkat/App-pq](https://github.com/symkat/App-pq)
