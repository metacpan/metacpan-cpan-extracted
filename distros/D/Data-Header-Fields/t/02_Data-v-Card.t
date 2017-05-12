#!/usr/bin/perl

use strict;
use warnings;

use utf8;

#use Test::More 'no_plan';
use Test::More tests => 15;
use Test::Differences;
use Test::Exception;
use Test::Deep;

binmode(Test::More->builder->$_ => q(encoding(:UTF-8))) for qw(output failure_output todo_output);

use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
	use_ok ( 'Data::v' ) or exit;
}

exit main();

sub main {
	basic();
	photo();
	return 0;
}

sub basic {
	my $aldo_vcf = IO::Any->slurp([ $Bin, 'vcf', 'aldo.vcf' ]);
	my $vdata = Data::v->new->decode(\$aldo_vcf);
	
	cmp_deeply([$vdata->keys], ['VCARD'], 'one VCARD record');
	my $vcard = $vdata->get_value('VCARD');
	isa_ok($vcard, 'Data::v::Card');
	cmp_ok($vcard->get_value('VERSION'), 'eq', '2.1', 'VERSION 2.1');

	is($vdata->line_ending, "\r\n", 'line_ending()');
	is($vcard->line_ending, "\r\n", 'line_ending()');
	
	my $aldo_vcf_enc = $vdata->encode(undef, [ '/tmp/aldo.vcf' ]);
	is($aldo_vcf, $aldo_vcf_enc, 'encode back and compare with original');
	
	is($vcard->get_value('ADR')->country, 'Österreich', 'adr->country() in Windows-1252');

	cmp_ok($vcard->get_value('tel', 'type' => 'cell'), 'eq', '+43 (699) 15 991 000', 'get cell phone');

	my $enc_vcf = IO::Any->slurp([ $Bin, 'vcf', 'enc.vcf' ]);
	my $enc_vdata = Data::v->new->decode(\$enc_vcf);
	my $enc_vcard = $enc_vdata->get_value('VCARD');
	foreach my $line (@{$enc_vcard->_lines}) {
		$line->line_changed;
	}
	
	is($enc_vdata->encode(), $enc_vcf, 'encode back and compare with original (mixed encoding)');
	cmp_ok($enc_vcard->get_value('N'), 'eq', 'aäčšťľžř;aacsztl', 'encoded N (iso-8859-2)');
	cmp_ok($enc_vcard->get_value('FN'), 'eq', 'aacsztl aäčšťľžř', 'encoded FN (windows-1250)');
	cmp_ok($enc_vcard->get_value('PHOTO'), 'eq', 'http://www.gravatar.com/avatar/b6e8656226999389e5098d10e00226fe?just-test=ůčšžťľä', 'encoded FN (iso-8859-2)');
}

sub photo {
	my $aldo_vcf = IO::Any->slurp([ $Bin, 'vcf', 'aldo.vcf' ]);
	my $aldo_img = IO::Any->slurp([ $Bin, 'vcf', 'aldo.jpg' ]);

	my $a_vdata = Data::v->new->decode(\$aldo_vcf);
	my $a_vcard = $a_vdata->get_value('VCARD');
	
	my $a_photo_bin = $a_vcard->get_value('photo');
	ok($a_photo_bin->value eq $aldo_img, 'extract photo');

	my $michael_vcf = IO::Any->slurp([ $Bin, 'vcf', 'michael.vcf' ]);
	my $michael_img = IO::Any->slurp([ $Bin, 'vcf', 'michael.jpg' ]);

	my $m_vdata = Data::v->new->decode(\$michael_vcf);
	my $m_vcard = $m_vdata->get_value('VCARD');
	
	my $m_photo_bin = $m_vcard->get_value('photo');
	ok($m_photo_bin->value eq $michael_img, 'extract photo');
}
