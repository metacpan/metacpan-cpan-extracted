package App::metacpansearch;

=head1 NAME

App::metacpansearch - Simple command-line search of CPAN using the metacpan API

=head1 DESCRIPTION

This provides L< cpans >, a very simple command-line search tool.

=head1 SYNOPSIS

  # Say you had a rough idea of what you want

  $ cpans devel trace
  Devel::Trace::Cwd - Print out each line before it is executed and track cwd changes
  Devel::Trace::More - Like Devel::Trace but with more control
  Devel::Trace::Method - Follow the flow of your object's method calls 
  Devel::Trace - 
  Devel::Trace::Fork - Devel::Trace-like output for multi-process programs
  Carp::Trace - 
  Devel::RemoteTrace - Attachable call trace of perl scripts
  (a.k.a) perldebguts by example
  Devel::StackTrace::AsHTML - Displays stack trace in HTML
  Devel::StackTrace - An object representing a stack trace
  Devel::TraceINC - Trace who is loading which perl modules
  [Limit 10 reached, use -l to change limit]

  # And then you can use cpandoc to preview the POD

  $ cpandoc Devel::Trace::Fork

  # And then finally, install!

  $ cpanm Devel::Trace::Fork

=cut

1;
