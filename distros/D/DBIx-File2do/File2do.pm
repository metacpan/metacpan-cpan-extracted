package DBIx::File2do;

use strict;
use DBI;

BEGIN {
    use Carp;
    use vars qw($VERSION $PACKAGE);
    $VERSION     = '0.001';

    $Carp::CarpLevel = 1;
    $PACKAGE         = "DBIx::File2do";

    use constant DEBUG => 0;
}


sub new {
    my ($class, @args) = @_;

    my $self = bless ({}, ref ($class) || $class);

    if ( !defined $args[0] ) {
        croak "$PACKAGE->new requires one value.  \$dbh\n";
    }
    $self->{_dbh}    = $args[0];

    if (DEBUG) {
        select (STDOUT);
        $| = 1;
        #use Data::Dumper;
    }

    return $self;
}

sub DESTROY() {
}

=head1 NAME

 DBIx::File2do - Execute SQL scripts from Perl.

=head1 SYNOPSIS

  use File2do;
  $SQL = File2do->new($dbh);

  ... do something ...

  $SQL->execute_script('filename.txt');

  ... do something else ...

  $SQL->execute_script('file_name.sql');

=head1 DESCRIPTION

  This module will run a SQL script from Perl.  

=head1 USAGE

  use File2do;
  $SQL=File2do->new($dbh);  ### pass the db handle.
  $SQL->execute_script('filename.txt');

=head1 AUTHOR

    Jack Bilemjian
    CPAN ID: JACKB
    jck000@gmail.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1), DBI.

=cut

sub execute_script($) {

  my $self        = shift;
  my $script_name = shift;
  my ($script,                ### script content
      @sql_commands,          ### individual sql commands
      $cmd,
      $lineno,
      $rv);

  $script = slurp_script("$script_name"); ### Read the script
  $script =~ s/\n/ /g;
  $script =~ s/$/ /g;
  @sql_commands = split('\;', $script);    ### Break up into individual commands

  $lineno=0;
  foreach $cmd (@sql_commands) {
    $lineno++;
    if (DEBUG) {
        print "$lineno) $cmd\n";
    }
    $rv = $self->{_dbh}->do("$cmd");
  }

  return $rv;
}

sub slurp_script($) {
  my $file_name   = shift;
  my $script;
  local $/;

  $file_name = $file_name;

  open(READFILE, $file_name);
  $script = <READFILE>;
  close(READFILE);

  return $script;
}


1;
