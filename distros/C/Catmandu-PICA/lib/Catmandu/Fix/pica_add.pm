package Catmandu::Fix::pica_add;

use Catmandu::Sane;

our $VERSION = '1.10';

use Moo;
use Catmandu::Util::Path qw(as_path);
use Catmandu::Fix::Has;
use PICA::Path;

has path => ( fix_arg => 1 );
has pica_path => (
    fix_arg => 1,
    coerce  => sub { PICA::Path->new( $_[0] ) }
);
has record    => ( fix_opt => 1 );
has force_new => ( fix_opt => 1 );

with 'Catmandu::Fix::Builder';

sub _build_fixer {
    my ($self) = @_;

    my $value_getter  = as_path( $self->path )->getter;
    my $record_getter = as_path( $self->record // 'record' )->getter;
    my $pica_path     = $self->pica_path;
    my $force_new     = $self->force_new;

    return sub { }
      unless defined $pica_path->fields && defined $pica_path->subfields;

    my @fixed_field;
    @fixed_field = ( $pica_path->fields, $pica_path->occurrences )
      if ( $pica_path->fields =~ qr{^[0-9A-Z@]{4}$}
        && ( $pica_path->occurrences // '' ) =~ qr{^[0-9]*$} );

    my $subfields = $pica_path->subfields;

    sub {
        my ($data) = @_;
        my @values =
          map { ref $_ eq 'ARRAY' ? @$_ : $_ } @{ $value_getter->($data) };
        return $data unless @values;

        for my $record ( @{ $record_getter->($data) } ) {

            my $fields =
              [ $force_new ? () : grep { $pica_path->match_field($_) }
                  @$record ];

            if (@$fields) {
                my @sf_codes = split '', $subfields;
                my @sf_values = @values;

                foreach my $f (@$fields) {
                    my $annotation = @$f % 2 ? pop @$f : undef;

                    for ( my $i = 0 ; $i < @sf_codes && $i < @sf_values ; $i++ )
                    {
                        push @$f, $sf_codes[$i], $sf_values[$i];
                    }

                    push @$f, $annotation if defined $annotation;
                }
            }
            elsif (@fixed_field) {
                my $field = [@fixed_field];

                my $i = 0;
                foreach ( split '', $subfields ) {
                    push @$field, $_, $values[ $i++ ];
                    last if $i >= @values;
                }

                push @$record, $field;
            }
        }

        $data;
      }
}

1;
__END__

=head1 NAME

Catmandu::Fix::pica_add - add new subfields to record

=head1 SYNOPSIS

    # Copy value of dc.identifier to PICA field 003A as subfield 0
    pica_add('dc.identifier', '003A0');
    
    # Same as above, but use another record path ('pica')
    pica_add('dc.identifier', '003A0', record:'pica');
    
    # force the creation of a new field 003A
    pica_add('dc.identifier', '003A0', force_new:1);
    
    # Add multiple subfields
    # "dc": {"subjects": ["foo", "bar"]}
    pica_add('dc.subjects', '004Faf')

=head1 DESCRIPTION

This fix adds subfields with value of PATH to the PICA field. The value of PATH must be either
a scalar or an array.

If PICA field does not exist, it will be created.

=head1 FUNCTIONS

=head2 pica_add(PATH, PICA_PATH, [OPTIONS])

=head3 Options

=over

=item * record - alternative record key (default is 'record')

=item * force_new - force the creation of a new field

=back

=head1 SEE ALSO

See L<Catmandu::Fix::pica_set> for setting a new value to an existing subfield.

See L<Catmandu::Fix::pica_map> if you want to copy values from a PICA record.

See L<PICA::Path> for a definition of PICA path expressions and L<PICA::Data>
for more methods to process parsed PICA+ records.

=cut
