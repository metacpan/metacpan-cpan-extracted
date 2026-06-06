package Check::Term;

use parent qw(Exporter);
use strict;
use warnings;

use Readonly;
use Term::Terminfo;

our $ERROR_MESSAGE;
Readonly::Array our @EXPORT_OK => qw(check_term_capabilities $ERROR_MESSAGE);

our $VERSION = 0.01;

sub check_term_capabilities {
	my @capabilities = @_;

	my $ti = Term::Terminfo->new;
	foreach my $capability (@capabilities) {
		if (! defined $ti->str_by_varname($capability)) {
			$ERROR_MESSAGE = "Terminal capability '$capability' ins't supported.";
			return 0;
		}
	}

	return 1;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Check::Term - Check terminal functionality.

=head1 SYNOPSIS

 use Check::Term qw(check_term_capabilities $ERROR_MESSAGE);

 my $ret = check_term_capabilities(@capabilities);
 print $ERROR_MESSAGE."\n";

=head1 DESCRIPTION

There is need of check for terminal capabilities in tests.
Actually we have duplicated checks in distributions.

Intent of this module is create common code for check string terminal
capabilities via L<Term::Terminfo>.
Extra thing is error message which describe issue.

=head1 SUBROUTINES

=head2 check_term_capabilities

 my $ret = check_term_capabilities(@capabilities);

Check possibility of string terminal capabilities on system.

Variables C<@capabilities> are terminal capability variable names for
L<Term::Terminfo/str_by_varname>.

Return value is 1 as supported terminal capabilities or 0 as not supported
capability.
If return value is 0, set C<$ERROR_MESSAGE> variable.

Returns 0/1.

=head1 EXAMPLES

=head2 EXAMPLE1

=for comment filename=check_term_capabilities.pl

 use strict;
 use warnings;

 use Check::Term qw(check_term_capabilities $ERROR_MESSAGE);

 if (check_term_capabilities('parm_ich')) {
         print "We could use terminal 'parm_ich' capability.\n";
 } else {
         print "We couldn't use terminal 'parm_ich' capability.\n";
         print "Error message: $ERROR_MESSAGE\n";
 }

 # Output with 'parm_ich' capability:
 # We could use terminal 'parm_ich' capability.

 # Output without 'parm_ich' capability:
 # We couldn't use terminal 'parm_ich' capability.
 # Error message: Terminal capability 'parm_ich' ins't supported.

=head2 EXAMPLE2

=for comment filename=test_term_capabilities.pl

 use strict;
 use warnings;

 use Check::Term qw(check_term_capabilities);
 use Test::More 'tests' => 1;

 SKIP: {
         skip $Check::Term::ERROR_MESSAGE, 1
                 unless check_term_capabilities('parm_ich');

         ok(1, "Terminal 'parm_ich' capability test");
 };

 # Output with 'parm_ich' capability:
 # 1..1
 # ok 1 - Terminal 'parm_ich' capability test

 # Output without 'parm_ich' capability:
 # 1..1
 # ok 1 # skip Terminal capability 'parm_ich' ins't supported.

=head1 DEPENDENCIES

L<Exporter>,
L<Readonly>,
L<Term::Terminfo>.

=head1 SEE ALSO

=over

=item L<Term::Terminfo>

Access to terminfo database.

=item L<Test2::Require::TermSize>

Skip a test file unless terminal is at least a certain size.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Check-Term>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2026 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
