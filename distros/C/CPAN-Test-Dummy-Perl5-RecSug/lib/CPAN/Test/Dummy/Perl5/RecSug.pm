use strict;
use warnings;

package CPAN::Test::Dummy::Perl5::RecSug;
# ABSTRACT: CPAN test dummy with optional prereqs
our $VERSION = '0.001'; # VERSION

# Dependencies
use autodie 2.00;

1;


# vim: ts=2 sts=2 sw=2 et:

__END__
=pod

=head1 NAME

CPAN::Test::Dummy::Perl5::RecSug - CPAN test dummy with optional prereqs

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use CPAN::Test::Dummy::Perl5::RecSug;

=head1 DESCRIPTION

This test dummy is for testing CPAN clients.  It has optional build and runtime
prerequisites of the 'recommends' and 'suggests' type.  Some of these
prerequisites are other test dummies that are guaranteed to fail.

=for Pod::Coverage method_names_here

=head1 USAGE

Don't use this if you don't already know how it works.

Seriously.  This is not for the casual Perl programmer.

Consider yourself warned.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Test-Dummy-Perl5-RecSug>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/cpan-test-dummy-perl5-recsug>

  git clone https://github.com/dagolden/cpan-test-dummy-perl5-recsug.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

