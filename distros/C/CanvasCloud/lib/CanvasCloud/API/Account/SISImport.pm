package CanvasCloud::API::Account::SISImport;
$CanvasCloud::API::Account::SISImport::VERSION = '0.004';
# ABSTRACT: extends L<CanvasCloud::API::Account>

use Moose;
use namespace::autoclean;
use IO::String;

extends 'CanvasCloud::API::Account';


augment 'uri' => sub { return '/sis_imports'; };


sub sendzip {
    my $self = shift;
    my $file_or_hash = shift || die 'no data given!';
    my $compressed;
    if ( -f $file_or_hash ) {
        open( my $ZF, '<', $file_or_hash ) or die sprintf( 'cannot open input file {%s} error {%s}', $file_or_hash, $! );
        binmode $ZF;
        while (<$ZF>) { $compressed .= $_; }
        close $ZF;
    }
    elsif ( ref($file_or_hash) eq 'HASH' ) {
        my $sh = IO::String->new($compressed);
        $file_or_hash->{zip}->writeToFileHandle($sh);
    }
    else {
        die sprintf( 'file {%s}{%%%s} does not exist or is not Archive::Zip object', $file_or_hash, ref($file_or_hash) );
    }
    my $r = $self->request( 'POST', $self->uri . '.json?import_type=instructure_csv&extension=zip' );
    $r->content_type( 'application/zip' );
    $r->content($compressed);
    return $self->send( $r );
}


sub status {
    my $self = shift;
    my $id   = shift || die 'id must be given!';
    return $self->send( $self->request( 'GET', $self->uri . '/' . $id . '.json' ) );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CanvasCloud::API::Account::SISImport - extends L<CanvasCloud::API::Account>

=head1 VERSION

version 0.004

=head1 ATTRIBUTES

=head2 uri

augments base uri to append '/sis_imports''

=head1 METHODS

=head2 sendzip

send zip data as POST ->uri

=head2 zipstatus

get sendzip status as GET ->uri/$id.json

=head1 AUTHOR

Ted Katseres

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ted Katseres.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
