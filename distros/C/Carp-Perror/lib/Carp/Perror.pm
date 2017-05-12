package Carp::Perror;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(perror pexit);
our $VERSION = '0.02';

sub perror
{
	pexit(@_);
}

sub pexit
{
	my $exitcode = 0;
	if ( $_[0] =~ /^[0-9]+$/ )
	{
		$exitcode = int(shift @_);
	}
	my $w = join " ", @_;
	print "$w";
	exit $exitcode;
}


1;
__END__

=head1 NAME

Carp::Perror - print msg then exit

=head1 SYNOPSIS

  use Carp::Perror qw/perror pexit/;
  pexit(1, "wrong argv given\n");
  # got "wrong argv given", exit code = 1;

  pexit("wrong argv given\n");
  # got "wrong argv given", exit code = 0;

  perror(1, "wrong argv given\n");
  # got "wrong argv given", exit code = 1;

  perror("wrong argv given\n");
  # got "wrong argv given", exit code = 0;

=head1 DESCRIPTION

Exit without any stack backtrace msg.

=head2 EXPORT

None by default.

=head1 METHODS

=head2 pexit()

exit with defined exit code if the first argv is a number.

else exit with 0.

=head2 perror()

just a alias of pexit().

=head1 SEE ALSO

L<Carp>

=head1 AUTHOR

Chen Gang, E<lt>yikuyiku.com@google.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Chen Gang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
