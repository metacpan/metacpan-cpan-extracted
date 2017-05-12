package Bio::MedChunker;

our $VERSION = '0.02';

use strict;
use YamCha;

use Bio::Medpost;
use Exporter::Lite;

our @EXPORT = qw(medchunker);
our $YamChaModel = '';

sub extract_NPchunks($) {
    my $l = shift;
    my @buf;
    my @np;
    while(my $a = shift @$l){
	if( ($a->[2] eq 'O' && @buf) || ($a->[2] eq 'I' && !@$l && @buf)) {
	    push @buf, $a if $a->[2] eq 'I';
	    push @np, [@buf];
	    @buf = ();
	}
	elsif( $a->[2] eq 'B' && @buf ){
	    push @np, [@buf];
	    @buf = ($a);
	}
	elsif( $a->[2] =~ /^[BI]$/o){
	    push @buf, $a;
	}
    }
    @np;
}

sub medchunker {
    my $text = shift;

    die "Please specify the model file\n" unless -e $YamChaModel;

    # apply medpost to $text
    my $p = medpost($text, qw(-penn));

    # create IOB2 file
    my $sentence = join( q//, map{"$_->[0]\t$_->[1]\n"} @$p).$/;

    # transform chunked IOB2 file
    my $c = new YamCha::Chunker([($0, '-m', $YamChaModel)]) or die;
    my @l = map{[split /\s/]} grep{$_} split /\n/, $c->parse ($sentence);
#    use Data::Dumper;
#    print Dumper \@l;

#    print Dumper [ extract_NPchunks(\@l) ];
    
    wantarray ? extract_NPchunks(\@l) : [ extract_NPchunks(\@l) ];
}


1;
__END__

=head1 NAME

Bio::MedChunker - NP chunker for MEDLINE texts

=head1 USAGE

    use Bio::MedChunker;

    $r = medchunker('We observed an increase in mitogen-activated protein kinase (MAPK) activity.');

    use Data::Dumper;

    print Dumper $r;

    If you need to change the model file's path, please use $Bio::MedChunker::YamChaModel

=head1 SEE ALSO 

http://www2.chasen.org/~taku/software/yamcha/

=head1 THE AUTHOR

Yung-chung Lin (a.k.a. xern) E<lt>xern@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself

=cut

