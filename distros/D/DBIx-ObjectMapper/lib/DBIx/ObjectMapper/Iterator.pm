package DBIx::ObjectMapper::Iterator;
use strict;
use warnings;
use base qw(DBIx::ObjectMapper::Iterator::Base);
use Carp::Clan qw/^DBIx::ObjectMapper/;

sub new {
    my ( $class, $data_ref, $query, $callback ) = @_;
    confess __PACKAGE__ . "->new([ARRAYREF])" unless ref $data_ref eq 'ARRAY';
    my $self = $class->SUPER::new( $query, $callback );
    $self->{data} = $data_ref;
    return $self;
}

sub next {
    my $self = shift;
    my $result = $self->{data}->[ $self->{cursor}++ ] || do {
        $self->{cursor}--;
        return;
    };
    return $self->callback($result);
}

sub size { scalar( @{ $_[0]->{data} } ) }
sub all  { map { $_[0]->callback($_) } @{ $_[0]->{data} } }

1;

__END__

=head1 NAME

DBIx::ObjectMapper::Iterator - An iterator for returning query results.

=head1 DESCRIPTION

this class is subclass of L<DBIx::ObjectMapper::Iterator::Base>.

=head1 AUTHOR

Eisuke Oishi

=head1 COPYRIGHT

Copyright 2010 Eisuke Oishi

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

