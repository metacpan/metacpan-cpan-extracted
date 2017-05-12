#!/usr/bin/perl -sw
##
## Makefile.PL for Crypt-RSA. 
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: Makefile.PL,v 1.12 2001/05/30 13:10:32 vipul Exp $

use inc::Module::Install;

name            'Crypt-RSA';
abstract_from   'lib/Crypt/RSA.pm';
author          'Vipul Ved Prakash <mail@vipul.net>';
license         'perl';
version_from    'lib/Crypt/RSA.pm';
perl_version    '5.006';

requires        'Math::Pari'            => '2.001804';
requires        'Crypt::Random'         => '0.34';
requires        'Crypt::Primes'         => '0.38';
requires        'Crypt::CBC'            => 0;
requires        'Crypt::Blowfish'       => 0;
requires        'Data::Dumper'          => 0; 
requires        'Tie::EncryptedHash'    => 0;
requires        'Convert::ASCII::Armour'=> 0;
requires        'Sort::Versions'        => 0;
requires        'Digest::SHA1'          => 0;
requires        'Digest::MD5'           => 0;
requires        'Digest::MD2'           => 0;
requires        'Class::Loader'         => '2.00';
requires        'Data::Buffer'          => 0; 

WriteAll;

