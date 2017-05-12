package App::Table2YAML::Loader::AsciiTable;

use common::sense;
use charnames q(:full);
use English qw[-no_match_vars];
use Moo::Role;

our $VERSION = '0.003'; # VERSION

sub load_asciitable {
    my $self = shift;

    local $INPUT_RECORD_SEPARATOR = $self->record_separator();
    my $ref = ref $self->input() || q();
    my $ascii_fh
        = $ref eq q(GLOB)
        ? $self->input()
        : IO::File->new( $self->input(), q(r) );

    my $sep = qq(\N{VERTICAL LINE});
    my @asciitable;
    while ( my $record = readline $ascii_fh ) {
        chomp $record;

        my $length = length $record;
        if ( index( $record, $sep ) == 0 ) {
            $record = substr $record, 1, $length;
        }
        if ( substr $record, -1 eq q($sep) ) {
            $record = substr $record, 0, $length - 2;
        }

        my @row = split m{\Q$sep\E}msx, $record;
        if ( @row == 1 && $row[0] =~ m{^-+(?:\+-+)*$}msx ) {
            next;
        }

        foreach (@row) {
            s{\A\p{IsSpace}+}{}msx;
            s{\p{IsSpace}+\z}{}msx;
            s{\\vert(?:\{\})?}{|}gmsx;
        }

        push @asciitable, [@row];
    } ## end while ( my $record = readline...)

    return @asciitable;
} ## end sub load_asciitable

no Moo;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Table2YAML::Loader::AsciiTable - Plugin for I<ASCII> tables.

=head1 VERSION

version 0.003

=head1 METHODS

=head2 load_asciitable

=head1 AUTHOR

Ronaldo Ferreira de Lima aka jimmy <jimmy at gmail>.

=cut
