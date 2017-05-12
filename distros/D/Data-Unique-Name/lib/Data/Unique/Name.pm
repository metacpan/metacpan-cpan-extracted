#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Generate a unique but stable name from a string
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2016
#-------------------------------------------------------------------------------

package Data::Unique::Name;
require v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp;

our $VERSION = '2017.324';

#1 Constructor
sub new($)                                                                      # Construct a new set of unique names
 {my ($length) = @_;                                                            # Maximum length of generated names                                                              # File name to be used on S3
  bless {length=>$length, count=>{}}
 }

#1 Methods
sub generateUniqueName($$)                                                      # Generate a unique name corresponding to a string
 {my ($set, $string) = @_;                                                      # Set of unique strings, string
  my $l = $set->{length};
  my $s = $string =~ s/\W//gsr =~ s/\d+\Z//sr;
     $s = substr($s, 0, $l) if length($s) > $l;
  if (my $n = $set->{count}{$s})
   {$set->{count}{$s}++;
    return $s.$n;
   }
  $set->{count}{$s}++;
  $s
 }

#-------------------------------------------------------------------------------
# Test
#-------------------------------------------------------------------------------

sub test
 {eval join('', <Data::Unique::Name::DATA>) || die $@
 }

test unless caller();

# Documentation
#extractDocumentation unless caller;

#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

require Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw();
%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

1;

=encoding utf-8

=head1 Name

Data::Unique::Name - Generate a unique but stable name from a string

=head1 Synopsis

 use Data::Unique::Name;

 my $u = Data::Unique::Name::new(4);

 ok $u->generateUniqueName("aaaa")      eq "aaaa";
 ok $u->generateUniqueName("aaaa")      eq "aaaa1";
 ok $u->generateUniqueName("aaaa1")     eq "aaaa2";
 ok $u->generateUniqueName("aaaa2")     eq "aaaa3";
 ok $u->generateUniqueName("aaaab")     eq "aaaa4";
 ok $u->generateUniqueName("a a a a b") eq "aaaa5";
 ok $u->generateUniqueName("a-a(a)/ab") eq "aaaa6";
 ok $u->generateUniqueName("bbbbb")     eq "bbbb";
 ok $u->generateUniqueName("bbbbbb")    eq "bbbb1";
 ok $u->generateUniqueName("bbbbbbb")   eq "bbbb2";

=head1 Description

=head2 new($length)

Construct a new set of unique names

     Parameter  Description
  1  $length    Maximum length of generated names                                                              # File name to be used on S3

=head2 generateUniqueName($set, $string)

Generate a unique name corresponding to a string

     Parameter  Description
  1  $set       Set of unique strings
  2  $string    string

=head1 Index

L</generateUniqueName($set, $string)>
L</new($length)>

=head1 Installation

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

philiprbrenan@gmail.com

http://www.appaapps.com

=head1 Copyright

Copyright (c) 2016 Philip R Brenan.

This module is free software. It may be used, redistributed and/or
modified under the same terms as Perl itself.

=cut

__DATA__
use Test::More tests => 10;

my $u = Data::Unique::Name::new(4);

ok $u->generateUniqueName("aaaa")      eq "aaaa";
ok $u->generateUniqueName("aaaa")      eq "aaaa1";
ok $u->generateUniqueName("aaaa1")     eq "aaaa2";
ok $u->generateUniqueName("aaaa2")     eq "aaaa3";
ok $u->generateUniqueName("aaaab")     eq "aaaa4";
ok $u->generateUniqueName("a a a a b") eq "aaaa5";
ok $u->generateUniqueName("a-a(a)/ab") eq "aaaa6";
ok $u->generateUniqueName("bbbbb")     eq "bbbb";
ok $u->generateUniqueName("bbbbbb")    eq "bbbb1";
ok $u->generateUniqueName("bbbbbbb")   eq "bbbb2";
