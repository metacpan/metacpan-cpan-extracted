use 5.006;
use strict;
use warnings;

package CPAN::Testers::Fact::TesterComment;
# ABSTRACT: comment about a CPAN Tester report

our $VERSION = '1.999003';

use Carp ();

use Metabase::Fact::String 0.016;
our @ISA = qw/Metabase::Fact::String/;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Testers::Fact::TesterComment - comment about a CPAN Tester report

=head1 VERSION

version 1.999003

=head1 SYNOPSIS

  my $fact = CPAN::Testers::Fact::TesterComment->new(
    resource => 'cpan:///distfile/RJBS/CPAN-Metabase-Fact-0.001.tar.gz',
    content => $my_comment,
  );

=head1 DESCRIPTION

Comment from a tester about a CPAN Testers report. (E.g. "Automated test, no
human checked these results")

=head1 USAGE

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.  
Bugs can be submitted through the web interface at 
L<http://rt.cpan.org/Dist/Display.html?Queue=CPAN-Testers-Report>

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
