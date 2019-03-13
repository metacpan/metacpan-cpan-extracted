package Alt::NewRelic::Agent::FFI::Empty;

use strict;
use warnings;
use 5.008001;

# ABSTRACT: NewRelic::Agent::FFI interface that doesn't do anything
our $VERSION = '0.02'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alt::NewRelic::Agent::FFI::Empty - NewRelic::Agent::FFI interface that doesn't do anything

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 env PERL_ALT_INSTALL=OVERWRITE cpanm Alt::NewRelic::Agent::FFI::Empty

=head1 DESCRIPTION

This distribution provides an interface for L<NewRelic::Agent::FFI> and 
L<NewRelic::Agent::FFI::Procedural> that doesn't do anything.  It might be useful for developing
an application that uses L<NewRelic::Agent::FFI>, that runs on a supported platform in production,
but you want to develop parts of the code base that don't rely on NewRelic on a platform that is not
supported (which is everything that isn't Linux AMD64 apparently).

=head1 SEE ALSO

=over 4

=item L<NewRelic::Agent>

=item L<NewRelic::Agent::FFI>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
