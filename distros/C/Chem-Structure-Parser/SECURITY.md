# Security policy

## Reporting a vulnerability

Please report security issues privately, by email to dec986@gmail.com,
rather than by opening an issue on the GitHub tracker, which is public.

It helps if you can include the version of Chem::Structure::Parser and of perl,
the platform, and the file that provokes it — this is a parser, so the input is
usually the whole reproducer. If the file cannot be shared, the record that goes
wrong, or enough of a description to reconstruct one, is nearly as good.
`perl -V:nvtype -V:useithreads` is worth pasting too: the XS is compiled
differently on a long-double or `__float128` perl, and a bug that needs one of
those is otherwise hard to place.

Chem::Structure::Parser is maintained by one person, unpaid, so there is no
guaranteed response time and no bounty. Reports are nevertheless taken
seriously, and you will be credited in `Changes` for anything that leads to a
fix unless you would rather not be.

If a report goes unanswered for a week, or if the issue is being exploited and
cannot wait that long, copy it to the CPAN Security Group at
<cpan-security@security.metacpan.org>, who can triage it and reach me by other
means. They are also the right people to write to first if you would rather not
deal with an individual maintainer, or if you want help deciding whether what
you have found is a vulnerability at all. Please do not disclose it publicly —
here, on the GitHub tracker, or anywhere else — before a fix is released or
CPANSec says otherwise.

## Which versions are supported

Only the most recent release on CPAN. Fixes are shipped as a new release
rather than as a patch to an older one.

Every perl the module installs on is supported: it declares 5.10 as its
minimum and is built and tested on 5.10.1, 5.12.5, 5.42.3 and 5.44.0, on the
`double`, `long double` and `__float128` NV widths and threaded as well as
unthreaded. A report that needs a perl older than 5.10 is a report about a
configuration the distribution declines to install on; a report that needs one
of the above is in scope, and saying which one it is saves most of the work of
reproducing it.

## Scope

The module reads a file and builds perl data structures out of it. It never
runs a command, never writes to the filesystem, and never opens a network
connection, so a report that it does any of those is in scope by itself.

Most of it is C, and it is meant to be pointed at files fetched from a public
archive, so what a hostile or merely broken file can make that C do is the
centre of the policy. In scope:

- any input that makes `Parser.xs` read or write outside its buffer, corrupt
  the interpreter, or crash it: a truncated record, a line that stops in the
  middle of a column, an mmCIF loop header that does not describe the rows
  under it, a count that disagrees with the file, a residue or chain identifier
  that is not what the format allows, a number that is not one.
- reference-count and ownership errors reachable from an ordinary call. A leak
  of a few hundred SVs per file is invisible on one structure and fatal on a
  directory of twenty thousand, which is what `t/leaks.t` is for.
- anything the module does with the file it was given that the documentation
  does not describe.

What is the caller's responsibility, and welcome as documentation bugs rather
than as vulnerabilities:

- **Size.** The file is read into memory whole, which is what makes the single
  pass possible and is documented. A caller that hands it an untrusted file of
  unbounded size has a denial of service in the *calling* program. A `.gz` is
  worse: `IO::Uncompress::Gunzip` expands it into memory and nothing here
  bounds what it expands to, so check the size, and the expanded size, before
  parsing anything you did not fetch yourself.
- **The path.** The file name is used as given. A caller that builds one out of
  untrusted data — a field from a downloaded file, a parameter from a web
  request — has a path traversal in the *calling* program, and this module will
  faithfully open whatever comes out of it.

The test suite is the one part that runs anything, and only to compare against
other people's readers: `t/oracle.t` runs a python — the one named in
`STRUCTURE_INFO_PYTHON`, or `python3` — to ask whether gemmi is importable, and
`t/features.t` runs the one that variable names if it is set. Neither is
reachable from `lib/` or `Parser.xs`, with the variable or without it.
