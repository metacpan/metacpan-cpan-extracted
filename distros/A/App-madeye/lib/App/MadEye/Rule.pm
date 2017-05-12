package App::MadEye::Rule;
use strict;
use warnings;
use App::MadEye::Util qw/get_schema_from_pod/;
use Kwalify ();

sub new {
    my ($class, $config) = @_;
    $config ||= {};
    if (my $schema = get_schema_from_pod($class)) {
        Kwalify::validate($schema, $config);
    }
    bless {config => $config}, $class;
}

sub config { $_[0]->{config} }

1;
