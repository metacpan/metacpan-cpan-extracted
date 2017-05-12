package Data::FormValidator::Filters::HTMLScrubber;

use strict;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
use HTML::Scrubber;

BEGIN {
	require Exporter;
	$VERSION = '0.02';
	@ISA = qw( Exporter );
	@EXPORT = qw();
	%EXPORT_TAGS = (
		'all' => [ qw( html_scrub ) ]
	);
	@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
}

sub html_scrub {
	my %args = @_;
	return sub { return _html_scrub( shift, %args ) };
}

sub _html_scrub {
	my ($value,%args) = @_;
	my $scrubber = HTML::Scrubber->new(
		default => $args{default},
		allow => $args{allow},
		deny => $args{deny},
		rules => $args{rules},
		process => $args{process},
		comment => $args{comment}
	);
	return $scrubber->scrub($value);
}

1;
__END__

=pod

=head1 NAME

Data::FormValidator::Filters::HTMLScrubber - Data::FormValidator filter that allows to scrub/sanitize html

=head1 SYNOPSIS

   use Data::FormValidator::Filters::HTMLScrubber qw(html_scrub);

   # Data::FormValidator Profile:
   my $dfv_profile = {
      required => [ qw/foo bar/ ],
      field_filters => {
         foo => [ 'trim', html_scrub( allow => [qw/b i em strong/] ) ]
      }
   };

=head1 DESCRIPTION

Data::FormValidator filter that allows to scrub/sanitize html in form field
values.

=head1 API

This module exports following filters:

=head2 html_scrub( %options )

This will create a filter that will scrub/sanitize tha vaule of the field of
the form that is being submitted.

The C<%options> arguments are correspondant to L<HTML::Scrubber> constructor
arguments:

=over 4

=item * C<default>

=item * C<allow>

=item * C<deny>

=item * C<rules>

=item * C<process>

=item * C<comment>

=back

See L<HTML::Scrubber> for detailed description.

=head1 TODO

=over 4

=item *

Add more tests using Test::FormValidator suite

=item *

Add a constraint method/closure in order to test presence of HTML tags 
in a form field

=back

=head1 BUGS 

Please submit bugs to CPAN RT system at
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-FormValidator-Filters-HTMLScrubber 
or by email at bug-data-formValidator-filters-htmlscrubber@rt.cpan.org

Patches are welcome and I'll update the module if any problems will be found.

=head1 VERSION

Version 0.02

=head1 SEE ALSO

L<Data::FormValidator>, L<HTML::Scrubber>

=head1 AUTHOR

Enrico Sorcinelli, E<lt>bepi@perl.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Enrico Sorcinelli

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
