package Acme::Coro::Suke;
use strict;
use warnings;
use utf8;
our $VERSION = '0.01';

use Coro;
use Encode;
use base qw/Exporter/;
our @EXPORT = qw/benzo/;

our $SERIF = Encode::encode('utf-8', "うわぁ…べんぞうさんの中…すごくあったかいナリぃ… \n");

sub benzo(&) { ##
    my $sub = shift;
    async {
        Coro::on_enter {
            print $SERIF;
        };
        $sub->();
    };
}


1;
__END__

=encoding utf8

=head1 NAME

Acme::Coro::Suke - the only real corosuke in benzo

=head1 SYNOPSIS

  use Coro;
  use Acme::Coro::Suke;

  benzo {
      print "コロ助君、ワス幸せっス\n";
      cede;
      print "・・・\n";
  };

  print "1\n";
  cede; # inside to benzo
  print "2\n";
  cede; # and again


=head1 DESCRIPTION

This module emulate to corosuke x benzo.

=head1 AUTHOR

Masahiro Chiba E<lt>chiba@geminium.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
