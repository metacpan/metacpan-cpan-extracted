package DBIx::Class::AsFdat;
use strict;
use warnings;
use base 'DBIx::Class';
use Scalar::Util qw/blessed/;

our $VERSION = '0.03';

sub as_fdat {
    my $self = shift;

    my $fdat;
    for my $column ($self->result_source->columns) {
        $fdat->{$column} = $self->$column;

        # inflate the datetime
        if (blessed $fdat->{$column} and $fdat->{$column}->isa('DateTime')) {
            for my $type (qw(year month day hour minute second)) {
                $fdat->{"${column}_$type"}  = $fdat->{$column}->$type;
            }
        }
    }
    return $fdat;
}

1;
__END__

=head1 NAME

DBIx::Class::AsFdat - like CDBI::Plugin::AsFdat.

=head1 SYNOPSIS

    __PACKAGE__->load_components(qw/
        AsFdat
    /);

    my $ad = $self->model('Ad')->search(rid => $self->r->param('ad_rid'))->first;
    $self->fillin_form->fdat($ad->as_fdat);

=head1 DESCRIPTION

This module like CDBI::Plugin::AsFdat.

=head1 METHODS

=head2 as_fdat

    my $ad = $self->model('Ad')->search(rid => $self->r->param('ad_rid'))->first;
    $ad->as_fdat 

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Atsushi Kobayashi  C<< <atsushi __at__ mobilefactory.jp> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Atsushi Kobayashi C<< <atsushi __at__ mobilefactory.jp> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

