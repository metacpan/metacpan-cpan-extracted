#! perl

use strict;
use warnings;

use Test::More 0.89;

use Config;
use Devel::FindPerl 'find_perl_interpreter';
use IPC::Open2;
use File::Spec::Functions 'catfile';
use File::Temp 'tempdir';

alarm 5;

sub spew {
	my ($filename, $content) = @_;
	open my $fh, '>', $filename or die "Couldn't open $filename: $!";
	print $fh $content or die "Couldn't write to $filename: $!";
	close $fh or die "Couldn't close $filename: $!"
}

my $tempdir = tempdir(CLEANUP => 1);
my $input_awk = catfile($tempdir, 'input.awk');
my $input_perl = catfile($tempdir, 'input.perl');

#mkdir $tempdir or die "Couldn't mkdir $tempdir: $!";
spew($input_awk, "/awk2perl/\n");
my $program = runa2p(progfile => $input_awk);
like($program, qr{print \$_ if /awk2perl/;}, 'Output looks like expected output');

spew($input_perl, $program);
my $output = runperl(progfile => $input_perl, args => [ $0 ]);
open my $self, '<', $0;
chomp(my @expected = grep { /awk2perl/ } <$self>);
is_deeply([ split /\n/, $output ], \@expected, 'Output is identical to … code');

done_testing;

sub run_command {
	my %args = @_;
	my @command = @{ $args{command} };
	my $pid = open2(my ($in, $out), @command) or die "Couldn't open2($?): $!";
	binmode $in, ':crlf' if $^O eq 'MSWin32';
	my $ret = do { local $/; <$in> };
	waitpid $pid, 0;
	return $ret;
}

sub runa2p {
	my %args = @_;
	my @command = catfile(qw{blib bin}, "a2p$Config{exe_ext}");
	push @command, @{ $args{args} } if $args{args};
	push @command, $args{progfile} if $args{progfile};
	return run_command(%args, command => \@command);
}

sub runperl {
	my %args = @_;
	my @command = find_perl_interpreter();
	push @command, $args{progfile} if $args{progfile};
	push @command, @{ $args{args} } if $args{args};
	return run_command(%args, command => \@command);
}
