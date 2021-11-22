package App::Kramerius::To::Images;

use strict;
use warnings;

use App::Kramerius::V4;
use Class::Utils qw(set_params);
use Data::Kramerius;
use English;
use Error::Pure qw(err);
use Getopt::Std;
use HTTP::Request;
use IO::Barf qw(barf);
use JSON::XS;
use LWP::UserAgent;
use METS::Files;
use Perl6::Slurp qw(slurp);

our $VERSION = 0.03;

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
			err "Parameter 'lwp_user_agent' must be a LWP::UserAgent instance.";
		}
	} else {
		$self->{'lwp_user_agent'} = LWP::UserAgent->new;
		$self->{'lwp_user_agent'}->agent('kramerius2images/'.$VERSION);
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
		'q' => 0,
		'v' => 0,
	};
	if (! getopts('hqv', $self->{'_opts'}) || (! -r 'ROOT' && @ARGV < 2)
		|| $self->{'_opts'}->{'h'}) {

		print STDERR "Usage: $0 [-h] [-q] [-v] [--version] [kramerius_id object_id]\n";
		print STDERR "\t-h\t\tHelp.\n";
		print STDERR "\t-q\t\tQuiet mode.\n";
		print STDERR "\t-v\t\tVerbose mode.\n";
		print STDERR "\t--version\tPrint version.\n";
		print STDERR "\tkramerius_id\tKramerius system id. e.g. ".
			"mzk\n";
		print STDERR "\tobject_id\tKramerius object id (could be ".
			"page, series or book edition).\n";
		return 1;
	}
	my ($kramerius_id, $object_id);
	if (@ARGV > 1) {
		$kramerius_id = shift @ARGV;
		$object_id = shift @ARGV;
	} elsif (-r 'ROOT') {
		($kramerius_id, $object_id) = slurp('ROOT', { chomp => 1 });
	} else {
		err 'Cannot read library id and work id.';
	}

	$self->{'_kramerius_obj'} = $self->{'_kramerius'}->get($kramerius_id);
	if (! defined $self->{'_kramerius_obj'}) {
		err "Library with ID '$kramerius_id' is unknown.";
	}
	barf('ROOT', <<"END");
$kramerius_id
$object_id
END

	my $quiet = '-q ';
	if ($self->{'_opts'}->{'v'}) {
		$quiet = '';
	}

	my @pages;
	if ($self->{'_kramerius_obj'}->version == 3) {

		# URI for METS.
		my $mets_uri = $self->{'_kramerius_obj'}->url.'kramerius/mets/'.$kramerius_id.
			'/'.$object_id;

		# Get METS.
		if ($self->{'_opts'}->{'v'}) {
			print "Downloads $mets_uri\n";
		}
		my $req = HTTP::Request->new('GET' => $mets_uri);
		my $res = $self->{'lwp_user_agent'}->request($req);
		my $mets;
		if ($res->is_success) {
			$mets = $res->content;

			# Get images from METS file.
			my $obj = METS::Files->new(
				'mets_data' => $mets,
			);

			# Get 'img' files.
			my @page_uris = $obj->get_use_files('img');

			if (! @page_uris) {
				err 'No images to download.';
			}

			# Get images.
			foreach my $page (@page_uris) {
				my $uri = URI->new($page);
				my @path_segments = $uri->path_segments;
				if (! -r $path_segments[-1]) {
					if (! $self->{'_opts'}->{'q'}) {
						print "$page\n";
					}
					$self->_download($page, $path_segments[-1]);
				}

				# Strip URI part.
				push @pages, $path_segments[-1];
			}

		# Direct file.
		} else {

			# TODO Stahnout primo soubor. Udelat na to skript.
			err "Cannot get '$mets_uri' URI.",
				'HTTP code', $res->code,
				'Message', $res->message;
		}

	} elsif ($self->{'_kramerius_obj'}->version == 4) {

		# URI for children JSON.
		my $json_uri = $self->{'_kramerius_obj'}->url.'search/api/v5.0/item/uuid:'.
			$object_id.'/children';

		# Get JSON.
		my $req = HTTP::Request->new('GET' => $json_uri);
		my $res = $self->{'lwp_user_agent'}->request($req);
		my $json;
		if ($res->is_success) {
			$json = $res->content;
			barf($object_id.'.json', $json);
		} else {
			err "Cannot get '$json_uri' URI.",
				'HTTP code', $res->code,
				'message', $res->message;
		}

		# Check JSON content type.
		if ($res->headers->content_type ne 'application/json') {
			err "Content type isn't 'application/json' for '$json_uri' URI.",
				'Content-Type', $res->headers->content_type;
		}

		# Get perl structure.
		my $json_ar = eval {
			JSON::XS->new->decode($json);
		};
		if ($EVAL_ERROR) {
			err "Cannot parse JSON on '$json_uri' URI.",
				'JSON decode error', $EVAL_ERROR;
		}

		# Each page.
		my $images = 0;
		foreach my $page_hr (@{$json_ar}) {
			if ($page_hr->{'model'} ne 'page') {
				next;
			}
			my $title = $self->_get_page_title($page_hr);
			my $pid = $page_hr->{'pid'};
			$pid =~ s/^uuid://ms;
			# TODO Support for page number in $pid =~ uuid:__uuid__@__page_number__ (PDF and number of page in PDF)
			if (! $self->{'_opts'}->{'q'}) {
				print "$pid: $title\n";
			}
			# XXX Support of jpg only
			if (! -r $pid.'.jpg') {
				$self->_do_command("kramerius4 $quiet $kramerius_id $pid");
			}
			push @pages, $pid.'.jpg';
			$images++;
		}

		# One page.
		if ($images == 0) {
			my $pid = $object_id;
			if (! $self->{'_opts'}->{'q'}) {
				print "$pid: ?\n";
			}
			# XXX Support of jpg only
			my $output_file = $pid.'.jpg';
			if (! -r $output_file) {
				$self->_do_command("kramerius4 $quiet $kramerius_id $pid");
			}
			push @pages, $output_file;
		}
	} else {
		err 'Bad version of Kramerius.',
			'Kramerius version', $self->{'_kramerius_obj'}->version;
	}
	barf('LIST', join "\n", @pages);

	return 0;
}

sub _download {
	my ($self, $uri, $local_file) = @_;

	$self->{'lwp_user_agent'}->get($uri,
		':content_file' => $local_file,
	);

	return;
}

# Get title from page.
sub _get_page_title {
	my ($self, $page_hr) = @_;

	my $title;
	if (ref $page_hr->{'title'} eq 'ARRAY') {
		$title = $page_hr->{'title'}->[0];
	} elsif (ref $page_hr->{'title'} eq '') {
		$title = $page_hr->{'title'};
	} else {
		err "Cannot get title for page '$page_hr->{'pid'}.'.";
	}
	$title =~ s/\s+/_/msg;

	return $title;
}

sub _do_command {
	my ($self, $command) = @_;

	if ($self->{'_opts'}->{'v'}) {
		print $command."\n";
	}

	system $command;
}

1;

=pod

=encoding utf8

=head1 NAME

App::Kramerius::To::Images - Base class for kramerius2images script.

=head1 SYNOPSIS

 use App::Kramerius::To::Images;

 my $app = App::Kramerius::To::Images->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::Kramerius::To::Images->new;

Constructor.

Returns instance of object.

=head2 C<run>

 my $exit_code = $app->run;

Run.

Returns 1 for error, 0 for success.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         Parameter 'lwp_user_agent' must be a LWP::UserAgent instance.

 run():
         Bad version of Kramerius.
                 Kramerius version: %s
         Cannot get title for page '%s'.
         Cannot get '%s' URI.
                 HTTP code: %s
                 message: %s
         Cannot parse JSON on '%s' URI.
                 JSON decode error: %s
         Cannot read library id and work id.
         Content type isn't 'application/json' for '%s' URI.
                 Content-Type: %s
         Library with ID '%s' is unknown.
         No images to download.

=head1 EXAMPLE

 use strict;
 use warnings;

 use App::Kramerius::To::Images;

 # Arguments.
 @ARGV = (
         '-h',
 );

 # Run.
 exit App::Kramerius::To::Images->new->run;

 # Output like:
 # Usage: ./ex1.pl [-h] [-q] [-v] [--version] [kramerius_id object_id]
 #         -h              Help.
 #         -q              Quiet mode.
 #         -v              Verbose mode.
 #         --version       Print version.
 #         kramerius_id    Kramerius system id. e.g. mzk
 #         object_id       Kramerius object id (could be page, series or book edition).

=head1 DEPENDENCIES

L<App::Kramerius::V4>,
L<Class::Utils>,
L<Data::Kramerius>,
L<English>,
L<Error::Pure>,
L<Getopt::Std>,
L<HTTP::Request>,
L<IO::Barf>,
L<JSON::XS>,
L<LWP::UserAgent>,
L<METS::Files>,
L<Perl6::Slurp>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-Kramerius-To-Images>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
