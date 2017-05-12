use strict;
use warnings;

package TestNet::Server::ServerBotted;

use Bot::Net::Server;
use Bot::Net::Mixin::Server::IRC;

use TestNet::Bot::AtoZ;

=head1 NAME

TestNet::Server::ServerBotted - A host for semi-autonomous agents

=head1 SYNOPSIS

  bin/botnet run --server ServerBotted

=head1 DESCRIPTION

A host for semi-autonomous agents. This documentation needs replacing.

=cut

on _start => run {
    remember AtoZ => TestNet::Bot::AtoZ->setup;
};

on server quit => run {
    forget 'AtoZ';
};

1;

