package App::HL7::Dump;

use strict;
use warnings;

use Class::Utils qw(set_params);
use English;
use Error::Pure qw(err);
use Getopt::Std;
use Net::HL7::Message;
use Perl6::Slurp qw(slurp);

our $VERSION = 0.05;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Process params.
	set_params($self, @params);

	# Object.
	return $self;
}

# Run.
sub run {
	my $self = shift;

	# Process arguments.
	$self->{'_opts'} = {
		'c' => 0,
		'h' => 0,
	};
	if (! getopts('ch', $self->{'_opts'}) || @ARGV < 1
		|| $self->{'_opts'}->{'h'}) {

		print STDERR "Usage: $0 [-c] [-h] [--version] hl7_file\n";
		print STDERR "\t-c\t\tColor mode.\n";
		print STDERR "\t-h\t\tPrint help.\n";
		print STDERR "\t--version\tPrint version.\n";
		return 1;
	}
	$self->{'_hl7_file'} = $ARGV[0];

	if ($ENV{'COLOR'}) {
		$self->{'_opts'}->{'c'} = 1;
	}

	# Load Term::ANSIColor.
	if ($self->{'_opts'}->{'c'}) {
		eval "require Term::ANSIColor;";
		if ($EVAL_ERROR) {
			err "Cannot load 'Term::ANSIColor'.",
				'Eval error', $EVAL_ERROR;
		}
	}

	# Get hl7_file.
	my $hl7 = slurp($self->{'_hl7_file'});

	# Create message.
	my $msg = Net::HL7::Message->new($hl7);
	if (! $msg) {
		err 'Cannot parse HL7 file.', 'File', $self->{'_hl7_file'};
		return 1;
	}

	# Segment name: size
	foreach my $seg ($msg->getSegments) {
		foreach my $index (1 .. $seg->size) {
			my $val = $seg->getField($index);
			if (defined $val) {
				my $print_val;
				if (ref $val eq 'ARRAY') {
					$print_val = $seg->getFieldAsString($index);
				} else {
					$print_val = $val;
				}
				if ($self->{'_opts'}->{'c'}) {
					print Term::ANSIColor::color('green').$seg->getName.
						Term::ANSIColor::color('reset').'-'.
						Term::ANSIColor::color('red').$index.
						Term::ANSIColor::color('reset').':'.
						Term::ANSIColor::color('bold white').
						$print_val.Term::ANSIColor::color('reset')."\n";
				} else {
					print $seg->getName.'-'.$index.':'.$print_val."\n";
				}
			}
		}
	}

	return 0;
}

1;


__END__

=pod

=encoding utf8

=head1 NAME

App::HL7::Dump - Base class for hl7dump script.

=head1 SYNOPSIS

 use App::HL7::Dump;

 my $app = App::HL7::Dump->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::HL7::Dump->new;

Constructor.

Returns instance of object.

=head2 C<run>

 my $exit_code = $app->run;

Run method.

Returns exit code (0 as success, > 0 as error).

=head1 ERRORS

 new():
         Cannot load 'Term::ANSIColor'.
                 Eval error: %s
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 run():
         Cannot parse HL7 file.
                 File: %s

=head1 EXAMPLE1

 use strict;
 use warnings;

 use App::HL7::Dump;
 use File::Temp qw(tempfile);
 use IO::Barf qw(barf);

 # Test data.
 my $hl7 = <<'END';
 MSH|^~\&|FROM|Facility #1|TO|Facility #2|20160403211012||ORM^O01|MSGID20160403211012|P|1.0
 PID|||11111||Novak^Jan^^^Ing.||19680821|M|||Olomoucká^^Brno^^61300^Czech Republic|||||||
 PV1||O|OP^PAREG^||||1234^Clark^Bob|||OP|||||||||2|||||||||||||||||||||||||20160403211012|
 ORC|NW|20160403211012
 OBR|1|20160403211012||003038^Urinalysis^L|||20160403211012
 END

 # Barf to temp file.
 my (undef, $file) = tempfile();
 barf($file, $hl7);

 # Arguments.
 @ARGV = (
         $file,
 );

 # Run.
 App::HL7::Dump->new->run;

 # Output:
 # MSH-1:|
 # MSH-2:^~\&
 # MSH-3:FROM
 # MSH-4:Facility #1
 # MSH-5:TO
 # MSH-6:Facility #2
 # MSH-7:20160403211012
 # MSH-9:ORM^O01
 # MSH-10:MSGID20160403211012
 # MSH-11:P
 # MSH-12:1.0
 # PID-3:11111
 # PID-5:Novak^Jan^^^Ing.
 # PID-7:19680821
 # PID-8:M
 # PID-11:Olomoucká^^Brno^^61300^Czech Republic
 # PV1-2:O
 # PV1-3:OP^PAREG
 # PV1-7:1234^Clark^Bob
 # PV1-10:OP
 # PV1-19:2
 # PV1-44:20160403211012
 # ORC-1:NW
 # ORC-2:20160403211012
 # OBR-1:1
 # OBR-2:20160403211012
 # OBR-4:003038^Urinalysis^L
 # OBR-7:20160403211012

=head1 EXAMPLE2

 use strict;
 use warnings;

 use App::HL7::Dump;
 use File::Temp qw(tempfile);
 use IO::Barf qw(barf);

 # Test data.
 my $hl7 = <<'END';
 MSH|^~\&|FROM|Facility #1|TO|Facility #2|20160403211012||ORM^O01|MSGID20160403211012|P|1.0
 PID|||11111||Novak^Jan^^^Ing.||19680821|M|||Olomoucká^^Brno^^61300^Czech Republic|||||||
 PV1||O|OP^PAREG^||||1234^Clark^Bob|||OP|||||||||2|||||||||||||||||||||||||20160403211012|
 ORC|NW|20160403211012
 OBR|1|20160403211012||003038^Urinalysis^L|||20160403211012
 END

 # Barf to temp file.
 my (undef, $file) = tempfile();
 barf($file, $hl7);

 # Arguments.
 @ARGV = (
         '-c',
         $file,
 );

 # Run.
 App::HL7::Dump->new->run;

 # Output (colored keys):
 # MSH-1:|
 # MSH-2:^~\&
 # MSH-3:FROM
 # MSH-4:Facility #1
 # MSH-5:TO
 # MSH-6:Facility #2
 # MSH-7:20160403211012
 # MSH-9:ORM^O01
 # MSH-10:MSGID20160403211012
 # MSH-11:P
 # MSH-12:1.0
 # PID-3:11111
 # PID-5:Novak^Jan^^^Ing.
 # PID-7:19680821
 # PID-8:M
 # PID-11:Olomoucká^^Brno^^61300^Czech Republic
 # PV1-2:O
 # PV1-3:OP^PAREG
 # PV1-7:1234^Clark^Bob
 # PV1-10:OP
 # PV1-19:2
 # PV1-44:20160403211012
 # ORC-1:NW
 # ORC-2:20160403211012
 # OBR-1:1
 # OBR-2:20160403211012
 # OBR-4:003038^Urinalysis^L
 # OBR-7:20160403211012

=head1 DEPENDENCIES

L<Class::Utils>,
L<English>,
L<Error::Pure>,
L<Getopt::Std>,
L<Net::HL7::Message>,
L<Perl6::Slurp>.

L<Term::ANSIColor> for color mode.

=head1 REPOSITORY

L<https://github.com/tu pinek/App-HL7-Dump>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2016-2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.05

=cut
