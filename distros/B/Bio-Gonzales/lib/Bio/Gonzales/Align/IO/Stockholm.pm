package Bio::Gonzales::Align::IO::Stockholm;

use Mouse;

use warnings;
use strict;

use 5.010;

our $VERSION = '0.0546'; # VERSION
use Bio::Gonzales::Util qw/flatten/;

with 'Bio::Gonzales::Util::Role::FileIO';

has _wrote_sth_before => ( is => 'rw' );
has wrap              => ( is => 'rw', default => '80' );
has relaxed           => ( is => 'rw' );
has file_feats        => ( is => 'rw', default => sub { {} } );

sub _write_header {

    my ($self) = @_;
    my $fh = $self->fh;
    say $fh "# STOCKHOLM 1.0";

    while ( my ( $f, $entry_data ) = each %{ $self->file_feats } ) {
        confess "Feature is not in valid format: $f" unless ( $f =~ /^[a-zA-Z]{2}$/ );
        my @entries = flatten($entry_data);
        for my $e (@entries) {
            say $fh '#=GF ' . uc($f) . " " . $e;
        }
    }

    $self->_wrote_sth_before(1);
}

sub write_aln {
    my ( $self, @data ) = @_;
    my @seqs = flatten(@data);

    my $fh = $self->fh;

    if ( $self->_wrote_sth_before ) {
        confess "Cannot write sequentially if wrap is active" if($self->wrap);

    } else {
        $self->_write_header;
    }

    my $length = $seqs[0]->length;
    for my $s (@seqs) {
        #do all seqs have the same length
        confess $s->id . " has a different length" unless ( $s->length == $length );
        #dashes to points
        ( my $seq = $s->seq ) =~ tr/-/./;
        $s->seq($seq);
    }

    #wrap to 80 char per line
    my @wrapped_seqs;
    if ( $self->wrap ) {
        @wrapped_seqs = map { _wrap( $_->seq, $self->wrap ) } @seqs;
    } else {
        @wrapped_seqs = map { [ $_->seq ] } @seqs;
    }

    my $format;
    if ( $self->relaxed ) {
        $format = "%s %s";
    } else {
        $format = "%- 11s %s";
    }

    for ( my $i = 0; $i < @{ $wrapped_seqs[0] }; $i++ ) {
        print $fh "\n";
        for ( my $j = 0; $j < @seqs; $j++ ) {
            say $fh sprintf( $format, $seqs[$j]->id, $wrapped_seqs[$j][$i] );
        }
    }
    return;
}

before 'close' => sub {
    my ($self) = @_;
    my $fh = $self->fh;
    say $fh '//';
};

sub _wrap {
    my ( $seq, $l ) = @_;
    return [ $seq =~ m[.{1,$l}]g ];
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Bio::Gonzales::Align::IO::Stockholm - IO class for the stockholm format

=head1 SYNOPSIS

    use Bio::Gonzales::Align::IO::Stockholm;


    my $sto = Bio::Gonzales::Align::IO::Stockholm->new(
        file       => 'xyz.aln.fa',
        mode       => '>',
        wrap       => 80,
        relaxed    => undef,
        file_feats => {}
    );

    $sto->write_aln($seqs);

    $sto->close;


=head1 DESCRIPTION

=head1 OPTIONS

=head1 SUBROUTINES
=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
