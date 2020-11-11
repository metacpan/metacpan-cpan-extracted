package App::optex::xform;

our $VERSION = "1.01";

=encoding utf-8

=head1 NAME

xform - data transform filter module for optex

=head1 SYNOPSIS

    optex -Mxform

=head1 DESCRIPTION

B<xform> is a filter module for B<optex> command which transform STDIN
into different form to make it convenient to manipulate, and recover
to the original form after the process.

Transformed data have to be appear in exactly same order as original
data.

=head1 OPTION

=over 7

=item B<--xform-ansi>

Transform ANSI terminal sequence into printable string, and recover.

=item B<--xform-utf8>

Transform multibyte Non-ASCII chracters into singlebyte sequene, and
recover.

=back

=head1 EXAMPLE

    $ jot 100 | egrep --color=always .+ | optex -Mxform --xform-ansi column -x

=head1 SEE ALSO

L<Text::VisualPrintf::Transform>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use v5.14;
use warnings;
use Carp;
use utf8;
use open IO => 'utf8', ':std';
use Data::Dumper;

use Text::VisualPrintf::Transform;
use Text::VisualWidth::PP qw(vwidth);
use Text::ANSI::Fold::Util qw(ansi_width);

my @xform;

my %param = (
    ansi => {
	length => \&ansi_width,
	match  => qr/\e\[.*?(?:\e\[0*m)+(?:\e\[0*K)*/,
	visible => 2,
    },
    utf8 => {
	length => \&vwidth,
	match  => qr/\P{ASCII}+/,
	visible => 2,
    },
    );

sub encode {
    my %arg = @_;
    my $param = $param{$arg{mode}} or die "$arg{mode}: unkown mode";
    my $xform = Text::VisualPrintf::Transform->new(%$param);
    local $_ = do { local $/; <> };
    if ($xform) {
	$xform->encode($_);
	push @xform, $xform;
    }
    return $_;
}

sub decode {
    my %arg = @_;
    local $_ = do { local $/; <> };
    if (my $xform = pop @xform) {
	$xform->decode($_);
    } else {
	die "Not encoded.\n";
    }
    print $_;
}

1;

__DATA__

option default -Mutil::filter

option --xform-encode --psub __PACKAGE__::encode=mode=$<shift>
option --xform-decode --osub __PACKAGE__::decode
option --xform --xform-encode $<shift> --xform-decode

option --xform-ansi --xform ansi
option --xform-utf8 --xform utf8

#  LocalWords:  xform optex STDIN
