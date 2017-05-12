#!/usr/bin/env perl 

# Modules {{{
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use strict;
use warnings;
use Test::More tests => 1;
use Acpi::Class::Attributes;
# }}}

# Define Variables {{{
my $value = Acpi::Class::Attributes->new( path => "$Bin/../../../lib/Acpi" )->attributes->{'test'};
my $content = "yes";
#}}}

ok( $value = $content, "Acpi::Class::Attributes reads file");

done_testing( 1 );
