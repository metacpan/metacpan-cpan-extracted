#!/usr/bin/env perl

use lib "../lib/";
use strict;
use warnings;

use App::DDNS::Namecheap;

my $timeout = 24;  # 24 hour timeout
$timeout *= 3600;

my $domain =  App::DDNS::Namecheap->new(
                domain   => 'mysite.org',
          	password => 'abcdefghijklmnopqrstuvwxyz012345',
		hosts    => [ "@", "www", "*" ],
);

while (1) {
  $domain->update();
  sleep ($timeout);
}

1;

=head1 NAME

update.pl - command line stub

=head1 SYNOPSIS

   perl update.pl

=head1 DESCRIPTION

Dynamic DNS update stub for Namecheap hosted domains

=head1 AUTHOR

David Watson <dwatson@cpan.org>

=head1 SEE ALSO

App::DDNS::Namecheap

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
