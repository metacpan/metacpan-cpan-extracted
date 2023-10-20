package Data::Record::Serialize::Encode::ddump;

# ABSTRACT:  encoded a record using Data::Dumper

use v5.12;
use Moo::Role;

our $VERSION = '1.05';

use Scalar::Util;
use Data::Dumper;
use Data::Record::Serialize::Error { errors => ['::parameter'] }, -all;
use namespace::clean;

sub _needs_eol { 1 }








has ddump => (
    is      => 'lazy',
    isa     => sub { Scalar::Util::blessed $_[0] && $_[0]->isa( 'Data::Dumper' ) },
    builder => sub {
        Data::Dumper->new( [] );
    },
);













has dd_config => (
    is  => 'ro',
    isa => sub {
        ref $_[0] eq 'HASH'
          or error( '::parameter' => q{'config' parameter  must be a hashref'} );
    },
    default => sub { {} },
);






sub encode {
    my $self = shift;
    $self->ddump->Values( \@_ )->Dump . q{,};
}

around BUILD => sub {
    my ( $orig, $self ) = ( shift, shift );

    $orig->( $self, @_ );

    my $ddump  = $self->ddump;
    my %config = (
        %{ $self->dd_config },
        Terse         => 1,
        Trailingcomma => 1,
    );

    for my $mth ( keys %config ) {
        my $code = $ddump->can( $mth )
          or error( '::parameter', "$mth is not a Data::Dumper configuration variable" );
        $code->( $ddump, $config{$mth} );
    }
    return;
};








with 'Data::Record::Serialize::Role::Encode';

1;

#
# This file is part of Data-Record-Serialize
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory Trailingcomma

=head1 NAME

Data::Record::Serialize::Encode::ddump - encoded a record using Data::Dumper

=head1 VERSION

version 1.05

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'ddump', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::ddump> encodes a record using
L<Data::Dumper>.  The resultant encoding may be decoded via

  @data = eval $buf;

It performs the L<Data::Record::Serialize::Role::Encode> role.

=head1 OBJECT ATTRIBUTES

=head2 ddump

The L<Data::Dumper> object. It will be constructed if not provided to
the constructor.

=head2 dd_config

Configuration data for the L<Data::Dumper> object stored in L</ddump>.
Hash keys are the names of L<Data::Dumper> configuration variables,
without the preceding C<Data::Dumper::> prefix.  Be careful to ensure
that the resultant output is a (comma separated) list of structures
which can be C<eval>'ed.

B<Terse> and B<Trailingcomma> are always set.

=head1 CLASS METHODS

=head2 new

This role adds two named arguments to the constructor, L</ddump> and
L</config>, which mirror the added object attributes.

=head1 INTERNALS

=for Pod::Coverage encode

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-data-record-serialize@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize>

=head2 Source

Source is available at

  https://gitlab.com/djerius/data-record-serialize

and may be cloned from

  https://gitlab.com/djerius/data-record-serialize.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Data::Record::Serialize|Data::Record::Serialize>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
