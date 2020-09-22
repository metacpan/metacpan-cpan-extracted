package App::Reorder::TSV;    ## no critic (RequireTidyCode)

use strictures 2;

our $VERSION = '0.1.1'; ## VERSION

# ABSTRACT: Reorder columns of TSV file by template

use autodie;
use Carp;
use IO::Uncompress::Gunzip qw($GunzipError);
use Exporter qw( import );
our @EXPORT_OK = qw( reorder );

sub reorder {
    my ($arg_ref) = @_;

    confess 'TSV argument missing'      if !defined $arg_ref->{tsv};
    confess 'Template argument missing' if !defined $arg_ref->{template};

    my $tsv_fh      = _open_tsv( $arg_ref->{tsv} );
    my $template_fh = _open_template( $arg_ref->{template} );

    my @new_cols = _get_cols($template_fh);
    my @old_cols = _get_cols($tsv_fh);
    _output_reorder( $arg_ref->{fh}, $tsv_fh, \@new_cols, \@old_cols );

    close $tsv_fh;
    close $template_fh;

    return;
}

sub _open_tsv {
    my ($tsv) = @_;

    confess sprintf 'Input TSV file does not exist (%s)', $tsv if !-e $tsv;
    my $fh;
    if ( $tsv =~ m/[.]gz \z/xms ) {
        $fh = IO::Uncompress::Gunzip->new(
            $tsv,
            MultiStream => 1,
            Transparent => 0
        ) or confess sprintf 'gunzip failed (%s): %s', $tsv, $GunzipError;
    }
    else {
        open $fh, q{<}, $tsv;    ## no critic (RequireBriefOpen)
    }

    return $fh;
}

sub _open_template {
    my ($template) = @_;

    confess sprintf 'Template TSV does not exist (%s)', $template
      if !-e $template;
    open my $fh, q{<}, $template;

    return $fh;
}

sub _get_cols {
    my ($fh) = @_;

    my $line = <$fh>;
    chomp $line;

    my @cols = split /\t/xms, $line;

    return @cols;
}

sub _output_reorder {
    my ( $fh, $tsv_fh, $new_cols, $old_cols ) = @_;

    _write_line( $fh, @{$new_cols} );    # Header

    while ( my $line = <$tsv_fh> ) {
        chomp $line;
        my @fields = split /\t/xms, $line;

        my %value_for;
        foreach my $i ( 0 .. ( scalar @{$old_cols} ) - 1 ) {
            $value_for{ $old_cols->[$i] } = $fields[$i];
        }

        my @output;
        foreach my $new_col ( @{$new_cols} ) {
            push @output, $value_for{$new_col} || q{};
        }

        _write_line( $fh, @output );
    }

    return;
}

sub _write_line {
    my ( $fh, @fields ) = @_;

    if ( !defined $fh ) {
        $fh = \*STDOUT;
    }

    printf {$fh} "%s\n", join "\t", @fields;

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Reorder::TSV - Reorder columns of TSV file by template

=head1 VERSION

version 0.1.1

=head1 FUNCTIONS

=head2 reorder

  Usage       : reorder( { tsv => $tsv, template => $template } )
  Purpose     : Reorder columns of TSV file by template
  Returns     : undef
  Parameters  : Hashref {
                    tsv      => String (the input TSV file)
                    template => String (the template TSV file)
                    fh       => Filehandle or undef (output filehandle)
                }
  Throws      : If TSV or template arguments are missing or don't exist
  Comments    : None

=head1 AUTHOR

Ian Sealy <cpan@iansealy.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Ian Sealy <cpan@iansealy.com>.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
