# CVE-Client: CLI-based client / toolbox for CVE.org
# Copyright © 2021-2023 CVE-Client Authors <https://hacktivis.me/git/cve-client/>
# SPDX-License-Identifier: AGPL-3.0-only
package App::CveClient;
our $VERSION = 'v1.0.5';

use warnings;
use strict;

use Exporter qw(import);

our @EXPORT_OK = qw(print_cve print_cve50 print_cve40);

sub print_cve {
	my ($object, $cve_id, $format) = @_;

	print "CVE ID: ", $cve_id, "\n";

	if ($object->{'error'} and $object->{'message'}) {
		die "Error ($object->{'error'}): $object->{'message'}\n";
	}

	if ($object->{'dataVersion'} == "5.0") {
		print_cve50($object, $cve_id, $format);
	} elsif ($object->{'data_version'} == "4.0") {
		print_cve40($object, $cve_id, $format);
	} else {
		print STDERR "Error: unknown CVE format:\n";
		print STDERR "- data_version: ", $object->{'data_version'}, "\n"
		  if $object->{'data_version'};
		print STDERR "- dataVersion: ", $object->{'dataVersion'}, "\n"
		  if $object->{'dataVersion'};
	}
}

# https://github.com/CVEProject/cve-schema/blob/master/schema/v5.0/
sub print_cve50 {
	my ($object, $cve_id, $format) = @_;

	if ($object->{'cveMetadata'}->{'cveId'} ne $cve_id) {
		print STDERR "Warning: Got <", $object->{'cveMetadata'}->{'cveId'},
		  "> instead of <", $cve_id, ">\n";
	}

	my $affected = $object->{'containers'}->{'cna'}->{'affected'};
	if ($affected) {
		foreach (@{$affected}) {
			print "Vendor Name: ",  $_->{'vendor'},  "\n";    # vendor required
			print "Product Name: ", $_->{'product'}, "\n";    # product required

			foreach (@{$_->{'versions'}}) {
				print "- ", $_->{'status'}, ": ", $_->{'version'}, "\n";
			}
		}
	} else {
		print STDERR
"Warning: No CVE affected versions could be found! (as required by the spec)\n";
	}

	print "\n";

	my $metrics = $object->{'containers'}->{'cna'}->{'metrics'};
	if ($metrics) {
		foreach (@{$metrics}) {
			if ($_->{'cvssV3_1'}) {
				my $metric = $_->{'cvssV3_1'};
				print "- Score: ", $metric->{'baseScore'}, " ",
				  $metric->{'baseSeverity'}, "\n";
			} else {
				print "Notice: unhandled metrics (CVSS) data\n";
			}
		}
	} else {
		print STDERR
"Warning: No CVE metrics (CVSS) could be found! (as required by the spec)\n";
	}

	print "\n";

	my $desc = $object->{'containers'}->{'cna'}->{'descriptions'};
	if ($desc) {
		foreach (@{$desc}) {
			print "Description Language: ", $_->{'lang'},  "\n";
			print "Description:\n",         $_->{'value'}, "\n\n";
		}
	} else {
		print STDERR
"Warning: No CVE description could be found! (as required by the spec)\n";
	}

	print "\n";

	my $refs = $object->{'containers'}->{'cna'}->{'references'};
	if ($refs) {
		print "References: \n";

		foreach (@{$refs}) {
			print "=> ", $_->{'url'}, "\n";
		}
	} else {
		print STDERR
"Warning: No CVE references could be found! (as required by the spec)\n";
	}
}

# https://github.com/CVEProject/cve-schema/blob/master/schema/v4.0/
sub print_cve40 {
	my ($object, $cve_id, $format) = @_;

	if ($object->{'CVE_data_meta'}->{'ID'} ne $cve_id) {
		print STDERR "Warning: Got ", $object->{'CVE_data_meta'}->{'ID'},
		  " instead of ", $cve_id, "\n";
	}

	print "TITLE: ", $object->{'CVE_data_meta'}->{'TITLE'}, "\n"
	  if $object->{'CVE_data_meta'}->{'TITLE'};

	print "\n";

	if ($object->{'affects'}->{'vendor'}) {
		foreach (@{$object->{'affects'}->{'vendor'}->{'vendor_data'}}) {
			print "Vendor Name: ", $_->{'vendor_name'}, "\n"
			  if $_->{'vendor_name'};

			foreach (@{$_->{'product'}->{'product_data'}}) {
				print "Product name: ", $_->{'product_name'}, "\n";
				print "Product versions: ";

				foreach (@{$_->{'version'}->{'version_data'}}) {
					print $_->{'version_value'}, "; ";
				}

				print "\n";
			}
		}
	}

	print "\n";

	if ($object->{'description'}->{'description_data'}) {
		my $descs = $object->{'description'}->{'description_data'};

		foreach (@{$descs}) {
			print "Description Language: ", $_->{'lang'},  "\n";
			print "Description:\n",         $_->{'value'}, "\n\n";
		}
	} else {
		print STDERR "Warning: No CVE description could be found!\n";
	}

	if ($object->{'references'}->{'reference_data'}) {
		my $refs = $object->{'references'}->{'reference_data'};

		foreach (@{$refs}) {
			if ($format == 'gemini') {
				print "Reference Source: ", $_->{'refsource'}, "\n";

				print "=> ", $_->{'url'} if $_->{'url'};
				if ($_->{'name'}) {
					print " ", $_->{'name'}, "\n\n";
				} else {
					print "\n\n";
				}
			} else {
				print "Reference Source: ", $_->{'refsource'}, "\n";
				print "- Name: ",           $_->{'name'}, "\n" if $_->{'name'};
				print "- URL: ",            $_->{'url'},  "\n" if $_->{'url'};
				print "\n";
			}
		}
	} else {
		print STDERR "Warning: No CVE references could be found!\n";
	}
}

1;
