package Chloro::Role::FormComponent;
BEGIN {
  $Chloro::Role::FormComponent::VERSION = '0.06';
}

use Moose::Role;

use namespace::autoclean;

use Chloro::Types qw( NonEmptyStr );

has name => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
);

has human_name => (
    is      => 'ro',
    isa     => NonEmptyStr,
    lazy    => 1,
    builder => '_build_human_name',
);

sub _build_human_name {
    my $self = shift;

    my $name = $self->name();

    $name =~ s/_/ /g;

    return $name;
}

1;

# ABSTRACT: A role for named things which are part of a form (fields and groups)



=pod

=head1 NAME

Chloro::Role::FormComponent - A role for named things which are part of a form (fields and groups)

=head1 VERSION

version 0.06

=head1 DESCRIPTION

This role defines two attributes which are shared between fields and groups,
C<name> and C<human_name>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__


