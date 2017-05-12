package DCOP::Amarok;

use 5.008001;
use strict;
use warnings;

require DCOP;
our @ISA = qw(DCOP);

our $VERSION = '0.036';

sub new() {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my %params = @_;
	my $self  = $class->SUPER::new(%params, target => "amarok" );
	bless ($self, $class);
	return $self;
}

1;
__END__

=head1 NAME

DCOP::Amarok- Perl extension to speak to an amaroK object via system's DCOP.

=head1 SYNOPSIS

  use DCOP::Amarok;
  $player = DCOP::Amarok->new();


=head1 DESCRIPTION

This module is a quick hack to get an interface between perl and Kde's DCOP,
since Kde3.4's perl bindings are disabled. This suite talks to 'dcop'.
DCOP::Amarok talks directly to the player object of amaroK. This is meant to be a
superclass for DcoP::Amarok::Player.

=head1 AUTHOR

Juan C. Muller, E<lt>jcmuller@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Juan C. Muller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
