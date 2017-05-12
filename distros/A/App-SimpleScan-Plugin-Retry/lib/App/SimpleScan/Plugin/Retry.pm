package App::SimpleScan::Plugin::Retry;

our $VERSION = '1.02';

use warnings;
use strict;
use Carp;
use Scalar::Util qw(looks_like_number);

my ($retry);

sub import {
  no strict 'refs';
  *{caller() . '::retry'}     = \&retry;
}

sub retry {
  my($self, $value) = @_;
  $retry = $value if defined $value;
  $retry;
}

sub options {
  return ('retry=s'    => \$retry,
         );
}

sub validate_options {
  my($class, $app) = @_;
  if (defined (my $count = $app->retry)) {
      $app->pragma('retry')->($app, $count);
  }
}

sub pragmas {
  return (['retry'    => \&retry_pragma],
         );
}

sub retry_pragma {
  my ($self, $args) = @_;
  if (looks_like_number($args)) {
    $args = int $args;   
    $self->stack_code(qq(mech->retry("$args");\n));
  }
  else {
    $self->stack_test(qq(fail "retry count '$args' is not a number";\n));
  }
}

1; # Magic true value required at end of module
__END__

=head1 NAME

App::SimpleScan::Plugin::Retry - implement retry pragma/command line option

=head1 VERSION

This document describes App::SimpleScan::Plugin::Retry version 1.00

=head1 SYNOPSIS

    simple_scan --retry 6

    or in a simple_scan input file:
    %%retry 6

Both of these would retry fetches up to 6 times, pausing an increasingly-long
time between each try.  If all attempts fail, the failure reported with the last fetch
is reflected back to the test program; if at any point the fetch
succeeds, further retry attempts are abandoned.

=head1 DESCRIPTION

C<App::SimpleScan::Plugin::Retry> allows C<simple_scan> to use the
C<retry> function implemented by the C<WWW::Mechanize::Pluggable>
retry plugin.

This allows you to retry a transaction multiple times; it checks
C<$mech->success> to see if the transaction was successful. 

If you need more sophisticated retry testing, you're better off scripting
this yourself using C<WWW::Mechanize::Pluggable> and 
C<WWW::Mechanize::Plugin::Retry>. One way is to use the C<%%retry> pragma in input to 
C<simple_scan --gen> to generate skeleton code, and then replace
the call to C<retry> to C<retry_if> with the appropriate 
status check subroutine (see C<WWW::Mechanize::Pluggable::Retry>
for more details).

=head1 INTERFACE 

=head2 options

Options supported by this plugin: C<--retry>, with one argument, the retry count.

=head2 pragmas

Pragmas supported by this plugin: C<%%retry>, same arguments as --retry.

=head2 retry

Setter/getter for the current retry count. Used by both the pragma and
the command-line option to store the argument value.

=head2 retry_pragma
Implements the actual code: stacks a call to C<mech->retry> on the
outgoing code stream, or a call to C<fail> if the argument is not 
a number.

=head2 validate_options

Generates a virtual C<%%retry> pragma for the value given on the command line.

=head1 OPTIONS

=head2 --retry

Allows you to specify a global retry count for the input file to be
processed. If the input file contains C<%%retry> pragmas, the count
will be reset as these pragmas are encountered.

=head1 PRAGMAS

=head2 %%retry

Set the retry count immediately to the new count specified as the
argument.

    %%retry 3
    http://unsteady.org/ /.../ Y Look for expected text
    %%retry 0
    http://steady.org/   /.../ Y Same text

A retry count of zero means that the fetch will not be retried.

=head1 DIAGNOSTICS

=head2 C<< "retry count '$args' is not a number >>

Issued by the generated test code if Perl can't parse the retry
count (either from a pragma or the command line) as a valid number.


=head1 CONFIGURATION AND ENVIRONMENT

App::SimpleScan::Plugin::Retry requires no configuration files or environment variables.


=head1 DEPENDENCIES

App::SimpleScan, WWW::Mechanize::Pluggable::Retry.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

This only retries fetch failures; a more flexible means of testing 
"did it work?" is probably in order.

Please report any bugs or feature requests to
C<bug-app-simplescan-plugin-retry@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Joe McMahon  C<< <mcmahon@cpan.org > >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, 2006 Yahoo! and 
Joe McMahon C<< <mcmahon@cpan.org > >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
