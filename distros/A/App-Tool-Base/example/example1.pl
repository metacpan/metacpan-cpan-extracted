#!/usr/bin/env perl

=head1 DESCRIPTION

Extended tool description here

=cut

use 5.010;
use strict;
use warnings;
use utf8;

use lib::abs '../lib';

use App::Tool::Base 'run';

run();

exit;


=head2 test_dump

Extended description and lot of examples here

=cut

sub test_dump
    :Action(test)
    :Description("Just test action")
    :Argument(arg, "positional argument, required")
    :OptionalArgument(arg2, "positional argument, optional")
    :Option('opt=s', "getopt option")
    :Option('list=s@', "getopt list option")
{
    my %opt = @_;

    use YAML; say "Got params:\n" . Dump \%opt;

    return;
}

