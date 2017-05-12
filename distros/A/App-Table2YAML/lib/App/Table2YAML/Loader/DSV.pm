package App::Table2YAML::Loader::DSV;

use common::sense;
use charnames q(:full);
use English qw[-no_match_vars];
use IO::File;
use Moo::Role;
use Text::CSV_XS;

our $VERSION = '0.003'; # VERSION

sub load_dsv {
    my $self = shift;

    my $ref = ref $self->input() // q();
    my $dsv_fh
        = $ref eq q(GLOB)
        ? $self->input()
        : IO::File->new( $self->input(), q(r) );
    my $csv_obj = Text::CSV_XS->new(
        {   binary         => 1,
            empty_is_undef => 1,
            sep_char       => $self->field_separator(),
            eol            => $self->record_separator(),
            auto_diag      => 9,
            diag_verbose   => 1,
        }
    );
    my @dsv = @{ $csv_obj->getline_all($dsv_fh) };

    return @dsv;
} ## end sub load_dsv

no Moo;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Table2YAML::Loader::DSV - Plugin for I<DSV> files.

=head1 VERSION

version 0.003

=head1 METHODS

=head2 load_dsv

=head1 AUTHOR

Ronaldo Ferreira de Lima aka jimmy <jimmy at gmail>.

=cut
