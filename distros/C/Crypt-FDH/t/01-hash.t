#!perl -T
# -*-cperl-*-
#
# 01-hash.t - Test Full Domain Hash
# Copyright (c) 2016-2017 Ashish Gulhati <crypt-fdh at hash.neo.tc>

use Test::More tests => 4;
use Crypt::FDH qw(hash);

is  (hash(Message => 'Hello world!', Size => 512, Algorithm => 'sha256'), 'e1dffbd4c9d12a16bd1f1c9124395077e04d5ec8b6604a2fc53b6ba8047e047d1602fef23ff0c65075a3bd038dfb546a161308e08ba10ab9a06873561b818500', 'SHA256 512 bit');
is  (hash(Message => 'Hello world!', Size => 480, Algorithm => 'sha1'), '154ce33899265f679d1f7794b18b492db140d6492247d1289dbf910e175d492fec631a8afb42cab1929b2cd19e2fbc01a00e77353f031892cf9df51e', 'SHA1 480 bit');
is  (hash(Message => 'Hello world!', Size => 1024, Algorithm => 'sha256'), 'e1dffbd4c9d12a16bd1f1c9124395077e04d5ec8b6604a2fc53b6ba8047e047d1602fef23ff0c65075a3bd038dfb546a161308e08ba10ab9a06873561b8185007a3c5e3dabcc27ec4ab619e80a3e36d90fece7fac592a0fa1d3c88e6e1a9d8991123558f9b1339bf0e37f2c729cc9fa1f97341d9c870741f33d295228c299e3a', 'SHA256 1024 bit');
is  (hash(Message => 'Hello world!', Size => 960, Algorithm => 'sha1'), '154ce33899265f679d1f7794b18b492db140d6492247d1289dbf910e175d492fec631a8afb42cab1929b2cd19e2fbc01a00e77353f031892cf9df51e537dec0f553832dcbddf4b586733c5d6a4125f4cd725f1c3bd6b9d3a4602f43aa8a878dd62d5023812c97ace1be3be7e08da71a36e657da8b38f8096', 'SHA1 960 bit');
