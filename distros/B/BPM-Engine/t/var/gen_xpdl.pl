#!/usr/bin/perl -w

use strict;
use warnings;

use File::Copy ();
use Template;
my $tt = Template->new(RELATIVE => 1);

# patterns
my $t = [
    {
      id    => '01-basic.xpdl',
      title => 'Basic Control Flow Patterns',
      items => [qw/1 2 4/],
    },
    {
      id    => '02-branching.xpdl',
      title => 'Advanced Branching and Synchronization Patterns',
      items => [qw/6 8 37 38 41/],
    },
    {
      id    => '03-mi.xpdl',
      title => 'Multiple Instance Patterns',
      items => [qw//],
    },
    {
      id    => '04-state.xpdl',
      title => 'State-based Patterns',
      items => [qw//],
    },
    {
      id    => '05-cancel.xpdl',
      title => 'Cancellation and Force Completion Patterns',
      items => [qw//],
    },
    {
      id    => '06-iteration.xpdl',
      title => 'Iteration Patterns',
      items => [qw/21a 21b 10a 10b/],
    },
    {
      id    => '07-termination.xpdl',
      title => 'Termination Patterns',
      items => [qw/11/],
    },
    {
      id    => '08-trigger.xpdl',
      title => 'Trigger Patterns',
      items => [qw//],
    },
    ];
    

foreach my $pack(@$t) {
    next unless @{$pack->{items}};
    $tt->process(
        './t/var/patterns/package.tt',
        { id => $pack->{id}, title => $pack->{title}, items => $pack->{items}, },
        './t/var/' . $pack->{id}
        ) || die $tt->error(), "\n";
  }

# samples
my @t = qw/
  06-multi-or-split-and-join
  07-multi-and-split-and-join
  09-unstructured-xor-routes
  11-unstructured-or-tasks
  14-inclusive-splits-and-joins
  15-mixed-join
  16-deadlock
  17-production
  18-production-unsynchronized
  /;
  
$tt->process(
    './t/var/samples/package.tt',
    { id => 'samples', title => 'Samples', items => \@t, },
    './t/var/08-samples.xpdl'
    ) || die $tt->error(), "\n";

# tasks
my @ts = qw/
  tasks
  assignments
  /;

$tt->process(
    './t/var/tasks/package.tt',
    { id => 'tasks', title => 'Task Samples', items => \@ts, },
    './t/var/10-tasks.xpdl'
    ) || die $tt->error(), "\n";

File::Copy::copy('./t/var/tasks/data.xpdl','./t/var/09-data.xpdl');

print "XPDL files generated in ./t/var\n";

1;
__END__

=pod

=head1 NAME

gen_xpdl - Generate XPDL files from templates

=head1 SYNOPSIS

gen_xpdl

Examples:

  perl bin/gen_xpdl

=head1 DESCRIPTION

Generate XPDL files into ./t/var from templates in ./t/var/samples and ./t/var/patterns

=head1 AUTHOR

Peter de Vos, C<< <sitetech at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Peter de Vos, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
