package Cikl::Smrt::Fetchers;

use strict;
use warnings;
use URI;
use Data::Dumper;
#use Cikl::Smrt::Fetcher;

use Carp;
use Module::Pluggable search_path => "Cikl::Smrt::Fetchers", 
      inner => 0, require => 1, sub_name => '_fetchers', 
      on_require_error => \&croak
      ;

sub new {
  my $class = shift;

  my $self = {};

  bless $self, $class;

  $self->{fetchers} = $self->_init_fetchers();

  return $self;
}

sub _init_fetchers {
  my $self = shift;
  my $ret = {};
  my @fetchers;
  foreach my $fetcher (__PACKAGE__->_fetchers()) {
    foreach my $scheme ($fetcher->schemes()) {
      my $scheme = lc($scheme) if (defined($scheme));
      if (my $existing = $ret->{$scheme}) {
        $scheme = 'undef' if (!defined($scheme)); # just make it printable
        die("Cannot associate parser '$fetcher' with the scheme '$scheme'. Already registered with $existing.");
      }
      $ret->{$scheme} = $fetcher;
    }
    push(@fetchers, $fetcher);
  }
  return $ret;
  #return \@fetchers;
}

sub fetchers {
  my $self = shift;
  return @{$self->{fetchers}};
}

sub lookup {
  my $self = shift;
  my $feedurl = shift;
  my $scheme = $feedurl->scheme;
  if (!defined($scheme)) {
    $scheme = '__undef__';
  }
  $scheme = lc($scheme);
  return $self->{fetchers}->{$scheme};
}

1;
