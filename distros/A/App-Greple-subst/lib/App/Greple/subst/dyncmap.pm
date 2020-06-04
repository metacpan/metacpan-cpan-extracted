=encoding utf-8

=head1 NAME

-Msubst::dyncmap - Getopt::EX Dynamic colormap module

=head1 SYNOPSIS

option --subst-color-light \
  -Msubst::dyncmap \
  --colormap \
  --dyncmap \
  range=0-2,except=000:111:222,shift=3,even="555D/%s",odd="I;000/%s"

=head1 DESCRIPTION

Parameter is given in a form of B<name>=I<value> and connected by
comma.

=over 7

=item B<range>=I<s>-I<e>[:I<s>-I<e>[:I<s>-I<e>]]

RGB range. All range can be given like C<0-2:0-2:0-2>, or if the
number of range is less than three, last range is repeated.

Each RGB value is in the range of 0 to 5, and produces 6x6x6 216
colors.

=item B<except>

Specify exception value, like C<000:111:222>.

=item B<even>=I<colormap>

=item B<odd>=I<colormap>

Colormap string for even and odd index.  String is given to C<sprintf>
function with RGB parameter.

=item B<shift>=I<number>

Range is shifted by this value for odd index map.  Shifted value have
to be in the range of 0 to 5.

=item B<sort>=[I<none>,I<average>,I<luminance>]

Specify sort algorithm.  Default is B<average>.

=item B<reverse>=[0,1]

If true, map is reversed.

=back

=head1 SEE ALSO

L<Getopt::EX>, L<Getopt::EX::Colormap>

L<App::Greple>, L<App::Greple::subst>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright (C) 2020 Kazumasa Utashiro.

You can redistribute it and/or modify it under the same terms
as Perl itself.

=cut

package App::Greple::subst::dyncmap;

use v5.14;
use strict;
use warnings;

use Carp;
use Data::Dumper;
use List::Util qw(notall pairmap reduce sum);

##
## Dyamic colormap generator
##

sub dyncmap {
    my %opt = @_;
    for ($opt{range}) {
	my @range = pairmap { [ $a..$b ] } /([0-5])-([0-5])/g
	    or die "$_: range format error";
	push @range, $range[-1] while @range < 3;
	$_ = \@range;
    }
    my @cm = cmap(%opt);
    join ',', @cm;
}

sub combination {
    my $c = reduce {
	[ map { my @a = @$_; map { [ @a, $_ ] } @$b } @$a ];
    } [ [] ], @_;
    @$c;
}

sub rgb {
    if (notall { 0 <= $_ && $_ <= 5 } @_) {
	local $" = '';
	die "@_: Invalid RGB value";
    }
    my($r, $g, $b) = @_;
    if ($r == $g and $r == $b) {
	qw(L03 L07 L11 L15 L19 L23)[$r];
    } else {
	"$r$g$b";
    }
}

my %sort = (
    none => undef,
    average => sub {
	local $" = '';
	map  { $_->[0] }
	sort { $a->[1] <=> $b->[1] || $a->[2] cmp $b->[2] }
	map  { [ $_, sum(@$_), "@$_" ] }
	@_;
    },
    luminance => sub {
	map  { $_->[0] }
	sort { $a->[1] <=> $b->[1] }
	map  { [ $_, $$_[0]*30 + $$_[1]*59 + $$_[2]*11 ] }
	@_;
    },
    );

sub cmap {
    my %opt = (shift => 0, except => '', sort => 'average', @_);
    my @cm = combination @{$opt{range}};
    if (my %except = map { $_ => 1 } $opt{except} =~ /\b(\d\d\d)\b/g) {
	local $" = '';
	@cm = grep { not $except{"@$_"} } @cm;
    }
    if (my $algorithm = $opt{sort}) {
	exists $sort{$algorithm} or die "$algorithm: unknown algorithm";
	if (my $sort = $sort{$algorithm}) {
	    @cm = $sort->(@cm);
	}
    }
    @cm = reverse @cm if $opt{reverse};
    my @map = map {
	( sprintf($opt{even}, rgb(@$_) ),
	  sprintf($opt{odd},  rgb(map $_ + $opt{shift}, @$_) ) );
    } @cm;
}

1;

__DATA__

mode function

option --dyncmap &dyncmap($<shift>)
