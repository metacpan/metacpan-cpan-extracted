=pod

=head1 NAME

App::Open::Using - Configuring and using App::Open and the `openit` commandline tool.

=head1 BASIC USAGE

Here's how `openit` likes to be used:

  $ openit myfile.tar.gz
  OR
  $ openit http://example.org

`openit`, on successful location of a program used to open your file, runs that
program against your file. In the .tar.gz case, it may be an archive viewer or
`tar tvzf` or if you're feeling lucky, `tar vxzf`. You control how it finds
that program by giving it a backend that supplies launch information to the
`openit` program.

You may notice some strong similarities to `openit` on Mac OS X/NeXTStep or (I am
told) `start` on Microsoft Windows. This application is modeled after the OS X
`openit` program.

=head1 WHAT THE HELL ARE BACKENDS FOR?

I miss `openit` from OS X. This, as stated before, is a homage to that, but
attempts to recognize the fact that modern UNIX systems have MIME and program
launching information in a million places, and that you may only care about one
or two of them.

So we accomplish this by providing various backends to be leveraged that can
access that data. There is a separate document, App::Open::Backend, which goes
into the backend interface should you wish to write or modify one.

=head1 Ok, this thing doesn't work/sucks/hasn't provided me with a config sample yet.

If you're looking to use multiple backends, look at B<MULTIPLE
BACKENDS> below. If you don't like reading or just want to get
started, in the contrib/ directory of the distribution there are a few
configurations that should work with most systems.

App::Open requires a configuration file ($HOME/.openrc) to define the backends
you want to use.  These backends may have further requirements, which should be
located in their individual documentation.

Because the author is unbelievably lazy, YAML is used for the configuration,
with a fixed data structure.

A basic, one-backend configuration looks something like this:

 ----
 backend:
    "BackendName":
        - "backend"
        - "specific"
        - "arguments"

For example, the MailCap backend:

 ----
 backend:
    "MailCap":

Or maybe you want to use a specific file (see App::Open::Backend::MailCap):

 ----
 backend:
    "MailCap":
        - "/etc/my_special_mailcap"

The structure is simple:

=over 4

=item Root

Keys are names of sections, values are section configuration. Currently only
"backend" is supported.

=over 4

=item "backend" Section

A hash, the key is the name of the backend (a full package name or just the
name with App::Open::Backend:: stripped), the value is an array (elements prefixed by `-`).

=over 4

=item backend arguments

Backend arguments will always be an array, and are specific to the backend.

=back

=back

=back

Backends are order-dependent and the first one to return a program that matches
your filename or URL will be executed.

You can use this scheme with multiple backends, but resolution order
cannot be guaranteed. The next section goes into setting up multiple
backends with a guaranteed resolution order.

=head1 MULTIPLE BACKENDS

An order-dependent configuration looks something like this:

    ---
    backend:
        - name: "YAML"
          args:
            - "t/resource/backends/yaml/def1.yaml"
        - name: "MailCap"

In this configuration, the "YAML" backend will be used first (using
the "def1.yaml" as the mapping), and if nothing is found, the
"MailCap" backend will be consulted.

The structure lays out like this:

=over 4

=item Root

Keys are names of sections, values are section configuration. Currently only
"backend" is supported.

=over 4

=item "backend" Section

An array (items prefixed with `-') that contains a hash with two key/value
pairs, listed below.

=over 4

=item name

The value for this key is the name of the backend, and has the same
naming rules as the backend name in single-backend configuration. This
is required.

=item args

Optional argument, an array of parameters to configure the backend.
Corresponds to the array value in single-backend configuration.

=back

=back

=back

=head1 How is my file's program located?

URLs are trivial: a program is found for your protocol scheme. It gets launched.

Filenames are less trivial but not complex. A filename's extensions are
extracted, and pieced into a list which are increasingly more diminuitive. This
is a non-issue for filenames which only have one extension (.gz), but is one
for filenames with more than one (.tar.gz).

What will happen in the latter case is that the filename's extensions will be
coerced into a search path as such: ".tar.gz, .gz". These extensions will be
searched in order for a matching program, f.e., if you have "gunzip" for the
.gz extension, and .tar.gz has nothing, "gunzip" will be called. If you have a
.tar.gz entry of "tar tvzf", it will be called instead of gunzip, regardless if
the defintion exists.

With all searches, the first program found is the one used. Leveraging multiple
backends may benefit you (mailcap makes no concessions for urls, f.e.), or
makes a seemingly innocent program a maintenance nightmare. Do what feels right.

=head1 How is my file executed?

The full command string is returned by the backend to the core application,
which then splits it into separate arguments for passing to the system() call.
This (in all cases I can think of) does not use a subshell and thus is fairly
immune to quoting issues. The exit status from the system call is what `openit`
uses to exit with, so your shell's $? equivalent should properly reflect the
status of your execution.

In most cases, the filename is simply the last argument to system(). However,
this is not always reasonable or desirable, so a special format definition,
'%s' is used.

Most backends do this for you, but some do not, and therefore it's important to
cover it here so I don't have to retype it.

Examples:

=over 4

=item tar xvzf

When launched, "tar xvzf filename" will be executed.

=item annoyingcmd -that -overuses %s -popt

When launched, "annoyingcmd -that -overuses filename -popt" will be executed.

=back

In almost all cases the first scenario will be easier on the eyes and exactly
what you need. In many cases you'll be using a backend that won't cause you to
worry about this.

B<WARNING>: No bundled backend nor App::Open make any attempt to do your shell
quoting for you. While this generally isn't an issue, it's important to be
aware of it.

=cut
