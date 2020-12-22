package DBIx::Class::StateMigrations::SchemaState;

use strict;
use warnings;

# ABSTRACT: Individual schema state

use Moo;
use Types::Standard qw(:all);


has 'fingerprint', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  die __PACKAGE__ . ' must supply either a checksum "fingerprint" or "DiffState"' unless ($self->DiffState);
  $self->_normalize_fingerprint( $self->filtered_DiffState->fingerprint )
}, isa => Str;

sub _normalize_fingerprint {
  my $self = shift;
  my $fp = shift or return undef;
  $fp =~ s/\-/_/g;
  return $fp
}


has 'DiffState' => (
  is => 'rwp', lazy => 1,
  isa => Maybe[InstanceOf['DBIx::Class::Schema::Diff::State']],
  default => sub { undef }
);

sub _clear_DiffState {
  my $self = shift;
  $self->fingerprint; # make sure we've already recorded the fingerprint
  $self->_set_DiffState( undef )
}


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

sub validate_fingerprint {
  my $self = shift;
  my $fp = $self->fingerprint or die "Couldn't obtain fingerprint";
  
  if($self->DiffState) {
    my $fresh_fp = $self->_normalize_fingerprint(
      $self->filtered_DiffState->fingerprint
    ) or die "Failed to obtain fingerprint from DiffState data";
    
    $fp eq $fresh_fp or die (
      "The recalculated fingerprint of the filtered DiffState data ($fresh_fp) does not match the declared/supplied fingerprint ($fp)"
    )
  }
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


