package Confman;

use strict;
use warnings;

use Confman::API;

our $VERSION = '0.04';
our $DEFAULT;

sub load_conf_set {
  my $self = shift;

  my $getter = shift;
  my $conf_set_name = shift;

  my $conf_set = $self->api->find_by_name($conf_set_name);
  {
    my $class = ref($self) || $self;
    no strict 'refs';
    *{$class.'::'.$getter} = sub { $conf_set; };
  }
  return $conf_set ? $conf_set->pairs : undef;
}

sub api {
  my $self = shift;
  $self->{_api} ||= Confman::API->new->load_config;
  return $self->{_api};
}

sub new {
  my $class = shift;
  my $self = bless({}, ref($class) || $class);

  $self;
}

sub default {
  my $self = shift;

  $DEFAULT ||= $self->new();
  $DEFAULT;
}

1;
__END__

=head1 NAME

Confman - Perl library to interface with Confman 

=head1 SYNOPSIS

  use Confman;
  my $confman = Confman->default;
  $confman->load_conf_set('config', 'development:config');
  $confman->load_conf_set('config2', 'development:config2');

  print $confman->config->some_config_variable;
  print $confman->config->some_config_variable2;

  print $confman->config2->my_api_key;

  # Updating configs. To update configs you have to have a key
  # with update permissions
  $confman->config2->update_pairs(my_api_key => '23456');

=head1 DESCRIPTION

TODO

=head1 SEE ALSO

http://www.synctree.com

=head1 AUTHOR

Masahji Stewart, E<lt>masahji@synctree.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Synctree Inc
