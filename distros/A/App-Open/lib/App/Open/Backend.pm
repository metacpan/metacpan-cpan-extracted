=pod

=head1 AUTHORING A BACKEND

Backends have a trivial API and can communicate upwards to the App::Open core
through a series of exceptions and call returns.

The rest of this document will describe the required API and exceptions you can
throw that App::Open will recognize.

=head1 REQUIRED API

=head2 Methods

=over 4

=item new($args)

`$args` can be an array ref or undef as passed to the constructor. It will
return a blessed object that has the methods listed below in the
namespace the object is bound to.

It is ok to require arguments, but the ideal case is to require as
little configuration as possible, leaving the user to expect
reasonable defaults without arguments.

=item lookup_file($extension)

Looks up the command string for `$extension`. 

The string returned should be usable in the shell as a full command,
with one potential exception, explained below. The command will then
be processed by the App::Open system and executed if possible.

`%s' in a command string allows the App::Open system to substitute the
filename in place of this format variable... f.e.:

"firefox %s -newtab"

%s will correspond to the filename/url that was the source for this
lookup after App::Open gets its hands back on it.

In the case that %s is omitted, the filename/url is appended to the
end of the command string.

App::Open actually splits up the command string for usage via
multiple-argument system() and as such shell quoting issues are rarely
an issue, but either you or the user are responsible for these issues,
App::Open will make no attempt to fix or add quoting.

=item lookup_url($scheme)

`$scheme` is a url protocol scheme, e.g., "https" or "ftp". Other than
this detail, it is expected to use the exact same semantics as
lookup_file().

=back

=head2 Exceptions

For this document, exceptions are triggered by calling die() with a
specific argument string. Some exceptions take optional arguments, which are
delimited by spaces in the die string.

Example:

    die "INVALID_CONFIGURATION"; # exception for invalid configuration
    die "ANOTHER_EXCEPTION that has four arguments"; # an exception with arguments

While there's nothing stopping you from processing exceptions this way
in your own backends, these exceptions are mainly for the benefit of
the App::Open core. The core uses these exceptions to provide useful
output to the user when there's an error running the `openit` command.

Anyways, on to the list of recognized exceptions.

=over 4

=item MISSING_ARGUMENT

=item INVALID_ARGUMENT

=item FILE_NOT_FOUND

=item INVALID_CONFIGURATION

I hope these are self-explanatory.

=item NO_PROGRAM

This is generally thrown by App::Open itself, when no matches for a
given extension/scheme are found. However, if your backend depends on
a program to perform lookups and can't find it, it would be
appropriate to throw this.

=item NO_BACKEND_FOUND backend_name

Used by App::Open::Config when initializing backends, and one cannot
be loaded. It's unlikely you will ever need this.

=item BACKEND_CONFIG_ERROR

This is what you will most often use; if you require arguments or
merely get garbage arguments, this is what you throw, and the `openit`
program will direct the user to your backend documentation. Obviously,
this can be used in less obvious cases.

=back

=head1 EXAMPLES

Please look at App::Open::Backend::Dummy for a very basic rundown of
the API. This is what's used to test the backend interface
functionality, and as such will remain updated along with this
document concerning any changes to the API.

If you'd like something with more meat, App:;Open::Backend::YAML is
fully functional and relatively simple to understand.

=head1 CONTRIBUTING BACKENDS

It is the author's desire that backends released be packaged
separately from App::Open and available via CPAN.

However, he will gladly consider backends for inclusion in this
package that:

=over 4

=item Do not add dependencies

=item Do not make assumptions about the operating system or installed tools

=item Are fully tested and documented

=back

In other words, you're better off just releasing it yourself.

=cut
