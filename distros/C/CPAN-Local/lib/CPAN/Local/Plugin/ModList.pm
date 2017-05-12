package CPAN::Local::Plugin::ModList;
{
  $CPAN::Local::Plugin::ModList::VERSION = '0.010';
}

# ABSTRACT: Update 03modlist.data

use CPAN::Index::API::File::ModList;
use Path::Class qw(file dir);
use namespace::autoclean;
use Moose;
extends 'CPAN::Local::Plugin';
with qw(CPAN::Local::Role::Initialise);

sub initialise
{
    my $self = shift;

    dir($self->root)->mkpath;

    my $modlist = CPAN::Index::API::File::ModList->new(
        repo_path => $self->root,
    );

    $modlist->write_to_tarball;
}

__PACKAGE__->meta->make_immutable;

__END__
=pod

=head1 NAME

CPAN::Local::Plugin::ModList - Update 03modlist.data

=head1 VERSION

version 0.010

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

