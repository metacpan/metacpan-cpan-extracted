package Acme::CPANPLUS::PreReq::Text::Tabs;
$Acme::CPANPLUS::PreReq::Text::Tabs::VERSION = '0.04';
#ABSTRACT: Fake module with a prereq on Text+Tabs for testing CPANPLUS

use strict;
use warnings;

q[Its like fail, but betterer];

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANPLUS::PreReq::Text::Tabs - Fake module with a prereq on Text+Tabs for testing CPANPLUS

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 # erm

 cpanp -i Acme::CPANPLUS::PreReq::Text::Tabs

=head1 DESCRIPTION

Acme::CPANPLUS::PreReq::Text::Tabs is a fake module that has a prereq on the
L<Text::Tabs> module so I can test something in L<CPANPLUS> and L<CPANPLUS::YACSmoke>

No moving parts and nothing to see.

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
