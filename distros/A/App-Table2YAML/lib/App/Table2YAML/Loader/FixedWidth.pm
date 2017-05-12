package App::Table2YAML::Loader::FixedWidth;

use common::sense;
use charnames q(:full);
use English qw[-no_match_vars];
use IO::File;
use Moo::Role;

our $VERSION = '0.003'; # VERSION

sub load_fixedwidth {
    my $self = shift;

    my @fixedwidth;

    my @template = @{ $self->field_offset() };
    foreach my $offset (@template) {
        substr $offset, 0, 0, q(A);
    }
    my $template = join q(), @template;

    local $INPUT_RECORD_SEPARATOR = $self->record_separator();
    my $ref = ref $self->input() || q();
    my $fw_fh
        = $ref eq q(GLOB)
        ? $self->input()
        : IO::File->new( $self->input(), q(r) );
    while ( my $record = readline $fw_fh ) {
        chomp $record;
        my @row = unpack $template, $record;
        push @fixedwidth, [@row];
    }

    return @fixedwidth;
} ## end sub load_fixedwidth

no Moo;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Table2YAML::Loader::FixedWidth - Plugin for I<Fixed-Width> files.

=head1 VERSION

version 0.003

=head1 METHODS

=head2 load_fixedwidth

=head1 AUTHOR

Ronaldo Ferreira de Lima aka jimmy <jimmy at gmail>.

=cut
