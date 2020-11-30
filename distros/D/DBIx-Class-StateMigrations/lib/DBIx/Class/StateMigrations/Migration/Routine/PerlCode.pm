package DBIx::Class::StateMigrations::Migration::Routine::PerlCode;

use strict;
use warnings;

# ABSTRACT: individual migration for a single version bump

use Moo;
extends 'DBIx::Class::StateMigrations::Migration::Routine';

use Types::Standard qw(:all);
use Path::Class 'file';

has 'file_path',      is => 'ro', isa => Maybe[Str], default => sub { undef };
has 'eval_code', is => 'ro', isa => Maybe[Str], default => sub { undef };

sub BUILD {
  my $self = shift;
  die "Must supply 'file_path' or 'eval_code'" unless ($self->file_path || $self->eval_code);
  die "Supply either 'file_path' or 'eval_code' - not both" if ($self->file_path && $self->eval_code);
}

sub _get_routine_coderef {
  my $self = shift;
  
  my $coderef;
  
  if($self->file_path) {
    my $File = file($self->file_path)->absolute;
    -f $File or die "Supplied file '".$self->file_path."' not found";
    
    my $eval = $File->slurp;
    die "Supplied file '".$self->file_path."' is empty" unless ($eval);
    $coderef = eval $eval;
    die "Supplied file '" . $self->file_path . "' did not return a CodeRef" unless (
      $coderef && ref($coderef)||'' eq 'CODE'
    );
  }
  elsif($self->eval_code) {
    my $eval = $self->eval_code;
    $coderef = eval $eval;
    die "Supplied 'eval_code' did not return a CodeRef" unless (
      $coderef && ref($coderef)||'' eq 'CODE'
    );
  }
  else {
    die "No file or eval_code - this is a bug"
  }
  
  $coderef
}



1;

__END__

=head1 NAME

DBIx::Class::StateMigrations::Migration::Routine::PerlCode - individual routine

=head1 SYNOPSIS

 use DBIx::Class::Schema::StateMigrations;
 
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


