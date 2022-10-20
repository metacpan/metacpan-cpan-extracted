package App::HL7::Send;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use Getopt::Std;
use Net::HL7::Connection;
use Net::HL7::Message;
use Perl6::Slurp qw(slurp);

our $VERSION = 0.04;

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
		'h' => 0,
	};
	if (! getopts('h', $self->{'_opts'}) || @ARGV < 3
		|| $self->{'_opts'}->{'h'}) {

		print STDERR "Usage: $0 [-h] [--version] host port hl7_file|-\n";
		print STDERR "\t-h\t\tPrint help.\n";
		print STDERR "\t--version\tPrint version.\n";
		return 1;
	}
	$self->{'_hl7_host'} = $ARGV[0];
	$self->{'_hl7_port'} = $ARGV[1];
	$self->{'_hl7_file'} = $ARGV[2];

	# Get hl7_file.
	my $hl7;
	if ($self->{'_hl7_file'} eq '-') {
		while (my $line = <STDIN>) {
			$hl7 .= $line;
		}
	} else {
		$hl7 = slurp($self->{'_hl7_file'});
	}

	# Create message.
	my $msg = Net::HL7::Message->new($hl7);
	if (! $msg) {
		err 'Cannot parse HL7 file.', 'File', $self->{'_hl7_file'};
	}

	# Create connection.
	my $conn = Net::HL7::Connection->new($self->{'_hl7_host'},
		$self->{'_hl7_port'});
	if (! $conn) {
		err 'Cannot connect to host.';
	}

	# Send.
	$conn->send($msg);
	print "Message was send.\n";

	return 0;
}

1;


__END__

=pod

=encoding utf8

=head1 NAME

App::HL7::Send - Base class for hl7send script.

=head1 SYNOPSIS

 use App::HL7::Send;

 my $app = App::HL7::Send->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::HL7::Send->new;

Constructor.

Returns instance of object.

=head2 C<run>

 my $exit_code = $app->run;

Run method.

Returns 1 for error, 0 for success.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 run():
         Cannot connect to host.
         Cannot parse HL7 file.
                 File: %s

=head1 EXAMPLE

=for comment filename=send_test_orm_to_dcm4chee.pl

 use strict;
 use warnings;

 use App::HL7::Send;
 use File::Temp qw(tempfile);
 use IO::Barf qw(barf);

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 host port\n";
         exit 1;
 }
 my $host = $ARGV[0];
 my $port = $ARGV[1] || 2575;

 # Test ORM data for dcm4chee.
 my $hl7 = <<'END';
 MSH|^~\&|FROM|Facility #1|TO|Facility #2|20160403211012||ORM^O01|MSGID20160403211012|P|1.0
 PID|||11111||Novak^Jan^^^Ing.||19680821|M|||Olomoucká^^Brno^^61300^Czech Republic|||||||
 PV1||O|OP^PAREG^||||1234^Clark^Bob|||OP|||||||||2|||||||||||||||||||||||||20160403211012|
 ORC|NW|A100Z^MESA_ORDPLC|B100Z^MESA_ORDFIL||SC||1^once^^20160101121212^^S||200008161510|^ROSEWOOD^RANDOLPH||7101^ESTRADA^JAIME^P^^DR||(314)555-1212|200008161510||922229-10^IHE-RAD^IHE-CODE-231||
 OBR|1|A100Z^MESA_ORDPLC|B100Z^MESA_ORDFIL|P1^Procedure 1^ERL_MESA^X1_A1^SPAction Item X1_A1^DSS_MESA|||||||||xxx||Radiology^^^^R|7101^ESTRADA^JAIME^P^^DR||XR999999|RP123456|SPS123456||||ES|||1^once^^20160101121212^^S|||WALK|||||||||||A|||RP_X1^RP Action Item RP_X1^DSS_MESA
 ZDS|1.2.1^100^Application^DICOM
 END

 # Barf to temp file.
 my (undef, $file) = tempfile();
 barf($file, $hl7);

 # Arguments (dcm4chee).
 @ARGV = (
         $host,
         $port,
         $file,
 );

 # Run.
 App::HL7::Send->new->run;

 # Output:
 # Message was send.

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Getopt::Std>,
L<Net::HL7::Connection>,
L<Net::HL7::Message>,
L<Perl6::Slurp>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-HL7-Send>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2016-2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
