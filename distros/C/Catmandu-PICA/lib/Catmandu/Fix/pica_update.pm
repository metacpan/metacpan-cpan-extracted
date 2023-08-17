package Catmandu::Fix::pica_update;

use Catmandu::Sane;

our $VERSION = '1.16';

use Moo;
use Catmandu::Fix::Has;
use PICA::Path;
use Scalar::Util 'reftype';

with 'Catmandu::Fix::Inlineable';

has path => (
    fix_arg => 1,
    coerce  => sub {
        PICA::Path->new( $_[0] =~ /^\$|^\./ ? "....$_[0]" : $_[0] );
    }
);
has value => ( fix_arg => 1 );
has all   => ( fix_opt => 1, default => sub { 1 } );
has add   => ( fix_opt => 1, default => sub { 0 } );

sub BUILD {
    my ($self) = @_;

    my $path  = $self->{path};
    my $value = $self->{value};

    # Update full field, given in PICA Plain syntax
    if ( !$path->{subfield} ) {
        my @sf;
        my $value = $self->{value};
        while ( $value =~ s/^\$([A-Za-u0-9])([^\$]+|\$\$)+(.*)/$3/ ) {
            push @sf, $1, $2;
        }

        die "invalid PICA field value: $self->{value}\n"
          if $self->{value} eq '' or $value ne "";

        $self->{value} = \@sf;
    }
}

sub fix {
    my ( $self, $data ) = @_;

    return $data if reftype( $data->{record} ) ne 'ARRAY';

    my $path           = $self->path;
    my $value          = $self->value;
    my $subfield_regex = $path->{subfield};

    my $add = $self->add;
    for my $field ( @{ $data->{record} } ) {
        if ( $path->match_field($field) ) {
            if ( ref $value ) {    # set full field
                splice @$field, 2;
                push @$field, @$value;
                $add = 0;
                last unless $self->all;
            }
            else {
                my $updated;
                for ( my $i = 2 ; $i < @$field ; $i += 2 ) {
                    if ( $field->[$i] =~ $subfield_regex ) {
                        $field->[ $i + 1 ] = $value;
                        $updated = 1;
                        last unless $self->all;
                    }
                }

                if ($updated) {
                    $add = 0;    # no need to add full field
                }
                elsif ( $self->add ) {

                    # add subfield(s) to current field
                    if ( $path->subfields =~ /^[A-Za-z0-9]+/ ) {
                        push @{$field}, map { $_ => $value } split //,
                          $path->subfields;
                    }
                }
            }
        }
    }

    if ($add) {
        my $tag = $path->fields;
        my $occ = $path->occurrences // '';

        if ( $tag =~ /^[0-9A-Z@]{4}$/ && $occ =~ /^[0-9]*$/ ) {
            unless ( ref $value ) {
                if ( $path->subfields =~ /^[A-Za-z0-9]+/ ) {
                    $value =
                      [ map { $_ => $value } split //, $path->subfields ];
                }
            }

            push @{ $data->{record} }, [ $tag, $occ, @$value ];
        }
    }

    return $data;
}

1;
__END__

=head1 NAME

Catmandu::Fix::pica_update - change or add a PICA (sub)field to a fixed value

=head1 SYNOPSIS

    pica_update('021A','$abook$hto read');       # update full field
    pica_update('003@$0','123');                 # update subfield(s)
    pica_update('021A$h','for reading', add: 1); # add 021A$a if missing
    
=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 pica_update(PATH, VALUE, [OPTIONS])

Change or add value of PICA+ field(s) or subfields, specified by PICA Path expression.

=head3 Options

=over

=item * all - update all (sub)field instances instead of only the first field (or first matching subfield in a field). Enabled by default.

=item * add - add field or subfield(s) if missing. Disabled by default. Ignored if PICA Path expression does not reference an individual field.

=back

=head1 SEE ALSO

See L<Catmandu::Fix::pica_set> and L<Catmandu::Fix::pica_add> for
setting/adding PICA (sub)fields to values from other record fields.

=cut
