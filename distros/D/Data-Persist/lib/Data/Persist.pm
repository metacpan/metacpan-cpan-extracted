package Data::Persist;
{
  $Data::Persist::VERSION = '0.12';
}
BEGIN {
  $Data::Persist::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: an easy-to-use data-to-disk dumper

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

use Try::Tiny;
use Data::Serializer;
use File::Blarf;

has 'filename' => (
    'is'       => 'rw',
    'isa'      => 'Str',
    'required' => 1,
);

has '_serializer' => (
    'is'      => 'ro',
    'isa'     => 'Data::Serializer',
    'lazy'    => 1,
    'builder' => '_init_serializer',
);

with qw(Log::Tree::RequiredLogger);

sub _init_serializer {
    my $self = shift;

    my $ser = Data::Serializer::->new( compress => 1, );
    return $ser;
}

sub BUILD {
    my $self = shift;

    # make sure we can either write to the exisiting file or, if it does not exist, write
    # to the parent directory
    if ( $self->filename()  && -e $self->filename() && !-w $self->filename() ) {
        die( 'Can not write cache file at ' . $self->filename() );
    }
    elsif ( $self->filename() && !-e $self->filename() ) {
        my @path = split /\//, $self->filename();
        my $file = pop @path;
        my $dir  = join q{/}, @path;
        if ( !-w $dir ) {
            die( 'File ' . $self->filename() . ' does not exist and parent directory '.$dir.' is not writeable.' );
        }
    }

    return 1;
}
## no critic (ProhibitBuiltinHomonyms)
sub write {
## use critic
    my $self     = shift;
    my $hash_ref = shift;
    my $filename = shift || $self->filename();

    my $success = try {
        my $text = $self->_serializer()->freeze($hash_ref);
        File::Blarf::blarf( $filename, $text, { Flock => 1, } );
        1;
    } catch {
        $self->logger()->log( message => 'Failed to serialize cache: '.$_, level => 'warning' );
    };
    if ( !$success ) {
        return;
    }
    $self->logger()->log( message => 'Serialized cache to ' . $filename, level => 'debug' );
    return 1;
}
## no critic (ProhibitBuiltinHomonyms)
sub read {
## use critic
    my $self = shift;
    my $filename = shift || $self->filename();

    if ( !-e $filename ) {
        $self->logger()->log( message => 'No cache file found at ' . $filename, level => 'notice' );
        return;
    }

    my $text = File::Blarf::slurp( $filename, { Flock => 1, } );
    my $unser;
    my $success = try {
        $unser = $self->_serializer()->thaw($text);
        1;
    } catch {
        $self->logger()->log( message => 'Failed to unserialize cache: '.$_, level => 'warning' );
    };
    if ( !$success || !$unser ) {
        return;
    }
    $self->logger()->log( message => 'Unserialized cache from ' . $filename, level => 'debug' );
    return $unser;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Data::Persist - an easy-to-use data-to-disk dumper

=head1 METHODS

=head2 write

Takes two arguments: an data structure and an filename.

Serializes that data structure and writes to the given filename.

=head2 read

Takes one argument: an filename to read from.

Unserializes this data structure and returns it.

=head2 BUILD

Make sure given filename is accessible.

=head1 NAME

Data::Persist - an easy-to-use data-to-disk dumper

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
