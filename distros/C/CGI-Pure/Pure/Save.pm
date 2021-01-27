package CGI::Pure::Save;

use strict;
use warnings;

use Class::Utils qw(set_params);
use English qw(-no_match_vars);
use Error::Pure qw(err);
use Readonly;
use URI::Escape;

# Constants.
Readonly::Scalar my $EMPTY_STR => q{};

our $VERSION = 0.09;

# Constructor.
sub new {
	my ($class, @params) = @_;
	my $self = bless {}, $class;

	# CGI::Pure object.
	$self->{'cgi_pure'} = $EMPTY_STR;

	# Process params.
	set_params($self, @params);

	# CGI::Pure object not exist.
	if (! $self->{'cgi_pure'} || ! $self->{'cgi_pure'}->isa('CGI::Pure')) {
		err 'CGI::Pure object doesn\'t define.';
	}

	# Object.
	return $self;
}

# Load parameters from file.
sub load {
	my ($self, $fh) = @_;
	if (! $fh || ! fileno $fh) {
		err 'Invalid filehandle.';
	}
	local $INPUT_RECORD_SEPARATOR = "\n";
	while (my $pair = <$fh>) {
		chomp $pair;
		if ($pair eq q{=}) {
			return;
		}
		$self->{'cgi_pure'}->_parse_params($pair);
	}
	return;
}

# Save parameters to file.
sub save {
	my ($self, $fh) = @_;
	local $OUTPUT_FIELD_SEPARATOR = $EMPTY_STR;
	local $OUTPUT_RECORD_SEPARATOR = $EMPTY_STR;
	if (! $fh || ! fileno $fh) {
		err 'Invalid filehandle.';
	}
	foreach my $param ($self->{'cgi_pure'}->param) {
		foreach my $value ($self->{'cgi_pure'}->param($param)) {
			print {$fh} uri_escape($param), '=',
				uri_escape($value), "\n";
		}
	}
	print {$fh} "=\n";
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

CGI::Pure::Save - Common Gateway Interface Class for loading/saving object in file.

=head1 SYNOPSIS

 use CGI::Pure::Save;

 my $cgi = CGI::Pure::Save->new(%parameters);
 $cgi->save($fh);
 $cgi->load($fh);

=head1 METHODS

=over 8

=item C<new(%parameters)>

 Constructor

=over 8

=item * C<cgi_pure>

 CGI::Pure object.

=back

=item C<load($fh)>

 Load parameters from file.
 Return undef.

=item C<save($fh)>

 Save parameters to file.
 Return undef.

=back

=head1 ERRORS

 new():
         CGI::Pure object doesn't define.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 load()
         Invalid filehandle.

 save()
         Invalid filehandle.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use CGI::Pure;
 use CGI::Pure::Save;
 use File::Temp qw(tempfile);
 use Perl6::Slurp qw(slurp);

 # Temporary file.
 my ($tempfile_fh, $tempfile) = tempfile();

 # Query string.
 my $query_string = 'par1=val1;par1=val2;par2=value';

 # CGI::Pure Object.
 my $cgi = CGI::Pure->new(
 	'init' => $query_string,
 );

 # CGI::Pure::Save object.
 my $save = CGI::Pure::Save->new(
 	'cgi_pure' => $cgi,
 );

 # Save.
 $save->save($tempfile_fh);
 close $tempfile_fh;
 
 # Print file.
 print slurp($tempfile);

 # Clean temp file.
 unlink $tempfile;

 # Output:
 # par1=val1
 # par1=val2
 # par2=value
 # =

=head1 EXAMPLE2

 use strict;
 use warnings;

 use CGI::Pure;
 use CGI::Pure::Save;
 use IO::Barf qw(barf);
 use File::Temp qw(tempfile);
 use File::Slurp qw(write_file);

 # Temporary file.
 my ($tempfile_fh, $tempfile) = tempfile();

 # CGI::Pure data.
 my $cgi_pure_data = <<'END';
 par1=val1
 par1=val2
 par2=value
 =
 END

 # Create file.
 barf($tempfile_fh, $cgi_pure_data);
 close $tempfile_fh;

 # CGI::Pure Object.
 my $cgi = CGI::Pure->new;

 # CGI::Pure::Save object.
 my $save = CGI::Pure::Save->new(
 	'cgi_pure' => $cgi,
 );

 # Load.
 open $tempfile_fh, '<', $tempfile;
 $save->load($tempfile_fh);
 close $tempfile_fh;

 # Print out.
 foreach my $param_key ($cgi->param) {
 	print "Param '$param_key': ".join(' ', $cgi->param($param_key))."\n";
 }

 # Clean temp file.
 unlink $tempfile;

 # Output:
 # Param 'par1': val1 val2
 # Param 'par2': value

=head1 DEPENDENCIES

L<Class::Utils>,
L<English>,
L<Error::Pure>,
L<Readonly>,
L<URI::Escape>.

=head1 SEE ALSO

=over

=item L<CGI::Pure>

Common Gateway Interface Class.

=item L<CGI::Pure::Fast>

Fast Common Gateway Interface Class for CGI::Pure.

=back

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2004-2021 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.09

=cut
