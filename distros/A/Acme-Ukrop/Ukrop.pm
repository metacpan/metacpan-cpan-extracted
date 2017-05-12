#  Content-Encoding: koi8-u
#  
#  $Id: Ukrop.pm,v 1.3 2008/04/11 17:05:15 dk Exp $

use strict;

package Acme::Ukrop;

use vars qw($VERSION);

$VERSION = '0.03';

my %n = (
	'взад'     => 'return',
	'або'      => 'else',
	'то'       => '{',
	'отож'     => '}',
	'так'      => '',
	'нехай'    => 'my',
	'кажи'     => 'print',
	'дiйство'  => 'sub',
	'доки'     => 'while',
	'якщо'     => 'if',
	'довжина'  => 'length',
	'геть'     => 'break',
	'вiдрiжемочи⌡що'=> 'chomp',
);

my $k  = join('|', sort keys %n);
my $nc = qr/[^a-zA-Z\x80-\xff]/;
$k = qr/(^|$nc)($k)(?=$|$nc)/;
use Filter::Simple sub { s/$k/$1$n{$2}/gs } ;

1;

=pod

=encoding koi8-u

=head1 NAME

Acme::Ukrop - ukrop parser

=head1 DESCRIPTION

Первый Настоящий Укропопарсер магически придает программам написанным на Укропе
все возможности перла.

=head1 SYNOPSIS

	use Acme::Ukrop;
	доки (<>) то
		вiдрiжемочи⌡що;
		кажи "ти казав: $_\n";
	так отож

=head1 SEE ALSO

http://community.livejournal.com/ru_ukrop/

=head1 THANKS

Kiev.pm for help with inseminating the Ukrop.

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=cut
