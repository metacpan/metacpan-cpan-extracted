package CPANPLUS::Dist::Arch::Test;

use warnings;
use strict;

use lib qw(t/lib); # override CPANPLUS::Dist::Arch's superclass
use base qw(CPANPLUS::Dist::Arch);

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new( @_ );

    $self->_prepare_status();
    $self->status->prepared(1);
    return $self;
}

sub _calc_tarballmd5 { '12345MD5SUM12345' }

sub _calc_shasum { my (undef, $size) = @_; "12345SHA${size}SUM12345" }


1;
