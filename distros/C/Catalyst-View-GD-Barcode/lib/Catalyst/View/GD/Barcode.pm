package Catalyst::View::GD::Barcode;

use strict;

our $VERSION = '0.05';

my($Revision) = '$Id: Barcode.pm,v 1.5 2006/04/26 13:59:45 yanagisawa Exp $';

=head1 NAME

Catalyst::View::GD::Barcode - make it easy to use GD::Barcode in Catalyst's View

=head1 SYNOPSIS

Set string to be converted to barcode.

 $c->stash->{'barcode_string'} = '123456';

Set barcode type. The default is 'NW7'.

 $c->stash->{'barcode_type'} = 'NW7';

 COOP2of5 | Code39 | EAN13 | EAN8 | IATA2of5 | ITF | Industrial2of5 | Matrix2of5 | NW7 | QRcode 

Set barcode size option.

 $c->stash->{'barcode_size'} = 10;

 When the number of digit is insufficient, it buries by 0.

Set content type option. The default is 'png'.

 $c->stash->{'content_type'} = 'png';

 png | gif | jpeg 

Set any other GD::Barcode options.

 $c->stash->{'barcode_option'} = {NoText => 1}

Print the barcode.

 $c->forward('Catalyst::View::GD::Barcode');

=head1 METHODS

=over 2

=item gen_barcoed

Generate barcode using GD::Barcode.
You only need to set string and barcode type and no need to bother anything else.
If it fails, it returns the string in plain text.

=back

=cut


sub gen_barcode {
    my $self = shift;
    my $c = shift;
    my $str =  $c->stash->{'barcode_string'};
    my $type = $c->stash->{'barcode_type'};
    die "not integer barcode_size" if($c->stash->{'barcode_size'} =~ /\D/);
    my $size = sprintf('%%0%ss', $c->stash->{'barcode_size'} || length($c->stash->{'barcode_string'}));
    my $content_type = $c->stash->{'content_type'} || 'png';
    my $opt = {};
    if($str) {
	##### set option
	my $size = sprintf('%%0%ss', $c->stash->{'barcode_size'});
	$opt = $c->stash->{'barcode_option'};
	$type ||= 'EAN13';
	my($Barcode);
	my $m_name = "GD::Barcode::$type";
	eval("use $m_name;");
	if($@) {
	    die "Do not install Barcord module $m_name";
	}
	if ($type eq 'EAN13') {
	    $Barcode = $m_name->new($self->calc_checkdigit(sprintf('%012s', $str)));
	} elsif ($type eq 'EAN8') {
	    $Barcode = $m_name->new($self->calc_checkdigit(sprintf('%07s', $str)));
	}elsif($type eq 'Code39') {
	    $Barcode = $m_name->new('*'. sprintf($size, $str).'*');
	} elsif($type eq 'NW7') {
	    $Barcode = $m_name->new('B'.sprintf($size, $str).'B');
	} elsif($type eq 'QRcode') {
	    $Barcode = $m_name->new(sprintf($size,$str), $opt);
	}else {
	    $Barcode = $m_name->new(sprintf($size,$str));
	}
	unless($Barcode) {
	    $c->res->header('Content-Type' => 'text/plain');
	    return $GD::Barcode::errStr;
	} else {
	    $c->res->header('Content-Type' => 'image/'.$content_type);
	    return $Barcode->plot(%{$opt})->$content_type();
	}
    }else{
	$c->res->header('Content-Type' => 'image/'.$content_type);
	return 'No Barcode String';
    }
}

=over 2

=item process

Set code in $c->res->body().

=back

=cut

sub process{
    my $self = shift;
    my $c = shift;
    $c->res->body($self->gen_barcode($c));
    return 1;
}

=over 2

=item calc_checkdigit

Returns the calculated check digit.

=back

=cut

sub calc_checkdigit {
    my $self = shift;
    my $str = shift;
    my($checkdigit) = (10 - ((((substr($str, 1, 1) + substr($str, 3, 1) + substr($str, 5, 1) + substr($str, 7, 1) + substr($str, 9, 1) + substr($str, 11, 1)) * 3) + (substr($str, 0, 1) + substr($str, 2, 1) + substr($str, 4, 1) + substr($str, 6, 1) + substr($str, 8, 1) + substr($str, 10, 1))) % 10)) % 10;
    if (length($str) == 12) {
	$str .= $checkdigit;
    } elsif (length($str) == 13) {
	substr($str, 12, 1) = $checkdigit;
    }
    return $str;
}

=head1 SEE ALSO

L<Catalyst>

=head1 AUTHOR

Toshimitu Yanagisawa, C<yanagisawa@shanon.co.jp>

=head1 COPYRIGHT AND LICENSE

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
