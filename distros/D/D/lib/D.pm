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

our @EXPORT = qw(du dw);

our $VERSION = '0.01';

# Encode data to UTF-8 and dump it to STDERR using warn function adn Data::Dumper.
sub du {
  my ($ref_data) = @_;
  $ref_data = _encode('UTF-8', $ref_data);
  my $ret = Dumper $ref_data;
  warn "$ret\n";
}

# Encode data to cp932 and dump it to STDERR using warn function adn Data::Dumper.
sub dw {
  my ($ref_data) = @_;
  $ref_data = _encode("cp932",$ref_data);
  my $ret = Dumper $ref_data;
  warn "$ret\n";
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
  
  # Export du and dw functions
  use D;
  
  # Reference data that contains decoded strings
  my $data = [{name => 'あ'}, {name => 'い'}];
  
  # Encode all strings to UTF-8 in data and dump it to STDERR using warn function and Data::Dumper.
  du $data;
  
  # Encode all strings to cp932 in data and dump it to STDERR using warn function and Data::Dumper.
  dw $data;

=head1 DESCRIPTION

D module provides utility functions to encode data and dump it to STDERR.

=head1 FEATURES

=over 2

=item * Export C<du> and C<dw> functions. These function names are consist of two characters. Don't conflict debug command 'p'.

=item * C<du> is a short name of "dump UTF-8"

=item * C<dw> is a short name of "dump Windows cp932"

=item * Can wirte dump operation by onliner: useD;du $data; useD;dw $data;

=item * Encode all strings in reference data

=item * Use Data::Dumper::Dumper function to dump data

=item * Use warn function to print STDERR

=back

=head1 EXPORT

Export C<du> and C<dw> functions.

=head1 FUNCTIONS

=head2 du

  du $data;

Encode all strings in reference data to UTF-8 and dump it to STDERR using warn function and L<Data::Dumper>.

=head2 dw

Encode all strings in reference data to cp932 and dump it to STDERR using warn function and L<Data::Dumper>.

=head1 Bug Report

L<https://github.com/YoshiyukiItoh/D>

=head1 SEE ALSO

L<Data::Dumper>, L<Data::Recursive::Encode>

=head1 AUTHOR

yoshiyuki ito, E<lt>yoshiyuki.ito.biz@gmail.comE<gt>

Yuki Kimoto, E<lt>kimoto.yuki@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by yoshi, Yuki Kimoto

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.08.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
