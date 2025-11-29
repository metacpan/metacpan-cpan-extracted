package App::optex::xform;

our $VERSION = "1.05";

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

Transform multibyte Non-ASCII chracters into single-byte sequene, and
recover.

=item B<--xform-bin>

Transform non-printable binary characters into printable string, and
recover.

=item B<--xform-visible>=I<0|1|2>

Specify the character set used for transformation. This option overrides
the default C<visible> parameter of C<Text::Conceal>.

=over 4

=item B<0>

Use both printable and non-printable characters.

=item B<1>

Use printable characters first, then non-printable characters if needed.

=item B<2>

Use only printable characters (default).

=back

This option can be combined with any xform mode (ansi, utf8, bin, generic).

=back

=head1 EXAMPLE

    $ jot 100 | egrep --color=always .+ | optex column -Mxform --xform-ansi -x

Use C<--xform-visible> to control character set used for transformation:

    $ optex -Mxform --xform-visible=2 --xform-ansi cat colored.txt

    $ optex -Mxform --xform-visible=1 --xform-utf8 command

=head1 SEE ALSO

L<App::optex::xform>, L<https://github.com/kaz-utashiro/optex-xform>,

L<App::optex>, L<https://github.com/kaz-utashiro/optex>,
L<https://qiita.com/kaz-utashiro/items/2df8c7fbd2fcb880cee6>

L<Text::Conceal>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2020-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use v5.14;
use warnings;
use Carp;
use utf8;
use open IO => 'utf8', ':std';
use Data::Dumper;
use Hash::Util qw(lock_keys);

use Text::Conceal;
use Text::VisualWidth::PP qw(vwidth);
use Text::ANSI::Fold::Util qw(ansi_width);

my %concealer;

my %option = (
    visible => undef,
);
lock_keys(%option);

my %param = (
    ansi => {
	length  => \&ansi_width,
	match   => qr/\e\[.*?(?:\e\[0*m)+(?:\e\[0*K)*/,
	visible => 2,
    },
    utf8 => {
	length  => \&vwidth,
	match   => qr/\P{ASCII}+/,
	visible => 2,
    },
    binary => {
	length  => sub { length $_[0] },
	match   => qr/[^\x0a\x20-\x7e]+/a,
	visible => 2,
	binmode => ':raw',
    },
    generic => {
	length  => sub { length $_[0] },
	match   => qr/.+/,
	visible => 2,
    },
    );

sub encode {
    my %arg = @_;
    my $mode = $arg{mode};
    my $param = { %{$param{$mode}} } or die "$mode: unkown mode\n";
    my $binmode = delete $param->{binmode};
    # Override parameters with user-specified options
    for my $key (grep { defined $option{$_} } keys %option) {
	$param->{$key} = $option{$key};
    }
    my $conceal = Text::Conceal->new(%$param);
    $concealer{$mode} and die "$mode: encoding repeated\n";
    if ($binmode) {
	binmode STDIN, $binmode or die "$binmode: $!";
    }
    local $_ = do { local $/; <> };
    $_ // die $!;
    if ($conceal) {
	$conceal->encode($_);
	$concealer{$mode} = $conceal;
    }
    return $_;
}

sub decode {
    my %arg = @_;
    my $mode = $arg{mode};
    $param{$mode} or die "$mode: unkown mode\n";
    if (my $binmode = $param{binmode}) {
	binmode STDIN, $binmode;
    }
    local $_ = do { local $/; <> } // return;
    if (my $conceal = $concealer{$mode}) {
	$conceal->decode($_);
    } else {
	die "$mode: not encoded\n";
    }
    use Encode ();
    $_ = Encode::decode('utf8', $_) if not utf8::is_utf8($_);
    print $_;
}

sub set {
    while (my($k, $v) = splice(@_, 0, 2)) {
	exists $option{$k} or next;
	$option{$k} = $v;
    }
    ();
}

1;

__DATA__

mode function

autoload -Mutil::filter --osub --psub

option --xform-visible &set(visible=$<shift>)

option --xform-encode --psub __PACKAGE__::encode(mode=$<shift>)
option --xform-decode --osub __PACKAGE__::decode(mode=$<shift>)

option --xform \
	--xform-encode $<copy(0,1)> \
	--xform-decode $<move(0,1)>

option --xform-ansi --xform ansi
option --xform-utf8 --xform utf8
option --xform-bin  --xform binary

#  LocalWords:  xform optex STDIN
