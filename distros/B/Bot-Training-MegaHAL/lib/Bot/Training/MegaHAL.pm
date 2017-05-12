package Bot::Training::MegaHAL;
BEGIN {
  $Bot::Training::MegaHAL::VERSION = '0.02';
}

use 5.010;
use Any::Moose;

extends 'Bot::Training::Plugin';

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bot::Training::MegaHAL - Provide F<megahal.trn> via L<Bot::Training>

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

