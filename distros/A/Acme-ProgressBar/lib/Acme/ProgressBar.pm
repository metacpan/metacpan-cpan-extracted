use strict;
use warnings;
package Acme::ProgressBar;
# ABSTRACT: a simple progress bar for the patient
$Acme::ProgressBar::VERSION = '1.128';
use Time::HiRes ();

#pod =head1 SYNOPSIS
#pod
#pod  use Acme::ProgressBar;
#pod  progress { do_something_slow };
#pod
#pod =cut

use base qw(Exporter);
our @EXPORT = qw(progress); ## no critic Export

#pod =head1 DESCRIPTION
#pod
#pod Acme::ProgressBar provides a simple solution designed to provide accurate
#pod countdowns.  No progress bar object needs to be created, and all the
#pod calculation of progress through total time required is handled by the module
#pod itself.
#pod
#pod =func progress
#pod
#pod  progress { unlink $_ for <*> };
#pod  progress { while (<>) { $ua->get($_) } };
#pod  progress { sleep 5; }
#pod
#pod There is only one function exported by default, C<progress>.  This function
#pod takes a coderef as its lone argument.  It will execute this code and display a
#pod simple progress bar indicating the time required for ten iterations through the
#pod code.
#pod
#pod =cut

sub progress(&) { ## no critic Prototype
  my ($code) = @_;
  local $| = 1; ## no critic
  _overprint(_message(0,10,undef));

  my $begun = Time::HiRes::time;
  $code->();
  my $total = Time::HiRes::time - $begun;

  for (1 .. 9) {
    _overprint(_message($_,10,$total));
    Time::HiRes::sleep($total);
  }

  _overprint(_message(10,10,$total));
  print "\n";
}

sub _message {
  my ($iteration, $total, $time) = @_;
  my $message = 'Progress: ['
              .  q{=} x $iteration
              .  q{ } x ($total - $iteration)
              .  '] ';

  if (defined $time) {
    $message .= sprintf '%0.0fs remaining%25s',
      (($total - $iteration) * $time), q{ };
  } else {
    $message .= '(calculating time remaining)';
  }
}

sub _overprint {
  my ($message) = @_;
  print $message, "\r";
}

#pod =head1 TODO
#pod
#pod =for :list
#pod * allow other divisions of time (other than ten)
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Term::ProgressBar>, L<Term::ProgressBar::Simple>,
#pod L<Progress::Any::Output::TermProgressBarColor>, L<Smart::Comments>
#pod
#pod =cut

"48102931829 minutes remaining";

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::ProgressBar - a simple progress bar for the patient

=head1 VERSION

version 1.128

=head1 SYNOPSIS

 use Acme::ProgressBar;
 progress { do_something_slow };

=head1 DESCRIPTION

Acme::ProgressBar provides a simple solution designed to provide accurate
countdowns.  No progress bar object needs to be created, and all the
calculation of progress through total time required is handled by the module
itself.

=head1 FUNCTIONS

=head2 progress

 progress { unlink $_ for <*> };
 progress { while (<>) { $ua->get($_) } };
 progress { sleep 5; }

There is only one function exported by default, C<progress>.  This function
takes a coderef as its lone argument.  It will execute this code and display a
simple progress bar indicating the time required for ten iterations through the
code.

=head1 TODO

=over 4

=item *

allow other divisions of time (other than ten)

=back

=head1 SEE ALSO

L<Term::ProgressBar>, L<Term::ProgressBar::Simple>,
L<Progress::Any::Output::TermProgressBarColor>, L<Smart::Comments>

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Ricardo SIGNES Sean Zellmer

=over 4

=item *

Ricardo SIGNES <rjbs@codesimply.com>

=item *

Sean Zellmer <sean@lejeunerenard.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
