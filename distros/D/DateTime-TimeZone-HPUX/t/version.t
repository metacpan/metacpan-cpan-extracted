#!perl -w

# Verifies that version numbers are matching POD.
# This is a release test

use strict;
use warnings;
use Test::More;


sub package_to_pm($)
{
    my $module = shift;
    $module =~ s{::}{/}g;
    return "$module.pm";
}


sub pod_version_ok($)
{
    my $perl_file = shift;
    my $in_pod = 0;
    my ($f, $head1, $version_pod, $version_perl);
    if (!open($f, '<', $perl_file)) {
        fail "$perl_file: $!";
        return;
    }
    while (<$f>) {
        if (/^=cut(\s|#|$)/) {
            $in_pod = ! $in_pod;
            next;
        }
        if (/^=head1\s+(.*\S)\s*$/) {
            $in_pod = 1;
            $head1 = $1;
            next;
        } elsif (/^=\w+/) {
            $in_pod = 1;
            next;
        }
        if ($in_pod) {
            if (defined $head1 && $head1 eq 'VERSION' && (/Version\s*(\S+)/i || /(?:^|: )(\d+\S*)/)) {
                $version_pod = $1;
                last if defined $version_perl;
            }
        } elsif (! defined $version_perl && /[^#]*\$VERSION\s=/) {
            # TODO check using the CPAN.pm implementation
            $version_perl = eval $_;
            last if defined $version_pod;
        }
    }
    close $f;
    SKIP: {
        skip "$perl_file: no version in POD", 1 unless $version_pod;
        skip "$perl_file: no version in Perl code", 1 unless $version_perl;
        is($version_pod, $version_perl, "POD version is matching Perl code version ($version_perl)");
    }
}

sub Changes_ok($)
{
    my $package = shift;
    require(package_to_pm($package));
    my $version = $package->VERSION;
    my $version_re = qr/^\Q$version\E\s+/;
    my $ok = 0;

    open(my $f, '<', 'Changes') or die $!;
    while (<$f>) {
        next unless /$version_re/;
        $ok = 1;
        last;
    }
    close $f;
    ok($ok, "Changes recorded for this version $version");
}


plan tests => 4;

pod_version_ok('lib/DateTime/TimeZone/HPUX.pm');
pod_version_ok('lib/DateTime/TimeZone/Local/hpux.pm');
pod_version_ok('lib/DateTime/TimeZone/HPUX/Map.pm');
Changes_ok('DateTime::TimeZone::HPUX');


# vim:set ts=4 et sw=4:
