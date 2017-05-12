package App::Relate;
#                                doom@kzsu.stanford.edu
#                                15 Mar 2010


=head1 NAME

App::Relate - simple form of the "relate" script (wrapper around locate)

=head1 SYNOPSIS

   use App::Relate ':all';

   relate( \@search, \@filter );

   relate( \@search, \@filter, $opts );

=head1 DESCRIPTION

relate simplifies the use of locate.

Instead of:

  locate this | egrep "with_this" | egrep "and_this" | egrep -v "but_not_this"

You can type:

  relate this with_this and_this -but_not_this

This module is a simple back-end to implement the relate script.
See L<relate> for user documentation.

=head2 EXPORT

None by default.  The following, on request (or via ':all' tag):

=over

=cut

use 5.008;
use strict;
use warnings;
my $DEBUG = 0;
use Carp;
use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [
  qw(
      relate
    ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(  ); # items to export into callers namespace by default.
                      # (don't use this without a very good reason.)
our $VERSION = '0.10';

=item relate

The relate routine searches the filesystem for items whose
fullpath matches all of the terms specified the search terms aref
(first argument), and filters out any that match a term in the
filters aref (second argument).  It's behavior can be modified
by options supplied in the options hashref (the third argument).

The options hashref may have values:

  ignore_case   do case insensitive searches

  dirs_only     return only matching directories
  files_only    return only matching plain files
  links_only    return only matching symlinks

  all_results   ignore any filter supplied as a second argument.
                A convenience to script usage: idential to using an undef second arg.

  test_data      For test purposes: an aref of strings to be searched and filtered.
                 Suppresses use of L<locate>.

  locate         Alternate 'locate' invocation string. See L<locate> routine.
  locatedb       Specify non-standard locate db file.  See L<locate> routine.

Example usage:

   my $results = relate( \@search_terms, \@filter_terms, $opts );


Example usage (searching a test data set):

   my $skipdull = ['~$', '\bRCS\b', '\bCVS\b', '^#', '\.elc$' ];
   my $results =
      relate( [ 'whun' ], $skipdull,
        { test_data => [ '/tmp/whun',
                         '/tmp/tew',
                         '/tmp/thruee',
                         '/etc/whun',
                     ],
          } );


=cut

sub relate {
  my $searches = shift;
  my $filters  = shift;
  my $opts     = shift;
  my $DEBUG    = $opts->{ DEBUG };

  my $all_results = $opts->{ all_results };
  my $ignore_case = $opts->{ ignore_case };
  my $test_data   = $opts->{ test_data };
  my $dirs_only   = $opts->{ dirs_only };
  my $files_only  = $opts->{ files_only };
  my $links_only  = $opts->{ links_only };

  my $initial;
  if ( ref( $test_data ) eq 'ARRAY' ) {
    $initial = $test_data;
  } elsif ( $test_data ) {
    carp "The 'test_data' option should be an array reference.";
  } else {
    my $seed = shift @{ $searches };
    $initial = locate( $seed, $opts );
  }

  # dwim upcarets: usually should behave like boundary matches
  my @rules = map{ s{^ \^ (?![/]) }{\\b}xg; $_ } @{ $searches };
  # TODO why not qr{ $_ }, compile regexps at this stage?  Bench this...

  my @set = @{ $initial };
  my @temp;
  # try each search term, winnowing down result on each pass
  if ( not( $ignore_case ) ) {
    foreach my $search ( @rules ) {
      # leading minus means negation
      if ( (my $term = $search) =~ s{ ^ - }{}x ) {
        my $rule = qr{ $term }x;
        @temp = grep { not m{ $rule }x } @set;
      } else {
        my $rule = qr{ $search }x;
        @temp = grep { m{ $rule }x } @set;
      }
      @set = @temp;
      @temp  = ();
    }
  } else { # ignore case
    foreach my $search ( @rules ) {
      # leading minus means negation
      if ( (my $term = $search) =~ s{ ^ - }{}x ) {
        my $rule = qr{ $term }xi;
        @temp = grep { not m{ $rule }x } @set;
      } else {
        my $rule = qr{ $search }xi;
        @temp = grep { m{ $rule }x } @set;
      }
      @set = @temp;
      @temp  = ();
    }
  }

  # pre-compile each filter term
  my @filters;
  if ( not( $ignore_case ) ) {
    @filters = map{ qr{ $_ }x } @{ $filters };
  } else {  # ignore case
    @filters = map{ qr{ $_ }xi } @{ $filters };
  }

  # apply each filter pattern, rejecting what matches
  unless( $all_results ) {
    foreach my $filter ( @filters ) {
      @temp = grep { not m{ $filter }x } @set;
      @set = @temp;
      @temp  = ();
    }
  }

  if( $dirs_only ) {
    @set = grep{ -d $_ } @set;
  } elsif ( $files_only ) {
    @set = grep{ -f $_ } @set;
  } elsif ( $links_only ) {
    @set = grep{ -l $_ } @set;
  }

  return \@set;
}


=item locate

Runs the locate command on the given search term, the "seed".
Also accepts a hashref of options as a second argument.

Makes use of options fields "DEBUG", "locate", and "locatedb"
(aka "database").

The "locate" option defaults simply to "locate".  Define it as
something else if you want to use a different program internally.
(note: you may include the path).

Example:

   my $hits = locate( $seed, { locate => '/usr/local/bin/slocate' } );

   my $hits = locate( $seed, { locatedb => '/tmp/slocate.db' } );

=cut

sub locate {
  my $seed     = shift;
  my $opts     = shift;
  my $DEBUG    = $opts->{ DEBUG };

  my $locate   = $opts->{ locate } || 'locate';
  my $database = $opts->{ database } || $opts->{ locatedb };

  my $option_string = '';
  if ( $opts->{ regexp } ) {
    $option_string .= ' -r ';
  }

  if ( $opts->{ ignore_case } ) {
    $option_string .= ' -i ';
  }

  if ( $database ) {
    $option_string .= " -d $database ";
  }

  my $cmd   = qq{ $locate $option_string $seed };
  ($DEBUG) && print STDERR "cmd: $cmd\n";

  my $raw   = qx{ $cmd };
  chomp( $raw );

  my @set = split /\n/, $raw;

  return \@set;
}

1;

=back

=head1 SEE ALSO

See the man page for "locate".

L<App::Relate> is a more complicated version of this project.
It's based on L<List::Filter>, which was intended to allow the
sharing of filters between different projects.

=head1 NOTES

=head1 TODO

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Joseph Brenner

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 BUGS

See L<relate>.

=cut
