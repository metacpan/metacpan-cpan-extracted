use 5.008008;
use strict;
use warnings;

package AskX::AutoLang;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.015';

use Moo::Role;

my @methods = qw(
	info warning error entry question file_selection
	single_choice multiple_choice
);

has language => ( is => 'ro', required => 1 );

for my $method ( @methods ) {
	around $method => sub {
		my $orig = shift;
		my $self = shift;
		$self->$orig( lang => $self->language, @_ );
	};
}

1;

__END__

=head1 NAME

AskX::AutoLang - automatically supply a "lang" argument to all method calls

=head1 SYNPOSIS

   my $ask = Ask->detect(traits => ['AskX::AutoLang'], language => "fr");
   $ask->question("Voulez-vous coucher avec moi ce soir?");

=head1 DESCRIPTION

Saves supplying C<< lang => "fu" >> to all method calls. Just do it once in
the constructor.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Ask>.

=head1 SEE ALSO

L<Ask>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013, 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
