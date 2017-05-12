package Beagle::Cmd::Command::status;
use Any::Moose;
use Beagle::Util;
extends qw/Beagle::Cmd::Command/;

has 'all' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'all the beagles',
    cmd_aliases   => 'a',
    traits        => ['Getopt'],
);

has 'names' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'names of beagles',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    my @bh;
    if ( $self->all ) {
        @bh = values %{handles()};
    }
    elsif ( $self->names ) {
        my $handles = handles();
        my $names = to_array( $self->names );
        for my $name ( @$names ) {
            die "invalid name: $name" unless $handles->{$name};
            push @bh, $handles->{$name};
        }
    }
    else {
        @bh = current_handle or die "please specify beagle by --name or --root";
    }

    return unless @bh;
    my $name_length = max_length( map { $_->name } @bh ) + 1;


    require Text::Table;
    my $tb =
      Text::Table->new( 'name', 'size', 'trust', 'entries', 'attachments',
              'comments' );
    for my $bh (@bh) {
        my $att_map = $bh->attachments_map;
        my $att_size = 0;
        for my $id ( keys %$att_map ) {
            $att_size += scalar values %{$att_map->{$id}};
        }
        $tb->add(
            $bh->name,
            format_bytes( $bh->total_size ),
            ( roots()->{ $bh->name }{trust} ? 'yes' : 'no' ),
            format_number( scalar @{$bh->entries} ),
            format_number( $att_size ),
            format_number( scalar @{$bh->comments} ),
        );
    }
    puts $tb;
}

sub size_info {
    my $entries = shift;
    return '' unless $entries;

    my $length = 0;
    for (@$entries) {
        my $len = length $_->body;
        $length += $len;
    }

    my $info = format_number( scalar @$entries );
    if (@$entries) {
        $info .= '(' . format_number($length) . ')';
    }
    return $info;
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::status - show status

=head1 SYNOPSIS

    $ beagle status

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

