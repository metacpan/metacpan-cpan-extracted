use strict;
use warnings;

use Test::More tests => 2;
use Test::Warn;
use Acme::Warn::LOLCAT;

warnings_like(sub { warn "ease" }, [qr/EEZ AT T\/ACME-WARN-LOLCAT\.T LINE 8/]);
warnings_like(sub { foo() },       [qr/EEZ AT T\/ACME-WARN-LOLCAT\.T LINE 11/]);

sub foo { warn "ease" };

