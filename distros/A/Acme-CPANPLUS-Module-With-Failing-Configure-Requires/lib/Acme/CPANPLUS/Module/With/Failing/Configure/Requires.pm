package Acme::CPANPLUS::Module::With::Failing::Configure::Requires;
BEGIN {
  $Acme::CPANPLUS::Module::With::Failing::Configure::Requires::VERSION = '0.02';
}

#ABSTRACT: Fake module with a configure prereq that fails for testing CPANPLUS

use strict;
use warnings;

q[Its like fail, but betterer];


__END__
=pod

=head1 NAME

Acme::CPANPLUS::Module::With::Failing::Configure::Requires - Fake module with a configure prereq that fails for testing CPANPLUS

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 # erm

 cpanp -i Acme::CPANPLUS::Module::With::Failing::Configure::Requires

=head1 DESCRIPTION

Acme::CPANPLUS::Module::With::Failing::Configure::Requires is a fake module that has a
configure requires module that fails so I can test something in L<CPANPLUS> and L<CPANPLUS::YACSmoke>

No moving parts and nothing to see.

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

