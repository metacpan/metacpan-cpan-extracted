package Code::TidyAll::Role::HasIgnore;

use strict;
use warnings;

use Code::TidyAll::Util::Zglob qw(zglobs_to_regex);
use Specio::Library::Builtins;
use Specio::Library::String;

use Moo::Role;

our $VERSION = '0.78';

has ignore => (
    is      => 'ro',
    isa     => t( 'ArrayRef', of => t('NonEmptyStr') ),
    default => sub { [] },
);

has ignore_regex => (
    is  => 'lazy',
    isa => t('RegexpRef'),
);

has ignores => (
    is  => 'lazy',
    isa => t( 'ArrayRef', of => t('NonEmptyStr') ),
);

has select => (
    is      => 'ro',
    isa     => t( 'ArrayRef', of => t('NonEmptyStr') ),
    default => sub { [] },
);

sub _build_ignores {
    my ($self) = @_;
    return $self->_parse_zglob_list( $self->ignore );
}

sub _parse_zglob_list {
    my ( $self, $zglobs ) = @_;
    if ( my ($bad_zglob) = ( grep {m{^/}} @{$zglobs} ) ) {
        die qq{zglob '$bad_zglob' should not begin with slash};
    }
    return $zglobs;
}

sub _build_ignore_regex {
    my ($self) = @_;
    return zglobs_to_regex( @{ $self->ignores } );
}

1;

# ABSTRACT: A role for any class that has a list of ignored paths specified in zglob syntax

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Role::HasIgnore - A role for any class that has a list of
ignored paths specified in zglob syntax

=head1 VERSION

version 0.78

=head1 SUPPORT

Bugs may be submitted at
L<https://github.com/houseabsolute/perl-code-tidyall/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Code-TidyAll can be found at
L<https://github.com/houseabsolute/perl-code-tidyall>.

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2020 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

The full text of the license can be found in the F<LICENSE> file included with
this distribution.

=cut
