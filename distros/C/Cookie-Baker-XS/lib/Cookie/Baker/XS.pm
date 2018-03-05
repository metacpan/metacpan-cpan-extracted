package Cookie::Baker::XS;

use 5.008001;
use strict;
use warnings;
use base qw/Exporter/;

our $VERSION = "0.09";
our @EXPORT_OK = qw/crush_cookie/;

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__

=encoding utf-8

=head1 NAME

Cookie::Baker::XS - boost Cookie::Baker's crush_cookie

=head1 SYNOPSIS

    use Cookie::Baker::XS qw/crush_cookie/;
    
    my $cookies_hashref = crush_cookie($headers->header('Cookie'));

=head1 DESCRIPTION

Cookie::Baker::XS provides cookie string parser that implemented by XS.
This modules only provides parser, does not have a generator function.

For more details, see L<Cookie::Baker>'s document

=head1 BENCHMARK

  ## length($cookie) == 675
  Benchmark: running pp, xs for at least 1 CPU seconds...
          pp:  1 wallclock secs ( 1.08 usr +  0.00 sys =  1.08 CPU) @ 16592.59/s (n=17920)
          xs:  1 wallclock secs ( 1.05 usr +  0.00 sys =  1.05 CPU) @ 182043.81/s (n=191146)
         Rate   pp   xs
  pp  16593/s   -- -91%
  xs 182044/s 997%   --
  
  ## length($cookie) == 17
  Benchmark: running pp, xs for at least 1 CPU seconds...
          pp:  2 wallclock secs ( 1.05 usr +  0.01 sys =  1.06 CPU) @ 201749.06/s (n=213854)
          xs:  0 wallclock secs ( 1.19 usr +  0.01 sys =  1.20 CPU) @ 1042617.50/s (n=1251141)
          Rate   pp   xs
  pp  201749/s   -- -81%
  xs 1042618/s 417%   --

=head1 SEE ALSO

L<Cookie::Baker>

=head1 LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

=cut

