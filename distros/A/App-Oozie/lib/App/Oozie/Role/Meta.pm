package App::Oozie::Role::Meta;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.019'; # VERSION

use namespace::autoclean -except => [qw/_options_data _options_config/];

use App::Oozie::Deploy::Validate::Meta;
use Moo::Role;
use Types::Standard qw( InstanceOf Str );

with qw(
    App::Oozie::Role::Fields::Generic
);

has meta => (
    is      => 'ro',
    isa     => InstanceOf['App::Oozie::Deploy::Validate::Meta'],
    default => sub {
        my $self = shift;
        App::Oozie::Deploy::Validate::Meta->new(
            ( verbose => $self->verbose ? 1 : 0 ),
        );
    },
    lazy => 1,
);

sub probe_meta {
    my $self  = shift;
    my $rs    = $self->meta->maybe_decode || {};
    my %vars = (
        user => $self->effective_username,
    );

    if ( my $owner = $rs->{ownership} ) {
        for my $tuple (
            [qw( justification   justification )],
            [qw( owner           org_id        )],
        ) {
            my($target_name, $source_name) = @{ $tuple };
            my $value = $owner->{ $source_name } // next;
            $vars{ $target_name } = $value;
        }
    }

    return %vars;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Role::Meta

=head1 VERSION

version 0.019

=head1 SYNOPSIS

    use Moo::Role;
    use MooX::Options;
    with 'App::Oozie::Role::Meta';

=head1 DESCRIPTION

This is a Role to be consumed by Oozie tooling classes and
defines various fields.

=head1 NAME

App::Oozie::Role::Meta - Meta file related role.

=head1 Methods

=head2 probe_meta

=head1 Accessors

=head2 Overridable from sub-classes

=head3 meta

=head1 SEE ALSO

L<App::Oozie>.

=head1 AUTHORS

=over 4

=item *

David Morel

=item *

Burak Gursoy

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
