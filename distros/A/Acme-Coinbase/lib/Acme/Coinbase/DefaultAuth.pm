package Acme::Coinbase::DefaultAuth;
# vim: set ts=4 sw=4 expandtab showmatch
#
use strict;

# FOR MOOSE
use Moose; # automatically turns on strict and warnings

# these are for our TEST account 
has 'api_key'    => (is => 'rw', isa => 'Str', default=>"pl5Yr4RK487wYpB2");
has 'api_secret' => (is => 'rw', isa => 'Str', default=>"TusAkTDkRqtDJrSXzn06aUCa6e8gt8Bh");

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Coinbase::DefaultAuth

=head1 VERSION

version 0.007

=head1 SYNOPSIS

Example of a usage goes here, such as...

    my $key    = Acme::Coinbase::DefaultAuth::api_key();
    my $secret = Acme::Coinbase::DefaultAuth::api_secret();

=head1 DESCRIPTION

Holds default, test api creds

=head1 NAME

Acme::Coinbase::DefaultAuth -- Default test creds for coinbase

=head1 METHODS

=head1 COPYRIGHT

Copyright (c) 2014 Josh Rabinowitz, All Rights Reserved.

=head1 AUTHORS

Josh Rabinowitz

=head1 AUTHOR

joshr <joshr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by joshr.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
