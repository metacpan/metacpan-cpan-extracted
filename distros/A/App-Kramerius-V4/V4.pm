package App::Kramerius::V4;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Data::Kramerius;
use Error::Pure qw(err);
use Getopt::Std;
use IO::Barf qw(barf);
use JSON::XS;
use LWP::UserAgent;

our $VERSION = 0.02;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# LWP::UserAgent object.
	$self->{'lwp_user_agent'} = undef;	

	# Process parameters.
	set_params($self, @params);

	$self->{'_kramerius'} = Data::Kramerius->new;

	if (defined $self->{'lwp_user_agent'}) {
		if (! $self->{'lwp_user_agent'}->isa('LWP::UserAgent')) {
			err "Parameter 'lwp_user_agent' must be a LWP::UserAgent object.";
		}
	} else {
		$self->{'lwp_user_agent'} = LWP::UserAgent->new;
		$self->{'lwp_user_agent'}->agent(__PACKAGE__.'/'.$VERSION);
	}

	# Object.
	return $self;
}

# Run.
sub run {
	my $self = shift;

	# Process arguments.
	$self->{'_opts'} = {
		'h' => 0,
		'o' => undef,
		'q' => 0,
	};
	if (! getopts('ho:q', $self->{'_opts'}) || @ARGV < 2
		|| $self->{'_opts'}->{'h'}) {

		print STDERR "Usage: $0 [-h] [-o out_file] [-q] [--version] kramerius_id document_uuid\n";
		print STDERR "\t-h\t\tHelp.\n";
		print STDERR "\t-o out_file\tOutput file.\n";
		print STDERR "\t-q\t\tQuiet mode.\n";
		print STDERR "\t--version\tPrint version.\n";
		print STDERR "\tkramerius_id\tKramerius system id. e.g. ".
			"mzk\n";
		print STDERR "\tdocument_uuid\tDocument UUID in Kramerius system\n";
		return 1;
	}
	$self->{'_kramerius_id'} = shift @ARGV;
	$self->{'_doc_uuid'} = shift @ARGV;

	$self->{'_kramerius_obj'} = $self->{'_kramerius'}->get($self->{'_kramerius_id'});
	if ($self->{'_kramerius_obj'}->version != 4) {
		err "Kramerius system for '$self->{'_kramerius_id'}' isn't version 4 of API.";
	}

	my $suffix = '';
	if (! $self->{'_opts'}->{'o'}) {
		$suffix = $self->_get_suffix;
	}

	my $kramerius_full_url = $self->{'_kramerius_obj'}->url.
		'search/api/v5.0/item/uuid:'.
		$self->{'_doc_uuid'}.'/full';
	$self->_message("Download $kramerius_full_url");
	my $full_res = $self->{'lwp_user_agent'}->get($kramerius_full_url);
	if (! $full_res->is_success) {
		err "Cannot download '$kramerius_full_url'.",
			'Status line', $full_res->status_line;
	}
	my $output_file = $self->{'_opts'}->{'o'} ? $self->{'_opts'}->{'o'}
		: $self->{'_doc_uuid'};
	if (! $self->{'_opts'}->{'o'}) {
		$output_file .= '.'.$suffix;
	}
	$self->_message("Save $output_file");
	barf($output_file, $full_res->content);
	
	return 0;
}

sub _get_suffix {
	my $self = shift;

	# Construct URL for metadata.
	my $kramerius_streams_url = $self->{'_kramerius_obj'}->url.
		'search/api/v5.0/item/uuid:'.
		$self->{'_doc_uuid'}.'/streams';
	$self->_message("Download $kramerius_streams_url");

	# Get metadata.
	my $stream_res = $self->{'lwp_user_agent'}->get($kramerius_streams_url);
	if (! $stream_res->is_success) {
		err "Cannot download '$kramerius_streams_url'.",
			'Status line', $stream_res->status_line;
	}
	my $struct_hr = decode_json($stream_res->content);
	if (! defined $struct_hr) {
		err "Cannot decode content of '$kramerius_streams_url' as JSON.";
	}
	if (! exists $struct_hr->{'IMG_FULL'}) {
		err "Object with '$self->{'_doc_uuid'}' isn't document.";
	}

	# Detect suffix.
	my $suffix = '';
	if ($struct_hr->{'IMG_FULL'}->{'mimeType'} eq 'image/jp2') {
		$suffix = 'jp2';
	} elsif ($struct_hr->{'IMG_FULL'}->{'mimeType'} eq 'image/jpeg') {
		$suffix = 'jpg';
	} elsif ($struct_hr->{'IMG_FULL'}->{'mimeType'} eq 'application/pdf') {
		$suffix = 'pdf';
	} else {
		my $mime_type = $struct_hr->{'IMG_FULL'}->{'mimeType'};
		if (defined $mime_type) {
			err "Unsupported image format '$mime_type'.";
		} else {
			err "Unsupported image format. Unknown issue.";
		}
	}

	return $suffix;
}

sub _message {
	my ($self, $message) = @_;

	if (! $self->{'_opts'}->{'q'}) {
		print "$message\n";
	}

	return;
}

1;

=pod

=encoding utf8

=head1 NAME

App::Kramerius::V4 - Base class for kramerius4 script.

=head1 SYNOPSIS

 use App::Kramerius::V4;

 my $app = App::Kramerius::V4->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::Kramerius::V4->new;

Constructor.

Returns instance of object.

=head2 C<run>

 my $exit_code = $app->run;

Run.

Returns 1 for error, 0 for success.

=head1 ERRORS

 new():
         Parameter 'lwp_user_agent' must be a LWP::UserAgent object.

 run():
         Cannot download '%s'.
         Cannot decode content of '%s' as JSON.
         Kramerius system for '%s' isn't version 4 of API.
         Object with '%s' isn't document.
         Unsupported image format '%s'.
         Unsupported image format. Unknown issue.

=head1 EXAMPLE

 use strict;
 use warnings;

 use App::Kramerius::V4;

 # Arguments.
 @ARGV = (
         'mzk',
         '224d66f8-f48e-4a92-b41e-87c88a076dc0',
 );

 # Run.
 exit App::Kramerius::V4->new->run;

 # Output like:
 # Download http://kramerius.mzk.cz/search/api/v5.0/item/uuid:224d66f8-f48e-4a92-b41e-87c88a076dc0/streams
 # Download http://kramerius.mzk.cz/search/api/v5.0/item/uuid:224d66f8-f48e-4a92-b41e-87c88a076dc0/full
 # Save 224d66f8-f48e-4a92-b41e-87c88a076dc0.jpg

=head1 DEPENDENCIES

L<Class::Utils>,
L<Data::Kramerius>,
L<Error::Pure>,
L<Getopt::Std>,
L<IO::Barf>,
L<JSON::XS>,
L<LWP::UserAgent>.

=head1 SEE ALSO

=over

=item L<App::Kramerius::URI>

Base class for kramerius-uri script.

=item L<Data::Kramerius>

Information about all Kramerius systems.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-Kramerius-V4>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
