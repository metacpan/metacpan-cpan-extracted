package MySWISH;

use strict;
use warnings;

use Catalyst::Runtime '5.70';
use Catalyst qw(
    ConfigLoader
    Static::Simple
);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use lib "$FindBin::Bin/../../../lib";

our $VERSION = '0.01';

__PACKAGE__->setup;

=head1 NAME

MySWISH - Catalyst based application

=head1 SYNOPSIS

    script/myswish_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<MySWISH::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Peter Karman

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
