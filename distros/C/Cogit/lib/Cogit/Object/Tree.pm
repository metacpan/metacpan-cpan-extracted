package Cogit::Object::Tree;
$Cogit::Object::Tree::VERSION = '0.001001';
use Moo;
use Cogit::DirectoryEntry;
use MooX::Types::MooseLike::Base 'ArrayRef', 'InstanceOf';
use namespace::clean;

extends 'Cogit::Object';

has '+kind' => ( default => sub { 'tree' } );

has directory_entries => (
    is         => 'rw',
    isa        => ArrayRef[InstanceOf['Cogit::DirectoryEntry']],
);

sub _build_content {
    my $self = shift;
    my $content;
    for my $de ( @{$self->directory_entries} ) {
        $content
            .= $de->mode . ' '
            . $de->filename . "\0"
            . pack( 'H*', $de->sha1 );
    }

    return $content;
}

sub BUILD {
    my $self    = shift;
    my $content = $self->content;
    return unless $content;
    my @directory_entries;
    while ($content) {
        my $space_index = index( $content, ' ' );
        my $mode = substr( $content, 0, $space_index );
        $content = substr( $content, $space_index + 1 );
        my $null_index = index( $content, "\0" );
        my $filename = substr( $content, 0, $null_index );
        $content = substr( $content, $null_index + 1 );
        my $sha1 = unpack( 'H*', substr( $content, 0, 20 ) );
        $content = substr( $content, 20 );
        push @directory_entries,
            Cogit::DirectoryEntry->new(
            mode     => $mode,
            filename => $filename,
            sha1     => $sha1,
            (
               $self->git
                  ? (git => $self->git)
                  : ()
            ),
            );
    }
    $self->directory_entries( \@directory_entries );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Cogit::Object::Tree

=head1 VERSION

version 0.001001

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <cogit@afoolishmanifesto.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
