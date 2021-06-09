#!/usr/bin/env perl
use Modern::Perl;
use Cfwp::fio qw(read_file read_file_text);

@_ = Cfwp::fio::read_file('/tmp/telegram.key');
say @_;

$_ = Cfwp::fio::read_file_text('Makefile.PL');
say; 
