package DashProfiler::UserGuide;
use strict;
our $VERSION = sprintf("1.%06d", q$Revision: 44 $ =~ /(\d+)/o);

=head1 NAME

DashProfiler::UserGuide - a user guide for the DashProfiler modules

=head1 INTRODUCTION

The DashProfiler modules provide an efficient, simple, flexible, and powerful
way to collect aggregate timing (performance) information for your code.

=head1 CONCEPTS

B<DashProfiler::Core>

The core of DashProfiler are DashProfiler::Core objects, naturally.

                         DashProfiler::Core

B<DashProfiler>

The L<DashProfiler> module provides a by-name interface to L<DashProfiler::Core> objects
to avoid needing to manage object references yourself. Most DashProfiler::Core
instance methods have corresponding DashProfiler static methods that take a profiler name
as the first argument.

                             DashProfiler
                                  |
                                  v
                         DashProfiler::Core

B<DBI::Profile>

Behind the scenes, DashProfiler::Core uses L<DBI::Profile> to efficiently aggregate timing samples.

                             DashProfiler
                                  |
                                  v
                         DashProfiler::Core  -->  DBI::Profile

DBI::Profile aggregates timing samples into a tree structure.

By default DashProfiler::Core arranges for the samples to be aggregated into a
tree with two levels. We refer to these as C<context1> and C<context2>.

You provide values for these that make the most sense for you and your
application.  For example, context1 might a type of network service and
context2 might be the specific host name being used to provide that service.

B<DashProfiler::Sample>

To add timing samples you need to use a Sampler. A Sampler is a code reference
that I<when called> creates a new L<DashProfiler::Sample> object and returns a
reference to it. Samplers are factories for creating samples. The Sampler code
reference is customized (curried) to contain the value for C<context1> to be
used for the created DashProfiler::Sample.

Samplers are created using the prepare() method of DashProfiler::Core or
DashProfiler (which is just a by-name wrapper for DashProfiler::Core).

                             DashProfiler
                                  |
                                  v
           .-----------  DashProfiler::Core  -->  DBI::Profile
           v                      ^
  sampler code ref -.             |
  sampler code ref ---> DashProfiler::Sample
  sampler code ref -'

Each time you call the Sampler code reference you pass it a value for C<context2> to
be used for I<this> sample and it returns a new DashProfiler::Sample object
containing the relevant information, including the exact time it was created.

When that DashProfiler::Sample object is destroyed, typically by going out of
scope, it adds a timing sample to all the DBI::Profile objects attached to the
Core it's associated with. The timing is from object creation to object destruction.

B<DashProfiler::Import>

The L<DashProfiler::Import> module lets you create and import customized
Sampler code references at load-time as if they were ordinary functions.

 DashProfiler::Import  <---  DashProfiler
         |                        |
         |                        |
         |                        v
         |               DashProfiler::Core  -->  DBI::Profile
         v                        ^
  sampler function -.             |
  sampler function ---> DashProfiler::Sample
  sampler function -'

B<DashProfiler::Auto>

The L<DashProfiler::Auto> module gives you a simple way to start using DashProfiler.
It creates a DashProfiler called 'auto' with a useful default configuration.
It also uses L<DashProfiler::Import> to import an auto_profiler() sampler function
pre-configured with the name of the source file it's imported into.

=head2 Where next?

Experimenting with L<DashProfiler::Auto> is a good place to start.

=cut
