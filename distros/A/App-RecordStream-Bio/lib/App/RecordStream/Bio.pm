package App::RecordStream::Bio;

use strict;
use 5.010;
our $VERSION = '0.23';

# For informational purposes only in the fatpacked file, so it's OK to fail.
# For now, classes are still under the App::RecordStream::Operation namespace
# instead of ::Bio::Operation.
eval {
    require App::RecordStream::Site;
    App::RecordStream::Site->register_site(
        name => __PACKAGE__,
        path => __PACKAGE__,
    );
};

1;
__END__

=encoding utf-8

=head1 NAME

App::RecordStream::Bio - A collection of record-handling tools related to biology

=head1 SYNOPSIS

    # Turn a FASTA into a CSV after filtering for sequence names containing the
    # words POL or GAG.
    recs fromfasta --oneline < seqs.fasta           \
        | recs grep '{{id}} =~ /\b(POL|GAG)\b/i'    \
        | recs tocsv -k id,sequence
    
    # Filter gaps from sequences
    recs fromfasta seqs.fasta \
        | recs xform '{{seq}} =~ s/-//g' \
        | recs tofasta > seqs-nogaps.fasta

    # Calculate average mapping quality from SAM reads
    recs fromsam input.sam \
        | recs collate -a avg,mapq

=head1 DESCRIPTION

App::RecordStream::Bio is a collection of record-handling tools related to
biology built upon the excellent L<App::RecordStream>.

The operations themselves are written as classes, but you'll almost always use
them via their command line wrappers within a larger record stream pipeline.

=head1 TOOLS

L<recs-fromfasta>

L<recs-fromgff3>

L<recs-fromsam>

L<recs-tofasta>

Looking for C<fromfastq> or C<tofastq>?  Install the
L<recs-fastq|https://github.com/MullinsLab/recs-fastq> package.

=head1 INSTALLATION

=head2 Quick, standalone bundle

The quickest way to start using these tools is via the minimal, standalone
bundle (also known as the "fatpacked" version).  First, grab
L<recs|App::RecordStream/INSTALLATION> if you don't already have it:

  curl -fsSL https://recs.pl > recs
  chmod +x recs

Then grab these bio tools and put them in place for recs:

  mkdir -p ~/.recs/site/
  curl -fsSL https://recs.pl/bio > ~/.recs/site/bio.pm

Congrats, you should now be able to run:

  ./recs fromfasta --help
  ./recs tofasta --help
  ./recs fromsam --help

recs version 4.0.14 or newer is required to support site loading from
F<~/.recs/site>.

=head2 From CPAN

You can also install from L<CPAN|http://cpan.org> as App::RecordStream::Bio:

  cpanm App::RecordStream::Bio

Other CPAN clients such as L<cpan> and L<cpanp> also work just great.

If you don't have L<cpanm> itself, you can install it easily with:

  curl -fsSL https://cpanmin.us | perl - App::cpanminus

=head1 AUTHOR

Thomas Sibley E<lt>trsibley@uw.eduE<gt>

=head1 COPYRIGHT

Copyright 2014-2017 Mullins Lab, Department of Microbiology, University of Washington

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<App::RecordStream>

=cut
