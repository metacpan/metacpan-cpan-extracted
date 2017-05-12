# Verifies that version numbers are matching POD.
# This is a release test

use strict;
use warnings;
use Test::More tests => 1;

#eval "use version 0.74";
#plan skip_all => "Module 'version' required for checking version" if $@;

sub version_ok
{
    my $perl_file = shift;
    my $in_pod = 0;
    my ($f, $head1, $version_pod, $version_perl);
    open $f, '<', $perl_file;
    while (<$f>) {
        if (/^=cut(\s|#|$)/) {
            $in_pod = ! $in_pod;
            next;
        }
        if (/^=head1\s+(.*)\s*$/) {
            $in_pod = 1;
            $head1 = $1;
            next;
        }
        if ($in_pod) {
            if (defined $head1 && $head1 eq 'VERSION' && /Version\s*(\S+)/i) {
                $version_pod = $1;
                last if defined $version_perl;
            }
        } elsif (! defined $version_perl && /\$VERSION\s=/) {
            # TODO check CPAN implementation
            $version_perl = eval $_;
            last if defined $version_pod;
        }
    }
    close $f;
    SKIP: {
        skip "$perl_file: no version in POD", 1 unless $version_pod;
        skip "$perl_file: no version in Perl code", 1 unless $version_perl;
        is($version_pod, $version_perl, "POD version is matching Perl version");
    }
}

version_ok('lib/Acme/PM/Paris/Meetings.pm');