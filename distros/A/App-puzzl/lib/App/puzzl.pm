package App::puzzl;

use v5.28;
use strict;
use warnings;
use Getopt::Long;
use Exporter 'import';

use App::puzzl::new qw(new_day);
use App::puzzl::run qw(run_day);

our $VERSION = "0.01";

sub run {
	my @new;
	my @run;
	GetOptions('new=i@' => \@new,
		   'run=s@' => \@run);


	foreach my $new (@new) {
		new_day($new);
	}

	foreach my $run (@run) {
		run_day($run);
	}
}

our @EXPORT_OK = qw(run);

1;
__END__

=encoding utf-8

=head1 NAME

App::puzzl - A CLI for writing running Advent of Code solutions written in Perl

=head1 SYNOPSIS

    puzzl --new=<day number(s)> --run=<day number(s)>
    puzzl --run=3
    puzzl --new=4

=head1 DESCRIPTION

App::puzzl is a CLI for running Advent of Code solutions. C<puzzl --new> will create a file in C<days/>,
and C<puzzl --run> will run a day, passing an input file descriptor for the file C<input/day(day number).txt>.

=head1 LICENSE

Copyright (C) Aleks Rutins.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Aleks Rutins E<lt>keeper@farthergate.comE<gt>

=cut
