package Bio::Tools::DNAGen;
use 5.006;
use strict;

our $VERSION = '0.02';

use XSLoader;
XSLoader::load 'Bio::Tools::DNAGen';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(calc_gcratio calc_mt);

use List::Util qw(shuffle);

# Standalone Functions
sub calc_gcratio { gcratio($_[0]) }
sub calc_mt { mt($_[0]) }

sub subseq {
    map{substr($_, length($_)-1)}grep{!is_selfcplm($_)}map{substr($_[0],1).$_} shuffle qw/a c g t/;
}


sub new {
    my $pkg = shift;
    my $arg = ref($_[0]) ? $_[0] : {@_};
    bless {
	gcratio => $arg->{gcratio},
	mt => $arg->{mt},
	limit => $arg->{limit} || 1,
	prefix => $arg->{prefix} || join(q//, subseq),
	len => $arg->{len} || 10,
	_result => '',
	_seqcnt => 0,
    }, $pkg;
}

sub set_limit   { $_[0]->{limit} = $_[1] || 1 }
sub set_gcratio { $_[0]->{gcratio} = (ref($_[1]) ? $_[1] : [@_[1..$#_]]) || undef }
sub set_mt      { $_[0]->{mt} = (ref($_[1]) ? $_[1] : [@_[1..$#_]]) || undef }
sub set_prefix  { $_[0]->{prefix} = $_[1] || join (q//, subseq) }
sub set_len     { $_[0]->{len} = $_[1] || 10 }


sub genseq($) {
    $_[0]->{_seqcnt} = 0;
    $_[0]->{_result} = undef;
    die "Prefix's length is greater than sequence's length\n" if length($_[0]->{prefix}) > $_[0]->{len};
    _genseq($_[0], $_[0]->{prefix});
    grep{$_}split /\n/, $_[0]->{_result};
}

use subs qw/_genseq/;
sub _genseq {
    my $prefix = $_[1];
    return if length $prefix == $_[0]->{len};
    if(length $prefix == $_[0]->{len}-1){
	for (
	     grep {
		 if(defined $_[0]->{mt} && ref($_[0]->{mt})){
		     if(@{$_[0]->{mt}} >= 2){
			 mt($_) >= $_[0]->{mt}->[0] && mt($_) <= $_[0]->{mt}->[1];
		     }
		     else{
			 mt($_) == $_[0]->{mt}->[0];
		     }
		 }
		 else{
		     $_;
		 }
	     }
	     grep {
		 if(defined $_[0]->{gcratio} && ref($_[0]->{gcratio})){
		     if(@{$_[0]->{gcratio}} >= 2){
			 gcratio($_) >= $_[0]->{gcratio}->[0] && gcratio($_) <= $_[0]->{gcratio}->[1];
		     }
		     else{
			 gcratio($_) == $_[0]->{gcratio}->[0];
		     }
		 }
		 else{
		     gcratio($_);
		 }
	     }
	     map{$prefix.$_} subseq $prefix){

	    if(++$_[0]->{_seqcnt} <= $_[0]->{limit}){
		$_[0]->{_result} .= $_."\n";
	    }
	    else{
		return;
	    }
	}
    }
    return if $_[0]->{_seqcnt} > $_[0]->{limit};
    map { _genseq($_[0], $prefix.$_) } subseq($prefix);
    return;
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Bio::Tools::DNAGen - Generating a pool of DNA sequences

=head1 SYNOPSIS

  use Bio::Tools::DNAGen;
  $gen = Bio::Tools::DNAGen;

  $gen->set_gcratio(50);

  $gen->set_prefix('acgt');

  $gen->getseq($len) for 1..10;

=head1 DESCRIPTION

This module is a tool for generating a pool of DNA sequences which meet some logical and physical requirements such as uniqueness, melting temperature and GC ratio. When you have set the parameters, this module will create an array of sequences for you.

=head1 USAGE

=head2 new

Constructor.

You may specify all the parameters here.

 $gen = Bio::Tools::DNAGen->new(
				gcratio => 50,
				mt => 30,
				limit => 10,
				prefix => 'acgt',
				len => 10,
				);


=head2 set_gcratio

Setting for the GC ratio.

You can give it a specific value, like

    $gen->set_gcratio(50);

or an array to say a range

    $gen->set_gcratio([40, 60]);

    # or

    $gen->set_gcratio(40, 60);

Default is 'undef', which means gc-ratio is not related to sequence selection.

=head2 set_mt

Setting for the melting temperature. For now, Wallace formula is adopted for calculation.

You can give it a specific value, like

    $gen->set_mt(30);

or an array to say a range

    $gen->set_mt([20, 30]);

    # or

    $gen->set_mt(20, 30);

Default is 'undef', which means melting temperature is not related to sequence selection.

=head2 set_len

    $gen->set_len(15);

Setting for the length of sequences to be generated.

Default is '10'.

=head2 set_prefix

    $gen->set_prefix('acgt');

Setting for the common prefix of sequences to be generated.

Default is a random prefix of length 4 composed of qw/a c g t/, and all the substrings of prefix's length in generated sequences will be checked for their uniqueness.

=head2 set_limit

    $gen->set_limit(20);

Setting for the number of sequences to be generated.

Default is '1'.

=head2 genseq

    print join $/, $gen->genseq;

Generating DNA sequences that meet your requirements.

=head1 EXPORTS

This module also automatically exports two utilities.

=head2 calc_gcratio

    print calc_gcratio($seq);

It returns the GC ratio of $seq 

=head2 calc_mt

    print calc_mt($seq);

It returns the melting temperature of $seq 

=head1 SEE ALSO

B<DNASequenceGenerator: A Program for the Construction of DNA Sequences> by I<Udo Feldkamp, Sam Saghafi, Wolfgang Banzhaf, and Rauhe>

=head1 COPYRIGHT

xern E<lt>xern@cpan.orgE<gt>

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.

=cut
