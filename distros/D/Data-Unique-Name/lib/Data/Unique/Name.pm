#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Generate a unique but stable name from a string
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2016
#-------------------------------------------------------------------------------
# podDocumentation

package Data::Unique::Name;
require v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp;

our $VERSION = '20170810';

#1 Constructor
sub new($)                                                                      # Construct a new set of unique names
 {my ($length) = @_;                                                            # Maximum length of generated names
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

# podDocumentation

#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

require Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw();
%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

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

=head2 Constructor

=head3 new

Construct a new set of unique names

  1  $length  Maximum length of generated names                                                              # File name to be used on S3

=head2 Methods

=head3 generateUniqueName

Generate a unique name corresponding to a string

  1  $set     Set of unique strings
  2  $string  String


=head1 Index


L<generateUniqueName|/generateUniqueName>

L<new|/new>

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read, use,
modify and install.

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut


# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
 }

test unless caller;

1;
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
