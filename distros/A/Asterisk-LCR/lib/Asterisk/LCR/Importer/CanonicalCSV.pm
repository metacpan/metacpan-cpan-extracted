=head1 NAME

Asterisk::LCR::Importer::CanonicalCSV


=head1 SYNOPSIS

  use Asterisk::LCR::Importer::CanonicalCSV;
  my $import = Asterisk::LCR::Importer::CanonicalCSV->new ( file => 'myfile.csv' );
  my $rates  = $import->rates();

=cut
package Asterisk::LCR::Importer::CanonicalCSV;
use base qw /Asterisk::LCR::Importer/;
use Asterisk::LCR::Route;
use Asterisk::LCR::Locale;
use warnings;
use strict;


sub validate
{
    my $self = shift;
    
    my $file = $self->target();
    -f $file or do {
        die 'asterisk/lcr/importer/canonicalcsv/file/inexistent';
        return 0;
    };
    
    return 1;
}


sub get_data
{
    my $self = shift;
    my $file = $self->target();
    my @res  = ();
    
    open FP, "<$file" or die "Cannot read-open $file. Reason: $!";
    $_ = <FP>;
    while (<FP>)
    {
        chomp;
	push @res, $_;
    }
    close FP;
    
    return \@res;
}


##
# $self->rates();
# ---------------
# Returns a { <international_code> => <rate> } hash reference
##
sub rates
{
    my $self = shift;
    my $locale = Asterisk::LCR::Locale->new ("fix_intl");
    $self->{rates} ||= do {
       my $data = $self->get_data();
       my $res  = {};
       for (@{$data})
       {
           my ($prefix, $label, $provider, $currency, $rate, $connection_fee, $first_increment, $increment) = split /\s*,\s*/, $_;
           $prefix = $locale->local_to_global ($prefix);   
           $res->{$prefix} = Asterisk::LCR::Route->new (
  	    connection_fee  => $connection_fee,
	    first_increment => $first_increment,
	    increment       => $increment,
	    currency        => $currency,
	    rate            => $rate,
	    provider	    => $provider,
	    label	    => $label,
            prefix          => $prefix,
        );
       }
       $res;
    };

    return $self->{rates};
}


1;


__END__
