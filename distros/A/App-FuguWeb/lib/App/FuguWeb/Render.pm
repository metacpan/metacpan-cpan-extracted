# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package App::FuguWeb::Render;
our $VERSION = '0.1.1';

use App::FuguWeb::Manual;
use Fugu::Log;
use Fugu::Process;

# App::FuguWeb::Render - the three external renderers.
#
# The tool renders no format itself. mandoc turns mdoc into HTML,
# lowdown turns Markdown into HTML, and pod2man turns POD into mdoc for
# mandoc to finish. Each one is a mature program that reads a format
# this project already writes; a Perl reimplementation would be a
# second, worse one.
#
# Every method returns the output as bytes, or undef with a message in
# the log. The class keeps no state beyond the tool names and the
# options that the site description decided.

# The three programs, and the name of each in the diagnostics.
use constant {
	DEFAULT_MANDOC  => 'mandoc',
	DEFAULT_LOWDOWN => 'lowdown',
	DEFAULT_POD2MAN => 'pod2man',
};

# The pod2man --center and --release values. They are constants and
# not settings: they pin the pod2man output so the site does not vary
# with the build host. Without them, pod2man writes its own center
# text and the perl version of the machine that built the site.
use constant {
	POD_CENTER  => 'Perl Library Manual',
	POD_RELEASE => 'OpenBSD',
};

# App::FuguWeb::Render->new(%args):
#	config  => $config	the site description (required)
#	log     => $logger	default: Fugu::Log->default
#	mandoc  => $program	default: mandoc
#	lowdown => $program	default: lowdown
#	pod2man => $program	default: pod2man
#
#	The tool names are overridable, so a caller can name another
#	binary and a test can name one that is not there.
sub new ( $class, %args )
{
	my $config = $args{config};
	die 'config parameter required'
	    unless defined $config;

	return bless {
		config  => $config,
		log     => $args{log}     // Fugu::Log->default,
		mandoc  => $args{mandoc}  // DEFAULT_MANDOC,
		lowdown => $args{lowdown} // DEFAULT_LOWDOWN,
		pod2man => $args{pod2man} // DEFAULT_POD2MAN,
	}, $class;
}

# $self->probe:
#	Return the name of the first renderer that is not on the path,
#	or undef when all three are there. The caller reports the name
#	and exits with EXIT_TOOL_MISSING, so an operator learns which
#	package to install and not that "the build failed".
sub probe ($self)
{
	for my $tool (qw(mandoc lowdown pod2man)) {
		my $program = $self->{$tool};
		return $program unless _on_path($program);
	}

	return;
}

# $self->lint(@paths):
#	Run mandoc over every mdoc source in warning mode. The method
#	returns true when every page is clean, and undef with the
#	diagnostics in the log otherwise. A malformed page must fail
#	the build, not render badly.
sub lint ( $self, @paths )
{
	return 1 unless @paths;

	my $result = Fugu::Process->run(
		cmd => [ $self->{mandoc}, '-Tlint', '-W', 'warning', @paths ],
	);
	return 1 if $result->{success};

	$self->{log}->error('mandoc rejected a manual source:');

	# mandoc -Tlint writes its diagnostics to standard output, not
	# to standard error. A caller that logged only stderr would
	# report the failure with no line, no column and no reason.
	my $said = join "\n", grep { defined } $result->{stdout},
	    $result->{stderr}, $result->{error};
	$self->{log}->error( '%s', $_ ) for grep { length } split /\n/, $said;

	return;
}

# $self->markdown($path):
#	Render one Markdown file into an HTML body fragment.
sub markdown ( $self, $path )
{
	return $self->_capture( 'lowdown',
		[ $self->{lowdown}, '-Thtml', $path ] );
}

# $self->mdoc($file, $dir):
#	Render one staged mdoc source into an HTML body fragment. The
#	child runs in $dir, because mandoc decides between a local link
#	and a link to the manual host by looking for a file named %N.%S
#	in its working directory.
sub mdoc ( $self, $file, $dir )
{
	return $self->_capture(
		'mandoc',
		[ $self->{mandoc}, $self->html_options, $file ],
		cwd => $dir
	);
}

# $self->pod($path, $name, $date):
#	Render one POD sidecar into an HTML body fragment. pod2man
#	writes mdoc, and mandoc finishes the job, so a module page
#	carries the same chrome as a hand-written manual.
#
#	The date comes from the caller and never from the file time.
#	git does not preserve file times, so a build that read one
#	would give different bytes on every checkout.
sub pod ( $self, $path, $name, $date )
{
	my $man = Fugu::Process->run(
		cmd => [
			$self->{pod2man},
			'--section=' . App::FuguWeb::Manual::POD_SECTION,
			"--name=$name",
			"--date=$date",
			'--center=' . POD_CENTER,
			'--release=' . POD_RELEASE,
			$path,
		],
	);

	# pod2man reports a malformed directive on standard error and
	# still writes the page. The page is what the site needs, so a
	# diagnostic is a warning and only empty output is fatal.
	unless ( $man->{success} ) {
		$self->{log}->warning( 'pod2man on %s: %s', $path, $_ )
		    for grep { length } split /\n/, $man->{stderr} // '';
	}
	unless ( length( $man->{stdout} // '' ) ) {
		$self->{log}->error( 'pod2man produced nothing for %s', $path );
		return;
	}

	return $self->_capture(
		'mandoc',
		[ $self->{mandoc}, $self->html_options ],
		stdin => $man->{stdout} );
}

# $self->html_options:
#	The mandoc options that every page shares.
#
#	-I os= pins the footer, which otherwise names the operating
#	system of the build host, and the site would then vary with the
#	machine that built it.
#
#	The './' in the man= template matters. A module page is named
#	Fugu::Daemon.3p.html, and a browser reads a relative URL whose
#	first segment holds a colon as a scheme.
sub html_options ($self)
{
	my $config = $self->{config};

	return (
		'-Thtml', '-I', 'os=' . $config->mandoc_os,
		'-O', 'fragment,man=./%N.%S.html;' . $config->man_url . '%N.%S',
	);
}

# $self->_capture($tool, $cmd, %args):
#	Run one renderer and return its output. A failure names the
#	tool and carries its diagnostics into the log.
sub _capture ( $self, $tool, $cmd, %args )
{
	my $result = Fugu::Process->run( cmd => $cmd, %args );
	unless ( $result->{success} ) {
		$self->{log}->error(
			'%s failed: %s',
			$tool,
			$result->{error} // 'exit code ' . $result->{exit_code}
		);
		$self->{log}->error( '%s', $_ )
		    for grep { length } split /\n/, $result->{stderr} // '';
		return;
	}

	return $result->{stdout};
}

# _on_path($program):
#	Report whether the program can be executed. A path with a
#	separator in it is tested as it stands; a bare name is looked
#	for in PATH, as the shell would.
sub _on_path ($program)
{
	return -x $program ? 1 : 0 if $program =~ m{/};

	for my $dir ( split /:/, $ENV{PATH} // '' ) {
		next unless length $dir;
		return 1 if -x "$dir/$program";
	}

	return 0;
}

1;
