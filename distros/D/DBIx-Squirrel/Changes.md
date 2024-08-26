## Revision history for DBIx-Squirrel

### 1.3.5 2024-08-26 07:40
-   Fixed a problem recently introduced into how transformation pipelines and
    arguments are partitioned.
-   Fixed the iterator execute method. It used the bleat about missing bind-
    values, but that doesn't make sense during construction when there might
    legitimately be none. Now calling execute with none of the expected 
    bind-values just effectively resets the iterator. 
-   Fixed the results code that was breaking due to a missing `no strict qw/refs/`.

### 1.3.4 2024-08-25 18:30
-   Some refactoring to improve robustness.

### 1.3.3 2024-08-25 18:15
-   Typos fixed and additions made to POD.
-   Tests no longer jump through hoops to open the SQLite test database in read-only mode. I only tried that
    to see if it would have a positive effect on tests segfaulting. I have since simplified testing a great
    deal since the rewrites, so pushing out this release to see if it mops-up a couple of red boxes on
    CPANTs.

### 1.3.2 2024-08-25 16:45
-   Fixed typos.
-   General improvements and optimisations.
-   Strawberry Perl 5.10.1.1 on MSWin32-x86-multi-thread can't seem to import DBD::SQLite::Constants ':file_open'
    because is isn't exported. Hopefully, a conditionally workaround solves the issue.
-   Strawberry Perl 5.14.4.1 on MSWin32-x86-multi-thread gives /Can't locate object method "e" via package "warnings"/
    error. Added "use diagnostics" pragma to all test code in an attempt to coax more useful information out.
-   Fixed broken iterator "buffer_size" code - manually set sizes weren't persistent.

### 1.3.1 2024-08-24 14:10
-   General code improvements.
-   Removed unnecessary imports.
-   Removed call to no longer extant iterator method from &DBIx::Squirrel::it::DESTROY.
-   Added the "count_all" method back into the iterator class, as well as ensuring that "count"
    does not affect a future call to "next".
-   Addressed build failures revealed by the CPAN Testers Matrix:
    -   Rewrote &DBIx::Squirrel::util::part_args - failed on Perl versions <= 5.18.4;
    -   Back to using "strict" and "warnings" - Modern::Perl having some issues with a bundle "all"
        in Perl versions <= 5.14.4.
    -   Perls versions <= 5.13 do not support ${^GLOBAL_PHASE}, so used Devel::GlobalDestruction
        to work around the issue.
    -   Testing under Perls <= 5.13 seems to require "done_testing()" for each sub-test, as well
        as at the end of the test script.
    -   Testing under Perls <= 5.11 does not support sub-test. I can live without them, so
        have refactored the tests not to use them. Tests pass under Perl 5.10!
-   The seemingly bottomless pit of joy that is documentation updates. I'm pushing this out,
    knowing that there are gaps in the POD that must be filled. I want to get the remaining
    red issues on the CPANTS matrix to go green, hence the expedited release. POD gaps will
    be filled in future point releases.

### 1.3.0 2024-08-23 21:00
-   Ground-up rewrite of iterators and result-set code.
-   Ground-up rewrite and simplification of test code.
-   More documentation added. This stuff is never finished, and I'll be adding more in future!
-   A lot of refactoring and tidying up completed.

### 1.2.11 2024-08-18 13:15
-   Fixed typos.
-   Did some internal refactoring.
-   Updated t/lib/T/Constants.pm to ensure that SQLite database connections are created with
    both `sqlite_see_if_its_a_number => !!1` and `sqlite_open_flags => SQLITE_OPEN_READONLY`
    flags and re-ran tests successfully on macOS under Perl 5.28.1. Action was prompted by
    CPAN Tester report confirming Wstat 139 SEGFAULT on BSD under Perl 5.28.1; I have no way
    to replicate this build environment exactly, so I'm hoping this fixes the issue. We shall
    see. Thanks to Chris Williams (BINGOS) for the original report.

### 1.2.10 2024-08-17 17:35
-   Fixed minor typos in POD.
-   Did some internal refactoring.
-   Updated dist.ini: no longer using Dist::Zilla Readme plugin to produce README.
-   Updated st.pm: bind_param method no longer drops the third argument (bind attributes) before
    handing-off to &DBI::st::bind_value.
-   No longer quoting hash keys matching /^\w+$/.

### 1.2.9 2024-08-17 22:50
-   Reorganised the examples folder and renamed an example script.
-   Added some canned transforms.
-   Added new example script (examples/transformations/02.pl).
-   Added DBD::SQLite to test dependencies, with thanks to Slaven Rezić (SREZIC) for the alert.

### 1.2.8 2024-08-16 18:45
-   Fixed some documentation issues.
-   Removed a redundant line from sample script (examples/transformations_1.pl).

### 1.2.7 2024-08-16 18:00
-   First version, released on an unsuspecting world.

