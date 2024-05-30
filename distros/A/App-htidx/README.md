# SYNOPSIS

Run `htidx` on the command line:

    htidx DIRECTORY

Or in in your Perl scripts:

    use App::htidx;

    App::htidx::main($DIRECTORY);

# INTRODUCTION

`App::htidx` generates static HTML directory listings for a directory tree.
This is useful in scenarios where you are using a static hosting service (such
as GitHub Pages) which doesn't auto-index directories which don't contain an
`index.html`.

# DIRECTORY INDEX FILES

`App::htidx` will create an `index.html` file in each directory, unless one
or more files matching the pattern `index.*` exist.

If `index.html` exists and was previously created by `App::htidx` then it will
be overwritten, otherwise it will be left as-is.
