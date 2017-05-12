package Acme::Nothing;
BEGIN {
  $Acme::Nothing::VERSION = '0.03';
}
# ABSTRACT: No more module loading!

use strict;
use 5.008;
use warnings;

open my $fh, '<', \$Acme::Nothing::VERSION;
close $fh;

@INC = sub {
    $INC{ $_[1] } = $_[1];
    open my $fh, '<', \!$[ or die;
    return $fh;
};

Internals::SvREADONLY( $_, 1 ) for @INC;
Internals::SvREADONLY( @INC, 1 );

() = .0

__END__

=head1 NAME

Acme::Nothing - No more module loading!

=head1 VERSION

version 0.03

=head1 SYNOPSIS

Stops your script from loading any more modules.

    use Acme::Nothing;
    use Improbable; # Nope!
    use Fish;       # Not this either!
    use CGI;        # Still not loading anything