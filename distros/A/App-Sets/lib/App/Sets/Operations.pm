package App::Sets::Operations;
$App::Sets::Operations::VERSION = '0.976';


use strict;
use warnings;

# ABSTRACT: set operations in Perl

use English qw( -no_match_vars );
use 5.010;
use App::Sets::Iterator;

sub intersect {
   my ($l, $r) = @_;
   my ($lh, $rh);
   return App::Sets::Iterator->new(
      sub {
         while ('necessary') {
            $lh //= $l->drop() // last;
            $rh //= $r->drop() // last;
            if ($lh eq $rh) {
               my $retval = $lh;
               $lh = $rh = undef;
               return $retval;
            }
            elsif ($lh gt $rh) {
               $rh = undef;
            }
            else {
               $lh = undef;
            }
         } ## end while ('necessary')
         return undef;
      }
   );
} ## end sub intersect

sub union {
   my ($l, $r) = @_;
   my ($lh, $rh);
   return App::Sets::Iterator->new(
      sub {
         while (defined($lh = $l->head()) && defined($rh = $r->head())) {
            if ($lh eq $rh) {
               $r->drop();
               return $l->drop();
            }
            elsif ($lh lt $rh) {
               return $l->drop();
            }
            else {
               return $r->drop();
            }
         } ## end while (defined($lh = $l->head...
         while (defined($lh = $l->drop())) {
            return $lh;
         }
         while (defined($rh = $r->drop())) {
            return $rh;
         }
         return undef;
      }
   );
} ## end sub union

sub minus {
   my ($l, $r) = @_;
   my ($lh, $rh);
   return App::Sets::Iterator->new(
      sub {
         while (defined($lh = $l->head()) && defined($rh = $r->head())) {
            if ($lh eq $rh) {    # shared, drop both
               $r->drop();
               $l->drop();
            }
            elsif ($lh lt $rh) {    # only in left, OK!
               return $l->drop();
            }
            else {                  # only in right, go on
               $r->drop();
            }
         } ## end while (defined($lh = $l->head...
         return $l->drop();
      }
   );
} ## end sub minus

1;

__END__

=pod

=head1 NAME

App::Sets::Operations - set operations in Perl

=head1 VERSION

version 0.976

=head1 AUTHOR

Flavio Poletti <polettix@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2016 by Flavio Poletti polettix@cpan.org.

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
