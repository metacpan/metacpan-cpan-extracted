# NAME

Dancer2::Plugin::DoFile - A file based MVC style plugin for Dancer2

# SYNOPSYS

In your config.yml

    plugins:
      DoFile:
        page_loc: "dofiles/pages"
        default_file: "index"
        extension_list: ['.do','.view']

Make sure you have created the directory used for page\_loc

Within a route in dancer2:

    my $result = dofile 'path/to/file'

You must not include the extension of the file as part of the path, as this will
be added per the settings.

Or a default route, with example handling of some return values:

    prefix '/';
    any qr{.*} => sub {
      my $self = shift;
      my $result = dofile undef;
      if ($result && ref $result eq "HASH") {
        if (defined $result->{status}) {
          status $result->{status};
        }
        if (defined $result->{url}) {
          if (defined $result->{redirect} && $result->{redirect} eq "forward") {
            return forward $result->{url};
          } else {
            return redirect $result->{url};
          }
        } elsif (defined $result->{content}) {
          return $result->{content};
        }
      }
    };

When the 1st parameter to 'dofile' is undef it'll use the request URI to work
out what the file(s) to execute are.

# DESCRIPTION

DoFile is a way of automatically pulling multiple perl files to execute as a way
to simplify routing complexity in Dancer2 for very large applications. In
particular it was designed to offload "as many as possible" URIs that related to
some standard functionality through a default route, just by having files
existing for the specific URI.

The magic will look through your filesystem for files to 'do' (execute), and
there may be several. The intent is to split out controller files and
view files, and these may individually be rolled out or split out. In the
default configuration the controller files are suffixed .do, and the view files
.view

## File Search Ordering

When presented with the URI `path/to/file` DoFile will begin searching for
files that can be executed for this request, until it finds one that returns
something that looks like content, a URL or is told you're done, when it stops.

Files are searched:

- By extension

    The default extensions .do and .view are checked, unless defined in your
    config.yml. The intention here is that .do files contain controller code and
    don't typically return content, but may return redirects. After .do files have
    been executed, .view files are executed. These are expected to return content.

    You can define as many extensions as you like. You could, for example have:
    `['.init','.do','.view','.final']`

- Root/HTTP request method

    For each extension, first the "root" file `file.ext` is tested, then a file
    that matches `file-METHOD.ext` is tested (where METHOD is the HTTP request
    method for this request, .ext is the extension).

- Iterating up the directory tree

    If your call to `path/to/file` results in a miss for `path/to/file.do`, DoFile
    will then test for `path/to.do` and finally `path.do` before moving on to
    `path/to/file-METHOD.do`

    Once DoFile has found one it will not transcend the directory tree any further.
    Therefore defining `path/to/file.do` and `path/to.do` will not result in
    both being executed for the URI `path/to/file` - only the first will be
    executed.

If you define files like so:

    path.do
    path/
      to.view
      to/
        file-POST.do

A POST to the URI `path/to/file` will execute `path.do`, then
`path/to/file-POST.do` and finally `path/to.view`.

## Arguments to the executed files

When a file is executed there will be a hashref called $args that contains a
few important things:

- path (arrayref)

    Anything that appears after the currently executing file on the URI. For example
    if I request `/path/to/file` and DoFile is executing `path-POST.do`, the
    `path` element will contain \['to','file'\]

- this\_url (string)

    The currently executing file without any extension. In the above example this
    would be `path`.

- stash (hashref)

    The stash can be initially passed from the router:

        dofile 'path/to/file', stash => { option => 1 }

    The stash can be read/written to from each file that executes:

        if ($args->{stash}->{option} == 1) {
          $args->{stash}->{anotheroption} = 2;
        }

    Or if the file being executed returns a hashref that does not contain any of
    the elements `contents`, `url` or `done` (see below), it's merged into the
    stash automatically for passing on to the next file to be executed

    The stash is used to pass internal state down the file chain.

- dofile\_plugin (object)

    Just in case the file being executed wants to mess about with Dancer2 or
    the plugin's internals.

## How DoFile interprets individual executed files response

The result (returned value) of each file is checked; if something is returned
DoFile will inspect the value to determine what to do next.

### Internal Redirects

If a hashref is returned it's checked for a `url` element but NO `done`
element. In this case, the DoFile restarts from the begining using the new URL.
This is a method for internally redirecting. For example, returning:

    {
      url => "account/login"
    }

Will cause DoFile to start over with the new URI `account/login`, without
processing any more files from the old URI

### Content

If a scalar or arrayref is returned, it's wrapped into a hashref into the
`contents` element and sent back to the router.

If a hashref is returned and contains a `contents` element, no more files will
be processed. The entire hashref is returned to the router. NB: the
`contents` element must contain something that evals to true, else it's
considered not there.

### Done

If a hashref is returned and there is a `done` element that evals to a true
value, DoFile will stop processing files and return the returned hashref to
the router.

### Continue

If a hashref is returned and there is no `url`, `content` or `done` element
then the contents of the hasref is combined with the stash and DoFile will look
for the next file.

If nothing is returned at all, DoFile will continue with the next file.

## What the router gets back

DoFile will always return a hashref, even if the files being executed do not
return a hashref. This hashref may have anything, but the recommended design
is to return one of the following:

- A `contents` element

    The implication is that you've had the web page to be served back. Note that
    DoFile doesn't care if this is a scalar string or an arrayref. This Plugin
    was designed to work with Obj2HTML, so in the case of an arrayref the
    implication is that Obj2HTML should be asked to convert that to HTML.

- A `url` element

    In this case the router should probably send a 30x response redirecting the
    client, or perform an internal forward... implementors choice.

- A `status` element

    This could be used to set the status code for returning to the client

DoFile may however return pretty much whatever you want to handle in your final
router code.

# TO-DO

## Cached, compiled, ready to go files

An LRU evicted cache of compiled files to speed up commonly used pages.

## Discovery of js assets to load in

Testing for the presence of static and generated javascript files that are
automatically included in the response for the browser to load in.

# AUTHOR

Pero Moretti

# COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Pero Moretti.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
