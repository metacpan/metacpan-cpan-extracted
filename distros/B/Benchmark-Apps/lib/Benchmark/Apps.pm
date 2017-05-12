package Benchmark::Apps;
$Benchmark::Apps::VERSION = '0.05';
use warnings;
use strict;

use Time::HiRes qw.gettimeofday tv_interval.;

=head1 NAME

Benchmark::Apps - Simple interface to benchmark applications.

=head1 SYNOPSIS

This module provides a simple interface to benchmark applications (not
necessarily Perl applications).

  use Benchmark::Apps;

  my $commands = {
       cmd1 => 'run_command_1 with arguments',
       cmd2 => 'run_command_2 with other arguments',
     };

  my $conf = { pretty_print=>1, iters=>5 };

  Benchmark::Apps::run( $commands, $conf );

=head1 DESCRIPTION

This module can be used to perform simple benchmarks on programs. Basically,
it can be used to benchmark any program that can be called with a system
call.

=head1 FUNCTIONS

=head2 run

This method is used to run benchmarks. It runs the commands described in 
the hash passed as argument. It returns an hash of the results each command.
A second hash reference can be passed to this method: a configuration
hash reference. The values passed in this hash override the default
behaviour of the run method. The configuration options available at this
moment are:

=over 4

=item C<pretty_print>

When enabled it will print to stdout, in a formatted way the results
of the benchmarks as they finish running. This option should de used
when you want to run benchmarks and want to see the results progress
as the tests run. You can disable it, so you can perform automated
benchmarks.

Options: true (1) or false (0)

Default: false (0)

=item C<iters>

This is the number of iterations that each test will run.

Options: integer greater than 1

Default: 5

=item C<args>

This is a reference to an anonymous function that will calculate the
command argument based on the iteraction number.

Options: any function reference that returns a string

Default: empty function: always returns an empty string, which means no
arguments will be given to the command

=back

=head2 run

This method runs the commands described in the hash passed as argument.
It returns an hash of the results and return codes for each command.

=cut

sub _empty { '' }

my %cfg = ( pretty_print => 1,
            iters        => 5 ,
            args         => \&_empty );
my %command = ();
my %res = ();

sub run {
	my @args = @_;

	@args == 0 and die 'At least one hash reference needs to be passed as argument';
	@args > 2 and die 'A maximum of two arguments (hash refs) should be passed to this function';
	# in case we got the second argument (configuration hash ref)
	if (@args > 1) {
            if (ref $args[1] eq 'HASH') {
   		my @l = keys %{$args[1]};
   		foreach (@l) {
                    if (defined $args[1]{$_}) { # XXX and validate args
         		$cfg{$_} = $args[1]{$_};
                    }
   		}
            }
            else { warn 'Second argument to run should be an hash ref'; }
	}

	%command = %{$args[0]};

	for my $iter (1..$cfg{'iters'}) {
		for my $c (keys %command) {
			$res{$c}{'run'} = $command{$c};
			my $time = time_this($command{$c}.' '.&{$cfg{'args'}}($iter));
			$res{$c}{'result'}{$iter} = $time;
		}
	}

	pretty_print(%res) if $cfg{'pretty_print'};

	return +{%res};
}

sub _validate_option {
	my ($option, $value) = @_;

	# TODO do some validations
	# everything ok for now

	return 1;
}

=head2 pretty_print

This method is used to print the final result to STDOUT before returning 
from the C<run> method.

=cut

sub pretty_print {
	my $self = shift;

  	for my $iter (1..$cfg{'iters'}) {
     	_show_iter($iter);

     	for my $c (keys %command) {
        	printf " %8s => %8.4f s\n", $c, $res{$c}{'result'}{$iter};
     	}
	}
}

sub _show_iter {
	my $i = shift;
	printf "%d%s iteration:\n", $i, $i==1?"st":$i==2?"nd":$i==3?"rd":"th";
}

=head2 time_this

This method is not meant to be used directly, although it can be useful.
It receives a command line and executes it via system, taking care
of registering the elapsed time.

=cut

sub time_this {
	my $cmd_line = shift;
	my $start_time = [gettimeofday];
	system("$cmd_line 2>&1 > /dev/null");
	return tv_interval($start_time);
}


=head1 EXAMPLES

Check files in C<examples/>.

=head1 AUTHOR

Aberto Simoes (aka ambs), C<< <ambs at cpan.org> >>
Nuno Carvalho (aka smash), C<< <smash @ cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-benchmark-apps at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Benchmark-Apps>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Benchmark::Apps

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Benchmark-Apps>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Benchmark-Apps>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Benchmark-Apps>

=item * Search CPAN

L<http://search.cpan.org/dist/Benchmark-Apps>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Aberto Simoes, Nuno Carvalho, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

!!1; # End of Benchmark::Apps

__END__
