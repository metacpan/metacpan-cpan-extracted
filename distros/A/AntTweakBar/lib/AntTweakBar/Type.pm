package AntTweakBar::Type;

use 5.12.0;
use strict;
use warnings;

use Carp;
use Alien::AntTweakBar;
use AntTweakBar;


=head1 NAME

AntTweakBar::Type - User-defined variable types (enumerations) for AntTweakBar

=head1 SYNOPSIS

  my $framework_type = AntTweakBar::Type->new(
    "framework_type",
    [qw/Mojolicious Kelp Dancer Catalyst/],
  );

  my $fw_index = 1; # default will be Kelp
  $bar->add_variable(
    mode       => 'rw',
    name       => "used_framework",
    type       => $framework_type,
    value      => \$fw_index,
  );

  my $gender_type = AntTweakBar::Type->new(
    "gender_type",
    { male => 1, female => 2},
  );


=head1 DESCRIPTION

C<AntTweakBar::Type> allows to insert into bar variables of custom type.
Currently only enumerations are supported.

An perl variable must be refernce to integer; so, the type definition
must be eithe array or hashref with integer values.

=cut

sub new {
    my ($class, $name, $value) = @_;
    my $hash = ref($value) eq 'ARRAY'
        ? { map { ($_ => $value->[$_]) } (0 .. @$value-1) }
        : ref($value) eq 'HASH'
        ? { map { $value->{$_} => $_ } keys %$value }
        : die("New type value should be either hash or array reference");
    my $type_id = AntTweakBar::_register_enum($name, $hash);
    my $self = {
        _name    => $name,
        _type_id => $type_id,
    };
    return bless $self => $class;
}

sub name {
    shift->{_name};
}

1;
