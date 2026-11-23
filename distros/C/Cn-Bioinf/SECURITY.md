# Security policy

## Reporting a vulnerability

Please report security issues privately, by email to dcondon@uidaho.edu,
rather than by opening an issue on the GitHub tracker, which is public.

It helps if you can include the version of Cn::Bioinf and of
Alien::Bioinf, the output of `perl -V` (or at least `ivsize`, `useithreads`
and `cc` — the FASTA reader is C, and a memory bug there is often specific to
a platform or a compiler), and a short script that shows the problem together
with any input file it needs.

Cn::Bioinf is maintained by one person, unpaid, so there is no guaranteed
response time and no bounty. Reports are nevertheless taken seriously, and
you will be credited in `Changes` for anything that leads to a fix unless you
would rather not be.

## Which versions are supported

Only the most recent release on CPAN. Fixes are shipped as a new release
rather than as a patch to an older one.

## Scope

`fasta2hash()` and `hash2fasta_file()` are XS. The reader walks a buffer it
allocates itself, in blocks, over a file that may well have come from
somewhere untrusted — a proteome download, a collaborator's alignment. So
anything in that path is in scope: an out-of-bounds read or write, a
use-after-free, an integer overflow in a size or line count, or an outright
crash, reached from a FASTA file (plain, or gzip-compressed and read through
`gzip -dc`) or from the hash handed to `hash2fasta_file()`. Dying with a
`croak` on malformed input is the designed behaviour and is not a
vulnerability; corrupting memory instead of croaking is.

The other functions run programs: Clustal Omega, `blastp`, and Python for the
plots, all of them the copies Alien::Bioinf installed, never whatever is first
on `PATH`. Every one is started with the list form of `system` or `open`, so no
shell ever sees a file name or a sequence name. Sequence names, labels and
titles reach Python as JSON or as command-line arguments; none is ever pasted
into Python source.
A name that makes any of these programs run something it was not asked to, or
that escapes into code, is in scope. If the fault turns out to be in
Alien::Bioinf, the report is still welcome here: it has the same maintainer.

Out of scope:

- **Paths the caller supplies.** Every function reads and writes exactly the
  files it is given, and `msa_quality_table()` writes its BLAST report to
  `alignment_json` when that file does not exist yet. A program that builds a
  path out of untrusted data, or writes into a directory other users can
  write to, has the problem in the *calling* program.
- **The LaTeX that `view_alignment()` writes.** It is meant to be
  `\input` into the caller's own document. Every character LaTeX treats specially in a
  sequence name or a residue (backslashes and braces included, since
  2026-11-02) is escaped so that it prints as itself. Even so, do not compile
  the output of untrusted names with `-shell-escape`, any more than you would
  any other untrusted `.tex`.
- **matplotlib mathtext in labels.** `$\it{...}$` in a label is rendered as
  mathtext; that is the documented way to italicise a species name.
- **Resource use proportional to the input.** Aligning or reading a large
  file because the caller asked for it is not a denial of service. Memory
  that grows without bound on input that is *small* is, and is in scope.
