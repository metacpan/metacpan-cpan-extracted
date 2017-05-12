use warnings;
use strict qw/subs refs/;

use File::Spec;
use File::Path;

$^W = 0; # @Test::Harness::ISA=qw(Shit);
$::name or die "No \$name specified...";

$tmpdir = ",test-temp-$name";
eval { rmtree($tmpdir); }; # Remove old crap...
mkpath($tmpdir); # Create temporary directory...

sub finalize {
    if($?) {
	diag("Preserving temporary data in $tmpdir")
    } else {
	rmtree($tmpdir);
    }
}

sub tf {
    File::Spec->catfile($tmpdir, @_);
}

sub puttemp {
    my ($name, $text, $layers) = @_;
    $layers ||= '';
    my $temp = tf($name);
    local *TF;
    open TF, ">$layers", $temp or die "Can't write $temp: $!";
    print TF $text;
    close TF;
    return $temp;
}

sub gettemp {
    my ($name, $layers) = @_;
    $layers ||= '';
    my $temp = tf($name);
    local *TF;
    local $/;
    open TF, "<$layers", $temp or die "Can't read $temp: $!";
    my $text = <TF>;
    close TF;
    return $text;
}

if($ENV{DEBUG}) {
    $VERBOSE = 1 unless defined $VERBOSE;
} else {
    $QUIET = 1 unless defined $QUIET;
}
use_ok('Config::Maker');

print STDERR $::ENCODING_LOG, "\n" if $::ENCODING_LOG;

1;

# arch-tag: e6538524-fdd6-419e-9b81-41dd0ba6e98c
# vim: set ft=perl:
