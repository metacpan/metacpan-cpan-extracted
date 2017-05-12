package Cogit::Object::Tag;
$Cogit::Object::Tag::VERSION = '0.001001';
use Moo;
use MooX::Types::MooseLike::Base 'Str', 'InstanceOf';
use namespace::clean;

extends 'Cogit::Object';

has '+kind' => ( default => sub { 'tag' } );

has object => (
    is => 'rw',
    isa => Str,
);

has tag => (
    is => 'rw',
    isa => Str,
);

has tagger => (
    is => 'rw',
    isa => InstanceOf['Cogit::Actor'],
);

has tagged_time => (
    is => 'rw',
    isa => InstanceOf['DateTime'],
);

has comment => (
    is => 'rw',
    isa => Str,
);

has object_kind => (
    is => 'rw',
    isa => sub {
        die "$_[0] is not a valid object type" unless $_[0] =~ m/commit|tree|blob|tag/
    },
);

my %method_map = (type => 'object_kind');

sub BUILD {
    my $self = shift;
    my @lines = split "\n", $self->content;
    while ( my $line = shift @lines ) {
        last unless $line;
        my ( $key, $value ) = split ' ', $line, 2;

        if ($key eq 'tagger') {
            my @data = split ' ', $value;
            my ($email, $epoch, $tz) = splice(@data, -3);
            my $name = join(' ', @data);
            my $actor =
                Cogit::Actor->new( name => $name, email => $email );
            $self->tagger($actor);
            my $dt= DateTime->from_epoch( epoch => $epoch, time_zone => $tz );
            $self->tagged_time($dt);
        } else {
            my $method = $method_map{$key} || $key;
            $self->$method($value);
        }
    }
    $self->comment( join "\n", @lines );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Cogit::Object::Tag

=head1 VERSION

version 0.001001

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <cogit@afoolishmanifesto.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
