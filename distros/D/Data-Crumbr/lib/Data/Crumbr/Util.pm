package Data::Crumbr::Util;
$Data::Crumbr::Util::VERSION = '0.1.2';
# ABSTRACT: utility functions for Data::Crumbr
use strict;
use Carp;
use Scalar::Util qw< reftype blessed >;

sub json_leaf_encoder {
   require B;
   return \&_json_leaf_encode;
}

{
   my $slash_escaped;

   BEGIN {
      $slash_escaped = {
         0x22 => '"',
         0x5C => "\\",
         0x2F => '/',
         0x08 => 'b',
         0x0C => 'f',
         0x0A => 'n',
         0x0D => 'r',
         0x09 => 't',
      };
   } ## end BEGIN

   sub _json_leaf_encode {
      return 'null' unless defined $_[0];

      my $reftype = ref($_[0]);
      return '[]' if $reftype eq 'ARRAY';
      return '{}' if $reftype eq 'HASH';
      return (${$_[0]} ? 'true' : 'false')
        if $reftype eq 'SCALAR';

      if (my $package = blessed($_[0])) {
         my $reftype = reftype($_[0]);
         return (${$_[0]} ? 'true' : 'false')
           if ($reftype eq 'SCALAR') && ($package =~ /bool/mxsi);
      }

      croak "unsupported ref type $reftype" if $reftype;

      my $number_flags = B::SVp_IOK() | B::SVp_NOK();
      return $_[0]
        if (B::svref_2object(\$_[0])->FLAGS() & $number_flags)
        && 0 + $_[0] eq $_[0]
        && $_[0] * 0 == 0;

      my $string = join '', map {
         my $cp = ord($_);

         if (exists $slash_escaped->{$cp}) {
            "\\$slash_escaped->{$cp}";
         }
         elsif ($cp >= 32 && $cp < 128) {    # ASCII
            $_;
         }
         elsif ($cp < 0x10000) {             # controls & BML
            sprintf "\\u%4.4X", $cp;
         }
         else {                              # beyond BML
            my $hi = ($cp - 0x10000) / 0x400 + 0xD800;
            my $lo = ($cp - 0x10000) % 0x400 + 0xDC00;
            sprintf "\\u%4.4X\\u%4.4X", $hi, $lo;
         }
      } split //, $_[0];
      return qq<"> . $string . qq<">;
   } ## end sub _json_leaf_encode
}

sub uri_encoder {
   require Encode;
   return \&_uri_encoder;
}

{
   my %is_unreserved;

   BEGIN {
      my @u = ('a' .. 'z', 'A' .. 'Z', '0' .. '9', qw< - _ . ~ >);
      %is_unreserved = map { $_ => 1 } @u;
   }

   sub _uri_encoder {
      my $octets = Encode::encode('UTF-8', $_[0], Encode::FB_CROAK());
      return join '',
        map { $is_unreserved{$_} ? $_ : sprintf('%%%2.2X', ord $_); }
        split //, $octets;
   } ## end sub _uri_encoder
}

sub id_encoder {
   return sub { $_[0] };
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Data::Crumbr::Util - utility functions for Data::Crumbr

=head1 VERSION

version 0.1.2

=head1 DESCRIPTION

Utility functions for Data::Crumbr.

=head2 INTERFACE

=over

=item B<< id_encoder >>

   my $encoder = id_encoder();

trivial encoding function that just returns its first argument (i.e. no
real encoding is performed).

=item B<< json_leaf_encoder >>

   my $encoder = json_leaf_encoder();

encoding function that returns a JSON-compliant value, only for leaf
values. It works on:

=over

=item *

plain strings, returned after JSON encoding (e.g. tranformation of
newlines, etc.)

=item *

empty array references, in which case string C<[]> is returned

=item *

empty hash references, in which case string C<{}> is returned

=item *

null values, in which case string C<null> is returned

=back

=item B<< uri_encoder >>

   my $encoder = uri_encoder();

encoding function that then encodes strings according to URI encoding
(i.e. percent-encoding).

=back

=head1 AUTHOR

Flavio Poletti <polettix@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Flavio Poletti <polettix@cpan.org>

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
