use strict;
use warnings;
package Bot::BasicBot::Pluggable::Module::AliG;
use base qw(Bot::BasicBot::Pluggable::Module);

our $VERSION = '0.002'; # VERSION

use Acme::AliG;

sub help { return "Talk like Ali G."; }

sub said {
    my ($self, $msg, $pri) = @_;

    return unless $pri == 2;
    my ($command, $phrase) = split( /\s+/, $msg->{body}, 2 );
    return Acme::AliG::alig($phrase) if(lc($command) eq 'alig');
}

# ABSTRACT: IRC bot that translates phrases from English to Ali G


1;

__END__
=pod

=head1 NAME

Bot::BasicBot::Pluggable::Module::AliG - IRC bot that translates phrases from English to Ali G

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Bot::BasicBot::Pluggable::Module;

=head1 DESCRIPTION

This is an IRC bot that translates phrases from English to Ali G.
The keyword alig triggers the translation.

=head1 AUTHOR

William Wolf <throughnothing@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by William Wolf.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

