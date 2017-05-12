Contributing to Apache Clownfish
================================

Make a plan
-----------

Clownfish is developed by the [Apache Lucy](http://lucy.apache.org) community.

If you propose to make non-trivial changes to Clownfish, especially changes
to the public API, send a note to the [Lucy developer's
list](http://lucy.apache.org/mailing_lists) describing your plans.

Get the code
------------

Clownfish's codebase is available via Git from git-wip-us.apache.org.  Start
by creating a clone of the repository:

    git clone https://git-wip-us.apache.org/repos/asf/lucy-clownfish.git

There is also a [mirror on Github](https://github.com/apache/lucy-clownfish).

Follow the instructions in INSTALL to set up your local workspace.

Make changes
------------

Edit the source code as you see fit, then build and run tests.

Clownfish supports continuous integration services Travis and Appveyor
to run tests under multiple host languages, host language versions, and
platforms. If you fork the Github repository, you can make these services
automatically test the changes you made in your fork.

Please bear the following in mind:

* All code will eventually need to be portable to multiple operating
  systems and compilers. (This is a complex requirement and it should not
  block your contribution.)
* All public APIs must be documented.
* Code should be formatted according to the style guidelines at
  <http://wiki.apache.org/lucy/LucyStyleGuide>.
* All unit tests must pass.
* New code needs to be accompanied by new unit tests.
* Simplicity, both in terms of API and implementation, is highly valued
  within the Lucy development community; the simpler the contribution, the
  more quickly it can be reviewed and integrated.

Github pull requests
--------------------

Github users may submit pull requests against our
[mirror](https://github.com/apache/lucy-clownfish).  An email notifying the
Lucy developers list of your pull request will be triggered automatically.

Ideally, open a JIRA issue and reference it by its `CLOWNFISH-NNN` identifier
in your pull request -- but this is not required.

Open an issue
-------------

The [Clownfish issue-tracker](https://issues.apache.org/jira/browse/CLOWNFISH)
runs Atlassian JIRA and we generally use the term "issue" rather than "bug"
because not every contribution fixes a "bug":

1. Create a JIRA account for yourself and sign in.
2. Once you have signed in, the "create new issue" link will appear.  Either
   use it to open a new issue or navigate to an existing one as appropriate.

Attach a patch to an issue
--------------------------

If you are not a Github user, you may propose changes by submitting patches
via JIRA.  The easiest way to create a patch with Git is to capture the output
of `git diff`:

    git diff > my_changes.patch

The resulting patch file can then be attached to a JIRA issue.  Make sure that
you are logged in as a JIRA user, then select the menu command 'More Actions >
Attach Files'.

Attaching a file to an issue causes an email notification to be sent to the
lucy-issues list signalling that a patch has arrived.  Please be patient but
persistent while engaging with the Lucy committers who review and apply such
patches.

