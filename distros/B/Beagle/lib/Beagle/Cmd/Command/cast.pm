package Beagle::Cmd::Command::cast;
use Any::Moose;
use Beagle::Util;
extends qw/Beagle::Cmd::Command/;

has 'type' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'cast type',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    $args = $self->resolve_ids( $args );
    die "beagle cast --type new_type id1 id2 [...]"
      unless @$args && $self->type;

    my $type      = lc $self->type;
    my $new_class = entry_type_info->{$type}{class};
    die "invalid type: $type" unless $new_class;

    for my $i (@$args) {
        my @ret = resolve_entry( $i, handle => current_handle() || undef );
        unless (@ret) {
            @ret = resolve_entry($i) or die_entry_not_found($i);
        }
        die_entry_ambiguous( $i, @ret ) unless @ret == 1;
        my $id    = $ret[0]->{id};
        my $bh    = $ret[0]->{handle};
        my $entry = $ret[0]->{entry};

        my $new_object = $new_class->new(%$entry);
        if (
            $bh->create_entry(
                $new_object, message => "cast $id to type $type"
            )
          )
        {

            $bh->backend->delete( $entry );
        }
    }
    puts 'casted.';
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::cast - cast entries to another type

=head1 SYNOPSIS

    $ beagle cast --type article id1 id2 # convert id1 and id2 to articles.

=head1 DESCRIPTION

Generally, cast is not a good thing, as it may cause some data loss.

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

