package Bio::Protease::Types;
{
  $Bio::Protease::Types::VERSION = '1.112980';
}

# ABSTRACT: Specific types for Bio::Protease

use MooseX::Types::Moose qw(Str ArrayRef RegexpRef Any);
use MooseX::Types -declare => [qw(ProteaseName ProteaseRegex)];
use namespace::autoclean;
use Carp qw(croak);

subtype ProteaseName, as Str;

subtype ProteaseRegex, as ArrayRef;

coerce ProteaseRegex,
    from Str,       via { _str_to_prot_regex($_) },
    from RegexpRef, via { [ $_ ] };

coerce ProteaseName,
    from Any, via { 'custom' };

sub _str_to_prot_regex {
    my $specificity = shift;
    my $specificity_of = Bio::Protease->Specificities;

    croak "Not a known specificity\n"
        unless $specificity ~~ %$specificity_of;

    return $specificity_of->{$specificity};
}

__PACKAGE__->meta->make_immutable;


__END__
=pod

=head1 NAME

Bio::Protease::Types - Specific types for Bio::Protease

=head1 VERSION

version 1.112980

=head1 DESCRIPTION

This module defines specific types and type coercions to be used by
L<Bio::Protease>. It should not be used by end users or consumer of the
Bio::ProteaseI role.

=head1 AUTHOR

Bruno Vecchi <vecchi.b gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Bruno Vecchi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

