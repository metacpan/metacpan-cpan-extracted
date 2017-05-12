package DBI::Test;

require 5.008001;

use strict;
use warnings;

require Exporter;
use Test::More import => [ '!pass' ];

use parent qw(Test::Builder::Module Exporter);

our $VERSION = "0.001";

# XXX improve / beautify ... map {} + categories ...
our @EXPORT = qw(connect_ok connect_not_ok prepare_ok execute_ok execute_not_ok do_ok do_not_ok);
our @EXPORT_OK = qw(connect_ok connect_not_ok prepare_ok execute_ok execute_not_ok do_ok do_not_ok);

my $CLASS = __PACKAGE__;

=head1 NAME

DBI::Test - Test suite for DBI API

=cut

sub connect_ok
{
    my ($data_source, $username, $auth, $attr, $testname) = @_;
    my $tb = $CLASS->builder();
    my $dbh = DBI->connect($data_source, $username, $auth, $attr);
    # maybe use Test::More::isa_ok directly from here?
    $tb->ok($dbh, $testname) and $tb->ok($dbh->isa("DBI::db"), "$testname delivers a DBI::db") and return $dbh;
    return;
}

sub connect_not_ok
{
    my ($data_source, $username, $auth, $attr, $testname) = @_;
    my $tb = $CLASS->builder();
    my $dbh = DBI->connect($data_source, $username, $auth, $attr);
    $tb->ok(!$dbh, $testname) or return $dbh;
    return;
}

sub prepare_ok
{
    my ($dbh, @vals) = @_;
    my $testname = pop(@vals);
    my $tb = $CLASS->builder();
    my $sth = $dbh->prepare(@vals);
    $tb->ok($sth, $testname) and  $tb->ok($sth->isa("DBI::st"), "$testname delivers DBI::st") and return $sth;
    return;
}

sub execute_ok
{
    my ($sth, @vals) = @_;
    my $testname = pop(@vals);
    my $tb = $CLASS->builder();
    my $rv = $sth->execute(@vals);
    $tb->ok($rv, $testname);
    return $rv;
}

sub execute_not_ok
{
    my ($sth, @vals) = @_;
    my $testname = pop(@vals);
    my $tb = $CLASS->builder();
    my $rv = $sth->execute(@vals);
    $tb->ok(!defined($rv),, $testname);
    return $rv;
}

sub do_ok
{
    my ($dbh, @vals) = @_;
    my $testname = pop(@vals);
    my $tb = $CLASS->builder();
    my $rv = $dbh->do(@vals);
    $tb->ok($rv, $testname);
    return $rv;
}

sub do_not_ok
{
    my ($dbh, @vals) = @_;
    my $testname = pop(@vals);
    my $tb = $CLASS->builder();
    my $rv = $dbh->do(@vals);
    $tb->ok(!defined($rv),, $testname);
    return $rv;
}

1;

__END__

=head1 SYNOPSIS

In Makefile.PL:

    use lib 'lib'; # to allow DBI::Test finds the test cases of your driver
    use DBI::Test::Conf ();
    my @generated_tests = DBI::Test::Conf->setup();
    WriteMakefile (
        test => {
	    TESTS           => join (' ' => 'xt/*.t', @generated_tests),
        },
	clean => { FILES => join( " " => @generated_tests ) }
    );

You provide

    package DBI::Test::Your::Namespace::List;
    
    sub test_cases
    {
	return qw(...); # list of the test cases you provide
    }
    
    package DBI::Test::Your::Namespace::Conf;
    
    sub conf
    {
	my %conf = (
	    gofer => {
			 category   => "Gofer",
			 cat_abbrev => "g",
			 abbrev     => "b",
			 init_stub  => qq(\$ENV{DBI_AUTOPROXY} = 'dbi:Gofer:transport=null;policy=pedantic';),
			 match      => sub {
					 my ($self, $test_case, $namespace, $category, $variant) = @_;
					 ...
				  },
			 name => "Gofer Transport",
		       },
		   );
    }
    
    package DBI::Test::Your::Namespace::Case::Your::First;
    
    ... # will be t/your/namespace/your/first.t
    
    package DBI::Test::Your::Namespace::Case::Your::Second;
    
    ... # will be t/your/namespace/your/second.t
    
    1;

And enhance DBI::Test with own test cases.

=head1 DESCRIPTION

This module aims to be a test suite for the DBI API and an underlying DBD
driver, to check if the provided functionality is working and complete.

Part of this module is the ability for self-testing using I<DBI::Mock>.
This is not designed to be another I<DBI::PurePerl> - it's designed to
allow tests can be verified to work as expected in a sandbox. This is,
of course, limited to DBI API itself and cannot load any driver nor
really execute any action.

=head1 EXPORTS

=head2 connect_ok

  $dbh = connect_ok($dsn, $user, $pass, \%attrs, $test_name);

connect_ok invokes DBI-E<gt> and proves the result in an I<ok>.
The created database handle (C<$dbh>) is returned, if any.

=head2 connect_not_ok

  $dbh = connect_not_ok($dsn, $user, $pass, \%attrs, $test_name);

connect_not_ok invokes DBI-E<gt> and proves the result in an I<ok>
(but expects that there is no C<$dsn> returned).  The created database
handle (C<$dbh>) is returned, if any.

=head2 prepare_ok

  $sth = prepare_ok($dbh, $stmt, \%attrs, $test_name);

prepare_ok invokes $dbh-E<gt>prepare and proves the result in
an I<ok>. The resulting statement handle (C<$sth>) is returned,
if any.

=head2 execute_ok

  $rv = execute_ok($sth, $test_name);
  $rv = execute_ok($sth, @bind_values, $test_name);

execute_ok invokes $sth->excute and proves the result via I<ok>.
The value got from $sth-E<gt>execute is returned.

=head2 execute_not_ok

  $rv = execute_not_ok($sth, $test_name);
  $rv = execute_not_ok($sth, @bind_values, $test_name);

execute_not_ok invokes $sth->excute and proves the result via I<is(undef)>.
The value got from $sth-E<gt>execute is returned.

=head2 do_ok

  $rv = do_ok($dbh, $test_name);
  $rv = do_ok($dbh, @bind_values, $test_name);

do_ok invokes $dbh->do and proves the result via I<ok>.
The value got from $dbh-E<gt>do / $sth-E<gt>execute is returned.

=head2 do_not_ok

  $rv = do_not_ok($dbh, $test_name);
  $rv = do_not_ok($dbh, @bind_values, $test_name);

do_not_ok invokes $dbh->do and proves the result via I<is(undef)>.
The value got from $dbh-E<gt>do / $sth-E<gt>execute is returned.

=head1 GOAL

=head2 TODO

=head2 Source

Recent changes can be (re)viewed in the public GIT repository at
GitHub L<https://github.com/perl5-dbi/DBI-Test>
Feel free to clone your own copy:

 $ git clone https://github.com/perl5-dbi/DBI-Test.git DBI-Test

=head2 Contact

We are discussing issues on the DBI development mailing list 1) and on IRC 2)

 1) The DBI team <dbi-dev@perl.org>
 2) irc.perl.org/6667 #dbi

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SQL::Statement

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBI-Test>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBI-Test>

=item * CPAN Ratings

L<http://cpanratings.perl.org/s/DBI-Test>

=item * CPAN Search

L<http://search.cpan.org/dist/DBI-Test/>

=back

=head2 Reporting bugs

If you think you've found a bug then please read
"How to Report Bugs Effectively" by Simon Tatham:
L<http://www.chiark.greenend.org.uk/~sgtatham/bugs.html>.

Your problem is most likely related to the specific DBD driver module you're
using. If that's the case then click on the 'Bugs' link on the L<http://metacpan.org>
page for your driver. Only submit a bug report against the DBI::Test itself if you're
sure that your issue isn't related to the driver you're using.

=head1 TEST SUITE

DBI::Test comes with some basic tests to test itself and L<DBI::Mock>.
The same tests are used for basic DBI self-tests as well as testing the
SQL::Statement mock driver.

=head1 EXAMPLES

??? Synopsis ???

=head1 DIAGNOSTICS

???

=head1 SEE ALSO

 DBI        - Database independent interface for Perl
 DBI::DBD   - Perl DBI Database Driver Writer's Guide
 Test::More - yet another framework for writing test scripts

=head1 AUTHOR

This module is a team-effort. The current team members are

  H.Merijn Brand   (Tux)
  Jens Rehsack     (Sno)
  Peter Rabbitson  (ribasushi)
  Joakim TE<0x00f8>rmoen   (trmjoa)

=head1 COPYRIGHT AND LICENSE

Copyright (C)2013 - The DBI development team

You may distribute this module under the terms of either the GNU
General Public License or the Artistic License, as specified in
the Perl README file.

=cut
