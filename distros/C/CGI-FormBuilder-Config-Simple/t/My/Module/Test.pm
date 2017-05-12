package My::Module::Test;

use strict;
use warnings;
use DBI;
use Config::Simple;

use base 'CGI::FormBuilder::Config::Simple';

sub new {
  my $class = shift;
  # my $class = 'My::Module::Test';
  my $defaults = shift;
  my $self = {};
  
  $self->{'cfg'} = Config::Simple->new(
      $defaults->{'config_file'} );
  
  my $db = $self->{'cfg'}->get_block('db');
  # $self->{'dbh'} = DBI->connect($db);
  # a DBI->connect() object
  
  # whatever else you need in your constructor
  
  bless $self, $class;
  return $self;

}

sub connect {
  my $class = shift;
  my $connection_paramaters = shift;
  my $self = {};

  foreach my $key (keys %{$connection_paramaters}){
    $self->{'tokens'}{$key} = $connection_paramaters->{$key};
  }

  bless $self, $class;
  return $self;
}

sub get_that_field_options {
  my @options = ('an_option','another_option');
  return \@options;
}

sub get_that_field_labels {
  my %options = (
         'an_option' => 'We call an_option like this',
    'another_option' => 'We call another_option like that',
    );
  return \%options;
}

1;

