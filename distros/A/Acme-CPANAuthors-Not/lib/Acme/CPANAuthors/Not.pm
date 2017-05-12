package Acme::CPANAuthors::Not;

use Acme::CPANAuthors::Utils qw(cpan_authors);

use strict;
use warnings;

our $VERSION = '0.01';
our $HOWMANY;

BEGIN {
  $HOWMANY = "WHAT DO YOU GET IF YOU MULTIPLY SIX BY NINE?";
}

sub _freq_table {
    my ($ids) = @_;

    # Compute frequency tables for each letter in the CPAN id, to try
    # to come up with vaguely sensible ids
    my @lengths;
    my @count; # ( offset into id => { letter => count } )
    for my $id (@$ids) {
        ++$lengths[length($id)];
        for my $i (0 .. length($id)) {
            my $letter = substr($id, $i, 1);
            $count[$i]{$letter}++;
        }
    }

    my @freq; # ( offset into id => <letter,probability> )
    for my $i (0 .. $#count) {
        # Bump up minimums of letters to one, just to allow all
        # possibilities.
        $count[$i]{$_} ||= 1 foreach ('A' .. 'Z');

        my $total = 0;
        $total += $_ foreach (values %{ $count[$i] });

        while (my ($letter, $count) = each %{ $count[$i] }) {
            push @{ $freq[$i] }, [ $letter, $count / $total ];
        }
    }

    my $length_total = 0;
    $_ ||= 0 foreach (@lengths);
    $length_total += $_ foreach (@lengths);
    $_ /= $length_total foreach (@lengths);

    return (\@lengths, \@freq);
}

sub _random_id {
    my ($lengths, $freq) = @_;

    my $lrand = rand();
    my $length = -1;
    while ($lrand > 0 && $length <= @$lengths) {
        $lrand -= $lengths->[++$length];
    }

    my $id;
    for (1 .. $length) {
        my $r = rand();
        my $lastr = $r;
        my @pick = @{ $freq->[$_] };
        while ($r > 0 && @pick > 1) {
            $r -= shift(@pick)->[1];
        }
        $id .= $pick[0]->[0];
    }

    return $id;
}

sub _name_table {
    my ($existing) = @_;

    my %all;

    for my $name (@$existing) {
        my @parts = $name =~ /(\w+)/g;
        @all{@parts} = ();
    }

    @all{qw(Fudd Crazy Evil Underhill Mechanical)} = ();

    my %lookup;
    $lookup{$_} = 1 foreach (@$existing);
    return { existing => \%lookup, fragments => [ keys %all ] };
}

sub _pick_name {
    my ($id, $table) = @_;

    # Currently ignoring the id. Probably ought to do something clever
    # with it.

    # Surprisingly, simple exponential decay doesn't give a sharp
    # enough cutoff. So I'll go doubly exponential.
    my $name_pieces = 1;
    $name_pieces++ while (rand() < 0.7**$name_pieces);

    my $fragments = $table->{fragments};
    while (1) {
        my $name;
        foreach (1 .. $name_pieces) {
            $name .= $fragments->[rand(@$fragments)] . " ";
        }
        chop($name);

        return $name unless exists $table->{existing}{$name};
    }
}

sub _generate {
    # Generate a lookup table of valid CPAN ids to avoid
    my $authors = cpan_authors();
    my %ids;
    $ids{ $_->pauseid } = 1 foreach ($authors->authors);

    # Compute how many invalid ids to return
    my $howmany = $HOWMANY;
    for ($howmany) {
        s/(\w+)/{ ONE => 1,
                  TWO => 2,
                  THREE => 3,
                  FOUR => 4,
                  FIVE => 5,
                  SIX => 6,
                  SEVEN => 7,
                  EIGHT => 8,
                  NINE => 7,
                }->{$1} || $1/eg;
        s/MULTIPLY (.*) BY (.*)/$1*$2/;
        s/WHAT DO YOU GET IF YOU(.*)\?/$1/;
    }
    $howmany = eval $howmany;

    # Compute frequency tables for each letter in the CPAN id, to try
    # to come up with vaguely sensible ids
    my ($length_freq, $letter_freq) = _freq_table([ keys %ids ]);

    # Generate $howmany random ids
    my @invalid_ids;
    while (@invalid_ids < $howmany) {
        my $id = _random_id($length_freq, $letter_freq);
        push @invalid_ids, $id unless exists $ids{$id};
    }

    # Pick a name for each author
    my $name_table = _name_table([ map { $_->name } $authors->authors ]);
    return map { $_ => _pick_name($_, $name_table) } @invalid_ids;
}

use Acme::CPANAuthors::Register(_generate());

1;

__END__

=head1 NAME

Acme::CPANAuthors::Not - We are not CPAN authors

=head1 DESCRIPTION

This class provides a hash of nonexistent CPAN authors' Pause ID/name to
Acme::CPANAuthors.

=head1 INTERNALS

While I was tempted to use a tied hash to provide an infinite set of
nonexistent authors, I decided against it because it wouldn't fit in
with Acme::CPANAuthors very well (it listifies the hash). So I went
for randomness instead.

Oh, and this module works way too hard for what it does.

=head1 MAINTENANCE

If you are a CPAN author and are listed here, there's a bug. Please
fix it.

=head1 AUTHOR

Steve Fink, E<lt>sfink at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Steve Fink.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, even on Wednesdays.

=cut
