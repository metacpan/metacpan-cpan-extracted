use strict;
use warnings;
package Acme::Robd::Boring; 
# ABSTRACT: a really boring module

our $VERSION = 0.002;


use Carp qw( carp );


sub new {
    return bless {}, shift;
}


sub name { __PACKAGE__ }


sub version { $VERSION }

1;

__END__
=pod

=head1 NAME

Acme::Robd::Boring - a really boring module

=head1 VERSION

version 0.002

=head1 SYNOPSIS

use strict;
use feature 'say';
...
use Acme::Robd::Boring;
my $arb = Acme::Robd::Boring->new;
say $arb->name;
Acme::Robd::Boring # bore-ing!

=head1 METHODS

=head2 new

bog-standard classic perl OOP constructor

=head2 name

returns the package (module) name

=head2 version

returns the package (module) version

=head1 AUTHOR

Rob Duncan <robd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Rob Duncan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

