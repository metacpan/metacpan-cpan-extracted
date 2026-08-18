Contributing to Clownfish
================================

Make a plan
-----------

Clownfish is developed by the [Lucy](https://github.com/lucysearch) community.

If you propose to make non-trivial changes to Clownfish, especially changes
to the public API, open an issue describing your plans.

https://github.com/lucysearch/lucy-clownfish/issues

Get the code
------------

Clownfish's codebase is available via Git from https://github.com/lucysearch/lucy-clownfish.git.  Start
by creating a clone of the repository:

    git clone https://github.com/lucysearch/lucy-clownfish.git

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
* All unit tests must pass.
* New code needs to be accompanied by new unit tests.
* Simplicity, both in terms of API and implementation, is highly valued
  within the Lucy development community; the simpler the contribution, the
  more quickly it can be reviewed and integrated.

Github pull requests
--------------------

Github users may submit pull requests against https://github.com/lucysearch/lucy-clownfish
An email notifying the Lucy developers list of your pull request will be triggered automatically.

Open an issue
-------------

The [Clownfish issue-tracker](https://github.com/lucysearch/lucy-clownfish/issues) is publically available.
we generally use the term "issue" rather than "bug" because not every contribution fixes a "bug":

