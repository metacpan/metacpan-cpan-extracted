# Business-CAMT

Use this module to manage CAMT messages, which are ISO20022 standard
"Cash Management" messages as produced in banking.  For instance,
CAMT.053 is produced by banks and consumed by accountancies, showing
transactions in bank-accounts.  See https://www.iso20022.org.

At the moment, this module can be used to read the XML files.  It is
intended to also support constructing them.  However, I need a sponsor
to make that happen.  Contact the author for support.

## References

  * My extended documentation: <http://perl.overmeer.net/CPAN/>
  * Development via GitHub: <https://github.com/markov2/perl5-Business-CAMT>
  * Download from CPAN: <ftp://ftp.cpan.org/pub/CPAN/authors/id/M/MA/MARKOV/>
  * Indexed from CPAN: <https://metacpan.org/release/Business-CAMT>

## Installing

When you install this Perl module, you will get both the perl5 module (which
is the most efficient interface when you need to process many files) and the
'camt' program (script).

To install the 'camt' command and the library, simply type

   cpan -i Business::CAMT

Then, read how it works:

   man camt

## Development &rarr; Release

Important to know, is that I use an extension on POD to write the manuals.
The "raw" unprocessed version is visible on GitHub.  It will run without
problems, but does not contain manual-pages.

Releases to CPAN are different: "raw" documentation gets removed from
the code and translated into real POD and clean HTML.  This reformatting
is implemented with the OODoc distribution (A name I chose before OpenOffice
existed, sorry for the confusion)

## Contributing

When you want to contribute to this module, you do not need to provide
a perfect patch... actually: it is nearly impossible to create a patch
which I will merge without modification.  Usually, I need to adapt the
style of code and documentation to my own strict rules.

When you submit an extension, please contribute a set with

1. code

2. code documentation

3. A line in the ChangeLog file

**Please note:**
When you contribute in any way, you agree to transfer the copyrights to
Mark Overmeer (you will get the honors in the code and/or ChangeLog).
You also automatically agree that your contribution is released under
the same license as this project: licensed as perl itself.

## Copyright and License

This project is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
See <http://dev.perl.org/licenses/>
