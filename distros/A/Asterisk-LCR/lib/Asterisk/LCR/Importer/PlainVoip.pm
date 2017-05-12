package Asterisk::LCR::Importer::PlainVoip;
use base qw /Asterisk::LCR::Importer/;
use warnings;
use strict;


sub new
{
    my $class = shift;
    my $self  = $class->SUPER::new (@_);
    $self->{prefix_locale}            = 'us';
    $self->{prefix_position}          = '0';
    $self->{label_position}           = '1';
    $self->{rate_position}            = '4';
    $self->{first_increment_position} = '2';
    $self->{increment_position}       = '3';
    $self->{connection_fee}           = '0';
    $self->{currency}                 = 'USD';
    $self->{uri}                      = 'http://www.plainvoip.com/ratedump.php';
    $self->{separator}                = '(?:,|(?<=\d)\/(?=\d))';
    return $self;
}


1;


__END__
