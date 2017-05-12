package App::Prove::Plugin::Idempotent;

use 5.010;
use strict;
use warnings;

use Test::More;

our $VERSION = '0.01';

# Problem to solve: overwrite _output *after* TAP::Formatter::Base is loaded

sub load {
    my ($class, $p) = @_;
    my @args = @{ $p->{args} };
    my $app  = $p->{app_prove};

    # That's currently quoting *all* output, regardless where it comes from
    no warnings 'redefine';
    require TAP::Formatter::Session; # load first, then overwrite
    *{TAP::Formatter::Session::_make_ok_line} = sub {
                                                     my ( $self, $suffix ) = @_;
                                                     return "";
                                                    };
    return $class;
}

# development on plugin:
#   perl -Ilib `which prove` -Ilib -vl -e cat -P Idempotent t/failed_IPv6.tap
# normally activate plugin:
#                     prove  -Ilib -vl -e cat -P Idempotent t/failed_IPv6.tap

1; # End of App::Prove::Plugin::Idempotent
