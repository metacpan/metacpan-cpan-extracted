#!/usr/bin/perl -w

#
# Kirrily "Skud" Robert <skud@cpan.org>
# $Id$

use strict;

package CPAN::Test::Reporter;

use Getopt::Long;
use Mail::Send;
use Config;
use Carp;
use CPAN;

use vars '$VERSION';
$VERSION = '0.02';

=pod

=head1 NAME

CPAN::Test::Reporter - Report test results of a package retrieved from CPAN

=head1 SYNOPSIS

    my $report = CPAN::Test::Reporter->new;
    $report->which_perl(path to the perl binary we tested with);
    $report->grade(pass|fail|na|unknown);
    $report->package(module name);
    $report->test_results(our build and/or make test results);
    $report->comments(other commentary on the module);
    $report->send(to whom);

=head1 DESCRIPTION

CPAN::Test::Reporter uniformly posts package test results in support of the
cpan-testers project.  See B<http://testers.cpan.org/>
for details.

NOTE TO TESTERS: this module will currently send its output email to
cpan-workers@perl.org, which might not be what you want.  You can set
$CPAN::Test::Reporters::CPAN_TESTERS to another email address if you
prefer.

=cut

my $CPAN_TESTERS = 'cpan-workers@perl.org';
use vars '%Config';

=head2 new()

Creates a new reporter object.

=for testing
BEGIN: use_ok('CPAN::Test::Reporter', "use CPAN::Test::Reporter");
my $r = new CPAN::Test::Reporter;
ok($r->isa('CPAN::Test::Reporter'), "Got a CPAN::Test::Reporter object");

=cut

sub new  {
    my $self = {};

    $self->{comments} = "[ None ]";
    bless $self;
    return $self;
}


=head2 grade($grade)

grade($grade) indicates the success or failure of the package's builtin
tests, and is one of:

    grade     meaning
    -----     -------
    pass      all tests included with the package passed
    fail      some tests failed
    na        the package does not work on this platform
    unknown   the package did not include tests

=for testing
my $r = new CPAN::Test::Reporter;
$r->grade('pass');
is($r->{grade}, 'pass', "Set the grade");

=cut

sub grade {
    my ($self, $grade) = @_;
    my %grades = (     # Legal grades:
        'pass'      => "all tests pass",
        'fail'      => "some tests fail",
        'na'        => "package will not work on this platform",
        'unknown'   => "package did not include tests",
    );

    Carp::carp "grade argument is required" unless $grade;
    Carp::carp "grade '$grade' is invalid" unless $grades{$grade};

    $self->{grade} = $grade;
}

=head2 which_perl($path)

Specifies the version of perl you just used to test the module.

my $r = new CPAN::Test::Reporter;
$r->which_perl('5.6.1');
is($r->{which_perl}, '5.6.1', "Set the perl version");

=cut

sub which_perl {
    my ($self, $version) = @_;
    $self->{which_perl} = $version;
}

=head2 package($module)

Sets the name of the package you're working on, for example Foo-Bar-0.01
There are no restrictions on what you put here -- it was found that even 
requiring it to end in a dash and a version number was too restrictive 
for use in the wild.

=for testing
my $r = new CPAN::Test::Reporter;
$r->package("Foo-Bar-0.01");
is($r->{package}, "Foo-Bar-0.01", "Set the package");

=cut

sub package {
    my ($self, $package) = @_;
    $self->{package} = $package;
}

=head2 test_results($results)

Sets the results for the test.  $results is in the form of a string, 
presumably as provided by CPAN::Smoke.

=for testing
my $r = new CPAN::Test::Reporter;
$r->test_results("here are my test results");
is($r->{test_results}, "here are my test results", "Set the test results");

=cut

sub test_results {
    my ($self, $test_results) = @_;
    $self->{test_results} = $test_results;
}

=head2 comments($comments)

Sets your comments on the test.

=for testing
my $r = new CPAN::Test::Reporter;
$r->comments("here are my comments");
is($r->{comments}, "here are my comments", "Set the comments");

=cut

sub comments {
    my ($self, $comments) = @_;
    $self->{comments} = $comments;
}

=head2 send(@recipients)

Sends the email to cpan-testers and Cc's the mail to the recipients 
listed.  Uses full email addresses.

=cut

sub send {
    my ($self, @recipients) = @_;

    my $report = qq(
This distribution has been tested as part of the cpan-testers
effort to test as many new uploads to CPAN as possible.  See
http://testers.cpan.org/

Please cc any replies to cpan-testers\@perl.org to keep other
test volunteers informed and to prevent any duplicate effort.

Comments: 

$self->{comments}

Test results: 

$self->{test_results}

Perl version: $self->{which_perl}

);

    $report .= Config::myconfig();

    my $subject    = uc($self->{grade}) 
        . " $self->{package} $Config{archname} $Config{osvers}";
    my $msg = new Mail::Send Subject => $subject, To => $CPAN_TESTERS;

    if (@recipients) {
        $msg->cc(build_cc(@recipients));
    }

    $msg->set('X-reported-via', "CPAN::Test::Reporter version $VERSION");

    my $fh = $msg->open;
    print $fh $report;
    $fh->close;
}

=for testing
is(CPAN::Test::Reporter::build_cc('skud@infotrope.net', 'skud@e-smith.com'), 'skud@infotrope.net, skud@e-smith.com', "Building CC list from email addresses");

=cut

sub build_cc {
    my @recipients = @_;
    return join(", ", @recipients);
}


=head1 COPYRIGHT

    Copyright (c) 1999 Kurt Starsinic, 2001 Kirrily Robert.
    This program is free software; you may redistribute it
    and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<CPAN::Smoke>

=head1 AUTHOR

Kirrily "Skud" Robert <skud@cpan.org>, based on the cpantest script 
by Kurt Starsinic E<lt>F<Kurt.Starsinic@isinet.com>E<gt>

=cut

return "FALSE";     # true value ;)
