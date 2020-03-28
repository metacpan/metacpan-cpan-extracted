#
# This file is part of Array-IntSpan
#
# This software is Copyright (c) 2014 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
##########################################################################
#
# Array::IntSpan::Fields - IntSpan array using integer fields as indices
#
# Author: Dominique Dumont
##########################################################################
# Copyright 2003 Dominique Dumont.  All rights reserved.
#
# This module is distributed under the Artistic 2.0 License. See
# https://www.perlfoundation.org/artistic-license-20.html
#
# For comments, questions, bugs or general interest, feel free to
# contact Dominique Dumont ddumont@cpan.org
##########################################################################

use strict;
use warnings;

package Array::IntSpan::Fields;
$Array::IntSpan::Fields::VERSION = '2.004';
use Array::IntSpan;
use Carp ;

use overload 
  # this emulate the usage of Intspan
  '@{}' => sub { return shift->{range} ;} ,
  # fallback on default behavior for all other operators
  fallback => 1 ;

sub new 
  {
    my $proto = shift ;
    my $class = ref($proto) || $proto;
    my $format = shift ;

    if (ref $format)
      {
        # in fact the user want a regular IntSpan
        return Array::IntSpan->new($format,@_);
      }

    my @temp = @_ ;
    my $self = {};
    bless $self, $class;
    $self->set_format($format) ;

    foreach my $i (@temp) 
      {
        $i->[0] = $self->field_to_int($i->[0]);
        $i->[1] = $self->field_to_int($i->[1]);
      }

    $self->{range}= Array::IntSpan->new(@temp) ;

    return $self;
  }

sub set_format
  {
    my ($self,$format) = @_ ;
    croak "Unexpected format : $format" unless 
      $format =~ /^[\d\.]+$/ ;

    $self->{format} = $format ;

    my @array = split /\./, $self->{format} ;
    # store nb of bit and corresponding bit mask
    $self->{fields} = [map { [$_, (1<<$_) -1 ]} @array ] ;
  }

sub int_to_field
  {
    my $self = shift ;
    my @all_int =  @_ ;
    my @result ;

    foreach my $int (@all_int)
      {
        my @res ;
        foreach my $f (reverse @{$self->{fields}})
          {
            unshift @res, ($f->[0] < 32 ? ($int & $f->[1]) : $int ) ;
            $int >>= $f->[0] ;
          }
        push @result, join('.',@res) ;
      }

    return wantarray ? @result : $result[0];
  }

sub field_to_int
  {
    my $self = shift ;

    my @all_field = @_;
    my @result ;

    foreach my $field (@all_field)
      {
        my $f = $self->{fields};
        my @array = split /\./,$field ;

        croak "Expected ",scalar @$f, 
          " fields for format $self->{format}, got ",
            scalar @array," in '$field'\n" unless @array == @$f ;

        my $res = 0 ;

        my $i =0 ;

        while ($i <= $#array)
          {
            my $shift = $f->[$i][0] ;
            croak "Field value $array[$i] too great. ",
              "Max is $f->[$i][1] (bit width is $shift)"
                if $shift<32 and $array[$i] >> $shift ;

            $res = ($res << $shift) + $array[$i++] ;
          }
        #print "field_to_int: changed $field to $res for format $self->{format}\n";
        push @result, $res ;
      }

    return wantarray ? @result : $result[0];
  }

sub get_range 
  {
    my ($self,$s_field,$e_field) = splice @_,0,3 ;
    my ($s, $e) = $self->field_to_int($s_field,$e_field) ;
    my @newcb = $self->adapt_range_in_cb(@_) ;

    my $got = $self->{range}->get_range($s,$e,@newcb) ;

    my $ret = bless {range => $got }, ref($self) ;
    $ret->set_format($self->{format}) ;
    return $ret ;
  }

sub lookup
  {
    my $self = shift;
    my @keys = $self->field_to_int(@_);
    $self->{range}->lookup(@keys) ;
  }

sub clear
  {
    my $self = shift;
    @{$self->{range}} = () ;
  }

sub consolidate
  {
    my ($self,$s_field,$e_field) = splice @_,0,3 ;
    my ($s, $e) = $self->field_to_int($s_field,$e_field) 
      if defined $s_field and defined $e_field;
    my @newcb = $self->adapt_range_in_cb(@_) if @_;

    return $self->{range}->consolidate($s,$e,@newcb) ;
  }


foreach my $method (qw/set_range set_consolidate_range/)
  {
    no strict 'refs' ;
    *$method = sub 
      {
        my ($self,$s_field,$e_field,$value) = splice @_,0,4 ;
        my ($s, $e) = $self->field_to_int($s_field,$e_field) ;
        my @newcb = $self->adapt_range_in_cb(@_) ;

        return $self->{range}->$method ($s, $e, $value, @newcb);
      };
  }

sub adapt_range_in_cb
  {
    my $self = shift;

    # the callbacks will be called with ($start, $end,$payload) or
    # ($start,$end)
    my @callbacks = @_ ; 

    return map
      {
        my $old_cb = $_; # required for closure to work
        defined $old_cb ?
          sub
            {
              my ($s_int,$e_int,$value) = @_ ;
              my ($s,$e) = $self->int_to_field($s_int,$e_int) ;
              $old_cb->($s,$e,$value);
            }
              : undef ;
      } @callbacks ;
  }

sub get_element
  {
    my ($self,$idx) = @_;
    my $elt = $self->{range}[$idx] || return () ;
    my ($s_int,$e_int,$value) = @$elt ;
    my ($s,$e) = $self->int_to_field($s_int,$e_int) ;

    return ($s,$e, $value) ;
  }

1;

__END__

=head1 NAME

Array::IntSpan::Fields -  IntSpan array using integer fields as indices

=head1 SYNOPSIS

  use Array::IntSpan::Fields;

  my $foo = Array::IntSpan::Fields
   ->new( '1.2.4',
          ['0.0.1','0.1.0','ab'],
          ['1.0.0','1.0.3','cd']);

  print "Address 0.0.15 has ".$foo->lookup("0.0.15").".\n";

  $foo->set_range('1.0.4','1.1.0','ef') ;

=head1 DESCRIPTION

C<Array::IntSpan::Fields> brings the advantages of C<Array::IntSpan>
to indices made of integer fields like an IP address and an ANSI SS7 point code.

The number of integer and their maximum value is defined when calling
the constructor (or the C<set_format> method). The example in the
synopsis defines an indice with 3 fields where their maximum values
are 1,3,15 (or 0x1,0x3,0xf).

This module converts the fields into integer before storing them into
the L<Array::IntSpan> module.

=head1 CONSTRUCTOR

=head2 new (...)

The first parameter defines the size of the integer of the fields, in
number of bits. For an IP address, the field definition would be
C<8,8,8,8>.

=head1 METHODS

All methods of L<Array::IntSpan> are available.

=head2 set_format( field_description )

Set another field description. Beware: no conversion or checking is
done. When changing the format, old indices may become illegal.

=head2 int_to_field ( integer )

Returns the field representation of the integer.

=head2 field_to_int ( field )

Returns the integer value of the field. May craok if the fields values
are too great with respect to the filed description.

=head1 AUTHOR

Dominique Dumont, ddumont@cpan.org

Copyright (c) 2003 Dominique Dumont. All rights reserved.

This module is distributed under the Artistic 2.0 License. See
https://www.perlfoundation.org/artistic-license-20.html

=cut

