package Apache2::ScoreboardIsFull;

use strict;
use warnings;

use Apache2::RequestRec;
use Apache2::RequestUtil;
use Apache2::Const -compile => qw( OK );
use Apache::Scoreboard;

our $VERSION = '0.01';


sub handler {
    my $r = shift;

    my $image        = Apache::Scoreboard->image( $r->pool );
    my $servers_left = $image->server_limit - scalar( @{ $image->pids } );
    if ( $servers_left == 0 ) {
        $r->pnotes( 'scoreboard_is_full' => 1 );
    }
    return Apache2::Const::DECLINED;
}


1;
__END__

=head1 NAME

Apache2::ScoreboardIsFull - set $r->pnotes('scoreboard_is_full' => 1) if no servers left

=head1 SYNOPSIS

  use Apache2::ScoreboardIsFull;

  PerlInitHandler Apache2::ScoreboardIsFull

Meanwhile, in a mod_perl handler elsewhere:

  if ($r->pnotes('scoreboard_is_full') {
      $r->log->emerg("No httpd children left. Call out the winged monkeys");
  }

=head1 DESCRIPTION

Sets scoreboard_is_full pnotes when there are no available httpd children.


=head1 SEE ALSO

Apache::Scoreboard, mod_perl

=head1 AUTHOR

Fred Moyer, E<lt>fred@redhotpenguin.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Fred Moyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
