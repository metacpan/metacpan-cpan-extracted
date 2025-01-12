# How to Contribute

Thank you for considering contributing to this distribution.  This file
contains instructions that will help you work with the source code.
 
PLEASE NOTE that if you have any questions or difficulties, you can reach the
maintainer through the bug queue described later in this document
(preferred), or by emailing the releaser directly. You are not required to
follow any of the steps in this document to submit a patch or bug report;
these are just recommendations, intended to help you (and help us help you
faster).
 
The distribution is managed with Dist::Zilla (https://metacpan.org/release/Dist-Zilla).
This means than many of the usual files you might expect are not in the
repository, but are generated at release time (e.g. Makefile.PL).
 
However, you can run tests directly using the 'prove' tool:
 
  $ prove -l
  $ prove -lv t/some_test_file.t
  $ prove -lvr t/
 
In most cases, 'prove' is entirely sufficent for you to test any
patches you have.

_the above text gratuitously stolen from https://metacpan.org/contributing-to/Dist-Zilla-Plugin-Test-Perl-Critic-Freenode ._

_here's some more stolen text_

* I prefer to get pull requests rather than patches. Please do pull requests on branches.
* Please add an entry for each change in Changes as well.
* If it's a significant change, please email me first, so we can discuss it, and I can tag it as being worked on.

## Contact the author

* raise an issue on github - it emails me
* email me with the address at https://metacpan.org/pod/Astro::Constants#AUTHOR

I am old school enough to accept patches as well as Pull Requests
and will happily discuss any ideas you might have.

Thanks for reading this far.
Boyd
