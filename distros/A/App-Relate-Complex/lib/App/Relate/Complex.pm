package App::Relate::Complex;
use base qw( Class::Base );

=head1 NAME

App::Relate::Complex - backend for "relate" script (filtered locate)

=head1 SYNOPSIS

    use App::Relate::Complex;

    # search the standard locate database
    my $rh = App::Relate::Complex->new();
    my $matches = $rh->relate_complex( \@search_terms );


    # screen the results with a named filter
    my $matches = $rh->relate_complex( \@terms, { add_filters => [':omit'] });


    # using options (1) a non-standard locate db, (2) alternate filter storage,
    # (3) case-insensitive matches

    # generating a newly created locate database
    use File::Locate::Harder;
    my $db_file = "/tmp/special_locate.db";
    my $flh = File::Locate::Harder->new( db => undef );
    $flh->create_database( $dir_to_be_indexed, $db_file );

    # filter storage search path consisting of:
    #   (1) yaml file (2) a DBI database connection
    my $alt_storage_aref = [
               $yaml_file,
               { format     => 'DBI',
                 connect_to => $connect_to,
                 owner      => $owner,
                 password   => $password,
               },
            ];

    my $rh = App::Relate::Complex->new( {
               storage            => $alt_storage_aref,
               locatedb           => $db_file,
               modifiers          => 'i',  # force case-insensitive matches
            } );
    my $matches = $rh->relate_complex( \@terms );


    # save_filters_when_used can be used to make user-modifiable copies
    # of standard filters
    my $lfar = App::Relate::Complex->new( {
                storage                => $yaml_file,
                save_filters_when_used => 1,
              } );
    my $result = $lfar->relate_complex( \@search_terms ); # by default uses ':skipdull'
        # A copy of the ":skipdull" filter should now be found in
        # $yaml_file, where it can be edited: it will take precedence
        # over the default definition on later runs.


=head1 DESCRIPTION

Implements the functionality for the L<relate_complex> script, which uses
the system's "locate" database to find file names that match
multiple search terms.

This version uses the List::Filter modules to get some
flexibility and persistance advantages.

It tries to access the locate database through File::Locate::Harder
in order to be relatively portable.

=head2 METHODS

=over

=cut

use 5.8.0;
use strict;
use warnings;
use Carp;
use Hash::Util qw( lock_keys unlock_keys );
use Env qw(HOME);

my $DEBUG = 0;
BEGIN {
  if ($DEBUG) {
    require Data::Dumper;
  }
};

use File::Path     qw(mkpath);
use File::Locate::Harder;
use List::Filter;
use List::Filter::Storage;
use List::Filter::Transform;
use List::Filter::Internal;

our $VERSION = '0.04';

=item new

Instantiates a new App::Relate::Complex object.

Takes an optional hashref as an argument, with named fields,
which are very similar but not quite identical to those of
L<List::Filter::Storage>.

=over

=item storage

Search path for L<List::Filter> filters, but with an
automatically appended handle for the standard filters
(defined in the code libraries List::Filter::Library::*)

=item write_storage

The location (typically a yaml file) that filters are saved to.
When we run with "save_filters_when_used" on, accessible copies
will be exist here for any filter that's been invoked, even the
standard filters.

=item transform_storage

Like "storage", except for L<List::Filter::Transform> "transforms".
Used internally to access one standard filter (the "dwim" transform
of "^" into a boundary match).  Unlike the case with filter storage,
copies of standard transforms are not saved to the write_storage.

=item locatedb

The "locate" database file used for primary searches. Optional,
defaults to the system's main locate database.  Setting this is
typically done only for testing purposes.

=item modifiers

Yet another place where perl regexp modifiers can be specified.
E.g. a "i" will force case-insensitive matches, overriding any
internal modifier settings.

=item save_filters_when_used

Option to create accessible copies of standard filters that are used
(gives the user an easy way to make modifications that override
the standard definitions).

=item search_filter_name

An internally used, temporary filter name, defaults to a value
which should be unique to the user (to avoid collisons if shared
filter storage is in use).  Note: List::Filter at present lacks
"anonymous filter" features, this is a work around.
Default: _prev_relate_<user>.

=back

=cut

# Note:
# "new" is inherited from Class::Base.
# It calls the following "init" routine automatically.

=item init

Initialize object attributes and then lock them down to prevent
accidental creation of new ones.

=cut

sub init {
  my $self = shift;
  my $args = shift;
  unlock_keys( %{ $self } );

  my $transform_storage  = $args->{ transform_storage } || [];

  my $default_stash_dir = "$HOME/.list-filter";
  mkpath( $default_stash_dir );
  my $default_stash_name = "filters.yaml";
  my $default_stash = "$default_stash_dir/$default_stash_name";

  my $lfi = List::Filter::Internal->new( { default_stash => $default_stash } );
  my $storage = $lfi->qualify_storage( $args->{ storage } );

  my $write_storage  = $args->{write_storage}  || $storage->[0];

  my $code_connect_params_filter = {
                             format => 'CODE',
                            };
  push @{ $storage }, $code_connect_params_filter;
  my $filter_storage = List::Filter::Storage->new(
                { storage                => $storage,
                  save_filters_when_used => $args->{ save_filters_when_used },
                } );

  push @{ $transform_storage }, { format => 'CODE' };
  my $lfth = List::Filter::Storage->new(
                { type                   => 'transform',
                  storage                => $transform_storage,
                } );

  my $flh = File::Locate::Harder->new(
                                       { db => $args->{ locatedb },
                                     } );

  # creating a filter name for internal use
  my $search_filter_name = '_prev_relate';
  my $user = $ENV{ USER };
  $search_filter_name .= "_$user" if ($user);

  # define new attributes
  my $attributes = {
                    filter_storage     => $filter_storage,
                    lfth               => $lfth, # list filter transform handle (?)
                    flh                => $flh,
                    locatedb           => $args->{ locatedb },
                    modifiers          => $args->{ modifiers },
                    search_filter_name => $search_filter_name,
           };

  if( $DEBUG ) {
    $self->debugging(1);
  }

  # add attributes to object
  my @fields = (keys %{ $attributes });
  @{ $self }{ @fields } = @{ $attributes }{ @fields };    # hash slice

  lock_keys( %{ $self } );
  return $self;
}

=item setup_filter_names

Routine used internally to setup fitler names from options settings and so on.

=cut

sub setup_filter_names {
  my $self = shift;
  my $opt  = shift;
  my $default_filters = shift;

  my $filter_names = [];
  if ( not ($opt->{ no_default_filters })) {
    push @{ $filter_names }, @{ $default_filters };
  };
  if( my $add_filters_string = $opt->{ add_filters } ) {
    # strip any leading and trailing quotes that might have leaked through
    $add_filters_string =~ s{ ^ ['"] }{}x;
    $add_filters_string =~ s{ ['"] $ }{}x;
    my @add_filters = split(' ', $add_filters_string);
    push @{ $filter_names }, @add_filters;
  }

  return $filter_names;
}

=item setup_locate_options

Routine used internally (by the relate_complex routine) to set up the
string of option switches that need to be used with the locate
command (now handled by File::Locate::Harder).

=cut

sub setup_locate_options {
  my $self = shift;
  my $opt  = shift;

  my $modifiers = $self->modifiers;
  my $case_insensitive = 0;
  if ($modifiers) {
    $case_insensitive = 1 if $modifiers =~ /i/;
  }

  #  -r => primary term is a POSIX regexp
  my $regexp_flag;
  if ( $opt->{regexp} ) {
     $regexp_flag = 1;
  }

  #  -e => primary term is a POSIX "extended" regexp
  my $posix_extended;
  if ( $opt->{posix_extended} ) {
     $posix_extended = 1;
  }

  my $flh = $self->flh;

  my $db_file = $self->locatedb;
  $flh->set_db( $db_file );
  $flh->set_case_insensitive( $case_insensitive );
  $flh->set_regexp( $regexp_flag );
  $flh->set_posix_extended( $posix_extended );

  return $flh;
}



=item relate_complex

Searches for matching items in the output from the system's
"locate" command, using some named filters (L<List::Filter>)
to winnow the results.

The list of search patterns may all be perl regexp's (where \x
should be assumed), except for the first term, which must be a
simple string that can be fed into the locate command (L<locate>).
Efficiency is greatly improved if this string
is relatively unique.

This defaults to using the standard ":skipdull" filter on the
search results.  If the "save_filters_when_used" option has been
enabled, a copy of this will be found in the "write_location": it
can be edited, and the modified version will take precedence over
the default definition on later runs.

Input:
(1) (aref) list of search patterns (with the first item simple, but unique)
(2) (href) options:

=over

=item  no_default_filters

supresses the default filter(s) (cf. ':skipdull')

=item add_filters

list of filter names to use (in addition to the defaults unless,
those have been supressed): this is a space seperated string (not
an aref)

=item regexp

The first item is a POSIX regexp.

=back

Returns: (aref) matching items that pass the filters

Example:

   @terms = qw( china www var images );
   $china_pics = $self->relate_complex( \@terms, { filters => [":jpeg"] } );

=cut

# In outline: here we use two filters with one transform *on* one of the filters
sub relate_complex {
  my $self            = shift;
  my $search_patterns = shift;
  my $opt             = shift;

  my $default_filters = [':skipdull'];
  my $filter_names = $self->setup_filter_names( $opt, $default_filters );

  #(0) shift off the special first term (the seed)
  #(1) transform input array of regexps $search_patterns
  #    ( or vice-versa, if -r is in use )

  my $dwim_upcaret_for_paths
    = $self->lfth->lookup( ':dwim_upcaret' );

  my ($primary, $primary_save, $dwim_search_patterns);
  $primary_save = shift( @{ $search_patterns } );
  if( $opt->{regexp} ) {  # if the first item is a regexp, than do the dwim magic to it too

     $primary = $dwim_upcaret_for_paths->apply( [ $primary_save ] )->[0];

     $dwim_search_patterns =
       $dwim_upcaret_for_paths->apply( $search_patterns );

  } else {

    $primary = $primary_save;

    $dwim_search_patterns =
      $dwim_upcaret_for_paths->apply( $search_patterns );
  }


  #(2) get raw listing of hits from locate using the seed term

  $self->setup_locate_options( $opt );
  my $flh = $self->flh;
  my $raw = $flh->locate( $primary );

  #(3) filter the raw results with a newly created filter from input array

  my $search_filter_name = $self->search_filter_name;

  my $modifiers = $self->modifiers;
  my $search_filter = List::Filter->new( {
                                          name         => $search_filter_name,
                                          description  => "The last relate search",
                                          method       => "match_all_any_order",
                                          terms        => $dwim_search_patterns,
                                          modifiers    => $modifiers,
                                         } );

   my $intermed = $search_filter->apply( $raw );

  # (4) filter using standard named omit filter(s) (":skipdull")

  # loop over filters applying each one in turn.
  my $filter_storage = $self->filter_storage;
  foreach my $filter_name (@{ $filter_names }) {
    if ( my $filter = $filter_storage->lookup( $filter_name ) ){

      $intermed = $filter->apply( $intermed );
    } else {
      warn "Could not lookup filter named: $filter_name";
    }
  }
  my $result = $intermed;

  # (5) cleaning up modification to search terms aref
  #     (avoiding a surprising side-effect, without copying array)
  unshift @{ $search_patterns }, $primary_save;

  return $result;
}



=item list_filters

Returns a list of all avaliable named filters.

=cut

sub list_filters {
  my $self = shift;
  my $search_patterns = shift;
  my $opt             = shift;

  my $modifiers       = $self->modifiers;

  my $filter_storage  = $self->filter_storage;
  my $filters         = $filter_storage->list_filters;

  my $search_filter_name = $self->search_filter_name;

  my $search_filter   = List::Filter->new( {
                           name         => $search_filter_name,
                           description  => "The last relate filter listing",
                           method       => "match_all_any_order",
                           terms        => $search_patterns,
                           modifiers    => $modifiers,
                        } );

  my $filtered_filters = $search_filter->apply( $filters );

  return $filtered_filters;
}



=back

=head2 basic setters and getters

=over

=item storage

Getter for object attribute storage

=cut

sub storage {
  my $self = shift;
  my $storage = $self->{ storage };
  return $storage;
}

=item set_storage

Setter for object attribute set_storage

=cut

sub set_storage {
  my $self = shift;
  my $storage = shift;
  $self->{ storage } = $storage;
  return $storage;
}



=item locatedb

Getter for object attribute locatedb

=cut

sub locatedb {
  my $self = shift;
  my $locatedb = $self->{ locatedb };
  return $locatedb;
}

=item set_locatedb

Setter for object attribute locatedb

=cut

sub set_locatedb {
  my $self = shift;
  my $locatedb = shift;
  $self->{ locatedb } = $locatedb;
  return $locatedb;
}



=item modifiers

Getter for object attribute modifiers

=cut

sub modifiers {
  my $self = shift;
  my $modifiers = $self->{ modifiers };
  return $modifiers;
}

=item set_modifiers

Setter for object attribute set_modifiers

=cut

sub set_modifiers {
  my $self = shift;
  my $modifiers = shift;
  $self->{ modifiers } = $modifiers;
  return $modifiers;
}


=item filter_storage

Getter for object attribute filter_storage

=cut

sub filter_storage {
  my $self = shift;
  my $filter_storage = $self->{ filter_storage };
  return $filter_storage;
}

=item set_filter_storage

Setter for object attribute set_filter_storage

=cut

sub set_filter_storage {
  my $self = shift;
  my $filter_storage = shift;
  $self->{ filter_storage } = $filter_storage;
  return $filter_storage;
}

=item lfth

Getter for object attribute lfth

=cut

sub lfth {
  my $self = shift;
  my $lfth = $self->{ lfth };
  return $lfth;
}

=item set_lfth

Setter for object attribute set_lfth

=cut

sub set_lfth {
  my $self = shift;
  my $lfth = shift;
  $self->{ lfth } = $lfth;
  return $lfth;
}


=item flh

Getter for object attribute flh

=cut

sub flh {
  my $self = shift;
  my $flh = $self->{ flh };
  return $flh;
}

=item set_flh

Setter for object attribute set_flh

=cut

sub set_flh {
  my $self = shift;
  my $flh = shift;
  $self->{ flh } = $flh;
  return $flh;
}


=item search_filter_name

Getter for object attribute search_filter_name

=cut

sub search_filter_name {
  my $self = shift;
  my $search_filter_name = $self->{ search_filter_name };
  return $search_filter_name;
}

=item set_search_filter_name

Setter for object attribute set_search_filter_name

=cut

sub set_search_filter_name {
  my $self = shift;
  my $search_filter_name = shift;
  $self->{ search_filter_name } = $search_filter_name;
  return $search_filter_name;
}

1;

=back

=head1 SEE ALSO

L<List::Filter>
L<List::Filter::Project>

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Joseph Brenner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
