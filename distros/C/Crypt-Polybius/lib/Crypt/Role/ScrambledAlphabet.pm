use 5.008;
use strict;
use warnings;

package Crypt::Role::ScrambledAlphabet;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Moo::Role;
use Const::Fast;
use Types::Common::String qw(Password);
use namespace::sweep;

has password => (
	is       => 'lazy',
	isa      => Password,
	required => !!1,
);

around alphabet => sub
{
	my $next = shift;
	my $self = shift;
	my $orig = $self->$next(@_);
	
	my %allowed_letters;
	$allowed_letters{$_}++ for @$orig;
	
	my @letters = grep $allowed_letters{$_}, split '', $self->password;
	push @letters, @$orig;
	
	my %seen;
	return [ grep !$seen{$_}++, @letters ];
};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Crypt::Role::ScrambledAlphabet - use a password to change the order of the alphabet

=head1 SYNOPSIS

   use Crypt::Polybius;
   
   my $square = Crypt::Polybius->new_with_traits(
      traits   => ['Crypt::Role::ScrambledAlphabet'],
      password => "FISHING",
   );
   
   print $square->encipher("Hello world!"), "\n";

=head1 DESCRIPTION

This role scrambles an alphabet. For example, given the password
"FISHING", the alphabet from L<Crypt::Role::LatinAlphabet> are
rearranged as follows:

   A B C D E F G H I K L M N O P Q R S T U V W X Y Z
   F I S H N G A B C D E K L M O P Q R T U V W X Y Z

=head2 Attrbutes

=over

=item C<< password >>

The password to scramble the alphabet with. Should use at least some
letters which exist in the available alphabet (case-sensitive!).

This attribute is required, and must conform to the C<Password> type
constraint (L<Types::Common::String>).

=back

=head2 Method Modifiers

=over

=item C<< alphabet >>

The alphabet method is wrapped, changing the order of the letters.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Crypt-Polybius>.

=head1 SEE ALSO

L<Crypt::Polybius>,
L<Crypt::Polybius::Greek>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

