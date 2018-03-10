package Acme::YAPC::Okinawa::Bus;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__

=encoding utf-8

=head1 NAME

Acme::YAPC::Okinawa::Bus - It's Tweet shere

=head1 SYNOPSIS

    use Acme::YAPC::Okinawa::Bus;
    say Acme::YAPC::Okinawa::Bus::time();
    say Acme::YAPC::Okinawa::Bus::place();

=head1 DESCRIPTION

Acme::YAPC::Okinawa::Bus is YAPC::Okinawa bus time.

=head1 LICENSE

Copyright (C) AnaTofuZ.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

AnaTofuZ E<lt>anatofuz@gmail.comE<gt>

=cut

