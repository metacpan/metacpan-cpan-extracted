package Asterisk::LCR::Storage;
use base qw /Asterisk::LCR::Object/;
use warnings;
use strict;

sub search_rates
{
    my $self   = shift;
    my $prefix = shift;
    my $limit  = shift;

    defined $prefix or return;
    $prefix ne ''   or return;

    my @res = $self->list ($prefix, $limit);
    return @res if (@res);

    chop ($prefix);
    return $self->search_rates ($prefix, $limit);
}


1;


__END__
