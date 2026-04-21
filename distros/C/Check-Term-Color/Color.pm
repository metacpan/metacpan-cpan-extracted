package Check::Term::Color;

use base qw(Exporter);
use strict;
use warnings;

use Readonly;

Readonly::Array our @EXPORT_OK => qw(check_term_color);

our $VERSION = 0.01;

sub check_term_color {
	my $env_hr = shift;

	$env_hr ||= \%ENV;

	my $ret;
	if (exists $env_hr->{'NO_COLOR'}) {
		$ret = 0;
	} elsif (defined $env_hr->{'COLOR'}) {
		if ($env_hr->{'COLOR'} eq 'always'
			|| $env_hr->{'COLOR'} eq 'yes') {

			$ret = 1;
		} elsif ($env_hr->{'COLOR'} eq 'never'
			|| $env_hr->{'COLOR'} eq 'no') {

			$ret = 0;
		} elsif ($env_hr->{'COLOR'} eq 'auto') {
			if (-t STDOUT) {
				$ret = 1;
			} else {
				$ret = 0;
			}
		} else {
			$ret = 1;
		}
	} else {
		$ret = 0;
	}

	return $ret;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Check::Term::Color - Check terminal color functionality.

=head1 SYNOPSIS

 use Check::Term::Color qw(check_term_color);

 my $ret = check_term_color($env_hr);

=head1 DESCRIPTION

This check test environment variables and returns value which define situation
about color output in terminal.

See L<https://no-color.org/> for more information about C<$ENV{'NO_COLOR'}>
environment variable.

Usage of C<$ENV{'COLOR'}> environment variable is related to GNU C<--color> option. See L<grep(1)>.

=head1 SUBROUTINES

=head2 C<check_term_color>

 my $ret = check_term_color($env_hr);

Check color terminal setting.

Variable C<$env_hr> is primarily for testing and default is C<\%ENV>.

Soubroutine is checking C<$ENV{'COLOR'}> and C<$ENV{'NO_COLOR'}> variables.

Returns 0/1.

=head1 EXAMPLE

=for comment filename=check_term_color.pl

 use strict;
 use warnings;

 use Check::Term::Color qw(check_term_color);

 if (check_term_color()) {
         print "We could write color output to terminal.\n";
 } else {
         print "We couldn't write color output to terminal.\n";
 }

 # Output with $ENV{'COLOR'} = 'always' set:
 # We could write color output to terminal.
 
 # Output with $ENV{'COLOR'} = 'never' set:
 # We couldn't write color output to terminal.

 # Output with $ENV{'COLOR'} = '1' set:
 # We could write color output to terminal.

 # Output with $ENV{'NO_COLOR'} = '1' set:
 # We couldn't write color output to terminal.

 # Output with $ENV{'NO_COLOR'} = 'foo' set:
 # We couldn't write color output to terminal.

=head1 DEPENDENCIES

L<Exporter>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Check-Term-Color>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2026 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
