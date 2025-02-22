package Data::Record::Serialize::Role::Encode::CSV;

# ABSTRACT: encode a record as csv

use Moo::Role;

use Data::Record::Serialize::Error { errors => ['csv_backend'] }, -all;
use Types::Common::String qw( NonEmptyStr );
use Types::Standard qw( Bool );

use Text::CSV;

use namespace::clean;

our $VERSION = '0.03';

sub _needs_eol { 1 }

has binary => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

has sep_char => (
    is      => 'ro',
    default => ','
);

has quote_char => (
    is      => 'ro',
    default => '"'
);

has escape_char => (
    is      => 'ro',
    default => '"'
);

has always_quote => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has quote_empty => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has _csv => (
    is       => 'lazy',
    init_arg => undef,
);

sub to_bool { $_[0] ? 1 : 0 }

sub _build__csv {
    my $self = shift;

    my %args = (
        binary       => $self->binary,
        sep_char     => $self->sep_char,
        quote_char   => $self->quote_char,
        escape_char  => $self->escape_char,
        always_quote => $self->always_quote,
        quote_empty  => $self->quote_empty,
        auto_diag => 2,
    );

    return Text::CSV->new( \%args );
}

sub setup {
    my $self = shift;
    $self->_csv->combine( @{ $self->output_fields } )
      or croak( 'error creating CSV header' );
    $self->say( $self->_csv->string );
}










1;

#
# This file is part of Data-Record-Serialize-Encode-csv
#
# This software is Copyright (c) 2022 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Data::Record::Serialize::Role::Encode::CSV - encode a record as csv

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'csv', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::csv> encodes a record as CSV (well
anything that L<Text::CSV> can write).

It performs the L<Data::Record::Serialize::Role::Encode> role.

=for Pod::Coverage encode
 send
 setup
 to_bool

=head1 CONSTRUCTOR OPTIONS

=head2 L<Text::CSV> Options

These are passed through to L<Text::CSV>:

=over

=item binary => I<Boolean>

Default: I<true>

=item sep_char => I<character>

Default: C<,>

=item quote_char => I<character>

Default: C<">

=item escape_char => i<character>

Default: C<">

=item always_quote => I<Boolean>

Default: I<false>
q

=item quote_empty => I<Boolean>

Default: I<false>

=back

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-data-record-serialize-encode-csv@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize-Encode-csv

=head2 Source

Source is available at

  https://gitlab.com/djerius/data-record-serialize-encode-csv

and may be cloned from

  https://gitlab.com/djerius/data-record-serialize-encode-csv.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Data::Record::Serialize::Encode::csv|Data::Record::Serialize::Encode::csv>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
