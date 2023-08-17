package App::optex::textconv::pdf;

our $VERSION = '1.06';

=encoding utf-8

=head1 NAME

textconv::pdf - optex::textconv submodule to handle PDF files

=head1 VERSION

Version 1.06

=head1 SYNOPSIS

optex command -Mtextconv

optex command -Mtextconv::pdf::set(pagebreak=number) -Mtextconv

=head1 DESCRIPTION

This is a submodule for L<App::optex::textconv> to handle PDF
documents.  You don't have to call it explicitly.

=head1 OPTIONS

To set options, call C<textconv::pdf> module before C<textconv>.

    optex command -Mtextconv::pdf::set(pagebreak=number) -Mtextconv ...

Accept following parameters.

=over 4

=item B<pagebreak>=I<type>

Takes one of follwoing I<type>s.  Default is C<rule>.

=over 4

=item B<rule>

Draw horizontal rule.
Default is successive 78 characters of C<->.
Looks B<width> and B<mark> parameter.

=item B<number>

Print page number.  Format is defined by B<format> parameter.

=item B<np>

Print ASCII new page code (C<^L>, C<0x0c>).

=back

=item B<width>

Set length of horizontal rule.
Default is 78.

=item B<mark>

Set character to used in horizontal rule.
Default is C<->.

=item B<format>

Define format for B<number> parameter.
Default is C<[ Page %d ]>.

=item B<raw>

Use C<-raw> option with L<pdftotext(1)> command.

=back

=head1 SEE ALSO

L<https://github.com/kaz-utashiro/optex>

L<https://github.com/kaz-utashiro/optex-textconv>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2019-2022 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use v5.14;
use warnings;
use Carp;

use App::optex::textconv::Converter 'import';

our @CONVERTER = (
    [ qr/\.pdf$/i => \&to_text ],
    );

our %param = (
    pagebreak => 'rule',
    width     => 78,
    mark      => '-',
    format    => '[ Page %d ]',
    raw       => 0,
    );

my %pagebreak = (
    rule => sub {
	my $rule = $param{mark} x $param{width} . "\n\n";
	sub { $rule };
    },
    number => sub {
	my $n = 1;
	my $format = $param{format} . "\n\n";
	sub { sprintf $format, $n++ };
    },
    np => sub {
	sub { "\f" };
    },
    );

sub to_text {
    my $file = shift;
    my $type = ($file =~ /\.(pdf)$/i)[0] or return;
    my $break = $pagebreak{$param{pagebreak}}->();
    my $pdftotext = 'pdftotext';
    $pdftotext .= ' -raw' if $param{raw};
    local $_ = qx{ $pdftotext -q \"$file\" - };
    s/\f/$break->()/ger;
}

sub set {
    my %opt = @_;
    while (my($k, $v) = each %opt) {
	exists $param{$k} or next;
	$param{$k} = $v;
    }
}

1;
