package Benchmark::Forking;

$VERSION = 1.01;

use Benchmark;
require Exporter;

use strict;
use vars qw( $Enabled $RunLoop );

sub import   { enable(); Exporter::export_to_level('Benchmark', 1, @_) }
sub unimport { disable() }

sub enable   { $Enabled = 1 }
sub disable  { $Enabled = 0 }
sub enabled  { ( $#_ > 0 ) ? $Enabled = $_[1] : $Enabled }

# The runloop sub uses a special open() call that causes our process to fork, 
# with a filehandle acting as an IO channel from the child back to the parent. 
# The child runs the timing loop and prints the values from the Benchmark
# result object to its STDOUT, then it exits, terminating the child process.
# The output from the child appears in the main process' FORK handle, which 
# is read, re-blessed to form a proper Benchmark result object, and returned.

sub runloop {
  $Enabled or return &$RunLoop;
  
  if ( not open( FORK, '-|' ) ) {
    print join "\n", @{ &$RunLoop }; 
    exit;
  } else {
    my @td = <FORK>;
    close( FORK ) or die $!;
    return bless \@td, 'Benchmark';
  }
}

# The BEGIN block captures a reference to the normal Benchmark runloop sub to 
# be called by the wrapper, then installs our sub in the original's place.

BEGIN {
  $Enabled = 1; 
  $RunLoop = \&Benchmark::runloop;
  no strict 'refs';
  local $^W; # avoid sub redefined warning
  *{'Benchmark::runloop'} = \&runloop;
}

1;

__END__

########################################################################

=head1 NAME

Benchmark::Forking - Run benchmarks in separate processes


=head1 SYNOPSIS

  use Benchmark::Forking qw( timethis timethese cmpthese );

  timethis ($count, "code");

  timethese($count, {
      'Name1' => sub { ...code1... },
      'Name2' => sub { ...code2... },
  });
  
  cmpthese($count, {
      'Name1' => sub { ...code1... },
      'Name2' => sub { ...code2... },
  });

  Benchmark::Forking->enabled(0);  # Stop using forking feature
  ...
  Benchmark::Forking->enabled(1);  # Begin using forking again


=head1 DESCRIPTION

The Benchmark::Forking module changes the behavior of the standard
Benchmark module, running each piece of code to be timed in a
separate forked process. Because each child exits after running
its timing loop, the computations it performs can't propogate back
to affect subsequent test cases.

This can make benchmark comparisons more accurate, because the
separate test cases are mostly isolated from side-effects caused
by the others. Benchmark scripts typically don't depend on those
side-effects, so in most cases you can simply use or require this
module at the top of your existing code without having to change
anything else. (A few key exceptions are noted in L</BUGS>.)

=head2 Background

The standard Benchmark module can sometimes report inaccurate or
misleading results, in part because it doesn't isolate its test
cases from one another. This means that the order that cases are
run in can influence the results, because side effects, either
obvious or obscure, can accumulate and affect later tests.

Data in global variables is an obvious source of side effects; in
the below example, the grep takes longer as more items are pushed
onto the array, so the test functions that run later will be reported
by Benchmark as being slower, despite their code being identical:

  cmpthese( 1000, {
    "test_1" => sub { push @global, scalar grep 1, @global },
    "test_2" => sub { push @global, scalar grep 1, @global },
    "test_3" => sub { push @global, scalar grep 1, @global },
  } );

More cryptic sources of side effects can include cache priming,
idiosyncrasies of the underlying Perl implementation, or the state
of the operating system and environment. For example, if the code
to be benchmarked require a lot of in-process RAM, earlier tests
may be slowed down by having to allocate the memory the first time,
or later tests may be slowed down by having to pick through the
heap looking for free space.  These effects are difficult to predict
and can be laborious to identify and compensate for.

This module provides a solution to most aspects of this problem.
Once you use Benchmark::Forking, the example benchmark above will
report the correct conclusion that the three identical tests run
at approximately the same speed. 

=head2 Implementation 

Benchmark::Forking replaces the private runloop() function in the
Benchmark module with a wrapper that forks before calling the
original function. Forking is accomplished by the special
C<open(F,"-|")> call described in L<perlfunc/open>, and the results
are passed back as text from the child to the parent through an
interprocess filehandle.

When comparing several test cases with the C<timethese> or C<cmpthese>
functions, the main process will fork off a child and wait for it
to complete its timing of all of the repetitions of one piece of
code, then fork off a new child to handle the next case and wait
again.


=head1 INTERFACE

You can use this module in the same way you would use the standard 
Benchmark module.

=head2 Exports

This module re-exports the same functions provided by Benchmark: 
countit, timeit, timethis, timethese, and cmpthese.

For a description of these functions, see L<Benchmark>.

=head2 Methods

The benchmark forking functionality is automatically enabled once
you load this module, but you can also disable and re-enable it at
run-time using the following class methods.

=over 10

=item enabled

If called without arguments, reports the current status:

    my $boolean = Benchmark::Forking->enabled;

If passed an additional argument, enables or disable forking:

    Benchmark::Forking->enabled( 1 );
    $t = timeit(10, '$Global = 5 * $Global');
    Benchmark::Forking->enabled( 0 );

=item enable

Enables benchmark forking.

    Benchmark::Forking->enable();

=item disable

Disables benchmark forking.

    Benchmark::Forking->disable();

=back


=head1 BUGS

Because this depends on Perl's implementation of fork, it will not work
as expected on platforms which lack this feature, notably Microsoft Windows.

Some external resources may not work when opened in the parent process
and then accessed from multiple forked instances. If using this module
causes your file, network, or database code to fail with an unusual
error, this issue may be the culprit.

Some Benchmark scripts either accidentally or deliberately rely on the
side-effects that this module avoids. If using this module causes your
Perl code to behave differently than expected, you may be relying on
this behavior; you can either revise your code to remove the dependency
or continue to use the non-forking Benchmark.

If the standard Benchmark module were more fully object-oriented, this
functionality could be added via subclassing, rather than by fiddling
with Benchmark's internals, but the current implemenation doesn't seem
to allow for this.


=head1 SEE ALSO

For documentation of the timing functions, see L<Benchmark>.


=head1 VERSION

This is version 1.01 of Benchmark::Forking.

=head2 Changes

  2010-02-01: Released version 1.01 to CPAN.
  2010-02-01: Adjusted META.yml to include license. 
  
  2010-02-01: Released version 1.00 to CPAN.
  2010-02-01: Updated documentation, rebuilt meta.yml, merged in the ReadMe.pod.
  
  2004-09-05: Released version 0.99 to CPAN.
  2004-09-05: Expanded documentation and packaged for distribution. 
  
  2004-09-03: First version written.


=head1 INSTALLATION

This module should work with any version of Perl 5, without platform
dependencies or additional modules beyond the core distribution.

You should be able to install this module using the CPAN shell interface:

  perl -MCPAN -e 'install Benchmark::Forking'

Alternately, you may retrieve this package from CPAN (C<http://search.cpan.org/~evo/>) and follow the normal procedure
to unpack and install it, using the commands shown below or their
local equivalents on your system:

  tar xzf Benchmark-Forking-*.tar.gz
  cd Benchmark-Forking-*
  perl Makefile.PL
  make test && sudo make install


=head1 SUPPORT

Once installed, this module's documentation is available as a 
manual page via C<perldoc Benchmark::Forking> or on CPAN sites 
such as C<http://search.cpan.org/dist/Benchmark-Forking>.

If you have questions or feedback about this module, please feel free to
contact the author at the address shown below. Although there is no formal
support program, I do attempt to answer email promptly.  Bug reports that
contain a failing test case are greatly appreciated, and suggested patches
will be promptly considered for inclusion in future releases.

To report bugs via the CPAN web tracking system, go to
C<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Benchmark-Forking> or send
mail to C<Dist=Benchmark-Forking#rt.cpan.org>, replacing C<#> with C<@>.

If you've found this module useful or have feedback about your
experience with it, consider sharing your opinion with other Perl users
by posting your comment to CPAN's ratings system
(C<http://cpanratings.perl.org/rate/?distribution=Benchmark-Forking>).

For more general discussion, you may wish to post a message on PerlMonks
(C<http://perlmonks.org/?node=Seekers%20of%20Perl%20Wisdom>) or on the
comp.lang.perl.misc newsgroup
(C<http://groups.google.com/group/comp.lang.perl.misc/topics>).


=head1 AUTHOR

Developed by Matthew Simon Cavalletto.  You may contact the author 
directly at C<evo@cpan.org> or C<simonm@cavalletto.org>.

Inspired by a discussion with Jim Keenan in the Perl Monks community.

My thanks also to other members of the Perl Monks community for
feedback on this module, including graff, tachyon, Aristotle,
pbeckingham, and others. http://perlmonks.org/?node_id=388481


=head1 LICENSE 

Copyright 2010, 2004 Matthew Simon Cavalletto. 

You may use, modify, and distribute this software under the same terms as Perl.

See http://dev.perl.org/licenses/ for more information.

=cut
