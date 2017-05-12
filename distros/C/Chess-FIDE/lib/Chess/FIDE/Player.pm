package Chess::FIDE::Player;

use 5.008;
use strict;
use warnings FATAL => 'all';

use Exporter;
use Carp;

use base 'Exporter';

our %FIDE_defaults = (
	id        => -1,
	name      => 'Unknown',
	surname   => '',
	givenname => '',
	fed       => 'UNK',
	sex       => '',
	tit       => undef,
	wtit      => undef,
	otit      => undef,
	srtng     => undef,
	sgm       => undef,
	sk        => undef,
	rrtng     => undef,
	rgm       => undef,
	rk        => undef,
	brtng     => undef,
	bgm       => undef,
	bk        => undef,
	bday      => 0,
	flag      => '',
	fidename  => '',
);

our @EXPORT = qw(%FIDE_defaults);

our $AUTOLOAD;
our $VERSION = 1.22;

sub new ($;@) {

	my $class = shift;
    my %param = @_;

    my $player = {};
    bless $player, $class;
    for (keys %param) {
		unless (exists $FIDE_defaults{$_}) {
			warn "$_ is not recognized as a valid field, ignoring" if $ENV{CHESS_FIDE_VERBOSE};
			next;
		}
		$player->{$_} = defined $param{$_} ? $param{$_} : $FIDE_defaults{$_};
	}
	for (keys %FIDE_defaults) {
		$player->{$_} ||= $FIDE_defaults{$_};
	}
	$player->{fed} = 'UNK' if $player->{fed} eq '*';
	$player->{sex} ||= $player->{flag} =~ /^w/ ? 'F' : 'M';
	$player->{otit} =~ s/^\,// if $player->{otit};
	$player->{tit} = 'i'  if $player->{tit} && $player->{tit} eq 'm';
	$player->{tit} = 'wi' if $player->{tit} && $player->{tit} eq 'wm';
	$player->{tit} = uc($player->{tit}) . 'M'
		if $player->{tit} && $player->{tit} ne 'WH' && $player->{tit} !~ /m$/i;
	$player->{fed} = uc($player->{fed});
    return $player;
}

sub AUTOLOAD ($;$) {

	my $self  = shift;
	my $param = shift;

	my $method = $AUTOLOAD;
	$method = lc $method;
	my @path = split(/\:\:/, $method);
	$method = pop @path;
	return if $method =~ /^destroy$/;
	unless (exists $self->{$method}) {
		carp "No such method or property $method";
		return undef;
	}
	$self->{$method} = $param if ($param);
	$self->{$method};
}

1;

__END__

=head1 NAME

Chess::FIDE::Player - Parse player data from FIDE Rating List.

=head1 SYNOPSIS

  use Chess::FIDE::Player;
  my $player = Chess::FIDE::Player->new(%param);
  print $player->id() . "\n";
  $player->value('field');

=head1 DESCRIPTION

Chess::FIDE::Player - Parse player data from FIDE Rating List.
FIDE is the International Chess Federation that every month of the year releases a list of its rated members. The list contains about five hundred thousand entries. This module provides means of translation of every entry into a perl object containing all the fields.

=head2 METHODS

=over

=item new /Constructor/

$player = Chess::FIDE::Player->new(%param);

The constructor creates a hash reference, blesses it and fills it with parameters passed in %param. The parameters should be fields corresponding to %FIDE_defaults (see section 'EXPORT'). If a field is
not defined, a default value contained in %FIDE_defaults is used.

=item <AUTOLOAD>

 $player->property_name();
 $player->property_name($value);

Property names of the object are autoloaded into available methods.

First one retrieves a field in the $player object. If the field is not
valid (i.e. not contained in %FIDE_defaults, an undef is returned. Second
one sets the field to $value, and again in case of an invalid field
undef is returned. Otherwise the new value of the field is returned.

=back

=head2 EXPORT

=over

=item C<%FIDE_defaults>

 - hash of valid fields for the Player object and their default values.

=back

=head1 SEE ALSO

Chess::FIDE http://www.fide.com

=head1 AUTHOR

Roman M. Parparov, E<lt>romm@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2015 by Roman M. Parparov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

Fide Rating List is Copyright (C) by the International Chess Federation
http://www.fide.com

=cut
