package Acme::BottomsUp;

use warnings;
use strict;

our $VERSION = '0.02';

use Filter::Simple;
use PPI;

FILTER {
  my $doc = PPI::Document->new(\$_);
  $_ = join '',
	map {
	  my $s = $_->content;
	  $s =~ s/;\s*$//s;
	  join("\n",
	      reverse
	      split "\n",
		$s
	  ) . "\n;"
	}
	@{ $doc->find('PPI::Statement') };
};

1;

=pod

=head1 NAME

Acme::BottomsUp - Write individual statements backwards

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

	my @arr = (1..10);
	
	use Acme::BottomsUp;
	@arr                  # first, start w/ numbers
	  grep { $_ % 2 }     # then get the odd ones
	  map { $_**3 }       # then cube each one
	  join ":",           # and glue together
	  print               # lastly, display result
	;
	print "ok";
	no Acme::BottomsUp;

=head1 DESCRIPTION

This module allows you to write multi-line perl statements in reverse order so that it "reads better".  For example, normally one would write the code from the SYNOPSIS as:

	my @arr = (1..10);
	
	print                 # lastly, display result
	     join ":",        # and glue together
	     map { $_**3 }    # then cube each one
	     grep { $_ % 2 }  # then get the odd ones
	     @arr		# first, start with numbers
	;

=head1 PREREQUISITES

=over 4

=item *

L<Filter::Simple>

=item *

L<PPI>

=back

=head1 SEE ALSO

L<http://perlmonks.org/?node_id=567298> - Original location for RFC

=head1 AUTHOR

David Westbrook (davidrw), C<< <dwestbrook at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-bottomsup at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-BottomsUp>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

I'm also available by email or via '/msg davidrw' on L<http://perlmonks.org>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::BottomsUp

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-BottomsUp>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-BottomsUp>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-BottomsUp>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-BottomsUp>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 David Westbrook, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

