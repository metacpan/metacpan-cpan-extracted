package Asterisk::LCR::Importer::NuFone;
use base qw /Asterisk::LCR::Importer/;
use warnings;
use strict;


sub new
{
    my $class = shift;
    my $self  = $class->SUPER::new (@_);
    $self->{prefix_position}          ||= 1;
    $self->{prefix_locale}            ||= 'us';
    $self->{label_position}           ||= 0;
    $self->{rate_position}            ||= 2;
    $self->{currency}                 ||= 'USD';
    $self->{connection_fee}           ||= 0;
    $self->{first_increment}          ||= 15;
    $self->{increment}                ||= 15;
    $self->{uri}                      ||= 'https://www.nufone.net/rates.csv';
    $self->{filter}                   ||= '^.*,\d+,';
    return $self;
}


sub get_data
{
    my $self = shift;
    my $uri  = $self->uri();
    my $data = `wget --no-check-certificate -O - $uri 2>/dev/null`;
    $data || die "Could not retrieve NuFone price list";

    my @data = split /\n/, $data;
    for (@data)
    {
        # Fix NuFone's two field prefix
        s/^(.*?),(.*?),(.*?),(.*)$/$1,$2$3,$4/;
    }
    return \@data;
}


1;


__END__
