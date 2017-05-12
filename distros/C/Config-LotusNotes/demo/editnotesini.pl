# This script illustrates how to retrieve, set and delete values from/to
# a notes.ini file. It works on the notes.ini of your default installation.

use strict;
use warnings;
use Config::LotusNotes 0.30;

my $usage = << "EOF";
notesinivalues.pl - get and set notes ini values for default Notes installation

  getting values:
    notesinivalues.pl parameter1 [parameter2 ...]
  setting values:
    notesinivalues.pl parameter1=value1 [parameter2=value2 ...]
  deleting values:
    notesinivalues.pl parameter1= [parameter2= ...]
EOF

my $notesini = Config::LotusNotes->new()->default_configuration() 
    or die "no Notes installtion found\n$usage";

die "Please supply a parameter name.\n$usage" unless @ARGV;

foreach my $argument (@ARGV) {
    if ($argument =~ /=/) {
        my ($key, $value) = $argument =~ /^([^=]+)=(.*)/;
        if ($value eq '') {
            print "DELETING $key\n";
            $notesini->set_environment_value($key, undef);
        }
        else {
            print "SETTING $key = $value\n";
            $notesini->set_environment_value($key, $value);
        }
    }
    else {
        my $value = $notesini->get_environment_value($argument);
        if (defined $value) {
            print "$argument = $value\n";
        }
        else {
            print STDERR "WARNING: the parameter \"$argument\" is not defined\n";
        }
    }
}