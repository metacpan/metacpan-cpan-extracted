package App::cryp::Role::ArbitStrategy;

our $DATE = '2018-12-03'; # DATE
our $VERSION = '0.009'; # VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny;

requires qw(
               calculate_order_pairs
       );

1;
# ABSTRACT: Role for arbitration strategy module

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cryp::Role::ArbitStrategy - Role for arbitration strategy module

=head1 VERSION

This document describes version 0.009 of App::cryp::Role::ArbitStrategy (from Perl distribution App-cryp-arbit), released on 2018-12-03.

=head1 DESCRIPTION

An arbitration strategy module is picked by the main arbit module
(L<App::cryp::arbit>). It must supply a C<calculate_order_pairs> class method.
This class method is given some arguments (see L</"calculate_order_pairs"> for
more details), and then must return order pairs. The order pairs will be created
on the exchanges by the main arbit module.

=head1 REQUIRED METHODS

=head2 calculate_order_pairs

Usage:

 __PACKAGE__->calculate_order_pairs(%args) => [$status, $reason, $payload, \%resmeta]

Will be fed these arguments:

=over

=item * r

Hash. The Perinci::CmdLine request hash/stash, which contains many information
inside it, for example:

 $r->{_cryp}     # information from the configuration, e.g. exchanges, wallets, masternodes
 $r->{_stash}
   {dbh}
   ...

See L<App::cryp::arbit> for more details.

=back

=head1 INTERNAL NOTES

=head1 BUGS

Please report all bug reports or feature requests to L<mailto:stevenharyanto@gmail.com>.

=head1 SEE ALSO

L<App::cryp::arbit>

C<App::cryp::arbit::Strategy::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
