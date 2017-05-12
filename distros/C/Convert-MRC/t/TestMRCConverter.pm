#
# This file is part of Convert-MRC
#
# This software is copyright (c) 2013 by Alan K. Melby.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package t::TestMRCConverter;
use Test::Base -Base;
use Convert::MRC;

package t::TestMRCConverter::Filter;
use Test::Base::Filter -base;
use Convert::MRC;
use Data::Dumper;

my $converter = Convert::MRC->new();

sub print_self {
	print Dumper $converter;
	return @_;
}

sub convert {
	my ($mrc) = @_;

	#read MRC from input string
	open my $mrc_handle, '<', \$mrc;

	#send output to strings
	my ( $tbx, $log );
	open my $tbx_handle, '>', \$tbx;
	open my $log_handle, '>', \$log;

	$converter->input_fh( $mrc_handle );
	$converter->tbx_fh($tbx_handle);
	$converter->log_fh($log_handle);
	$converter->convert;

	close $mrc_handle;
	close $tbx_handle;
	close $log_handle;

	#remove datetime stamps from log
	$log = remove_datetime(undef, $log);

	#return output TBX and log
	return [$tbx, $log];
}

sub no_tbx {
	my ($tbx_log) = @_;

	return [ undef, $tbx_log->[1] ];
}

sub remove_datetime {
	my ($text) = @_;
	defined $text
		or return;
	$text =~ s/\] \[[^\]]+\]/\]/gm;
	return $text;
}

# fix version numbers and chomp logs
# so that they can be matched properly
sub fix_version {
	my ($log) = @_;

	chomp $log;
	#fix version
	$log =~ s/\[version\]/Convert::MRC->_version/e;

	return $log;
}

1;
