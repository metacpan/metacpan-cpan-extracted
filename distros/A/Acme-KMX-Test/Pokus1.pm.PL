use strict;
use warnings;

my $p = "Acme::KMX::Pokus1";
warn "Creating[$p]: '$ARGV[0]'";
open my $fh, ">", $ARGV[0];
print {$fh} <<"MARKER";
package $p;

sub demo1 { warn "1" };

1;

__END__

=head1 NAME

$p - Testing package 1

=head1 SYNOPSIS

 No synopsis for $p

=head1 DESCRIPTION

 No description for $p

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 COPYRIGHT

Copyright (c) 2014 KMX

MARKER

close $fh;