#!perl -w

# CGI::Lingua must load and work with only its PREREQ_PM installed.
# A child perl hides every optional ("recommends") and test-only module,
# loads the module and negotiates a language.  This catches a prerequisite
# that is only installed because the tests need it: 0.87 needed
# IPC::System::Simple through "use autodie qw(:all)" without declaring it,
# and so does Object::Configure 0.24, which is why 0.25 is the minimum.
# IPC::System::Simple is not hidden: Object::Configure 0.25 requires it.

use strict;
use warnings;

use Readonly;
use Test::Most;
use Test::Needs qw(Test::Without::Module IPC::Run3 File::Temp);

Readonly my $MARKER => 'MINIMAL-DEPS:';

# Keep in step with optional_features and TEST_REQUIRES in Makefile.PL
Readonly my @HIDDEN => qw(
	IP::Geolocation::MMDB MaxMind::DB::Reader IP::Country IP::Country::Fast
	Geo::IP Geo::IPfree Net::Subnet Data::Validate::IP NetAddr::IP
	JSON::Parse LWP::Simple::WithCache LWP::Simple
	DateTime::TimeZone DateTime::TimeZone::Local CGI::Info
	CHI IPC::Run3 Test::Mockingbird Test::Log::Abstraction
	Test::Permissions Test::Returns
);

# A file, not "perl -e": Windows mangles a multi-line -e argument
Readonly my $CHILD => <<"EOF";
use strict;
use warnings;
use CGI::Lingua;

local \%ENV = (HTTP_ACCEPT_LANGUAGE => 'fr-FR,fr;q=0.8,en;q=0.5');
my \$l = CGI::Lingua->new(supported => ['en', 'fr'], dont_use_ip => 1);
print '$MARKER', join('|', \$l->language(), \$l->language_code_alpha2(), \$l->text_direction()), "\\n";
EOF

my ($fh, $script) = File::Temp::tempfile(SUFFIX => '.pl', UNLINK => 1);
print {$fh} $CHILD;
close $fh;

# Under "cover -test" pass Devel::Cover on to the child
my @cover = grep { /^-MDevel::Cover\b/ } split(/\s+/, $ENV{HARNESS_PERL_SWITCHES} // '');

my ($out, $err) = ('', '');
{
	# PERL5OPT (for example a Test::Without::Module list) must not change
	# what the child sees
	local $ENV{PERL5OPT};
	IPC::Run3::run3(
		[ $^X, @cover, '-Ilib', '-MTest::Without::Module=' . join(',', @HIDDEN), $script ],
		\undef, \$out, \$err,
	);
}
my $status = $? >> 8;
diag("child stdout: $out\nchild stderr: $err") if($ENV{TEST_VERBOSE});

is($status, 0, 'CGI::Lingua loads with only its prerequisites') or diag($err);
my ($answer) = $out =~ /^\Q$MARKER\E(.*)$/m;
ok(defined($answer), 'the child printed an answer') or diag(length($out) ? $out : 'child printed nothing');
is($answer, 'French|fr|ltr', 'and negotiates the language');
is($err, '', 'without warnings');

done_testing();
