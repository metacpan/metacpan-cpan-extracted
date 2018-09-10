package Dancer2::Plugin::Redis::SerializationRole;
use strictures 1;
# ABSTRACT: Dancer2::Plugin::Redis serialization role used in brokers.
#
# This file is part of Dancer2-Plugin-Redis
#
# This software is Copyright (c) 2018 by BURNERSK <burnersk@cpan.org>.
#
# This is free software, licensed under:
#
#   The MIT (X11) License
#

BEGIN {
  our $VERSION = '0.001';  # fixed version - NOT handled via DZP::OurPkgVersion.
}

use Moo::Role;

############################################################################

requires 'decode';
requires 'encode';

############################################################################
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::Redis::SerializationRole - Dancer2::Plugin::Redis serialization role used in brokers.

=head1 VERSION

version 0.009

=head1 AUTHOR

BURNERSK <burnersk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by BURNERSK <burnersk@cpan.org>.

This is free software, licensed under:

  The MIT (X11) License

=cut
