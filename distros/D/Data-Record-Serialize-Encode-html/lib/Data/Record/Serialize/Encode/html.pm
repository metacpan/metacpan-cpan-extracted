package Data::Record::Serialize::Encode::html;

# ABSTRACT: encode a record as html

use v5.10;

use Moo::Role;

our $VERSION = '0.02';

use warnings::register;

use namespace::clean;

has _html => (
    is       => 'lazy',
    init_arg => undef,
    builder  => sub {
        require HTML::Tiny;
        HTML::Tiny->new( mode => 'html' );
    },
);

has _closed => (
    is       => 'rwp',
    init_arg => undef,
    default  => 1,
);



























has [ 'table_class', 'thead_class', 'tbody_class', 'td_class', 'tr_class', 'th_class' ] => (
    is        => 'ro',
    predicate => 1,
);

has _class => (
    is        => 'lazy',
    init_args => undef,
    builder   => sub {
        my $self = shift;
        {
            table => $self->has_table_class ? { class => $self->table_class } : undef,
            thead => $self->has_thead_class ? { class => $self->thead_class } : undef,
            th    => $self->has_th_class    ? { class => $self->th_class }    : undef,
            td    => $self->has_td_class    ? { class => $self->td_class }    : undef,
            tr    => $self->has_tr_class    ? { class => $self->tr_class }    : undef,
        };
    },
);

sub _needs_eol { 0 }

sub encode {
    my $self = shift;
    $self->_html->tr( [
            $self->_html->td(
                $self->_class->{td} // (),
                map { $_ // q{} } @{ $_[0] }{ @{ $self->output_fields } } ) ] );
}

sub setup {
    my $self = shift;
    my $html = $self->_html;
    $self->say( $html->open( 'table', $self->_class->{table} // () ) );

    $self->say(
        $html->thead( [
                $html->tr(
                    $self->_class->{'tr'} // (),
                    [ $html->th( $self->_class->{th} // (), @{ $self->output_fields } ) ],
                ),
            ],
        ),
    );
    $self->say( $html->open( 'tbody', $self->_class->{tbody} // () ) );
    $self->_set__closed( 0 );
}

sub finalize {
    my $self = shift;
    return if $self->_closed;
    $self->say( $self->_html->close( 'tbody' ) );
    $self->say( $self->_html->close( 'table' ) );
    $self->_set__closed( 1 );
}


sub DEMOLISH {
    my $self = shift;

    warnings::warnif( 'Data::Record::Serialize::Encode::html',
        __PACKAGE__ . ': html table is not closed' )
      unless $self->_closed;
}

with 'Data::Record::Serialize::Role::Encode';

1;

#
# This file is part of Data-Record-Serialize-Encode-html
#
# This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Data::Record::Serialize::Encode::html - encode a record as html

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use Data::Record::Serialize;
    my $s = Data::Record::Serialize->new( encode => 'html', ... );
    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::html> encodes a record as HTML.

It performs the L<Data::Record::Serialize::Role::Encode> role.

You cannot construct this directly. You must use L<Data::Record::Serialize/new>.

=head1 OBJECT ATTRIBUTES

=head2 table_class

=head2 thead_class

=head2 tbody_class

=head2 tr_class

=head2 th_class

=head2 td_class

See L</CONSTRUCTOR ARGUMENTS>.

Optional.

=for Pod::Coverage has_table_class
has_thead_class
has_tbody_class
has_tr_class
has_th_class
has_td_class

=for Pod::Coverage encode
setup
finalize
DEMOLISH

=head1 CONSTRUCTOR OPTIONS

=head3 table_class

=head3 thead_class

=head3 tbody_class

=head3 tr_class

=head3 th_class

=head3 td_class

The CSS class associated with the given element.  All are optional.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-data-record-serialize-encode-html@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize-Encode-html>

=head2 Source

Source is available at

  https://gitlab.com/djerius/data-record-serialize-encode-html

and may be cloned from

  https://gitlab.com/djerius/data-record-serialize-encode-html.git

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
