package Alien::Unicruft;
use strict;
use warnings;
use parent 'Alien::Base';
our $VERSION = '0.001';

__END__

=pod

=encoding utf8

=head1 NAME

Alien::Unicruft - install the libunicruft C library on your system

=head1 SYNOPSIS

   use 5.010;
   use strict;
   use Alien::Unicruft;
   
   my $alien = Alien::Unicruft->new;
   say $alien->libs;
   say $alien->cflags;

=head1 DESCRIPTION

Ensures that the libunicruft C library is installed on your system.

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

