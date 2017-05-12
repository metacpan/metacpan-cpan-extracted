use strict;
use warnings;
package CPAN::Testers::Metabase;
# ABSTRACT: Instantiate a Metabase backend for CPAN Testers 
our $VERSION = '1.999002'; # VERSION

1;



=pod

=head1 NAME

CPAN::Testers::Metabase - Instantiate a Metabase backend for CPAN Testers 

=head1 VERSION

version 1.999002

=head1 SYNOPSIS

  use CPAN::Testers::Metabase::Demo;

  # defaults to directory on /tmp
  my $mb = CPAN::Testers::Metabase::Demo->new;

  $mb->public_librarian->search( %search spec );

=head1 DESCRIPTION

The CPAN::Testers::Metabase namespace is intended to span a collection
of classes that instantiate specific Metabase backend storage and indexing
capabilities for a CPAN Testers style Metabase.

Each class consumes the L<Metabase::Gateway> role and can be used by
the L<Metabase::Web> application as a data model.

See specific classes for more detail:

=over 4

=item *

[CPAN::Testers::Metabase::AWS] -- storage and indexing with Amazon Web Services

=item *

[CPAN::Testers::Metabase::MongoDB] -- storage and indexing with MongoDB

=item *

[CPAN::Testers::Metabase::Demo] -- SQLite archive and flat-file index (for test/demo purposes only)

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Testers-Metabase>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/cpan-testers-metabase>

  git clone https://github.com/dagolden/cpan-testers-metabase.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut


__END__


