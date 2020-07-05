# perl-pp-autolink

![macos](https://github.com/shawnlaffan/perl-pp-autolink/workflows/macos/badge.svg)
![linux](https://github.com/shawnlaffan/perl-pp-autolink/workflows/linux/badge.svg)

pp is a tool that packs perl scripts and their dependencies into a stand alone executable.  https://metacpan.org/pod/pp

However, it currently does not find external dynamic libs. These can be added to the pp call using the ```--link``` option,
but knowing which dynamic libs to list is a source of general angst.  This tool automates that process.

The pp_autolink.pl script finds dependent dynamic libs and passes them to a pp call.

It has been tested for Windows, Mac and Linux machines only so far.

The argument list is the same as for pp.  

```perl
perl pp_autolink.pl -o some.exe some_script.pl
```

It will also scan files passed as --link arguments

```perl
perl pp_autolink.pl -o some.exe --link /path/to/some.dylib some_script.pl
```


Note that currently only one script is supported, and it must be the last argument in the command.  

PRs are welcome.


### Acknowledgements ###

The initial logic was adapted from the pp_simple.pl script at https://www.perlmonks.org/?node_id=1148802
