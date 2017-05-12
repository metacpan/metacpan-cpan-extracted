use warnings;
use strict;

use IO::File 1.13;
use Test::More tests => 36;

require_ok "DateTime::TimeZone::Tzfile";

my $tz;

sub new_fh() {
	my $fh;
	($fh = IO::File->new("t/London.tz")) && $fh->binmode or die $!;
	return $fh;
}

$tz = DateTime::TimeZone::Tzfile->new("t/London.tz");
ok $tz;
is $tz->name, "t/London.tz";

$tz = DateTime::TimeZone::Tzfile->new(filename => "t/London.tz");
ok $tz;
is $tz->name, "t/London.tz";

$tz = DateTime::TimeZone::Tzfile->new(filename => "t/London.tz",
	name => "foobar");
ok $tz;
is $tz->name, "foobar";

$tz = DateTime::TimeZone::Tzfile->new(name => "foobar",
	filename => "t/London.tz");
ok $tz;
is $tz->name, "foobar";

my $fh = new_fh();
$tz = DateTime::TimeZone::Tzfile->new(name => "foobar", filehandle => $fh);
ok $tz;
is $tz->name, "foobar";
ok $fh->eof;

$fh = new_fh();
{ local $/ = \1; defined $fh->getline or die "read error: $!"; }
eval { DateTime::TimeZone::Tzfile->new(name => "foobar", filehandle => $fh); };
like $@, qr/\Abad tzfile: wrong magic number\b/;

eval { DateTime::TimeZone::Tzfile->new(); };
like $@, qr/\Afile not specified\b/;

eval { DateTime::TimeZone::Tzfile->new(name => "foobar"); };
like $@, qr/\Afile not specified\b/;

eval { DateTime::TimeZone::Tzfile->new(quux => "foobar"); };
like $@, qr/\Aunrecognised attribute\b/;

eval { DateTime::TimeZone::Tzfile->new(name => "foobar", name => "quux"); };
like $@, qr/\Atimezone name specified redundantly\b/;

eval {
	DateTime::TimeZone::Tzfile->new(category => "foobar",
		category => "quux");
};
like $@, qr/\Acategory value specified redundantly\b/;

eval { DateTime::TimeZone::Tzfile->new(is_olson => 1, is_olson => 1); };
like $@, qr/\Ais_olson flag specified redundantly\b/;

eval { DateTime::TimeZone::Tzfile->new(filehandle => new_fh()); };
like $@, qr/\Atimezone name not specified\b/;

eval {
	DateTime::TimeZone::Tzfile->new(filename => "t/London.tz",
		filename => "t/London.tz");
};
like $@, qr/\Afilename specified redundantly\b/;

eval {
	DateTime::TimeZone::Tzfile->new(filehandle => new_fh(),
		filename => "t/London.tz");
};
like $@, qr/\Afilename specified redundantly\b/;

eval {
	DateTime::TimeZone::Tzfile->new(filename => "t/London.tz",
		filehandle => new_fh());
};
like $@, qr/\Afilehandle specified redundantly\b/;

eval {
	DateTime::TimeZone::Tzfile->new(filehandle => new_fh(),
		filehandle => new_fh());
};
like $@, qr/\Afilehandle specified redundantly\b/;

foreach(
	undef,
	[],
	*STDOUT,
	bless({}),
) {
	eval { DateTime::TimeZone::Tzfile->new(name => $_) };
	like $@, qr/\Atimezone name must be a string\b/;
	if(defined $_) {
		eval { DateTime::TimeZone::Tzfile->new(category => $_) };
		like $@, qr/\Acategory value must be a string or undef\b/;
	}
	eval { DateTime::TimeZone::Tzfile->new(filename => $_) };
	like $@, qr/\Afilename must be a string\b/;
}

eval { DateTime::TimeZone::Tzfile->new(filename => "t/notexist.tz"); };
like $@, qr#\Acan't read t/notexist\.tz: #;

1;
