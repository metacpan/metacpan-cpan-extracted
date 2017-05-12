package BuzzSaw::Filter::UserClassifier; # -*-perl-*-
use strict;
use warnings;

# $Id: UserClassifier.pm.in 23005 2013-04-04 06:42:45Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 23005 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/Filter/UserClassifier.pm.in $
# $Date: 2013-04-04 07:42:45 +0100 (Thu, 04 Apr 2013) $

our $VERSION = '0.12.0';

use BuzzSaw::UserClassifier ();

use Moose;

with 'BuzzSaw::Filter', 'MooseX::Log::Log4perl';

has 'classifier' => (
  isa     => 'BuzzSaw::UserClassifier',
  is      => 'ro',
  lazy    => 1,
  builder => '_build_classifier',
);

sub _build_classifier {
  my $classifier = BuzzSaw::UserClassifier->new(
    nonpersonal_users => '/usr/share/buzzsaw/data/nonpersonal.txt',
  );

  return $classifier;
}

no Moose;
__PACKAGE__->meta->make_immutable;

sub check {
  my ( $self, $event, $votes ) = @_;

  if ( !$votes ) {
    return $BuzzSaw::Filter::VOTE_NO_INTEREST;
  }

  my @tags;
  if ( defined $event->{userid} && length $event->{userid} > 0 ) {
    my $username = $self->classifier->mangle_username($event->{userid});
    my $class = $self->classifier->classify($username);

    my $tag = 'user_is_' . $class;
    push @tags, $tag;
  }

  return ( $BuzzSaw::Filter::VOTE_NEUTRAL, @tags );
}

1;
__END__

=head1 NAME

BuzzSaw::Filter::UserClassifier - A BuzzSaw event filter for classifying users

=head1 VERSION

This documentation refers to BuzzSaw::Filter::UserClassifier version 0.12.0

=head1 SYNOPSIS

   my @filters = [BuzzSaw::Filter::SSH->new(),
                  BuzzSaw::Filter::Cosign->new(),
                  BuzzSaw::Filter::UserClassifier->new()];

   while ( defined( my $line = $fh->getline ) ) {
     my %event = $parser->parse_line($line);

     my ( $store, @all_tags);
     for my $filter (@filters) {
        my ( $accept, @tags ) = $filter->check(\%event, $store);
        if ($accept) {
          if ( $accept > 0 ) {
             $store = 1;
          }
          push @all_tags, @tags;
        }
     }

     if ($store) {
        # store log entry in DB
     }
   }

=head1 DESCRIPTION

This is a Moose class which provides a filter which implements the
BuzzSaw::Filter role. It is used to post-process entries where a
previous filter in the stack has requested that it be stored into the
database. If an entry of interest has a value set for the C<userid>
attribute then this module will classify the type of username (root,
nonperson, real, others) using the L<BuzzSaw::UserClassifier>
module. This module will return a tag with a C<user_is_> prefix, like
C<user_is_root> or C<user_is_real>. This module will not affect
whether (or not) the entry is stored into the database. This module is
designed to be used at the end of the filter stack so that it can
process the results of all filters which might set a value for the
C<userid> attribute.

The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=head1 ATTRIBUTES

=over

=item name

The short name of the module. The default is to use the final part of
the Perl module name lower-cased (e.g. the name of
C<BuzzSaw::Filter::UserClassifier> is C<userclassifier>).

=back

=head1 SUBROUTINES/METHODS

=over

=item ( $accept, @tags ) = $filter->check(\%event,$votes)

This method checks to see if any previous filter in the stack has
requested that the log entry be stored (the C<$votes> counter). If an
entry of interest has a value set for the C<userid> attribute then
this module will classify the type of username (root, nonperson, real,
others) using the L<BuzzSaw::UserClassifier> module. This module will
return a tag with a C<user_is_> prefix, like C<user_is_root> or
C<user_is_real>. This module will not affect whether (or not) the
entry is stored into the database. This module is designed to be used
at the end of the filter stack so that it can process the results of
all filters which might set a value for the C<userid> attribute.

=back

=head1 DEPENDENCIES

This module is powered by L<Moose>. This module implements the
L<BuzzSaw::Filter> Moose role.

=head1 SEE ALSO

L<BuzzSaw>, L<BuzzSaw::Parser>

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

ScientificLinux6

=head1 BUGS AND LIMITATIONS

Please report any bugs or problems (or praise!) to bugs@lcfg.org,
feedback and patches are also always very welcome.

=head1 AUTHOR

    Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

    Copyright (C) 2013 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
