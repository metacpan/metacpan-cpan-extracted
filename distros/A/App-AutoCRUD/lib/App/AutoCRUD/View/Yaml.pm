package App::AutoCRUD::View::Yaml;

use 5.010;
use strict;
use warnings;

use Moose;
extends 'App::AutoCRUD::View';

use YAML::Any;

use namespace::clean -except => 'meta';

has 'yaml_flags' => ( is => 'bare', isa => 'HashRef', default => sub {{}} );


sub render {
  my ($self, $data, $context) = @_;

  # YAML modules don't have an OO API, so we must play with global variables
  my $yaml_class = YAML::Any->implementation;
  my $local_flags = "";
  while (my ($flag, $val) = each %{$self->{yaml_flags}}) {
    $local_flags .= "local \$${yaml_class}::$flag = q{$val};";
  }
  eval $local_flags if $local_flags;

  my $output = Dump $data;
  return [200, ['Content-type' => 'application/yaml'], [$output] ];
}

1;


__END__



