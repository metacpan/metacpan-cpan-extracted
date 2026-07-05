package Crypt::OpenSSL3::MD;
$Crypt::OpenSSL3::MD::VERSION = '0.010';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: message digest algorithms

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::MD - message digest algorithms

=head1 VERSION

version 0.010

=head1 SYNOPSIS

 my $md = Crypt::OpenSSL3::MD->fetch('SHA2-256');

 my $context = Crypt::OpenSSL3::MD::Context->new;
 $context->init($md);

 $context->update("Hello, World!");
 my $hash = $context->final;

=head1 DESCRIPTION

This class holds a message digest. It's used to create a L<digest context|Crypt::OpenSSL3::Cipher::Context> that will do the actual digestion.

=head1 METHODS

=head2 fetch

=head2 digest

=head2 get_block_size

=head2 get_description

=head2 get_flags

=head2 get_name

=head2 get_param

=head2 get_pkey_type

=head2 get_size

=head2 get_type

=head2 is_a

=head2 list_all_provided

=head2 names_list_all

=head2 xof

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Leon Timmermans.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
