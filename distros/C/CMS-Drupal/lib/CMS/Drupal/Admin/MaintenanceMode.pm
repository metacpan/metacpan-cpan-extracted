package CMS::Drupal::Admin::MaintenanceMode;
$CMS::Drupal::Admin::MaintenanceMode::VERSION = '0.94';
# ABSTRACT: Put your Drupal site into Maintenance Mode, or take it out

use strict;
use warnings;

use base "Exporter::Tiny";
our @EXPORT = qw/ maintenance_mode_check
                  maintenance_mode_on
                  maintenance_mode_off /;

sub maintenance_mode_check {
  my $dbh = shift;

  my $sql = qq|
    SELECT value
    FROM variable
    WHERE name = 'maintenance_mode'
  |;

  return ( $dbh->selectrow_array( $sql ) eq 'i:1;' ) ? 1 : 0;
}

sub maintenance_mode_on {
  my $dbh = shift;

  my $sql1 = qq|
    UPDATE variable
    SET value = 'i:1;'
    WHERE name = 'maintenance_mode'
  |;

  my $rv1 = $dbh->do( $sql1 );

  my $sql2 = qq|
    DELETE FROM cache_bootstrap
    WHERE cid = 'variables'
  |;

  my $rv2 = $dbh->do( $sql2 );

  # cache_bootstrap may not have an entry
  # for 'variables' so we allow 0E0
  return ( $rv1 > 0  and $rv2 >= 0 ) ? 1 : 0;
}

sub maintenance_mode_off {
  my $dbh = shift;

  my $sql1 = qq|
    UPDATE variable
    SET value = 'i:0;'
    WHERE name = 'maintenance_mode'
  |;

  my $rv1 = $dbh->do( $sql1 );

  my $sql2 = qq|
    DELETE FROM cache_bootstrap
    WHERE cid = 'variables'
  |;

  my $rv2 = $dbh->do( $sql2 );

  # cache_bootstrap may not have an entry
  # for 'variables' so we allow 0E0
  return ( $rv1 > 0 and $rv2 >= 0 ) ? 1 : 0;
}

1; # return true

__END__

=pod

=encoding UTF-8

=head1 NAME

CMS::Drupal::Admin::MaintenanceMode - Put your Drupal site into Maintenance Mode, or take it out

=head1 VERSION

version 0.94

=head1 SYNOPSIS

  use CMS::Drupal::Admin::MaintenanceMode qw/ -all /;

  my $on = 'yes' if maintenance_mode_check($dbh);
 
  maintenance_mode_on($dbh);

  maintenance_mode_off($dbh);

=head1 DESCRIPTION

This module provides methods to check whether your Drupal site is
currently in maintenance mode, and to put it into and take it out
of maintenance mode.

You might like to put the site into maintenance mode before running
a script that reads from the DB, or perhaps you would like to have
a monitoring tool able to shut off public access to the site if
something bad happens.

Note that this and all CMS::Drupal::* Perl packages interact with
the database directly, not with the website. You must have the 
user credentials for your database in order to use these tools.

=head1 METHODS

=head2 maintenance_mode_check

Returns 1 if the site is currently in maintenance mode, otherwise
returns 0. Takes one argument; your active $dbh.

=head2 maintenance_mode_on

Puts the site into maintenance mode. Returns 1 if there was no failure;
i.e. the site was successfully put into, or already was in, maintenance
mode. Returns 0 on DB error. Takes one argument; your active $dbh.

=head2 maintenance_mode_off

Takes the site out of maintenance mode. Returns 1 if there was no 
failure; i.e. the site was successfully taken out of, or was already
not in, maintenance mode. Returns 0 on DB error. Takes one argument;
your active $dbh.

=head1 USAGE

Use the module as shown in the SYNOPSIS.

=head1 AUTHOR

Nick Tonkin <tonkin@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Nick Tonkin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
