#!perl
# -*- perl -*-
#
# DO NOT EDIT, created automatically by mkprereqinst.pl

# on Sat May 10 14:26:25 2003
#

use Getopt::Long;
my $require_errors;
my $use = 'cpan';

if (!GetOptions("ppm"  => sub { $use = 'ppm'  },
		"cpan" => sub { $use = 'cpan' },
	       )) {
    die "usage: $0 [-ppm | -cpan]\n";
}

if ($use eq 'ppm') {
    require PPM;
    do { print STDERR 'Install WWW-Scraper'.qq(\n); PPM::InstallPackage(package => 'WWW-Scraper') or warn ' (not successful)'.qq(\n); } if !eval 'require WWW::Scraper; WWW::Scraper->VERSION(3.01)';
} else {
    use CPAN;
    install 'WWW::Scraper' if !eval 'require WWW::Scraper; WWW::Scraper->VERSION(3.01)';
}
if (!eval 'require WWW::Scraper; WWW::Scraper->VERSION(3.01);') { warn $@; $require_errors++ }warn "Autoinstallation of prerequisites completed\n" if !$require_errors;
