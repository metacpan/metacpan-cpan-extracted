# NAME

Dancer2::Plugin::DoFile - A file based MVC style plugin for Dancer2

# SYNOPSYS

In your config.yml

    plugins:
      DoFile:
        controller_loc: 'dofiles/controllers'
        controller_extension_list: ['.ctl','.do']
        view_loc: 'dofiles/views'
        view_extension_list: ['.view','.po']
        default_file: "index"

Make sure you have created the directory used for the locations in your dancer application root.

Within a route in dancer2:

    my $result = controller 'path/to/file'

You must not include the extension of the file as part of the path, as this will
be added per the settings.

An example route in Dancer2, not using HTML::Obj2HTML (the controller returns the
layout and tokens directly):

    get 'dashboard' => sub {
      my $self = shift;
      my $result = controller 'dashboards/user-dashboard';
      return template $result->{layout} => $result->{tokens};
    }

An example default route that will search for controllers (or views) based on the
URI requested, and some handling of other controller return keys:

    prefix '/';
    any qr{.*} => sub {
      my $self = shift;

      my $result = controller undef;  # Not specifying the controller to use will use the URI to guess

      # My controller might return all manner of different things; this is an example:
      if ($result && ref $result eq "HASH") {
        if (defined $result->{url}) {
          if (defined $result->{redirect} && $result->{redirect} eq "forward") {
            return forward $result->{url};
          } else {
            return redirect $result->{url};
          }
        }
        if (defined $result->{status}) {
          status $result->{status};
        }
        if (defined $result->{template}) {
          set layout => $result->{template};
        }
        if (defined $result->{headers}) {
          headers %{$result->{headers}};
        }
        if (defined $result->{content}) {
          return template $result->{content}, $result->{tokens};
        }
      };
    };

When the 1st parameter to 'controller' is undef it'll use the request URI to work
out what the file(s) to execute are.

# DESCRIPTION

DoFile is a way of automatically pulling multiple perl files to execute as a way
to simplify routing complexity in Dancer2 for very large applications. In
particular it was designed to split out larger controllers into logical partitions
based on heirarchy of files compared to what's being requested.

The magic will look through your filesystem for files to 'do' (execute), and
there may be several.

An added benefit of using DoFile is it's ability to execute multiple files per
request, effectively allowing you to split controllers into sub-parts. For example,
you might have a "DoFile" that is always executed for /some/uri, and another
for POST or GET, and even another for the fact you hade /some too.

## File Search Ordering

When presented with the URI `path/to/file` DoFile will begin searching for
files that can be executed for this request, until it finds one that returns
something that looks like content, a URL or is told you're done, when it stops.

Files are searched:

- By extension

    The default extensions .ctl and .view are checked (.do and .po are legacy extensions),
    unless defined in your config.yml. The intention here is that .do files contain
    controller code and don't typically return content, but may return redirects. After
    .do files have been executed, .view files are executed. These are expected to return
    content.

    You can define as many extensions as you like. You could, for example have:
    `['.init','.do','.view','.final']`

- Root/HTTP request method

    For each extension, first the "root" file `file.ext` is tested, then a file
    that matches `file-METHOD.ext` is tested (where METHOD is the HTTP request
    method for this request, .ext is the extension). Finally `file-ANY.ext` is
    checked.

- Iterating up the directory tree

    If your call to `path/to/file` results in a miss for `path/to/file.ctl`, DoFile
    will then test for `path/to.ctl` and finally `path.ctl` before moving on to
    `path/to/file-METHOD.ctl`

    Once DoFile has found one it will not transcend the directory tree any further.
    Therefore defining `path/to/file.ctl` and `path/to.ctl` will not result in
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

During execution of the file a hashref called $args is available that contains
some important things.

If the executed file returns a coderef, the coderef is executed with this same
hashref as the only argument.

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

### Coderef (anonymous sub)

You can return a coderef; this will be cached within the plugin and the file
will not be checked again, but the coderef will be executed each time that
"file" is requested. Generally whether the file should be checked or not is
left up to the application (e.g. `plackup -R ./ -r ...`).

In the case a coderef is used, when the code is executed it is passed one
argument, a hashref, which is the stash. This saves needing to import the stash
from within the code of the file.

The return of the coderef will be evaluated exactly as below.

### Internal Redirects

If a hashref is returned it's checked for a `url` element but NO `done`
element. In this case, the DoFile restarts from the begining using the new URL.
This is a method for internally redirecting. For example, returning:

    {
      url => "account/login"
    }

Will cause DoFile to start over with the new URI `account/login`, without
processing any more files from the old URI. The stash is preserved.

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

# EXAMPLES

As noted, what's returned from a DoFile can contain anything. That gives you
the opportunity to do pretty much whatever you want with what's returned.

# AUTHOR

Pero Moretti

# COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Pero Moretti.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
