package DBIx::Class::StateMigrations::SchemaState;

use strict;
use warnings;

# ABSTRACT: Individual schema state

use Moo;
use Types::Standard qw(:all);


has 'fingerprint', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  die __PACKAGE__ . ' must supply either a checksum "fingerprint" or "DiffState"' unless ($self->DiffState);
  my $fp = $self->filtered_DiffState->fingerprint;
  $fp =~ s/\-/_/g;
  return $fp
}, isa => Str;

has 'DiffState' => (
  is => 'ro', lazy => 1,
  isa => Maybe[InstanceOf['DBIx::Class::Schema::Diff::State']],
  default => sub { undef }
);

has 'diff_filters', is => 'ro', default => sub {[]}, isa => ArrayRef;

sub filtered_DiffState {
  my $self = shift;
  
  my $State = $self->DiffState or return undef;
  my @chain = @{ $self->diff_filters };
  while (scalar(@chain) > 0) {
    my $meth = shift @chain;
    die "bad diff_filters - argument list must be even" unless (scalar(@chain) > 0);
    
    die "bad diff_filters method '$meth' - only 'filter' or 'filter_out' supported" unless (
      $meth eq 'filter' || $meth eq 'filter_out'
    );
    
    my $arg = shift @chain;
    $State = $State->$meth($arg)  
  }
  
  $State
}


1;

__END__

=head1 NAME

DBIx::Class::Schema::StateMigrations::SchemaState - Individual schema state

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


