package App::Bin::Search;

use strict;
use warnings;

use Bit::Vector;
use Getopt::Std;

our $VERSION = 0.02;

$| = 1;

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
		'b' => 0,
		'h' => 0,
		'v' => 0,
	};
	if (! getopts('bhv', $self->{'_opts'}) || @ARGV < 2
		|| $self->{'_opts'}->{'h'}) {

		print STDERR "Usage: $0 [-b] [-h] [-v] [--version] hex_stream search\n";
		print STDERR "\t-b\t\tPrint in binary (default hexadecimal).\n";
		print STDERR "\t-h\t\tPrint help.\n";
		print STDERR "\t-v\t\tVerbose mode.\n";
		print STDERR "\t--version\tPrint version.\n";
		print STDERR "\thex_stream\tInput hexadecimal stream.\n";
		print STDERR "\tsearch\t\tSearch string (in hex).\n";
		return 1;
	}
	$self->{'_hex_stream'} = $ARGV[0];
	$self->{'_search'} = $ARGV[1];

	$self->{'_bv'} = Bit::Vector->new_Hex(
		length($self->{'_hex_stream'}) * 4,
		$self->{'_hex_stream'},
	);
	$self->{'_bvs'} = Bit::Vector->new_Hex(
		length($self->{'_search'}) * 4,
		$self->{'_search'},
	);

	my $processed_bits = 0;
	if ($self->{'_opts'}->{'v'}) {
		if ($self->{'_opts'}->{'b'}) {
			print "Hexadecimal stream: ".$self->{'_bv'}->to_Bin."\n";
		} else {
			print "Hexadecimal stream: ".$self->{'_bv'}->to_Hex."\n";
		}
		print 'Size of hexadecimal stream: '.$self->{'_bv'}->Size."\n";
		if ($self->{'_opts'}->{'b'}) {
			my $len = length($self->{'_search'}) * 4;
			printf "Looking for: %0${len}s\n", $self->{'_bvs'}->to_Bin;
		} else {
			print 'Looking for: '.$self->{'_search'}."\n";
		}
	}
	while ($self->{'_bv'}->Size) {
		$processed_bits++;
		if ($self->{'_opts'}->{'v'}) {
			if ($self->{'_opts'}->{'b'}) {
				print $self->{'_bv'}->to_Bin.' at '.$processed_bits."bit\n";
			} else {
				print $self->_print_hex.' at '.$processed_bits."bit\n";
			}
		}

		my $s = $self->{'_bvs'}->to_Bin;
		if ($self->{'_bv'}->to_Bin =~ m/^$s/ms) {
			if ($self->{'_opts'}->{'b'}) {
				print 'Found '.$self->{'_bv'}->to_Bin.' at '.$processed_bits." bit\n";
			} else {
				print 'Found '.$self->_print_hex.' at '.$processed_bits." bit\n";
			}
		}
		$self->{'_bv'}->Resize($self->{'_bv'}->Size - 1);
	}

	return 0;
}

sub _print_hex {
	my $self = shift;

	my $tmp = $self->{'_bv'}->Clone;
	my $size = $tmp->Size;
	my $plus = ($size % 4) ? 4 - ($size % 4) : 0;
	$tmp->Resize($size + $plus);
	$tmp->Move_Left($plus);

	return $tmp->to_Hex;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Bin::Search - Base class for bin-search tool.

=head1 SYNOPSIS

 use App::Bin::Search;

 my $app = App::Bin::Search->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::Bin::Search->new;

Constructor.

Returns instance of object.

=head2 C<run>

 my $exit_code = $app->run;

Run.

Returns 1 for error, 0 for success.

=head1 EXAMPLE1

=for comment filename=bin_search.pl

 use strict;
 use warnings;

 use App::Bin::Search;

 # Arguments.
 @ARGV = (
         'FFABCD',
         'D5',
 );

 # Run.
 exit App::Bin::Search->new->run;

 # Output like:
 # Found D5E68 at 8 bit

=head1 EXAMPLE2

=for comment filename=bin_search_bin.pl

 use strict;
 use warnings;

 use App::Bin::Search;

 # Arguments.
 @ARGV = (
         '-b',
         'FFABCD',
         'D5',
 );

 # Run.
 exit App::Bin::Search->new->run;

 # Output like:
 # Found 11010101111001101 at 8 bit

=head1 EXAMPLE3

=for comment filename=bin_search_verbose.pl

 use strict;
 use warnings;

 use App::Bin::Search;

 # Arguments.
 @ARGV = (
         '-v',
         'FFABCD',
         'D5',
 );

 # Run.
 exit App::Bin::Search->new->run;

 # Output like:
 # Hexadecimal stream: FFABCD
 # Size of hexadecimal stream: 24
 # Looking for: D5
 # FFABCD at 1bit 
 # FF579A at 2bit 
 # FEAF34 at 3bit 
 # FD5E68 at 4bit 
 # FABCD at 5bit 
 # F579A at 6bit 
 # EAF34 at 7bit 
 # D5E68 at 8bit 
 # Found D5E68 at 8 bit
 # ABCD at 9bit 
 # 579A at 10bit 
 # AF34 at 11bit 
 # 5E68 at 12bit 
 # BCD at 13bit 
 # 79A at 14bit 
 # F34 at 15bit 
 # E68 at 16bit 
 # CD at 17bit 
 # 9A at 18bit 
 # 34 at 19bit 
 # 68 at 20bit 
 # D at 21bit 
 # A at 22bit 
 # 4 at 23bit 
 # 8 at 24bit

=head1 DEPENDENCIES

L<Bit::Vector>,
L<Getopt::Std>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-Bin-Search>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
