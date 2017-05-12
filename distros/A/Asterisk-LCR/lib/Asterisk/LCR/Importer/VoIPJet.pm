package Asterisk::LCR::Importer::VoIPJet;
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
    $self->{first_increment_position} ||= 3;
    $self->{increment}                ||= 6;
    $self->{connection_fee}           ||= 0;
    $self->{currency}                 ||= 'USD';
    $self->{uri}                      ||= 'http://voipjet.com/ratescsv.php';
    $self->{filter}                   ||= '^.*(?<!dialing),\d+,';
    return $self;
}


1;


__END__
