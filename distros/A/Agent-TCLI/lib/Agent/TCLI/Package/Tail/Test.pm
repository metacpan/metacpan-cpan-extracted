package Agent::TCLI::Package::Tail::Test;
#
# $Id: Test.pm 59 2007-04-30 11:24:24Z hacker $
#
=head1 NAME

Agent::TCLI::Package::Tail::Test - A class for an individual test on Lines.

=head1 SYNOPSIS

An internal object for storing Agent::TCLI::Test item information.
Used to facilitate Agent::TCLI::Test::Tail.

=cut

use warnings;
use strict;

use Object::InsideOut qw(Agent::TCLI::Base);

our $VERSION = '0.030.'.sprintf "%04d", (qw($Id: Test.pm 59 2007-04-30 11:24:24Z hacker $))[2];

=head2 ATTRIBUTES

The following attributes are accessible through standard accessor/mutator
methods unless otherwise noted

=over

=item code

The actual test subroutine to run.
B<sub> will only contain Code values.

=cut
my @code			:Field
					:Type('CODE')
					:All('code');

=item name

The name of the test, as output on the TAP line.
B<name> will only contain scalar values.

=cut
my @name			:Field
#					:Type('scalar')
					:All('name');

=item max_lines

The number of lines to observe before failing.
Defaults to the test_max_lines value in Tail.
B<max_lines> will only contain numeric values.

=cut
my @max_lines		:Field
					:Type('numeric')
					:All('max_lines');

=item match_times

The number of times the test should match before passing.
Defaults to the value of test_matchtimes in Tail.
B<match_times> will only contain numeric values.

=cut
my @match_times		:Field
					:Type('numeric')
					:All('match_times');

=item test_verbose

A flag to make the test output more information. This applies to the
test and not to the underlying code which has its own verbose setting.
B<test_verbose> will only contain numeric values.

=cut
my @test_verbose	:Field
					:Type('numeric')
					:All('test_verbose');

=item feedback

A value to indicate how frequently the test should report.
Zero is for only when complete. One will report on every match.

B<feedback> will only contain Numeric values.

=cut
my @feedback		:Field
					:Type('Numeric')
					:All('feedback');

=item birth_time

The activation time for the test. As a time() value.
B<birth_time> will only contain numeric values.

=cut
my @birth_time		:Field
					:Type('numeric')
					:All('birth_time');

=item handler

To handle event....

=cut
my @handler			:Field
#					:Type('type')
					:All('handler');

=item log_name

Name of the SimpleLog event that is being watched. 'none' for no log.
B<log_name> will only contain scalar values.

=cut
my @log_name		:Field
#					:Type('scalar')
					:All('log_name');

=item match_count

The counter for the number of times it has matched, or passed.
B<match_count> will only contain numeric values.

=cut
my @match_count		:Field
					:Type('numeric')
					:Arg('name'=>'match_count','default'=>0)
					:Acc('match_count');

=item line_count

A counter for the number of lines seen.
B<line_count> will only contain numeric values.

=cut
my @line_count		:Field
					:Type('numeric')
					:Arg('name'=>'line_count','default'=>0)
					:Acc('line_count');

=item last_line

The last line number processed.
B<last_line> will only contain numeric values.

=cut
my @last_line		:Field
					:Type('numeric')
					:Arg('name'=>'last_line','default'=>0)
					:Acc('last_line');

=item success

A boolean for whether the test passed or failed.
B<success> should only contain boolean values.

=cut
my @success			:Field
#					:Type('boolean')
					:All('success');

=item complete

A boolean that indicates whether the test has completed.
B<complete> should only contain boolean values.

=cut
my @complete		:Field
#					:Type('boolean')
					:Arg('name'=>'complete','default'=>0)
					:Acc('complete');

=item num

The relative position within the current test run of all tests.
B<num> will only contain numeric values.

=cut
my @num			:Field
					:Type('numeric')
					:All('num');

=item ttl

Line time to live. Set as an offset to time() upon creation, so this
is the actual time the test should expire.
B<ttl> will only contain numeric values.

=cut
my @ttl				:Field
					:Type('numeric')
					:All('ttl');

=item ordered

A flag indicating if the test is ordered.
B<ordered> should only contain boolean values.

=cut
my @ordered			:Field
#					:Type('boolean')
					:All('ordered');

=item request

The TCLI request object that set the test, for returning results.
B<request> will only contain Request objects.

=cut
my @request			:Field
#					:Type('Request')
					:All('request');

=back

=head2 METHODS

=over

=item new ( hash of attributes )

See attributes for their descriptions.

=cut

# Standard class utils are inherited

1;
#__END__

=back

=head2 INHERITED METHODS

This module is an Object::InsideOut object that inherits from Agent::TCLI::Base. It
inherits methods from both. Please refer to their documentation for more
details.

=head1 AUTHOR

Eric Hacker	 E<lt>hacker at cpan.orgE<gt>

=head1 BUGS

SHOULDS and MUSTS are currently not enforced.

Test scripts not thorough enough.

Probably many others.

=head1 LICENSE

Copyright (c) 2007, Alcatel Lucent, All rights resevred.

This package is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut
