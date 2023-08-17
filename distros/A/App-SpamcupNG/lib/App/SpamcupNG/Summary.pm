package App::SpamcupNG::Summary;
use warnings;
use strict;
use parent qw(Class::Accessor);
use Hash::Util 'lock_keys';
use Carp 'confess';
use Set::Tiny 0.04;

use App::SpamcupNG::Summary::Receiver;

our $VERSION = '0.017'; # VERSION

=pod

=head1 NAME

App::SpamcupNG::Summary - class to summarise SPAM report data

=head1 SYNOPSIS

    use App::SpamcupNG::Summary;
    my $summary = App::SpamcupNG::Summary->new;
    $summary->set_age(16);

=head1 DESCRIPTION

This class is used internally to store SPAM report data that can latter be
saved to generate reports.

This class is also based on L<Class::Accessor> and uses
C<follow_best_practice>.

=head1 ATTRIBUTES

=over

=item tracking_id: the SPAM report unique tracking ID.

=item mailer: the e-mail header C<X-Mailer>, if available. Might be C<undef>.

=item content_type: the e-mail header C<Content-Type>, if available. Might be C<undef>.

=item age: the time elapsed since the SPAM e-mail was received.

=item age_unit: the time elapsed unit since the SPAM e-mail was received.

=item contacts: an array reference with the "best contacts" found in the report.

=item receivers: an array reference with L<App::SpamcupNG::Summary::Receiver> instances.

=back

Sometimes the C<receivers> addresses will not real ones, but "counters" that
will not be used for the report, but only for Spamcop statistics.

=cut

__PACKAGE__->follow_best_practice;
my $fields = Set::Tiny->new(
    (
        'tracking_id', 'mailer',   'content_type', 'age',
        'age_unit',    'contacts', 'receivers',    'charset'
    )
);
my $ro_fields = Set::Tiny->new(qw(receivers));

__PACKAGE__->mk_accessors( ( $fields->difference($ro_fields) )->members );
__PACKAGE__->mk_ro_accessors( $ro_fields->members );

=head1 METHODS

=head2 new

Creates a new instance. No parameter is required or expected.

=cut

sub new {
    my ( $class, $attribs_ref ) = @_;
    my $self = {
        tracking_id  => undef,
        mailer       => undef,
        content_type => undef,
        age          => undef,
        age_unit     => undef,
        contacts     => undef,
        receivers    => undef,
        charset      => undef
    };
    bless $self, $class;
    lock_keys( %{$self} );
    return $self;
}

=head2 as_text

Returns the summary attributes as strings, separated by commas.

If some of attributes are C<undef>, the string C<not avaialable> will be used
instead.

=cut

sub as_text {
    my $self = shift;
    my @simple;

# Set::Tiny->members is not ordered and we need that to have deterministic text
    my @fields  = sort( $fields->members );
    my $complex = Set::Tiny->new(qw(contacts receivers age));

    foreach my $field (@fields) {
        next if ( $complex->has( ($field) ) );
        push( @simple, $field );
    }

    my @dump = map { $_ . '=' . ( $self->{$_} || $self->na ) } @simple;

    # age can be zero
    if ( defined( $self->{age} ) ) {
        push( @dump, 'age=' . $self->{age} );
    }
    else {
        push( @dump, 'age=' . $self->na );
    }

    foreach my $key (qw(receivers contacts)) {
        if ( $self->{$key} ) {

            if ( $key eq 'contacts' ) {
                push( @dump,
                    ( "$key=(" . join( ';', @{ $self->{$key} } ) . ')' ) );
                next;
            }

            push( @dump, $self->_receivers_as_text );

        }
        else {
            push( @dump, "$key=()" );
        }
    }

    return join( ',', @dump );
}

=head2 tracking_url

Returns the tracking URL of the SPAM report as a string.

=cut

sub tracking_url {
    my $self = shift;
    return 'https://www.spamcop.net/sc?id=' . $self->{tracking_id};
}

=head2 to_text

Getter for attributes that returns the value as a string.

If the attribute value is C<undef>, the string return by C<na()> will be used
instead.

Expects as parameter the name of the parameter, returns a string.

=cut

sub _receivers_as_text {
    my $self = shift;
    my @receivers;

    foreach my $receiver ( @{ $self->{receivers} } ) {
        push( @receivers, '(' . $receiver->as_text . ')' );
    }

    return "receivers=(" . join( ';', @receivers ) . ')';
}

sub _contacts_as_text {
    my $self = shift;
    return '(' . join( ';', @{ $self->{contacts} } ) . ')'
        if ( $self->{contacts} );
    return '()';
}

sub to_text {
    my ( $self, $attrib ) = @_;
    return $self->_receivers_as_text if ( $attrib eq 'receivers' );
    return $self->_contacts_as_text  if ( $attrib eq 'contacts' );
    return $self->{$attrib} || $self->na;
}

=head2 na

Returns the "not available" string. Can be used as class method.

=cut

sub na {
    return 'not available';
}

sub _fields {
    my @fields = sort( $fields->members );
    return \@fields;
}

=head2 set_receivers

Setter for the C<receivers> attribute.

Expects as parameter an array reference, with inner array references inside.

Returns "true" (1) if everything goes fine.

=cut

sub set_receivers {
    my ( $self, $receivers_ref ) = @_;
    confess 'An array reference is expected as parameter'
        unless ( ref($receivers_ref) eq 'ARRAY' );
    my @items;

    foreach my $receiver_ref ( @{$receivers_ref} ) {
        push( @items, App::SpamcupNG::Summary::Receiver->new($receiver_ref) );
    }

    $self->{receivers} = \@items;
    return 1;
}

=head1 SEE ALSO

=over

=item *

L<Class::Accessor>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 of Alceu Rodrigues de Freitas Junior,
E<lt>arfreitas@cpan.orgE<gt>

This file is part of App-SpamcupNG distribution.

App-SpamcupNG is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

App-SpamcupNG is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
App-SpamcupNG. If not, see <http://www.gnu.org/licenses/>.

=cut

1;
