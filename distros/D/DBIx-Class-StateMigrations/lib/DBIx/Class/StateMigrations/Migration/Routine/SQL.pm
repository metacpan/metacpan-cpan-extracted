package DBIx::Class::StateMigrations::Migration::Routine::SQL;

use strict;
use warnings;

# ABSTRACT: Raw SQL routine


use Moo;
extends 'DBIx::Class::StateMigrations::Migration::Routine';

use Types::Standard qw(:all);
use Path::Class 'file';
use SQL::SplitStatement;
use Try::Tiny;

has 'file_path',    is => 'ro', isa => Maybe[Str], default => sub { undef };
has 'raw_sql', is => 'ro', isa => Maybe[Str], default => sub { undef };

sub BUILD {
  my $self = shift;
  die "Must supply 'file_path' or 'raw_sql'" unless ($self->file_path || $self->raw_sql);
  die "Supply either 'file_path' or 'raw_sql' - not both" if ($self->file_path && $self->raw_sql);
}

sub _get_routine_coderef {
  my $self = shift;
  
  my $sql = $self->raw_sql;
  
  if($self->file_path) {
    my $File = file($self->file_path)->absolute;
    -f $File or die "Supplied file '".$self->file_path."' not found";
    
    $sql = $File->slurp;
    die "Supplied file '".$self->file_path."' is empty" unless ($sql);
  }
  
  my $err_pfx = $self->file_path ? $self->file_path . ': ' : 'routine (raw_sql): ';
  $err_pfx = "  $err_pfx";
  
  my @stmts = SQL::SplitStatement->new->split($sql);
  
  scalar(@stmts) > 0 or die $err_pfx . "no sql statements to run";
  
  return sub {
    my $db = shift;
    
    for my $stmt (@stmts) {
      try {
        $db->storage->dbh->do($stmt)
      }
      catch {
        my $err = shift;
        die $err_pfx . "[Exception running statement '$stmt']: $err";
      }
    }
  }
}



1;

__END__

=head1 NAME

DBIx::Class::StateMigrations::Migration::Routine::SQL - individual raw SQL routine

=head1 SYNOPSIS

 use DBIx::Class::StateMigrations;
 
 ...
 

=head1 DESCRIPTION



=head1 CONFIGURATION


=head1 METHODS


=head1 SEE ALSO

=over

=item * 

L<DBIx::Class>

=item *

L<DBIx::Class::DeploymentHandler>

=item * 

L<DBIx::Class::Migrations>

=item * 

L<DBIx::Class::Schema::Versioned>

=back


=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


