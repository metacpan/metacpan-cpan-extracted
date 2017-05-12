package Asterisk::LCR::Importer::RichMedium;
use base qw /Asterisk::LCR::Importer/;
use warnings;
use strict;


sub new
{
    my $class = shift;
    my $self  = $class->SUPER::new (@_);
    $self->{uri}                      ||= "http://www.richmedium.com/wholesale-termination.csv";
    $self->{prefix_position}          ||= 0;
    $self->{prefix_locale}            ||= 'us';
    $self->{label_position}           ||= 4;
    $self->{rate_position}            ||= 1;
    $self->{first_increment_position} ||= 2;
    $self->{increment_position}       ||= 3;
    $self->{connection_fee}           ||= 0;
    $self->{currency}                 ||= 'USD';
    return $self;
}


1;


__END__
