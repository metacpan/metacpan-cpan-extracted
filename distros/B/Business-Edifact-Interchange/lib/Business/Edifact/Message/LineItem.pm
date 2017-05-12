package Business::Edifact::Message::LineItem;

use warnings;
use strict;
use 5.010;
use Carp;

=head1 NAME

Business::Edifact::Message::LineItem - Model an individual Item Line in a message

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

An edifact Message can caontain a number of line items
This is an instance of one

=head1 SUBROUTINES/METHODS

=head2 new

Called by Business::Edifact::Message to instantiate a new LineItem
object. The caller passes the lineitem fields to
the constructor

=cut

sub new {
    my $class = shift;
    my $self  = shift;

    bless $self, $class;
    return $self;
}

=head2 addsegment

adds a segment arrayref

=cut

sub addsegment {
    my $self        = shift;
    my $datalabel   = shift;
    my $data_arrref = shift;

    if ( !exists $self->{$datalabel} ) {
        $self->{$datalabel} = $data_arrref;
    }
    else {
        if ( ref $self->{$datalabel} eq 'ARRAY' ) {
            push @{ $self->{$datalabel} }, $data_arrref;
        }
    }
    return $self;
}

=head2 order_reference_number

=cut

sub order_reference_number {
    my $self = shift;

}

=head2 line_sequence_number

=cut

sub line_sequence_number {
    my $self = shift;
    return $self->{line_number};
}

=head2 ean

Return the lineitem's ean (a 13 digit ISBN)

=cut

sub ean {    #LIN
    my $self = shift;
}

=head2 author_surname

=cut

sub author_surname {    #010
    my $self = shift;
    for my $d ( @{ $self->{item_description} } ) {
        if ( $d->{code} eq '010' ) {
            return $d->{text};
        }
    }
    return q{};
}

=head2 author_firstname

=cut

sub author_firstname {    # 011
    my $self = shift;
    for my $d ( @{ $self->{item_description} } ) {
        if ( $d->{code} eq '011' ) {
            return $d->{text};
        }
    }
    return q{};
}

=head2 author

=cut

sub author {
    my $self = shift;
}

=head2 title

=cut

sub title {    #050
    my $self = shift;
    for my $d ( @{ $self->{item_description} } ) {
        if ( $d->{code} eq '050' ) {
            return $d->{text};
        }
    }
    return q{};
}

=head2 subtitle

=cut

sub subtitle {    #060
    my $self = shift;
    for my $d ( @{ $self->{item_description} } ) {
        if ( $d->{code} eq '060' ) {
            return $d->{text};
        }
    }
    return q{};
}

=head2 edition

=cut

sub edition {    # IMD 100
    my $self = shift;
    for my $d ( @{ $self->{item_description} } ) {
        if ( $d->{code} eq '100' ) {
            return $d->{text};
        }
    }
    return q{};
}

=head2 place_of_publication

=cut

sub place_of_publication {    # IMD 110
    my $self = shift;
    for my $d ( @{ $self->{item_description} } ) {
        if ( $d->{code} eq '110' ) {
            return $d->{text};
        }
    }
    return q{};
}

=head2 publisher

=cut

sub publisher {    # IMD 120
    my $self = shift;
    for my $d ( @{ $self->{item_description} } ) {
        if ( $d->{code} eq '120' ) {
            return $d->{text};
        }
    }
    return q{};
}

=head2 date_of_publication

=cut

sub date_of_publication {    # IMD 170
    my $self = shift;
    for my $d ( @{ $self->{item_description} } ) {
        if ( $d->{code} eq '170' ) {
            return $d->{text};
        }
    }
    return q{};
}

=head2 item_format

=cut

sub item_format {    #IMD 220
    my $self = shift;
    for my $d ( @{ $self->{item_description} } ) {
        if ( $d->{code} eq '220' ) {
            return $d->{text};
        }
    }
    return q{};
}

=head2 shelfmark

=cut

sub shelfmark {    #IMD 230
    my $self = shift;
    for my $d ( @{ $self->{item_description} } ) {
        if ( $d->{code} eq '230' ) {
            return $d->{text};
        }
    }
    return q{};
}

=head2 quantity

=cut

sub quantity {
    my $self = shift;
}

=head2 price

=cut

sub price {
    my $self = shift;
}

=head2 related_numbers

=cut

sub related_numbers {
    my $self = shift;
    if ( $self->{related_numbers} ) {
        return $self->{related_numbers};
    }
    else {
        return;
    }
}

=head1 AUTHOR

Colin Campbell, C<< <colinsc@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-edifact-interchange at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-Edifact-Interchange>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Business::Edifact::Message



=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011-2014 Colin Campbell.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Business::Edifact::Message::LineItem
