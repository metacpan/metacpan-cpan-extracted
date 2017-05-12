package Bio::Chado::Schema::Util;
BEGIN {
  $Bio::Chado::Schema::Util::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Util::VERSION = '0.20000';
}
use strict;
use Carp::Clan qr/^Bio::Chado::Schema/;

sub create_properties {
    my ($class,  %args) = @_;

    #check for required args
    $args{prop_relation_name} or confess "must provide $_ arg"
      for qw/ row prop_relation_name properties options/;

    my $self  = delete $args{row};
    my $props = delete $args{properties};
    my $opts  = delete $args{options};
    my $prop_relation_name = delete $args{prop_relation_name};

    %args and confess "invalid option(s): ".join(', ', sort keys %args);

    # normalize the props to hashrefs
    foreach (values %$props) {
        $_ = { value => $_ } unless ref eq 'HASH';
    }

    # process opts
    $opts ||= {};
    defined $opts->{cv_name} or confess 'must provide a cv_name in options';
    $opts->{db_name} = 'null'
        unless defined $opts->{db_name};
    $opts->{dbxref_accession_prefix} = 'autocreated:'
        unless defined $opts->{dbxref_accession_prefix};

    # cannot support literal-sql values (i.e. SQL function calls)
    # without allow_duplicate_values being set
    my $have_literal_sql = 0;
    for my $propname ( keys %$props ) {
        my $val = $props->{$propname}{value};
        if( ref $val eq 'SCALAR' ) {
            $have_literal_sql = 1;
            unless( $opts->{allow_duplicate_values} ) {
                croak "SQL-literal value '$$val' requested for '$propname' property, but allow_duplicate_values not set.  Cannot check for duplicates";
            }
        }
    }

    my $schema = $self->result_source->schema;

    my $prop_cv = do {
        my $cvrs = $schema->resultset('Cv::Cv');
        my $find_or_create = $opts->{autocreate} ? 'find_or_create' : 'find';
        $cvrs->$find_or_create({ name => $opts->{cv_name}},
                               { key => 'cv_c1' })
            or croak "cv '$opts->{cv_name}' not found and autocreate option not passed, cannot continue";
    };

    my $prop_db; #< set as needed below

    # find/create cvterms and dbxrefs for each of our featureprops,
    # and remember them in %propterms
    my %propterms;
    foreach my $propname (keys %$props) {
        my $existing_cvterm = $propterms{$propname} =
            $prop_cv->find_related('cvterms',
                                   { name => $propname,
                                     is_obsolete => 0,
                                   },
                                   { key => 'cvterm_c1' },
                                  );

        # if there is no existing cvterm for this in the prop table,
        # and we have the autocreate flag set true, then create a
        # cvterm, dbxref, and db for it if necessary
        unless( $existing_cvterm ) {
            $opts->{autocreate}
               or croak "cvterm not found for property '$propname', and autocreate option not passed, cannot continue";

            # look up the db object if we don't already have it, now
            # that we know we need it
            $prop_db ||=
                $self->result_source->schema
                     ->resultset('General::Db')
                     ->find_or_create( { name => $opts->{db_name} },
                                       { key => 'db_c1' }
                                     );

            # find or create the dbxref for this cvterm we are about
            # to create
            my $dbx_acc = $opts->{dbxref_accession_prefix}.$propname;
            my $dbxref =
                $prop_db->search_related( 'dbxrefs',
                                          { accession => $dbx_acc },
                                          { order_by => { -desc => ['version'] } }
                                        )
                                ->first
             || $prop_db->create_related( 'dbxrefs', { accession => $dbx_acc,
                                                               version => 1,
                                                             });

            # look up any definition we might have been given for this
            # propname, so we can insert it if given
            my $def = $opts->{definitions}->{$propname};

            $propterms{$propname} =
                $prop_cv->create_related('cvterms',
                                         { name => $propname,
                                           is_obsolete => 0,
                                           dbxref_id => $dbxref->dbxref_id,
                                           $def ? (definition => $def) : (),
                                         }
                                        );
        }
    }

    my %props;
    while( my ($propname,$propval) = each %$props ) {

        my $data = $propval;
        $data->{type_id} = $propterms{$propname}->cvterm_id;


        # decide whether to skip creating this prop
        my $skip_creation = $opts->{allow_duplicate_values}
            ? 0
            : $self->search_related( $prop_relation_name,
                                     { type_id => $data->{type_id},
                                       value   => $data->{value},
                                     })
                   ->count;


        unless( $skip_creation ) {
            #if rank is defined
            if ($opts->{rank} && defined $opts->{rank} ) {
                my ($existing_prop) = $self->search_related(
                    $prop_relation_name,
                    {
                        type_id =>$data->{type_id},
                        rank => $opts->{rank}
                    }
                  );
                if( defined $existing_prop ) {
                    warn "Property " .  $existing_prop->value() . "  already exists with rank " . $opts->{rank} . ". skipping! \n"
                }
                $data->{rank} = $opts->{rank};
            } else {
                # find highest rank for props of this type
                my $max_rank= $self->search_related(
                    $prop_relation_name,
                    {
                        type_id => $data->{type_id},
                    }
                 )->get_column('rank')
                  ->max;
                $data->{rank} = defined $max_rank ? $max_rank + 1 : 0;
            }
            $props{$propname} = $self->find_or_create_related(
                $prop_relation_name,
                $data
             );
        }
    }

    if( $have_literal_sql ) {
        $_->discard_changes for values %props;
    }
    return \%props;
}

1;

__END__

=head1 NAME

Bio::Chado::Schema::Util - utility functions shared by Bio::Chado::Schema objects

=head1 SYNOPSIS

  sub create_organismprops {
      my ($self, $props, $opts) = @_;

      # process opts
      $opts ||= {};
      $opts->{cv_name} = 'organism_property'
          unless defined $opts->{cv_name};

      return Bio::Chado::Schema::Util->create_props
          ( properties => $props,
            options    => $opts,
            row        => $self,
            prop_relation_name => 'organismprops',
          );
  }

=head1 DESCRIPTION

Helper functions used by several schema classes.

Important Note:
This package is located in the Schema.pm file as secondary package
and it haven't a file for itself. Nevertheless, the use will be the same.

=head1 PACKAGE METHODS

=head2 create_properties

  Usage: *::Util->create_properties( row => $self,
                                     properties => { baz => 2, foo => 'bar' },
                                     options => { cv_name => autocreate => 0, ...},
                                     prop_relation_name => 'organismprops',
                                   );

  Desc : Chado has a number of <thing>prop tables with a similar
         structure.  This utility function is used by a number of
         modules to create properties in these kinds of tables.

  Args : row => the DBIC row object to create properties for,
         prop_relation_name => the DBIC relation name for the
                               properties table to operate on,
                               e.g. 'featureprops',
         properties => hashref of { propname => value, ...},
         options => options hashref as:
             {
               autocreate => 0,
                  (optional) boolean, if passed, automatically create cv,
                  cvterm, and dbxref rows if one cannot be found for the
                  given featureprop name.  Default false.

               cv_name => cv.name to use for the given featureprops.
                          Defaults to 'feature_property',

               db_name => db.name to use for autocreated dbxrefs,
                          default 'null',

               allow_duplicate_values => default false.
                   If true, allow duplicate instances of the same cvterm
                   and value in the properties of the feature.  Duplicate
                   values will have different ranks.

               dbxref_accession_prefix => optional, default
                                          'autocreated:',
               definitions => optional hashref of:
                   { cvterm_name => definition,
                   }
                to load into the cvterm table when autocreating cvterms
             }
  Ret  : hashref of { propname => new row object in property table }

=cut


=head1 AUTHOR

Robert Buels, <rmb32@cornell.edu>

Naama Menda, <naama.menda@gmail.com>

=cut
