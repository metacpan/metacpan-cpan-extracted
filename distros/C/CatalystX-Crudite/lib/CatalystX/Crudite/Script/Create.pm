package CatalystX::Crudite::Script::Create;
use strict;
use warnings;
use Try::Tiny;
use Class::Load qw(load_class);

sub run {
    my $dist_name = shift;
    my $type      = shift @ARGV;
    my $class     = __PACKAGE__ . "::\L\u$type";
    try {
        load_class($class);
    }
    catch {
        my $E = shift;
        print "can't load creator for type [$type]\n";
        die $E;
    };
    $class->run($dist_name);
}
1;
