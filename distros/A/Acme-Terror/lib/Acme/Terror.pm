package Acme::Terror;
$Acme::Terror::VERSION = '0.01';

use strict;
use LWP::Simple;
use XML::Simple;

=head1 NAME

Acme::Terror - Fetch the current US terror alert level

=head1 VERSION

This document describes version 0.01 of B<Acme::Terror>.

=head1 SYNOPSIS

	use Acme::Terror;
	my $t = Acme::Terror->new();				# create new Acme::Terror object
	
	my $level = $t->fetch;					# fetches current level

	print "Current terror alert level is: $level\n";	# prints

=cut

sub new {
	my ($class, %args) = @_;
	$class = ref($class) if (ref $class);

	return bless(\%args, $class);
}

sub fetch {
	my $url = "http://www.dhs.gov/dhspublic/getAdvisoryCondition";
	my $con = get($url);
	my $res = XMLin($con);
	my $lvl = $res->{CONDITION};
	return $lvl;
}

1;

__END__

=head1 AUTHORS

Matt Galisa E<lt>mrdelayer@gmail.com<gt>

=head1 COPYRIGHT

Copyright 2005 by Matt Galisa E<lt>mrdelayer@gmail.com<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
