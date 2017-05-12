package App::pscan;
use warnings;
use strict;
use App::pscan::Utils;
use 5.008_005;
our $VERSION = '0.02';

1;
__END__

=encoding utf-8

=head1 NAME

App::pscan - a handful network scan swiss tool

=head1 SYNOPSIS

  $ pscan [scantype] [iprange]:[port range]

=head1 DESCRIPTION

App::pscan is a small POE network scanner, it scan tcp/udp protocol of the specified range

=head1 OPTIONS

	scantype can be:
		- tcp
		- udp
		- discover (doesn't need the port range)

=head1 AUTHOR

mudler E<lt>mudler@dark-lab.netE<gt>

=head1 COPYRIGHT

Copyright 2014- mudler

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
