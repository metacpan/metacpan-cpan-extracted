package App::SmokeBox::Mini::Plugin::Stats;
BEGIN {
  $App::SmokeBox::Mini::Plugin::Stats::VERSION = '0.10';
}

#ABSTRACT: gather smoking statistics from minismokebox

use strict;
use warnings;
use File::Spec;
use POE qw[Component::EasyDBI];
use App::SmokeBox::Mini;
use Time::HiRes ();

use constant STATSDB => 'stats.db';

sub init {
  my $package = shift;
  my $config  = shift;
  return unless $config and ref $config eq 'Config::Tiny';
  return if
    $config->{Stats} and defined $config->{Stats}->{enable} and !$config->{Stats}->{enable};
  my $heap = $config->{Stats} || {};
  POE::Session->create(
     package_states => [
        __PACKAGE__, [qw(_start _start_up sbox_smoke sbox_stop sbox_perl_info _create_db _db_result)],
     ],
     heap => $heap,
  );
}

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $kernel->refcount_increment( $_[SESSION]->ID(), __PACKAGE__ );
  $kernel->yield( '_start_up' );
  $heap->{dbfile} = File::Spec->catfile( App::SmokeBox::Mini->_smokebox_dir, '.smokebox', STATSDB );
  return;
}

sub _start_up {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $heap->{_db} = POE::Component::EasyDBI->new(
    alias => '',
    dsn   => 'dbi:SQLite:dbname=' . $heap->{dbfile},
    username => '',
    password => '',
  );
  $kernel->yield( '_create_db' );
  return;
}

sub _create_db {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $heap->{_db}->do(
      sql => 'PRAGMA synchronous = OFF',
      event => '_db_result',
  );

  $heap->{_db}->do(
    sql => $_,
    event => '_db_result',
  ) for (
    q[CREATE TABLE IF NOT EXISTS jobs ( ts varchar(32), vers varchar(20), arch varchar(100), job BLOB, start varchar(32), end varchar(32), killed integer, status integer )],
    q[CREATE TABLE IF NOT EXISTS smokers ( ts varchar(32), vers varchar(20), arch varchar(100), start varchar(32), end varchar(32), total integer, idle integer, excess integer, average varchar(32), minimum varchar(32), maximum varchar(32) )],
  );

  return;
}

sub _db_result {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  return unless $heap->{terminate};
  $heap->{_db}->shutdown();
  $kernel->refcount_decrement( $_[SESSION]->ID(), __PACKAGE__ );
  return;
}

sub sbox_perl_info {
  my ($kernel,$heap,$vers,$arch) = @_[KERNEL,HEAP,ARG0,ARG1];
  $heap->{vers} = $vers;
  $heap->{arch} = $arch;
  return;
}

sub sbox_smoke {
  my ($kernel,$heap,$data) = @_[KERNEL,HEAP,ARG0];
  my $dist = $data->{job}->module();
  my ($result) = $data->{result}->results;
  my $killed = scalar grep { /kill$/ } keys %{ $result };
  $heap->{_db}->insert(
    sql => 'INSERT INTO jobs values(?,?,?,?,?,?,?,?)',
    placeholders => [ Time::HiRes::time, $heap->{vers}, $heap->{arch}, $dist, $result->{start_time}, $result->{end_time}, $killed, $result->{status} ],
    event => '_db_result',
  );
  return;
}

sub sbox_stop {
  my ($kernel,$heap,@stats) = @_[KERNEL,HEAP,ARG0..$#_];
  $heap->{terminate} = 1;
  $heap->{_db}->insert(
    sql => 'INSERT INTO smokers values(?,?,?,?,?,?,?,?,?,?,?)',
    placeholders => [ Time::HiRes::time, $heap->{vers}, $heap->{arch}, @stats ],
    event => '_db_result',
  );
  return;
}

q[lies, damned lies and statistics];


__END__
=pod

=head1 NAME

App::SmokeBox::Mini::Plugin::Stats - gather smoking statistics from minismokebox

=head1 VERSION

version 0.10

=head1 SYNOPSIS

  # example minismokebox configuration file

  [Stats]

  enable=0

=head1 DESCRIPTION

App::SmokeBox::Mini::Plugin::Stats is a statistics gathering plugin for L<App::SmokeBox::Mini> and
L<minismokebox> that collects all jobs and smokers data and logs it to a L<DBD::SQLite> based database.

The database file will be found in the C<.smokebox> directory, see L<minismokebox> documentation for
details of its location and how to affect its location.

=for Pod::Coverage   init
  sbox_perl_info
  sbox_smoke
  sbox_stop

=head1 CONFIGURATION

This plugin uses an C<[Stats]> section within the L<minismokebox> configuration file.

=over

=item C<enable>

By default the plugin is enabled. You may set this to a C<false> value to disable the use of the plugin

=back

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

