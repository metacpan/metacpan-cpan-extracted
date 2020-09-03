package D;

use 5.008007;
use strict;
use warnings;

use Data::Dumper;
use Encode ();
use Carp ();
use Scalar::Util qw(blessed refaddr);
use B;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(du dw dn dustr dwstr dnstr);

our $VERSION = '0.05';

sub du {
  print STDERR dustr(@_);
}

sub dustr {
  my ($ref_data) = @_;
  $ref_data = _encode('UTF-8', $ref_data);
  my $d = Data::Dumper->new([$ref_data]);
  $d->Sortkeys(1)->Indent(1)->Terse(1);
  my $ret = $d->Dump;
  chomp $ret;
  my $carp_short_message = Carp::shortmess($ret);

  return $carp_short_message;
}

sub dw {
  print STDERR dwstr(@_);
}

sub dwstr {
  my ($ref_data) = @_;
  $ref_data = _encode("cp932",$ref_data);
  my $d = Data::Dumper->new([$ref_data]);
  $d->Sortkeys(1)->Indent(1)->Terse(1);
  my $ret = $d->Dump;
  chomp $ret;
  my $carp_short_message = Carp::shortmess($ret);

  return $carp_short_message;
}

sub dn {
  print STDERR dnstr(@_);
}

sub dnstr {
  my ($ref_data) = @_;
  my $d = Data::Dumper->new([$ref_data]);
  $d->Sortkeys(1)->Indent(1)->Terse(1);
  my $ret = $d->Dump;
  chomp $ret;
  my $carp_short_message = Carp::shortmess($ret);

  return $carp_short_message;
}

# Copy from Data::Recursive::Encode
our $DO_NOT_PROCESS_NUMERIC_VALUE = 0;
sub _apply {
    my $code = shift;
    my $seen = shift;
 
    my @retval;
    for my $arg (@_) {
        if(my $ref = ref $arg){
            my $refaddr = refaddr($arg);
            my $proto;
 
            if(defined($proto = $seen->{$refaddr})){
                 # noop
            }
            elsif($ref eq 'ARRAY'){
                $proto = $seen->{$refaddr} = [];
                @{$proto} = _apply($code, $seen, @{$arg});
            }
            elsif($ref eq 'HASH'){
                $proto = $seen->{$refaddr} = {};
                %{$proto} = _apply($code, $seen, %{$arg});
            }
            elsif($ref eq 'REF' or $ref eq 'SCALAR'){
                $proto = $seen->{$refaddr} = \do{ my $scalar };
                ${$proto} = _apply($code, $seen, ${$arg});
            }
            else{ # CODE, GLOB, IO, LVALUE etc.
                $proto = $seen->{$refaddr} = $arg;
            }
 
            push @retval, $proto;
        }
        else{
            push @retval, defined($arg) && (! $DO_NOT_PROCESS_NUMERIC_VALUE || ! _is_number($arg)) ? $code->($arg) : $arg;
        }
    }
 
    return wantarray ? @retval : $retval[0];
}
 
# Copy from Data::Recursive::Encode
sub _encode {
    my ($encoding, $stuff, $check) = @_;
    $encoding = Encode::find_encoding($encoding)
        || Carp::croak("unknown encoding '$encoding'");
    $check ||= 0;
    _apply(sub { $encoding->encode($_[0], $check) }, {}, $stuff);
}
 
# Copy from Data::Recursive::Encode
sub _is_number {
    my $value = shift;
    return 0 unless defined $value;
 
    my $b_obj = B::svref_2object(\$value);
    my $flags = $b_obj->FLAGS;
    return $flags & ( B::SVp_IOK | B::SVp_NOK ) && !( $flags & B::SVp_POK ) ? 1 : 0;
}

1;

=encoding utf8

=head1 NAME

D - Provides utility functions to encode data and dump it to STDERR.

=head1 SYNOPSIS
  
  use utf8;
  
  # Export du, dw, dn, dustr, dwstr, dnstr functions
  use D;
  
  # Reference data that contains decoded strings
  my $data = [{name => 'あ'}, {name => 'い'}];
  
  # Encode all strings in reference data to UTF-8 and dump the reference data to STDERR.
  du $data;

  # Encode all strings in reference data to cp932 and dump the reference data to STDERR.
  dw $data;

  # Dump reference data to STDERR without encoding.
  dn $data;

  # Examples of useful oneliner.
  use D;du $data;
  use D;dw $data;
  use D;dn $data;

  # Output example of du function.
  [
    {
      'name' => 'あ'
    },
    {
      'name' => 'い'
    }
  ] at test.pl line 7.

=head1 DESCRIPTION

D module provides utility functions to encode data and dump it to STDERR.

=head1 FEATURES

=over 2

=item * Export C<du> and C<dw> and C<dn> functions. Don't conflict debug command such as 'p' because these function names are consist of two characters.

=item * Encode all strings in reference data in C<dustr> and C<dwstr> function.

=item * C<du> is a short name of "dump UTF-8"

=item * C<dw> is a short name of "dump Windows cp932"

=item * C<dn> is a short name of "dump no encoding"

=item * Use C<Dump> method of L<Data::Dumper> to dump data

=item * Print line number and file name to STDERR

=item * Keys of hash of dumped data is sorted.

=item * Don't print "$VAR1 =" unlike L<Data::Dumper> default.

=back

=head1 FUNCTIONS

=head2 du

Encode all strings in reference data to UTF-8 and return string the reference data with file name and line number.

If the argument is not reference data such as a string, it is also dumped in the same way as reference data.
This function is exported.

  use D;
  my $data = [{name => 'あ'}, {name => 'い'}];
  du $data;

Following example is oneliner used. It can be used all functions.

  my $data = [{name => 'あ'}, {name => 'い'}];
  use D;du $data;

=head2 dw

Encode all strings in reference data to cp932 and dump the reference data to STDERR with file name and line number.

If the argument is not reference data such as a string, it is also dumped in the same way as reference data.
This function is exported.

  use D;
  my $data = [{name => 'あ'}, {name => 'い'}];
  dw $data;

=head2 dn

Dump reference data to STDERR without encoding with file name and line number.

If the argument is not reference data such as a string, it is also dumped in the same way as reference data.
This function is exported.

  use D;
  my $data = [{name => 'あ'}, {name => 'い'}];
  dn $data;

=head2 dustr

This function is return that UTF-8 encoded string.
This function is exported.

Following example is get the UTF-8 encoded string.

  use D;
  my $data = [{name => 'あ'}, {name => 'い'}];
  my $str = dustr $data;

=head2 dwstr

This function is return that cp932 encoded string.
This function is exported.

Following example is get the cp932 encoded string.

  use D;
  my $data = [{name => 'あ'}, {name => 'い'}];
  my $str = dwstr $data;

=head2 dnstr

This function is return that without encoded string.
This function is exported.

Following example is get the without encoded string.

  use D;
  my $data = [{name => 'あ'}, {name => 'い'}];
  my $str = dnstr $data;

=head1 Bug Report

L<https://github.com/YoshiyukiItoh/D>

=head1 SEE ALSO

L<Data::Dumper>, L<Carp>, L<Data::Recursive::Encode>

=head1 AUTHOR

Yoshiyuki Ito, E<lt>yoshiyuki.ito.biz@gmail.comE<gt>

Yuki Kimoto, E<lt>kimoto.yuki@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Yoshiyuki Ito, Yuki Kimoto

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.08.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
