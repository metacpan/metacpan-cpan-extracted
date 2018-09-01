#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use FindBin '$Bin';
use Template;
use C::Utility qw/linein lineout/;
chdir $Bin or die $!;
my %vars = (statuses => [qw/good great super fantastic/]);
my $tt = Template->new (INCLUDE_DIR => '.');
my $textin = linein ('status-c-tmpl');
$tt->process (\$textin, \%vars, \my $textout);
lineout ($textout, 'status.c');

