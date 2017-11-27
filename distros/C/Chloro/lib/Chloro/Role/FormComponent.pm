package Chloro::Role::FormComponent;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.07';

use Moose::Role;

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

__END__

=pod

=encoding UTF-8

=head1 NAME

Chloro::Role::FormComponent - A role for named things which are part of a form (fields and groups)

=head1 VERSION

version 0.07

=head1 DESCRIPTION

This role defines two attributes which are shared between fields and groups,
C<name> and C<human_name>.

=head1 SUPPORT

Bugs may be submitted at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Chloro> or via email to L<bug-chloro@rt.cpan.org|mailto:bug-chloro@rt.cpan.org>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Chloro can be found at L<https://github.com/autarch/Chloro>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
