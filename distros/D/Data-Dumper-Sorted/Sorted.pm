#!/usr/bin/perl
package Data::Dumper::Sorted;
#
# recurse2txt routines
#
# version 1.10, 5-24-13, michael@bizsystems.com
#
# 10-3-11	updated to bless into calling package
# 10-10-11	add SCALAR ref support
# 1.06	12-16-12	add hexDumper
# 1.07	12-19-12	added wantarray return of data and elements
# 1.08	12-20-12	add wantarray to hexDumper
# 1.09	5-18-13		add my (data,count)
# 1.10	5-24-13		add pod and support for blessed objects
#			converted to a module
#
#use strict;
#use diagnostics;

use vars qw(@EXPORT_OK $VERSION @ISA);
use overload;
require Exporter;

@ISA = qw(Exporter);

$VERSION = do { my @r = (q$Revision: 1.12 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@EXPORT_OK = qw(
	hexDumper
	hexDumperA
	hexDumperC
	Dumper
	DumperA
	DumperC
);

=head1 NAME

Data::Dumper::Sorted - Dumper with repeatable signature

=head1 SYNOPSIS - similar to Data::Dumper

Data::Dumper::Sorted generates a unique signature for hashs
by sorting the keys into alphabetic order.

Data::Dumper actually does much more than this, however, it
does not stringify hash's in a consistent manner. i.e. no SORT

The routines below, while not covering recursion loops, non ascii
characters, etc.... does produce text that can be eval'd and is 
consistent with each rendering, version of Perl, and platform.

The module routines may be called as functions or methods.

  use Data::Dumper::Sorted qw(
	hexDumper
	hexDumperC
	hexDumperA
	Dumper
	DumperC
	DumperA
  };

OR as methods

  require Data::Dumper::Sorted;

  my $dd = new Data::Dumper::Sorted;

A blessed reference is not really needed.

  my $dd = 'Data::Dumper::Sorted';

  $countText = $dd->hexDumperC($ref);
  $evalText  = $dd->hexDumper($ref);
  ($text,$count) = $dd->hexDumperA($ref);

  $countText = $dd->DumperC($ref);
  $evalText  = $dd->Dumper($ref);
  ($text,$count) = $dd->DumperA($ref);

=item * $dd = new Data::Dumper::Sorted;

This method returns a blessed reference that can be used to access the
functions in this modules as methods.

=cut

sub new ($) {
  my $class = ref $_[0] || shift || __PACKAGE__;
  bless {}, $class;
}

=item * $countText = hexDumperC($ref);

  same as:
	scalar DumperA($ref);

It prefixes the dumped text with a COUNT of the 
nodes in the text instead of a symbol name. This is useful
in developing perl test routines.

i.e 		5 { text....

instead of:	$Var = { text....

=item * $evalText = hexDumper($ref);

Same form as Data::Dumper. This method returns a string which
can be eval'd to reconstitute the reference.

=item * ($text,$count) = hexDumperA($ref);

Returns the text of fully numeric data items converted to hex.

  input:	reference
  return:	array context
	 text_for_reference_contents,
	 count_of_data_items

		scalar context
	 count	text_for_reference_contents

=cut

sub hexDumper {
  my($txt) = &hexDumperA;
  return '$Var00 = '. $txt;
}

sub hexDumperC {
  return scalar &hexDumperA;
}

sub hexDumperA {
  shift if @_ > 1;
  my ($data,$count) = DumperA($_[0]);
  $data =~ s/([ [])(\d+),/sprintf("%s0x%x,",$1,$2)/ge;
  return (wantarray) ? ($data,$count) : $count ."\t= ". $data;
}

=item * $countText = DumperC($ref);

  same as:
	scalar DumperA($ref);

It prefixes the dumped text with a COUNT of the 
nodes in the text instead of a symbol name.. This is useful
in developing perl test routines.

i.e 		5 { text....

instead of:	$Var = { text....

=item * $evalText = Dumper($ref);

Same form as Data::Dumper. This method returns a string which
can be eval'd to reconstitute the reference.

=item * ($text,$count) = DumperA($ref);

  input:	reference
  return:	array context
	 text_for_reference_contents,
	 count_of_data_items

		scalar context
	 count	text_for_reference_contents

=cut

# input:	potential reference
# return:	ref type or '',
#		blessing if blessed

sub __getref {
  return ('') unless (my $class = ref($_[0]));
  if ($class =~ /(HASH|ARRAY|SCALAR|CODE|GLOB)/) {
    return ($1,'');
  }
  my($ref) = (overload::StrVal($_[0]) =~ /^(?:.*\=)?([^=]*)\(/);
  return ($ref,$class);
}

sub Dumper {
  my($txt) = &DumperA;
  return '$Var00 = '. $txt;
}

sub DumperC {
  return scalar &DumperA;
}

sub DumperA {
  shift if @_ > 1;
  unless (defined $_[0]) {
    return ("undef\n",'undef') if wantarray;
    return "undef\n";
  }
#  my $ref = ref $_[0];
#  return "not a reference\n" unless $ref;
#  unless ($ref eq 'HASH' or $ref eq 'ARRAY' or $ref eq 'SCALAR') {
#    ($ref) = (overload::StrVal($_[0]) =~ /^(?:.*\=)?([^=]*)\(/);
#  }
  my($ref,$class) = &__getref;
  return "not a reference\n" unless $ref;
  my $p = {
	depth		=> 0,
	elements	=> 0,
  };
#  (my $pkg = (caller(0))[3]) =~ s/(.+)::DumperA/$1/;
#  bless $p,$pkg;
  bless $p;
  my $data;
  if ($ref eq 'HASH') {
    $data = $p->hash_recurse($_[0],"\n",$class);
  }
  elsif ($ref eq 'ARRAY') {
    $data = $p->array_recurse($_[0],'',$class);
  } else {
#  return $ref ." unsupported\n";
    $data = $p->scalar_recurse($_[0],'',$class);
  }
  $data =~ s/,\n$/;\n/;
  return ($data,$p->{elements}) if wantarray;
  return $p->{elements} ."\t= ". $data;
}
  
# input:	pointer to scalar, terminator
# returns	data
#
sub scalar_recurse {
  my($p,$ptr,$n,$bls) = @_;
  $n = '' unless $n;
  my $data = $bls ? 'bless(' : '';
  $data .= "\\";
  $data .= _dump($p,$$ptr);
  $data .= " '". $bls ."')," if $bls;
  $data .= "\n";
}

# input:	pointer to hash, terminator
# returns:	data
#
sub hash_recurse {
  my($p,$ptr,$n,$bls) = @_;
  $n = '' unless $n;
  my $data = $bls ? 'bless(' : '';
  $data .= "{\n";
  foreach my $key (sort keys %$ptr) {
    $data .= "\t'". $key ."'\t=> ";
    $data .= _dump($p,$ptr->{$key},"\n");
  }
  $data .= '},';
  $data .= " '". $bls ."')," if $bls;
  $data .= $n;
}

# generate a unique signature for a particular array
#
# input:	pointer to array, terminator
# returns:	data
sub array_recurse {
  my($p,$ptr,$n,$bls) = @_;
  $n = '' unless $n;
  my $data = $bls ? 'bless(' : '';
  $data .= '[';
  foreach my $item (@$ptr) {
    $data .= _dump($p,$item);
  }
  $data .= "],";
  $data .= " '". $bls ."')," if $bls;
  $data .= "\n";
}

# input:	self, item, append
# return:	data
#
sub _dump {
  my($p,$item,$n) = @_;
  $p->{elements}++;
  $n = '' unless $n;
  my($ref,$class) = __getref($item);
  if ($ref eq 'HASH') {
    return tabout($p->hash_recurse($item,"\n",$class));
  }
  elsif($ref eq 'ARRAY') {
    return $p->array_recurse($item,$n,$class);
  }
  elsif($ref eq 'SCALAR') {
 #   return q|\$SCALAR,|.$n;
    return($p->scalar_recurse($item,$n,$class)); 
 }
  elsif ($ref eq 'GLOB') {
    my $g = *{$item};
    return  "\\$g" .','.$n;
  }
  elsif(do {my $g = \$item; ref $g eq 'GLOB'}) {
    return "$item" .','.$n;
  }
  elsif($ref eq 'CODE') {
    return q|sub {'DUMMY'},|.$n;
  }
  elsif (defined $item) {
    return wrap_data($item) .','.$n;
  }
  else {
    return 'undef,'.$n;
  }
}

sub tabout {
  my @data = split(/\n/,shift);
  my $data = shift @data;
  $data .= "\n";
  foreach(@data) {
    $data .= "\t$_\n";
  }
  $data;
}

sub wrap_data {
  my $data = shift;
  if ($data =~ /^$/) {
    return '';
  } elsif ($data =~ /\D/) {
    $data =~ s/'/\\'/g;
    return q|'|. $data .q|'|;
  }
  $data;
}

=head1 AUTHOR

Michael Robinton, <miker@cpan.org>

=head1 COPYRIGHT

Copyright 2013-2014, Michael Robinton

This program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

1;
