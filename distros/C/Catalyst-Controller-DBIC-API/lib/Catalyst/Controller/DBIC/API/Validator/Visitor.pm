package Catalyst::Controller::DBIC::API::Validator::Visitor;
$Catalyst::Controller::DBIC::API::Validator::Visitor::VERSION = '2.006002';
#ABSTRACT: Provides validation services for inbound requests against whitelisted parameters
use Moose;
use namespace::autoclean;

BEGIN { extends 'Data::DPath::Validator::Visitor'; }


use constant DEBUG => $ENV{DATA_DPATH_VALIDATOR_DEBUG} || 0;

around visit_array => sub {
    my ( $orig, $self, $array ) = @_;
    $self->dive();
    warn 'ARRAY: ' . $self->current_template if DEBUG;
    if ( @$array == 1 && $array->[0] eq '*' ) {
        $self->append_text('[reftype eq "HASH" ]');
        $self->add_template( $self->current_template );
    }
    else {
        if ( $self->current_template =~ /\/$/ ) {
            my $temp = $self->current_template;
            $self->reset_template();
            $temp =~ s/\/$//;
            $self->append_text($temp);
        }
        $self->$orig($array);
    }
    $self->rise();
};

sub visit_array_entry {

    # to make release-unused-vars.t happy
    #my ($self, $elem, $index, $array) = @_;
    my ( $self, $elem ) = @_;
    $self->dive();
    warn 'ARRAYENTRY: ' . $self->current_template if DEBUG;
    if ( !ref($elem) ) {
        $self->append_text( $elem . '/*' );
        $self->add_template( $self->current_template );
    }
    elsif ( ref($elem) eq 'HASH' ) {
        $self->visit($elem);
    }
    $self->rise();
    $self->value_type('NONE');
}

around visit_hash => sub {
    my ( $orig, $self, $hash ) = @_;
    $self->dive();
    if ( $self->current_template =~ /\/$/ ) {
        my $temp = $self->current_template;
        $self->reset_template();
        $temp =~ s/\/$//;
        $self->append_text($temp);
    }
    warn 'HASH: ' . $self->current_template if DEBUG;
    $self->$orig($hash);
    $self->rise();
};

around visit_value => sub {
    my ( $orig, $self, $val ) = @_;

    if ( $self->value_type eq 'NONE' ) {
        $self->dive();
        $self->append_text( $val . '/*' );
        $self->add_template( $self->current_template );
        warn 'VALUE: ' . $self->current_template if DEBUG;
        $self->rise();
    }
    elsif ( $self->value_type eq 'HashKey' ) {
        $self->append_text($val);
        warn 'VALUE: ' . $self->current_template if DEBUG;
    }
    else {
        $self->$orig($val);
    }

};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Catalyst::Controller::DBIC::API::Validator::Visitor - Provides validation services for inbound requests against whitelisted parameters

=head1 VERSION

version 2.006002

=head1 PRIVATE_ATTRIBUTES

=head2 DEBUG

Debugging warnings can be enabled by setting the environment variable
DATA_DPATH_VALIDATOR_DEBUG to a true value.

=head1 AUTHORS

=over 4

=item *

Nicholas Perez <nperez@cpan.org>

=item *

Luke Saunders <luke.saunders@gmail.com>

=item *

Alexander Hartmaier <abraxxa@cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Oleg Kostyuk <cub.uanic@gmail.com>

=item *

Samuel Kaufman <sam@socialflow.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Luke Saunders, Nicholas Perez, Alexander Hartmaier, et al..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
