package Attribute::Contract::Utils;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT = qw(build_check);

sub build_check {
    my ($package, $name, $code_ref, $import, $attributes) = @_;

    $attributes = '' unless defined $attributes;

    my $prefix = '';
    $prefix .= 'use Type::Params compile => {confess => 1};';
    foreach my $key (keys %$import) {
        if ($key eq '-types') {
            my @types =
              ref $import->{$key} ? @{$import->{$key}} : ($import->{$key});
            $prefix .= "use Types::Standard qw(@types);";
        }
        elsif ($key eq '-library') {
            my $lib = $import->{$key};
            foreach my $library (ref $lib ? @$lib : $lib) {
                $prefix .= "use $library -types;";
            }
        }
    }

    my $ref = eval "$prefix; Type::Params::compile($attributes)"
      or die "Can't compile types: $@";
    return $ref;
}

1;
