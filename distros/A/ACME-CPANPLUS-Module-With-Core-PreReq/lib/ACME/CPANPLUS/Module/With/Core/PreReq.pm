package ACME::CPANPLUS::Module::With::Core::PreReq;
$ACME::CPANPLUS::Module::With::Core::PreReq::VERSION = '0.06';
#ABSTRACT: Fake module with a prereq that is a core module for testing CPANPLUS

use strict;
use warnings;

qq[Nobody here but us chickens];

__END__

=pod

=encoding UTF-8

=head1 NAME

ACME::CPANPLUS::Module::With::Core::PreReq - Fake module with a prereq that is a core module for testing CPANPLUS

=head1 VERSION

version 0.06

=head1 SYNOPSIS

 # erm

 cpanp -i ACME::CPANPLUS::Module::With::Core::PreReq

=head1 DESCRIPTION

ACME::CPANPLUS::Module::With::Core::PreReq is a fake module that has a prerequisite of a core module
so I can test something in L<CPANPLUS> and L<CPANPLUS::YACSmoke>

No moving parts and nothing to see.

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
