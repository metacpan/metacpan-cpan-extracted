package Data::FormValidator::Filters::WikiTrim;

###############################################################################
# Required inclusions.
###############################################################################
use strict;
use warnings;

###############################################################################
# Export a few of our methods
###############################################################################
use base qw( Exporter );
our @EXPORT_OK = qw(
    wiki_trim
    );

###############################################################################
# Version number
###############################################################################
our $VERSION = '0.03';

###############################################################################
# Subroutine:   wiki_trim()
###############################################################################
# Returns a filter which trims leading/trailing whitespace in a manner more
# suitable for wikitext entry fields; leading blank -lines- are trimmed, as
# well as all trailing whitespace.
#
# This differs from the standard "trim" filter in that we're only trimming
# leading blank -lines- but leave any leading whitespace on the first line;
# those leading spaces may be important.
###############################################################################
sub wiki_trim {
    return sub {
        return _wiki_trim( shift );
    }
}

sub _wiki_trim {
    my $value = shift;
    return unless defined $value;

    # remove leading blank lines
    $value =~ s/^\s+\n//;

    # remove trailing whitespace
    $value =~ s/\s+$//;

    # done
    return $value;
}

1;

=for stopwords wikitext

=head1 NAME

Data::FormValidator::Filters::WikiTrim - Trim filter for wikitext fields

=head1 SYNOPSIS

  use Data::FormValidator::Filters::WikiTrim qw(wiki_trim);

  # Build Data::FormValidator profile
  my $profile = {
      'required' => [qw( subject body )],
      'field_filters' => {
          'subject' => 'trim',
          'body'    => wiki_trim(),
      },
  };

=head1 DESCRIPTION

C<Data::FormValidator::Filters::WikiTrim> provides a slightly different C<trim>
filter than the default.  Rather than trimming I<all> leading/trailing
whitespace, we trim all leading I<blank lines> and all trailing whitespace.  In
a wikitext field, leading spaces on the first line could be important so they
need to be preserved (while leading blank lines aren't important and could be
trimmed out).

=head1 METHODS

=over

=item wiki_trim()

Returns a filter which trims leading/trailing whitespace in a manner more
suitable for wikitext entry fields; leading blank -lines- are trimmed, as
well as all trailing whitespace.

This differs from the standard "trim" filter in that we're only trimming
leading blank -lines- but leave any leading whitespace on the first line;
those leading spaces may be important.

=back

=head1 AUTHOR

Graham TerMarsch <cpan@howlingfrog.com>

=head1 COPYRIGHT

Copyright (C) 2007, Graham TerMarsch.  All Rights Reserved.

This is free software; you can redistribute it and/or modify it under the same
license as Perl itself.

=head1 SEE ALSO

=over

=item L<Data::FormValidator>

=back

=cut
