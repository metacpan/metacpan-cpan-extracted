#
# This file is part of Audio-MPD-Common
#
# This software is copyright (c) 2007 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use strict;
use warnings;

package Audio::MPD::Common::Stats;
# ABSTRACT: class representing MPD stats
$Audio::MPD::Common::Stats::VERSION = '2.003';
use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ Int };


# -- public attributes


has artists     => ( ro, isa=>Int, required );
has albums      => ( ro, isa=>Int, required );
has songs       => ( ro, isa=>Int, required );
has uptime      => ( ro, isa=>Int, required );
has playtime    => ( ro, isa=>Int, required );
has db_playtime => ( ro, isa=>Int, required );
has db_update   => ( ro, isa=>Int, required );


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Audio::MPD::Common::Stats - class representing MPD stats

=head1 VERSION

version 2.003

=head1 DESCRIPTION

The MPD server maintains some general information. Those information can
be queried with the mpd modules. Some of those information are served to
you as an L<Audio::MPD::Common::Stats> object.

An L<Audio::MPD::Common::Stats> object does B<not> update itself
regularly, and thus should be used immediately.

Note: one should B<never> ever instantiate an L<Audio::MPD::Common::Stats>
object directly - use the mpd modules instead.

=head1 ATTRIBUTES

=head2 $stats->artists;

Number of artists in the music database.

=head2 $stats->albums;

Number of albums in the music database.

=head2 $stats->songs;

Number of songs in the music database.

=head2 $stats->uptime;

Daemon uptime (time since last startup) in seconds.

=head2 $stats->playtime;

Time length of music played.

=head2 $stats->db_playtime;

Sum of all song times in the music database.

=head2 $stats->db_update;

Last database update in UNIX time.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
