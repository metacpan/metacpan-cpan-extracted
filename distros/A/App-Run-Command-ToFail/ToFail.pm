package App::Run::Command::ToFail;

use strict;
use warnings;

use Getopt::Std;
use Readonly;

Readonly::Hash our %PRESETS => (
	'blank' => [
		0,
		'',
	],
	'perl' => [
		1,
		'perl %s',
	],
	'strace_perl' => [
		1,
		'strace -ostrace.log -esignal,write perl -Ilib %s',
	],
);

our $VERSION = 0.03;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Object.
	return $self;
}

# Run.
sub run {
	my $self = shift;

	# Process arguments.
	$self->{'_opts'} = {
		'h' => 0,
		'l' => 0,
		'n' => 100,
		'p' => 'perl',
	};
	if (! getopts('hln:p:', $self->{'_opts'}) || $self->{'_opts'}->{'h'}) {
		print STDERR "Usage: $0 [-h] [-l] [-n cycles] [-p preset] [--version]\n";
		print STDERR "\t-h\t\tPrint help.\n";
		print STDERR "\t-l\t\tList presets.\n";
		print STDERR "\t-n cycles\tNumber of cycles (default is 100).\n";
		print STDERR "\t-p preset\tPreset for run (default is perl).\n";
		print STDERR "\t--version\tPrint version.\n";
		return 1;
	}

	if ($self->{'_opts'}->{'l'}) {
		foreach my $key (sort keys %PRESETS) {
			print $key.': '.$PRESETS{$key}[1]."\n";
		}
		return 0;
	}

	# Check presets.
	if (! exists $PRESETS{$self->{'_opts'}->{'p'}}) {
		print STDERR 'Bad preset. Possible values are \''.(join "', '", (sort keys %PRESETS))."'.\n";
		return 1;
	}

	if ($PRESETS{$self->{'_opts'}->{'p'}}[0] > @ARGV) {
		print STDERR 'Wrong number of arguments (need '.$PRESETS{$self->{'_opts'}->{'p'}}[0].
			" for command '".$PRESETS{$self->{'_opts'}->{'p'}}[1]."').\n";
		return 1;
	}

	foreach my $i (1 .. $self->{'_opts'}->{'n'}) {
		my @preset_args;
		my @other_args;
		for (my $i = 0; $i < @ARGV; $i++) {
			if ($i + 1 <= $PRESETS{$self->{'_opts'}->{'p'}}[0]) {
				push @preset_args, $ARGV[$i];
			} else {
				push @other_args, $ARGV[$i];
			}
		}
		my $command = sprintf $PRESETS{$self->{'_opts'}->{'p'}}[1], @preset_args;
		$command .= ' '.(join ' ', @other_args);
		my $ret = system $command;
        	if ($ret > 1) {
                	print STDERR "Exited in $i round with exit code $ret.\n";
                	return 1;
        	}
	}
	print "Everything is ok.\n";
	
	return 0;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Run::Command::ToFail - Base class for run-command-to-fail tool.

=head1 SYNOPSIS

 use App::Run::Command::To::Fail;

 my $app = App::Run::Command::ToFail->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::Run::Command::ToFail->new;

Constructor.

Returns instance of object.

=head2 C<run>

 my $exit_code = $app->run;

Run.

Returns 1 for error, 0 for success.

=head1 EXAMPLE

=for comment filename=run_perl_command.pl

 use strict;
 use warnings;

 use App::Run::Command::ToFail;
 use File::Temp qw(tempfile);
 use IO::Barf qw(barf);

 my (undef, $tmp_file) = tempfile();
 barf($tmp_file, <<'END');
 use strict;
 use warnings;

 print ".";
 END

 # Arguments.
 @ARGV = (
         '-n 10',
         $tmp_file,
 );

 # Run.
 exit App::Run::Command::ToFail->new->run;

 # Output like:
 # ..........Everything is ok.

=head1 DEPENDENCIES

L<Getopt::Std>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-Run-Command-ToFail>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
