# d-oh

```
use D'oh;
```

This is D'oh 1.00, a simple debug module that redirects STDERR and STDOUT to files.

You can also drop a timestamp into the redirect file, and import a function that dumps (as JSON) arbitrarty data structures to STDERR.  The name of the function is whatever you want (as long as it isn't `stderr`, `stdout`, `date`, `import`, or `AUTOLOAD`).

See the docs for more info.

The last version, 0.05, came out 20 years ago.  It's time to release 1.00.  Version 1.00 outputs the timestamp in a very different format, and adds the name-your-own-debug-function stuff, but otherwise the module functionality fundamentally the same.
