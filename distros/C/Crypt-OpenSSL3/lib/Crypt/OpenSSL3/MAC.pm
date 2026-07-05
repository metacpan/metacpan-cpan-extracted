package Crypt::OpenSSL3::MAC;
$Crypt::OpenSSL3::MAC::VERSION = '0.010';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: Message authentication code algorithms

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::MAC - Message authentication code algorithms

=head1 VERSION

version 0.010

=head1 SYNOPSIS

 my $algoritm = Crypt::OpenSSL3::MAC->fetch('HMAC');
 my $context = Crypt::OpenSSL3::MAC::Context->new($algoritm);
 my $key = "0123456789ABCDEF";
 $context->init($key, { digest => 'SHA2-256' });

 $context->update('Hello, World!');
 my $mac = $context->final;

=head1 METHODS

=head2 fetch

=head2 get_description

=head2 get_name

=head2 get_param

=head2 is_a

=head2 list_all_provided

=head2 names_list_all

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Leon Timmermans.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
