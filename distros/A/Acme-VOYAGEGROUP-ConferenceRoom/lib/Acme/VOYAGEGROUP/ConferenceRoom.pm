package Acme::VOYAGEGROUP::ConferenceRoom;
use 5.008005;
use strict;
use warnings;
use Carp;
use utf8;
use UNIVERSAL::require;
use parent 'Exporter';

binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

our $VERSION = "0.01";
our @EXPORT = qw/ conference_room /;

use constant FLOOR_PLAN => <<'EOS';
.---------------.---------------------.
|               |                     |
|               |      .--.--.----.---|
|               |      |  |  |    |   |
|               |---.  |  |--|    |   |
|               |   |  '--'  '----|   |
|               |---'-.          .'---|
|               |     |          |    |
'---------------'-----'.--.--.  .'----|
                       |     |  |     |
                       |--.--|  |--.--|
                       |  |  |  |  |  |
                       '--'--'  '--'--|
                                      |
                         .------------|
                         |            |
                         |            |
                         '------------'
EOS

my %PROCESS_OF = (
    pangea => {
        lines         => [1..7],
        normalization => qr/^ぱんげあ|パンゲア$/ms,
        position      => qr{ ^(\|/*)\s }x,
        direction     => 'head',
    },
    megallanica => {
        lines         => [3..4],
        normalization => qr/^めがらにか|メガラニカ$/ms,
        position      => qr{ ^(\|\s+\|[^\|]+\|/*)\s }x,
    },
    mu => {
        lines         => [3],
        normalization => qr/^むー|ムー$/ms,
        position      => qr{ \s(/*\|\s+\|\s+\|)$ }x,
    },
    ultima => {
        lines         => [5],
        normalization => qr/^うるてぃま|ウルティマ$/ms,
        position      => qr{ ^(\|\s+\|/*)\s }x,
    },
    atlantis => {
        lines         => [3..4],
        normalization => qr/^あとらんてぃす|アトランティス$/ms,
        position      => qr{ \s(/*\|\s+\|)$ }x,
    },
    pacifis => {
        lines         => [3..5],
        normalization => qr/^ぱしふぃす|パシフィス$/ms,
        position      => qr{ \s(/*\|)$ }x,
    },
    zipang => {
        lines         => [7],
        normalization => qr/^じぱんぐ|ジパング$/ms,
        position      => qr{ ^(\|\s+\|/*)\s }x,
    },
    lemuria => {
        lines         => [7],
        normalization => qr/^れむりあ|レムリア$/ms,
        position      => qr{ \s(/*\|)$ }x,
    },
    africa => {
        lines         => [9],
        normalization => qr/^あふりか|アフリカ$/ms,
        position      => qr{ \s(/*\|\s+\|\s+\|)$ }x,
    },
    eurasia => {
        lines         => [9],
        normalization => qr/^ゆーらしあ|ユーラシア$/ms,
        position      => qr{ \s(/*\|)$ }x,
    },
    north_america => {
        lines         => [11],
        normalization => qr/^のーすあめりか|ノースアメリカ$/ms,
        position      => qr{ \s(/*\|)$ }x,
    },
    south_america => {
        lines         => [11],
        normalization => qr/^さうすあめりか|サウスアメリカ$/ms,
        position      => qr{ \s(/*\|\s+\|)$ }x,
    },
    australlia => {
        lines         => [11],
        normalization => qr/^おーすとらりあ|オーストラリア$/ms,
        position      => qr{ \s(/*\|\s+\|\s+\|\s+\|)$ }x,
    },
    antarctica => {
        lines         => [11],
        normalization => qr/^あんたーくてぃか|アンタークティカ$/ms,
        position      => qr{ \s(/*\|\s+\|\s+\|\s+\|\s+\|)$ }x,
    },
    ajito => {
        lines         => [15..16],
        normalization => qr/^あじと|アジト$/ms,
        position      => qr{ \s(/*\|)$ }x,
    },
);

my %OUTPUT_OF = (
    color        => 'Acme::VOYAGEGROUP::ConferenceRoom::Output::Color',
    json         => 'Acme::VOYAGEGROUP::ConferenceRoom::Output::JSON',
    xml          => 'Acme::VOYAGEGROUP::ConferenceRoom::Output::XML',
    message_pack => 'Acme::VOYAGEGROUP::ConferenceRoom::Output::MessagePack',
);

sub conference_room {
    my $room_name = shift or croak "Conference Room Not Found";
    my $output_type = shift || 'color';

    $room_name = _normalize($room_name);
    my $process = $PROCESS_OF{$room_name};
    croak "Conference Room Not Found: $room_name" unless $process;

    croak "Mistake Position: $process->{position}" if $process->{position} !~ m/\s(\^?).+?(\$?)\s/xms;
    my @lines = split "\n", FLOOR_PLAN;
    my($head, $tail) = ($1) ? ('', '/') : ('/', '');
    for my $i (@{ $process->{lines} }) {
        1 while $lines[$i] =~ s{$process->{position}}{$head$1$tail};
    }

    if ($output_type ne 'none') {
        my $module = $OUTPUT_OF{$output_type};
        croak "No Type: $output_type" unless $module;

        return $module->convert(\@lines) if $module->use;
    }

    join "\n", @lines;
}

sub _normalize {
    my $room_name = shift;

    for my $normalized_room_name (keys %PROCESS_OF) {
        return $normalized_room_name
            if $room_name =~ $PROCESS_OF{$normalized_room_name}->{normalization};
    }

    lc($room_name);
}

1;
__END__

=encoding utf-8

=head1 NAME

Acme::VOYAGEGROUP::ConferenceRoom - It's new $module

=head1 SYNOPSIS

    use Acme::VOYAGEGROUP::ConferenceRoom;

=head1 DESCRIPTION

Acme::VOYAGEGROUP::ConferenceRoom is ...

=head1 LICENSE

Copyright (C) monmon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

monmon E<lt>lesamoureuses@gmail.comE<gt>

=cut

