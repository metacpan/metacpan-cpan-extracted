package DBIC::Violator;

use strict;
use warnings;

# ABSTRACT: Violate DBIC's most private moments

use DBIC::Violator::Collector;
require DBIx::Class::Storage::DBI;
use Class::MOP::Class;
use Try::Tiny;

our $VERSION = '0.900';

our $INITIALIZED = 0;
our $COLLECTOR_INSTANCE = undef;

use RapidApp::Util ':all';

sub import {
  my $pkg = shift;
  my %params = @_;
  
  my $caller = caller;
  
  $params{application_name} ||= do {
    no warnings 'uninitialized';
    my $ver = try{$caller->VERSION} || eval "$caller::VERSION";
    $ver ? join(' v',$caller,$ver) : $caller
  };
  
  #initialize immediately on use:
  $pkg->collector(\%params);
  
  return 1;
}



sub collector {
  my $pkg = shift;
  return $COLLECTOR_INSTANCE if ($INITIALIZED);
  $COLLECTOR_INSTANCE //= $pkg->_init_attach_collector(@_)
}

sub _init_attach_collector {
  my $pkg = shift;
  my $params = shift || {};
  return $COLLECTOR_INSTANCE if ($INITIALIZED);
  
  $INITIALIZED = 1; # one and only one shot - we get it here and now or never
  
  # Currently only enable via env var:
  my $dn = $ENV{DBIC_VIOLATOR_DB_DIR} or return;
  
  my $Collector = DBIC::Violator::Collector->new({ log_db_dir => $dn, %$params });
  
  my $package = 'DBIx::Class::Storage::DBI';
  $pkg->__attach_around_sub($package, '_execute'     => $Collector->_execute_around_coderef);
  $pkg->__attach_around_sub($package, '_dbh_execute' => $Collector->_dbh_execute_around_coderef);
  
  $COLLECTOR_INSTANCE = $Collector
}



sub __attach_around_sub {
  my ($pkg, $package, $method, $around) = @_;

  #### This is based on RapidApp's 'debug_around' -
  #
  # It's a Moose class or otherwise already has an 'around' class method:
  if($package->can('around')) {
    $package->can('around')->($method => $around);
  }
  else {
    # The class doesn't have an around method, so we'll setup manually with Class::MOP:
    my $meta = Class::MOP::Class->initialize($package);
    $meta->add_around_method_modifier($method => $around);
  }
  #
  ####
}




1;

__END__

=head1 NAME

DBIC::Violator - Violate DBIC's most private moments

=head1 SYNOPSIS

 use DBIC::Violator
   application_name => "Some app name V1.234",
   username_from_res_header => 'X-RapidApp-Authenticated';
 
 ...
 
 use DBIC::Violator::Plack::Middleware;
 use Plack::Builder;

 builder {
   enable '+DBIC::Violator::Plack::Middleware';
   $psgi_app
 };
 

=head1 DESCRIPTION

EXPERIMENTAL - not ready for production use

This is module "violates" L<DBIx::Class> by tracking all queries and logging them to an SQLite 
database. It does not do this in a "nice" or correct way, hence the tongue-in-cheek name. 
It does not use the already provided debugobj API; instead it wraps method modifiers on DBIC 
global storage classes in order to intercept all DBIC-originated queries process-wide.

The Plack middleware L<DBIC::Violator::Plack::Middleware> is also provided which can be used
in Plack apps to track and link all DBIC queries and associate them with a parent HTTP 
request.

This module exists for some specific uses and may not ever be supported and so you probably
shouldn't use it. Full documentation maybe TBD.

=head1 CONFIGURATION


=head1 METHODS


=head1 SEE ALSO

=over

=item * 

L<DBIx::Class>

=back


=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
