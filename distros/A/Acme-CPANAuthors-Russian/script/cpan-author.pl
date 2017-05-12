#!/usr/bin/perl
use utf8; # encoding="utf-8"
use strict;
no  warnings;

my $NAME = [
	qr/Aleksandar/,
	qr/Aleksandr Guidrevitch/,
	qr/Alex$/,
	qr/Alexander Lourier/,
	qr/Alex Noso/,
	qr/Alex Prota/,
	qr/Alexe[iy]/,
	qr/Aleksey/,
	qr/Anatoly/,
	qr/Andre[iy]/,
	qr/Andrew (?:Maltsev|Shitov|V\. Ma)/,
	qr/Anton\b/,
	qr/Artur Penttinen/,
	qr/Boris Sukholitko/,
	qr/Denis \w+[oe]v\b/,
	qr/Denis S/,
	qr/(?:Evdokimov|Arapov) Denis/,
	qr/Dmitr[iy]/,
	qr/Egor/,
	qr/Eugen Konkov/,
	qr/Eugen Sob/,
	qr/Gregory (?:A|Be)/,
	qr/Igor/,
	qr/Ilya/,
	qr/Ivan/,
	qr/Kirill/,
	qr/kostya/,
	qr/Konstantin/,
	qr/Maxim\b/,
	qr/Mishka/,
	qr/Mons Anderson/,
	qr/Nic?kolay/,
	qr/Oleg/,
	qr/Pavel/,
	qr/Ruslan/,
	qr/Serge[iy]/,
	qr/Timur/,
	qr/Vadim/,
	qr/Victor (?:M|\w+[oe]v\b)/,
	qr/Vladimir/,
	qr/Vladislav/,
	qr/Vyacheslav/,
	qr/Walery/,
	qr/Yur[iy]/,
	qr/Zaha/,
	qr/Zoffix/,
	qr/Irakliy Sunguryan/,
	qr/Daniil/,
	
	qr/Anastasiya Deeva/,
	
	qr/[а-я]+/,
];

print
	map  { @$_ }
	grep { warn scalar @$_ }
	[
		# for module
		map  { sprintf "%-9s => '%s',\n", grep { defined } @$_{'pause', 'name', 'email'} }
		sort { $a->{'pause'} cmp $b->{'pause'} }
		
		# for list
		#~ map  { join("\t", grep { defined } @$_{'id', 'name', 'pause', 'author', 'email', 'url'}), "\n" }
		
		# check email
		#~ map  { qq{"$_->{'pause'}" $_->{'email'}\n} }
		#~ grep { $_->{'email'} && $_->{'email'} !~ /CENSORED/ && $_->{'email'} !~ /\.ru$/ }
		
		# cpan author
		grep { $_->{'author'} }
		
		# not cpan author, have pause id
		# grep {!$_->{'author'} }
		
		# ru
		grep { $_->{'pause'} eq 'STEALTHY' and $_->{'author'}=0; 1}
		grep { $_->{'pause'} !~ /^(KORSHAK|AGNISLAV|ZERO|ZWON|SODASODA|CUB|DZHARIY|IHEFFNER|QUEVLAR|VTI|GUGU|EJS|GRUBER|EGORSH|MVUETS|BEROV|CYBER|NIKIP|TTOD|OMEGA|DRINCHEV|YAKWOO|PLCGI|MADZ|VMS|SHTATLAND|IVAN|ILYA|GREGORY|ERIC|DIMRUB|ANDREI|AXS|MOO|ICHLADIL|IZUT|IKETRIS|IVANS|ITUB|IVANWILLS|IVANWONG|PAVELH|INITDOTD|RUSSOZ)$/ }
		
		grep { $_->{'email'} !~ /ua$/ }
		grep { $_->{'email'} !~ /bg$/ }
		grep { $_->{'email'} !~ /by$/ }
		grep { $_->{'email'} !~ /ws$/ }
		grep { $_->{'email'} !~ /cz$/ }
		
		# ua
		# grep { $_->{'pause'} =~ /^ZERO|CUB|VTI|GUGU|EJS|GRUBER|MVUETS|DARKNOS|DZHARIY$/ || $_->{'email'} =~ /ua$/ }
		
		# cyrillic
		grep {
			my $name = $_->{'name'};
			scalar grep { $name =~ /$_/ } @$NAME;
		}
	
		# no
		# grep { $_->{pause} !~ /^BDULFER$/ }
		# grep { $_->{pause} =~ /^KIRILLM|KJETIL|SJN|MRAMBERG|KRN|ANDREMAR|TRONDMM|ARNE|EIDOLON|NICOMEN|COSIMO|AFF|ESPIZO$/ || $_->{'email'} =~ /no$/ }
		
		map  {
			my($url,  $name ) = $_->[ 1] =~ /<a href="([^"]+)">([^<]+)/; $name  ||= $_->[ 1]; $name =~ s/\s+$//; $name =~ s/&[^;]+;//sg;
			my($url2, $pause) = $_->[-1] =~ /<a href="([^"]+)">([^<]+)/; $pause ||= $_->[-1];
			
			+{
				'id'     => $_->[0],
				'name'   => $name,
				'url'    => $url,
				'email'  => $_->[2],
				'pause'  => $pause,
				'author' => $url2 ? 1 : 0,
			};
		}
		map  {
			[m{^ (\d+)\. \s ([^<]+ | <a.*?/a> | \s) .*? <a \s href="mailto:([^"]*)" .* -- \s+ (.*) $}x]
		}
		map  { split m{\s*<br />\s*} }
		grep { utf8::decode($_);1 }
		do { local $/; open my $fh, '<', 'get_utf8.html'; <$fh> } =~ m{Archives</a></h3>(.*)<h3><a id="mailinglists"}s
		# map  { $_->is_success ? $_->content =~ m{Archives</a></h3>(.*)<h3><a id="mailinglists"}s : () }
		# LWPUserAgent->new('timeout' => 15)->get('http://pause.perl.org/pause/query?ACTION=who_is')
	]
;

package LWPUserAgent; # XXX: bad UTF-8 encoding
use strict;
use base 'LWP::UserAgent';
use constant {
	FILE => '~get.html',
	EXP  => 24*60*60, # 1 day
};

sub get {
	my $self = shift;
	
	unlink FILE if -e FILE && time - [stat(FILE)]->[9] > EXP;
	
	if (my $data = eval { local $/; open my $fh, '<', FILE or die $!; <$fh> }) {
		warn 'cache';
		$_->request(HTTP::Request->new('GET', shift)), return $_ for HTTP::Response->new(200, 'OK', undef, $data);
	}
	for ($self->SUPER::get(@_)) {
		open my $fh, '>', FILE or die $!;
		print   $fh $_->content;
		
		return $_;
	}
}

1;

__END__

=head1 NAME

cpan-author.pl - try to find Russian CPAN authors

=head1 SYNOPSIS

	./cpan-author.pl

=head1 DESCRIPTION

You can use this to find Russian CPAN authors or Russian PAUSE id accounts.

This script fetches data from L<http://pause.perl.org/pause/query?ACTION=who_is>.

See source code :)

=head1 AUTHOR

Anatoly Sharifulin, E<lt>sharifulin at gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Anatoly Sharifulin.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
