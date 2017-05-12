package Asterisk::LCR::Storage::MyRoutes;
use base qw /Asterisk::LCR::Storage::DiskBlob/;
use warnings;
use strict;

our $FILE = "my_rates.csv";

sub new
{
    my $class = shift;
    my $self  = bless {};
    
    $self->{map} = {};
    open FP, "<$FILE" or die "Cannot read-open $FILE\n";
    
    while (my $L = <FP>)
    {
        chomp ($L);
        $L =~ /\d+,/ or next;
        my ($pfx, $lab, $rate) = $L =~ /^(.+?),(.+),(.+?)$/;
        $self->{map}->{$pfx} = [ Asterisk::LCR::Route->new (
            prefix          => $pfx,
            provider        => 'MySelf',
            connection_fee  => 0,
            first_increment => 1,
            increment       => 1,
            rate            => $rate,
            currency        => 'EUR',
            label           => $lab,
            _is_normal      => 1,
        ) ];
    }
    
    close FP;    
    return $self;
}


1;


__END__
