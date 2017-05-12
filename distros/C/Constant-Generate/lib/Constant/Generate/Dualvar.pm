package Constant::Generate::Dualvar::_Overloaded;
use constant {
    FLD_INT => 0,
    FLD_STR => 1
};
#Stolen from:
#http://perldoc.perl.org/overload.html

sub new { my $p = shift; bless [@_], $p }
use overload '""' => \&str, '0+' => \&num, fallback => 1;
sub num {shift->[0]}
sub str {shift->[1]}


BEGIN {
    $INC{'Constant/Generate/Dualvar/_Overloaded.pm'} = 1;
}

package Constant::Generate::Dualvar;
use strict;
use warnings;
use Scalar::Util;
use base qw(Exporter);

our @EXPORT_OK = qw(CG_dualvar);
our $USE_SCALAR_UTIL;

sub CG_dualvar($$);

BEGIN {
    $USE_SCALAR_UTIL = eval 'use List::Util::XS 1.20; $List::Util::XS::VERSION;';
    if($USE_SCALAR_UTIL) {
        *CG_dualvar = \&Scalar::Util::dualvar;
    } else {
        require Constant::Generate::Stringified::_Overloaded;
        warn "Scalar::Util::XS not available. Falling back to using overload";
        *CG_dualvar = sub($$) {
            my ($num,$string) = @_;
            return Constant::Generate::Stringified::_Overloaded->new(
                $num,$string);
        }
    }
}

sub import {
    my ($cls,$symspec,%options) = @_;
    if($symspec) {
        #We're being imported as user..
        require 'Constant/Generate.pm';
        $options{dualvar} = 1;
        @_ = ('Constant::Generate', $symspec, %options);
        goto &Constant::Generate::import;
    } else {
        goto &Exporter::import;
    }
}