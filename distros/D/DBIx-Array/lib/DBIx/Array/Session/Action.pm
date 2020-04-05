package DBIx::Array::Session::Action;
use strict;
use warnings;

our $VERSION='0.64';

=head1 NAME

DBIx::Array::Session::Action - Ties DBIx::Array->{"action"} to the database

=head1 SYNOPSIS

  use DBIx::Array;
  my $dbx=DBIx::Array->new;
  $dbx->connect($connection, $user, $pass, \%opt); #passed to DBI
  $dbx->{"action"}="Main";
  while ($this or $that) {
    local $dbx->{"action"}="This or That Loop";
  }

=head1 DESCRIPTION

This package ties the $dbx->{"action"} scalar to the database so that a local assignment to $dbx->{"action"} will set action twice.  Once at the beginning and once at the end of the local variable scope.

=head1 USAGE

  $dbx->action("Default");
  { #any block
    local $dbx->{"action"}="block action";
    #action is now "block action".
  }
  #action is now "Default" again.

  foreach my $i (1 .. 5) {
    local $dbx->{"action"}="Loop $i";
    #action is now "Loop X".
  }
  #action is now "Default" again.

=head2 TIESCALAR

=cut

sub TIESCALAR {
  my $class = shift;
  my %self = @_;
  return bless \%self, $class;
}

=head2 FETCH

Gets action from database

=cut

sub FETCH {
  my $self=shift;
  return $self->parent->action;
}

=head2 STORE

Sets Action in database

=cut

sub STORE {
  my $self=shift;
  my $value=shift;
  return unless defined $value; #Note local calls STORE first time with undef then with real value. no need to hit database twice
  return unless defined $self->parent;            #DESTROYED
  return unless exists $self->parent->{"action"}; #untied
  return unless defined $self->parent->dbh;       #DESTROYED
  return unless $self->parent->dbh->{"Active"};   #Disconnected
  $self->parent->action($value);                  #void context for performance
  return;
}

=head1 PROPERTIES

=head2 parent

  my $parent=$self->parent; #isa L<DBIx::Array>

=cut

sub parent {shift->{"parent"}};

=head1 BUGS

Send email to author and log on RT.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications big or small.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  STOP, LLC
  domain=>stopllc,tld=>com,account=>mdavis
  http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<DBIx::Array>

=cut

1;
