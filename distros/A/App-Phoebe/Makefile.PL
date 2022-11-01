use 5.008004;
use ExtUtils::MakeMaker;

os_unsupported if $^O eq 'MSWin32';

WriteMakefile(
  NAME             => 'App::Phoebe',
  VERSION_FROM     => 'lib/App/Phoebe.pm',
  ABSTRACT         => 'a Gemini-based wiki',
  AUTHOR           => 'Alex Schroeder',
  LICENSE          => 'agpl_3',
  MIN_PERL_VERSION => '5.26.0', # Modern::Perl '2018'
  EXE_FILES        => [
    'script/phoebe',
    'script/phoebe-ctl',
    'script/gemini',
    'script/gemini-chat',
    'script/titan',
    'script/ijirait',
    'script/spartan',
  ],
  PREREQ_PM => {
    # t/prerequisites.t is serious about all these!
    'Modern::Perl' => 1.20180701, # for '2018'
    'URI::Escape' => 0,
    'Encode::Locale' => 0,
    'Algorithm::Diff' => 0,
    'File::ReadBackwards' => 0,
    'File::Slurper' => 0,
    'Mojolicious' => 9.00,        # removed tls_verify from Mojo::IOLoop::TLS 9.0
    'IO::Socket::SSL' => 2.069,   # optional for Mojo::IOLoop
    'Net::SSLeay' => 1.90,
    'Net::IDN::Encode' => 0,
    'IRI' => 0,                   # for script/gemini
    'Text::Wrapper' => 0,         # Gopher.pm
    'File::MimeInfo' => 0,        # Iapetus.pm, Capsules.pm
    'File::MimeInfo::Magic' => 0, # WebDAV.pm
    'IO::Scalar' => 0,            # WebDAV.pm
    'HTTP::Date' => 0,            # WebDAV.pm
    'XML::LibXML' => 0,           # WebDAV.pm
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
	type => 'git',
	url  => 'https://alexschroeder.ch/cgit/phoebe',
	web  => 'https://alexschroeder.ch/cgit/phoebe/about/',
      },
    },
  },
  clean => {
    FILES => "test-[0-9][0-9][0-9][0-9] t/*.pem",
  },
);

sub MY::postamble {
  return <<'PHOEBE_TARGETS';

# Check for syntax and documentation formatting errors
check:
	find lib -name '*.pm' -exec perl -Ilib -c '{}' ';' -exec podchecker '{}' ';'

# Start the wiki with the default options (using 'wiki' in the current
# directory as the data directory). This also uses unsafe certificates
# from the test directory. Don't use them in production. See the cert
# target to make your own. :)
start:
	./t/cert.pl
	./script/phoebe \
	  --cert_file=./t/cert.pem \
	  --key_file=./t/key.pem

# Start the wiki as a daemon with the default options, but also server
# port 443 (HTTPS). As this is a port below 1024 it is priviledged and
# requires the use of 'sudo'; the --user and --group options make sure
# that it drops priviledges to the current user as soon as it started.
web:
	./t/cert.pl
	sudo ./script/phoebe \
	  --cert_file=./t/cert.pem \
	  --key_file=./t/key.pem \
          --user=$(shell id -un) --group=$(shell id -gn) \
          --port=443 --port=1965

# Start the wiki on port 2020, with debug log level, two example
# spaces, allowing the upload of JPEG files, and use 'morbo' (which is
# part of the Mojolicious Perl package) to watch for changes of the
# code: when it detects a change, the server is restarted
# automatically.
dev:
	morbo --watch ./script/phoebe \
	      --watch ./wiki/config -- \
	  ./script/phoebe \
	    --host localhost --host 127.0.0.1 --port=2020 \
	    --wiki_space=127.0.0.1/alex --wiki_space=localhost/berta \
	    --log_level=4 --wiki_main_page=Welcome \
	    --wiki_mime_type=image/jpeg

# Update the README file.
README.md: script/phoebe \
  $(sort $(filter-out phoebe,$(filter-out %~,$(wildcard script/*)))) \
  lib/App/Phoebe.pm $(sort $(wildcard lib/App/Phoebe/*.pm))
	./update-readme $^

# Run the test using multiple jobs.
parallel-test:
	prove --state=slow,save --jobs 4 t/

# Run the tests individually, with the server logging debug output,
# and with the test output getting printed instead of being
# aggregated.
debug:
	for t in t/*.t; do DEBUG=4 perl "$$t"; done

# Regenerate the certificates used by the wiki. These use eliptic
# curves and are valid for five years, for a common name "Phoebe"
# (which is not used) and multiple alternative subject names (add more
# and different ones).
cert:
	openssl req -new -x509 -newkey ec \
	-pkeyopt ec_paramgen_curve:prime256v1 \
        -subj "/CN=Phoebe" \
        -addext "subjectAltName=DNS:localhost,DNS:phoebe.local" \
	-days 1825 -nodes -out cert.pem -keyout key.pem

# Print all the info about the certificate.
cert-info:
	openssl x509 -in cert.pem -text

# Generate client certificates for testing. These use eliptic
# curves and are valid for five years.
client-cert:
	openssl req -new -x509 -newkey ec \
	-pkeyopt ec_paramgen_curve:prime256v1 \
	-days 1825 -nodes -out client-cert.pem -keyout client-key.pem

# Generates the fingerprint of the client certificate in a form
# suitable for comparison with fingerprints by IO::Socket::SSL.
client-fingerprint:
	openssl x509 -in client-cert.pem -noout -sha256 -fingerprint \
	| sed -e 's/://g' -e 's/SHA256 Fingerprint=/sha256$$/' | tr [:upper:] [:lower:]

PHOEBE_TARGETS
}
