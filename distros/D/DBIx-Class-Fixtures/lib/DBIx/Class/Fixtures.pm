package DBIx::Class::Fixtures;

use strict;
use warnings;

use DBIx::Class 0.08100;
use DBIx::Class::Exception;
use Class::Accessor::Grouped;
use Config::Any::JSON;
use Data::Dump::Streamer;
use Data::Visitor::Callback;
use Hash::Merge qw( merge );
use Data::Dumper;
use Class::C3::Componentised;
use MIME::Base64;
use IO::All;
use File::Temp qw/tempdir/;

use base qw(Class::Accessor::Grouped);

our $namespace_counter = 0;

__PACKAGE__->mk_group_accessors( 'simple' => qw/config_dir
    _inherited_attributes debug schema_class dumped_objects config_attrs/);

our $VERSION = '1.001039';

$VERSION = eval $VERSION;

=head1 NAME

DBIx::Class::Fixtures - Dump data and repopulate a database using rules

=head1 SYNOPSIS

 use DBIx::Class::Fixtures;

 ...

 my $fixtures = DBIx::Class::Fixtures->new({
     config_dir => '/home/me/app/fixture_configs'
 });

 $fixtures->dump({
   config => 'set_config.json',
   schema => $source_dbic_schema,
   directory => '/home/me/app/fixtures'
 });

 $fixtures->populate({
   directory => '/home/me/app/fixtures',
   ddl => '/home/me/app/sql/ddl.sql',
   connection_details => ['dbi:mysql:dbname=app_dev', 'me', 'password'],
   post_ddl => '/home/me/app/sql/post_ddl.sql',
 });

=head1 DESCRIPTION

Dump fixtures from source database to filesystem then import to another
database (with same schema) at any time. Use as a constant dataset for running
tests against or for populating development databases when impractical to use
production clones. Describe fixture set using relations and conditions based on
your DBIx::Class schema.

=head1 DEFINE YOUR FIXTURE SET

Fixture sets are currently defined in .json files which must reside in your
config_dir (e.g. /home/me/app/fixture_configs/a_fixture_set.json). They
describe which data to pull and dump from the source database.

For example:

 {
   "sets": [
     {
       "class": "Artist",
       "ids": ["1", "3"]
     },
     {
       "class": "Producer",
       "ids": ["5"],
       "fetch": [
         {
           "rel": "artists",
           "quantity": "2"
         }
       ]
     }
   ]
 }

This will fetch artists with primary keys 1 and 3, the producer with primary
key 5 and two of producer 5's artists where 'artists' is a has_many DBIx::Class
rel from Producer to Artist.

The top level attributes are as follows:

=head2 sets

Sets must be an array of hashes, as in the example given above. Each set
defines a set of objects to be included in the fixtures. For details on valid
set attributes see L</SET ATTRIBUTES> below.

=head2 rules

Rules place general conditions on classes. For example if whenever an artist
was dumped you also wanted all of their cds dumped too, then you could use a
rule to specify this. For example:

 {
   "sets": [
     {
       "class": "Artist",
       "ids": ["1", "3"]
     },
     {
       "class": "Producer",
       "ids": ["5"],
       "fetch": [
         {
           "rel": "artists",
           "quantity": "2"
         }
       ]
     }
   ],
   "rules": {
     "Artist": {
       "fetch": [ {
         "rel": "cds",
         "quantity": "all"
       } ]
     }
   }
 }

In this case all the cds of artists 1, 3 and all producer 5's artists will be
dumped as well. Note that 'cds' is a has_many DBIx::Class relation from Artist
to CD. This is eqivalent to:

 {
   "sets": [
    {
       "class": "Artist",
       "ids": ["1", "3"],
       "fetch": [ {
         "rel": "cds",
         "quantity": "all"
       } ]
     },
     {
       "class": "Producer",
       "ids": ["5"],
       "fetch": [ {
         "rel": "artists",
         "quantity": "2",
         "fetch": [ {
           "rel": "cds",
           "quantity": "all"
         } ]
       } ]
     }
   ]
 }

rules must be a hash keyed by class name.

L</RULE ATTRIBUTES>

=head2 includes

To prevent repetition between configs you can include other configs. For
example:

 {
   "sets": [ {
     "class": "Producer",
     "ids": ["5"]
   } ],
   "includes": [
     { "file": "base.json" }
   ]
 }

Includes must be an arrayref of hashrefs where the hashrefs have key 'file'
which is the name of another config file in the same directory. The original
config is merged with its includes using L<Hash::Merge>.

=head2 datetime_relative

Only available for MySQL and PostgreSQL at the moment, must be a value that
DateTime::Format::* can parse. For example:

 {
   "sets": [ {
     "class": "RecentItems",
     "ids": ["9"]
   } ],
   "datetime_relative": "2007-10-30 00:00:00"
 }

This will work when dumping from a MySQL database and will cause any datetime
fields (where datatype => 'datetime' in the column def of the schema class) to
be dumped as a DateTime::Duration object relative to the date specified in the
datetime_relative value. For example if the RecentItem object had a date field
set to 2007-10-25, then when the fixture is imported the field will be set to 5
days in the past relative to the current time.

=head2 might_have

Specifies whether to automatically dump might_have relationships. Should be a
hash with one attribute - fetch. Set fetch to 1 or 0.

 {
   "might_have": { "fetch": 1 },
   "sets": [
     {
       "class": "Artist",
       "ids": ["1", "3"]
     },
     {
       "class": "Producer",
       "ids": ["5"]
     }
   ]
 }

Note: belongs_to rels are automatically dumped whether you like it or not, this
is to avoid FKs to nowhere when importing.  General rules on has_many rels are
not accepted at this top level, but you can turn them on for individual sets -
see L</SET ATTRIBUTES>.

=head1 SET ATTRIBUTES

=head2 class

Required attribute. Specifies the DBIx::Class object class you wish to dump.

=head2 ids

Array of primary key ids to fetch, basically causing an $rs->find($_) for each.
If the id is not in the source db then it just won't get dumped, no warnings or
death.

=head2 quantity

Must be either an integer or the string 'all'. Specifying an integer will
effectively set the 'rows' attribute on the resultset clause, specifying 'all'
will cause the rows attribute to be left off and for all matching rows to be
dumped. There's no randomising here, it's just the first x rows.

=head2 cond

A hash specifying the conditions dumped objects must match. Essentially this is
a JSON representation of a DBIx::Class search clause. For example:

 {
   "sets": [{
     "class": "Artist",
     "quantiy": "all",
     "cond": { "name": "Dave" }
   }]
 }

This will dump all artists whose name is 'dave'. Essentially
$artist_rs->search({ name => 'Dave' })->all.

Sometimes in a search clause it's useful to use scalar refs to do things like:

 $artist_rs->search({ no1_singles => \'> no1_albums' })

This could be specified in the cond hash like so:

 {
   "sets": [ {
     "class": "Artist",
     "quantiy": "all",
     "cond": { "no1_singles": "\> no1_albums" }
   } ]
 }

So if the value starts with a backslash the value is made a scalar ref before
being passed to search.

=head2 join

An array of relationships to be used in the cond clause.

 {
   "sets": [ {
     "class": "Artist",
     "quantiy": "all",
     "cond": { "cds.position": { ">": 4 } },
     "join": ["cds"]
   } ]
 }

Fetch all artists who have cds with position greater than 4.

=head2 fetch

Must be an array of hashes. Specifies which rels to also dump. For example:

 {
   "sets": [ {
     "class": "Artist",
     "ids": ["1", "3"],
     "fetch": [ {
       "rel": "cds",
       "quantity": "3",
       "cond": { "position": "2" }
     } ]
   } ]
 }

Will cause the cds of artists 1 and 3 to be dumped where the cd position is 2.

Valid attributes are: 'rel', 'quantity', 'cond', 'has_many', 'might_have' and
'join'. rel is the name of the DBIx::Class rel to follow, the rest are the same
as in the set attributes. quantity is necessary for has_many relationships, but
not if using for belongs_to or might_have relationships.

=head2 has_many

Specifies whether to fetch has_many rels for this set. Must be a hash
containing keys fetch and quantity.

Set fetch to 1 if you want to fetch them, and quantity to either 'all' or an
integer.

Be careful here, dumping has_many rels can lead to a lot of data being dumped.

=head2 might_have

As with has_many but for might_have relationships. Quantity doesn't do anything
in this case.

This value will be inherited by all fetches in this set. This is not true for
the has_many attribute.

=head2 external

In some cases your database information might be keys to values in some sort of
external storage.  The classic example is you are using L<DBIx::Class::InflateColumn::FS>
to store blob information on the filesystem.  In this case you may wish the ability
to backup your external storage in the same way your database data.  The L</external>
attribute lets you specify a handler for this type of issue.  For example:

    {
        "sets": [{
            "class": "Photo",
            "quantity": "all",
            "external": {
                "file": {
                    "class": "File",
                    "args": {"path":"__ATTR(photo_dir)__"}
                }
            }
        }]
    }

This would use L<DBIx::Class::Fixtures::External::File> to read from a directory
where the path to a file is specified by the C<file> field of the C<Photo> source.
We use the uninflated value of the field so you need to completely handle backup
and restore.  For the common case we provide  L<DBIx::Class::Fixtures::External::File>
and you can create your own custom handlers by placing a '+' in the namespace:

    "class": "+MyApp::Schema::SomeExternalStorage",

Although if possible I'd love to get patches to add some of the other common
types (I imagine storage in MogileFS, Redis, etc or even Amazon might be popular.)

See L<DBIx::Class::Fixtures::External::File> for the external handler interface.

=head1 RULE ATTRIBUTES

=head2 cond

Same as with L</SET ATTRIBUTES>

=head2 fetch

Same as with L</SET ATTRIBUTES>

=head2 join

Same as with L</SET ATTRIBUTES>

=head2 has_many

Same as with L</SET ATTRIBUTES>

=head2 might_have

Same as with L</SET ATTRIBUTES>

=head1 RULE SUBSTITUTIONS

You can provide the following substitution patterns for your rule values. An
example of this might be:

    {
        "sets": [{
            "class": "Photo",
            "quantity": "__ENV(NUMBER_PHOTOS_DUMPED)__",
        }]
    }

=head2 ENV

Provide a value from %ENV

=head2 ATTR

Provide a value from L</config_attrs>

=head2 catfile

Create the path to a file from a list

=head2 catdir

Create the path to a directory from a list

=head1 METHODS

=head2 new

=over 4

=item Arguments: \%$attrs

=item Return Value: $fixture_object

=back

Returns a new DBIx::Class::Fixture object. %attrs can have the following
parameters:

=over

=item config_dir:

required. must contain a valid path to the directory in which your .json
configs reside.

=item debug:

determines whether to be verbose

=item ignore_sql_errors:

ignore errors on import of DDL etc

=item config_attrs

A hash of information you can use to do replacements inside your configuration
sets.  For example, if your set looks like:

   {
     "sets": [ {
       "class": "Artist",
       "ids": ["1", "3"],
       "fetch": [ {
         "rel": "cds",
         "quantity": "__ATTR(quantity)__",
       } ]
     } ]
   }

    my $fixtures = DBIx::Class::Fixtures->new( {
      config_dir => '/home/me/app/fixture_configs'
      config_attrs => {
        quantity => 100,
      },
    });

You may wish to do this if you want to let whoever runs the dumps have a bit
more control

=back

 my $fixtures = DBIx::Class::Fixtures->new( {
   config_dir => '/home/me/app/fixture_configs'
 } );

=cut

sub new {
  my $class = shift;

  my ($params) = @_;
  unless (ref $params eq 'HASH') {
    return DBIx::Class::Exception->throw('first arg to DBIx::Class::Fixtures->new() must be hash ref');
  }

  unless ($params->{config_dir}) {
    return DBIx::Class::Exception->throw('config_dir param not specified');
  }

  my $config_dir = io->dir($params->{config_dir});
  unless (-e $params->{config_dir}) {
    return DBIx::Class::Exception->throw('config_dir directory doesn\'t exist');
  }

  my $self = {
              config_dir            => $config_dir,
              _inherited_attributes => [qw/datetime_relative might_have rules belongs_to/],
              debug                 => $params->{debug} || 0,
              ignore_sql_errors     => $params->{ignore_sql_errors},
              dumped_objects        => {},
              use_create            => $params->{use_create} || 0,
              use_find_or_create    => $params->{use_find_or_create} || 0,
              config_attrs          => $params->{config_attrs} || {},
  };

  bless $self, $class;

  return $self;
}

=head2 available_config_sets

Returns a list of all the config sets found in the L</config_dir>.  These will
be a list of the json based files containing dump rules.

=cut

my @config_sets;
sub available_config_sets {
  @config_sets = scalar(@config_sets) ? @config_sets : map {
    $_->filename;
  } grep {
    -f "$_" && $_=~/json$/;
  } shift->config_dir->all;
}

=head2 dump

=over 4

=item Arguments: \%$attrs

=item Return Value: 1

=back

 $fixtures->dump({
   config => 'set_config.json', # config file to use. must be in the config
                                # directory specified in the constructor
   schema => $source_dbic_schema,
   directory => '/home/me/app/fixtures' # output directory
 });

or

 $fixtures->dump({
   all => 1, # just dump everything that's in the schema
   schema => $source_dbic_schema,
   directory => '/home/me/app/fixtures', # output directory
   #excludes => [ qw/Foo MyView/ ], # optionally exclude certain sources
 });

In this case objects will be dumped to subdirectories in the specified
directory. For example:

 /home/me/app/fixtures/artist/1.fix
 /home/me/app/fixtures/artist/3.fix
 /home/me/app/fixtures/producer/5.fix

C<schema> and C<directory> are required attributes. also, one of C<config> or C<all> must
be specified.

The optional parameter C<excludes> takes an array ref of source names and can be
used to exclude those sources when dumping the whole schema. This is useful if
you have views in there, since those do not need fixtures and will currently result
in an error when they are created and then used with C<populate>.

Lastly, the C<config> parameter can be a Perl HashRef instead of a file name.
If this form is used your HashRef should conform to the structure rules defined
for the JSON representations.

=cut

sub dump {
  my $self = shift;

  my ($params) = @_;
  unless (ref $params eq 'HASH') {
    return DBIx::Class::Exception->throw('first arg to dump must be hash ref');
  }

  foreach my $param (qw/schema directory/) {
    unless ($params->{$param}) {
      return DBIx::Class::Exception->throw($param . ' param not specified');
    }
  }

  if($params->{excludes} && !$params->{all}) {
    return DBIx::Class::Exception->throw("'excludes' param only works when using the 'all' param");
  }

  my $schema = $params->{schema};
  my $config;
  if ($params->{config}) {
    $config = ref $params->{config} eq 'HASH' ?
      $params->{config} :
      do {
        #read config
        my $config_file = io->catfile($self->config_dir, $params->{config});
        $self->load_config_file("$config_file");
      };
  } elsif ($params->{all}) {
    my %excludes = map {$_=>1} @{$params->{excludes}||[]};
    $config = {
      might_have => { fetch => 0 },
      has_many => { fetch => 0 },
      belongs_to => { fetch => 0 },
      sets => [
        map {
          { class => $_, quantity => 'all' };
        } grep {
          !$excludes{$_}
        } $schema->sources],
    };
  } else {
    DBIx::Class::Exception->throw('must pass config or set all');
  }

  my $output_dir = io->dir($params->{directory});
  unless (-e "$output_dir") {
    $output_dir->mkpath ||
    DBIx::Class::Exception->throw("output directory does not exist at $output_dir");
  }

  $self->msg("generating  fixtures");
  my $tmp_output_dir = io->dir(tempdir);

  if (-e "$tmp_output_dir") {
    $self->msg("- clearing existing $tmp_output_dir");
    $tmp_output_dir->rmtree;
  }
  $self->msg("- creating $tmp_output_dir");
  $tmp_output_dir->mkpath;

  # write version file (for the potential benefit of populate)
  $tmp_output_dir->file('_dumper_version')->print($VERSION);

  # write our current config set
  $tmp_output_dir->file('_config_set')->print( Dumper $config );

  $config->{rules} ||= {};
  my @sources = @{delete $config->{sets}};

  while ( my ($k,$v) = each %{ $config->{rules} } ) {
    if ( my $source = eval { $schema->source($k) } ) {
      $config->{rules}{$source->source_name} = $v;
    }
  }

  foreach my $source (@sources) {
    # apply rule to set if specified
    my $rule = $config->{rules}->{$source->{class}};
    $source = merge( $source, $rule ) if ($rule);

    # fetch objects
    my $rs = $schema->resultset($source->{class});

    if ($source->{cond} and ref $source->{cond} eq 'HASH') {
      # if value starts with \ assume it's meant to be passed as a scalar ref
      # to dbic. ideally this would substitute deeply
      $source->{cond} = {
        map {
          $_ => ($source->{cond}->{$_} =~ s/^\\//) ? \$source->{cond}->{$_}
                                                   : $source->{cond}->{$_}
        } keys %{$source->{cond}}
      };
    }

    $rs = $rs->search($source->{cond}, { join => $source->{join} })
      if $source->{cond};

    $self->msg("- dumping $source->{class}");

    my %source_options = ( set => { %{$config}, %{$source} } );
    if ($source->{quantity}) {
      $rs = $rs->search({}, { order_by => $source->{order_by} })
        if $source->{order_by};

      if ($source->{quantity} =~ /^\d+$/) {
        $rs = $rs->search({}, { rows => $source->{quantity} });
      } elsif ($source->{quantity} ne 'all') {
        DBIx::Class::Exception->throw("invalid value for quantity - $source->{quantity}");
      }
    }
    elsif ($source->{ids} && @{$source->{ids}}) {
      my @ids = @{$source->{ids}};
      my (@pks) = $rs->result_source->primary_columns;
      die "Can't dump multiple col-pks using 'id' option" if @pks > 1;
      $rs = $rs->search_rs( { $pks[0] => { -in => \@ids } } );
    }
    else {
      DBIx::Class::Exception->throw('must specify either quantity or ids');
    }

    $source_options{set_dir} = $tmp_output_dir;
    $self->dump_rs($rs, \%source_options );
  }

  # clear existing output dir
  foreach my $child ($output_dir->all) {
    if ($child->is_dir) {
      next if ("$child" eq "$tmp_output_dir");
      if (grep { $_ =~ /\.fix/ } $child->all) {
        $child->rmtree;
      }
    } elsif ($child =~ /_dumper_version$/) {
      $child->unlink;
    }
  }

  $self->msg("- moving temp dir to $output_dir");
  $tmp_output_dir->copy("$output_dir");

  if (-e "$output_dir") {
    $self->msg("- clearing tmp dir $tmp_output_dir");
    # delete existing fixture set
    $tmp_output_dir->rmtree;
  }

  $self->msg("done");

  return 1;
}

sub load_config_file {
  my ($self, $config_file) = @_;
  DBIx::Class::Exception->throw("config does not exist at $config_file")
    unless -e "$config_file";

  my $config = Config::Any::JSON->load($config_file);

  #process includes
  if (my $incs = $config->{includes}) {
    $self->msg($incs);
    DBIx::Class::Exception->throw(
      'includes params of config must be an array ref of hashrefs'
    ) unless ref $incs eq 'ARRAY';

    foreach my $include_config (@$incs) {
      DBIx::Class::Exception->throw(
        'includes params of config must be an array ref of hashrefs'
      ) unless (ref $include_config eq 'HASH') && $include_config->{file};

      my $include_file = $self->config_dir->file($include_config->{file});

      DBIx::Class::Exception->throw("config does not exist at $include_file")
        unless -e "$include_file";

      my $include = Config::Any::JSON->load($include_file);
      $self->msg($include);
      $config = merge( $config, $include );
    }
    delete $config->{includes};
  }

  # validate config
  return DBIx::Class::Exception->throw('config has no sets')
    unless $config && $config->{sets} &&
           ref $config->{sets} eq 'ARRAY' && scalar @{$config->{sets}};

  $config->{might_have} = { fetch => 0 } unless exists $config->{might_have};
  $config->{has_many} = { fetch => 0 }   unless exists $config->{has_many};
  $config->{belongs_to} = { fetch => 1 } unless exists $config->{belongs_to};

  return $config;
}

sub dump_rs {
    my ($self, $rs, $params) = @_;

    while (my $row = $rs->next) {
        $self->dump_object($row, $params);
    }
}

sub dump_object {
  my ($self, $object, $params) = @_;
  my $set = $params->{set};

  my $v = Data::Visitor::Callback->new(
    plain_value => sub {
      my ($visitor, $data) = @_;
      my $subs = {
       ENV => sub {
          my ( $self, $v ) = @_;
          if (! defined($ENV{$v})) {
            return "";
          } else {
            return $ENV{ $v };
          }
        },
        ATTR => sub {
          my ($self, $v) = @_;
          if(my $attr = $self->config_attrs->{$v}) {
            return $attr;
          } else {
            return "";
          }
        },
        catfile => sub {
          my ($self, @args) = @_;
          "".io->catfile(@args);
        },
        catdir => sub {
          my ($self, @args) = @_;
          "".io->catdir(@args);
        },
      };

      my $subsre = join( '|', keys %$subs );
      $_ =~ s{__($subsre)(?:\((.+?)\))?__}{ $subs->{ $1 }->( $self, $2 ? split( /,/, $2 ) : () ) }eg;

      return $_;
    }
  );

  $v->visit( $set );

  die 'no dir passed to dump_object' unless $params->{set_dir};
  die 'no object passed to dump_object' unless $object;

  my @inherited_attrs = @{$self->_inherited_attributes};

  my @pk_vals = map {
    $object->get_column($_)
  } $object->primary_columns;

  my $key = join("\0", @pk_vals);

  my $src = $object->result_source;
  my $exists = $self->dumped_objects->{$src->name}{$key}++;


  # write dir and gen filename
  my $source_dir = io->catdir($params->{set_dir}, $self->_name_for_source($src));
  $source_dir->mkpath(0, 0777);

  # Convert characters not allowed on windows
  my $file = io->catfile("$source_dir",
      join('-', map { s|[/\\:\*\|\?"<>]|_|g; $_; } @pk_vals) . '.fix'
  );

  # write file
  unless ($exists) {
    $self->msg('-- dumping ' . "$file", 2);

    # get_columns will return virtual columns; we just want stored columns.
    # columns_info keys seems to be the actual storage column names, so we'll
    # use that.
    my $col_info = $src->columns_info;
    my @column_names = keys %$col_info;
    my %columns = $object->get_columns;
    my %ds; @ds{@column_names} = @columns{@column_names};

    if($set->{external}) {
      foreach my $field (keys %{$set->{external}}) {
        my $key = $ds{$field};
        my ($plus, $class) = ( $set->{external}->{$field}->{class}=~/^(\+)*(.+)$/);
        my $args = $set->{external}->{$field}->{args};

        $class = "DBIx::Class::Fixtures::External::$class" unless $plus;
        eval "use $class";

        $ds{external}->{$field} =
          encode_base64( $class
           ->backup($key => $args),'');
      }
    }

    # mess with dates if specified
    if ($set->{datetime_relative}) {
      my $formatter= eval {$object->result_source->schema->storage->datetime_parser};
      unless (!$formatter) {
        my $dt;
        if ($set->{datetime_relative} eq 'today') {
          $dt = DateTime->today;
        } else {
          $dt = $formatter->parse_datetime($set->{datetime_relative}) unless ($@);
        }

        while (my ($col, $value) = each %ds) {
          my $col_info = $object->result_source->column_info($col);

          next unless $value
            && $col_info->{_inflate_info}
              && (
                  (uc($col_info->{data_type}) eq 'DATETIME')
                    or (uc($col_info->{data_type}) eq 'DATE')
                    or (uc($col_info->{data_type}) eq 'TIME')
                    or (uc($col_info->{data_type}) eq 'TIMESTAMP')
                    or (uc($col_info->{data_type}) eq 'INTERVAL')
                 );

          $ds{$col} = $object->get_inflated_column($col)->subtract_datetime($dt);
        }
      } else {
        warn "datetime_relative not supported for this db driver at the moment";
      }
    }

    # do the actual dumping
    my $serialized = Dump(\%ds)->Out();

    $file->print($serialized);
  }

  # don't bother looking at rels unless we are actually planning to dump at least one type
  my ($might_have, $belongs_to, $has_many) = map {
    $set->{$_}{fetch} || $set->{rules}{$src->source_name}{$_}{fetch}
  } qw/might_have belongs_to has_many/;

  return unless $might_have
             || $belongs_to
             || $has_many
             || $set->{fetch};

  # dump rels of object
  unless ($exists) {
    foreach my $name (sort $src->relationships) {
      my $info = $src->relationship_info($name);
      my $r_source = $src->related_source($name);
      # if belongs_to or might_have with might_have param set or has_many with
      # has_many param set then
      if (
            ( $info->{attrs}{accessor} eq 'single' &&
              (!$info->{attrs}{join_type} || $might_have)
            )
         || $info->{attrs}{accessor} eq 'filter'
         ||
            ($info->{attrs}{accessor} eq 'multi' && $has_many)
      ) {
        my $related_rs = $object->related_resultset($name);
        my $rule = $set->{rules}->{$related_rs->result_source->source_name};
        # these parts of the rule only apply to has_many rels
        if ($rule && $info->{attrs}{accessor} eq 'multi') {
          $related_rs = $related_rs->search(
            $rule->{cond},
            { join => $rule->{join} }
          ) if ($rule->{cond});

          $related_rs = $related_rs->search(
            {},
            { rows => $rule->{quantity} }
          ) if ($rule->{quantity} && $rule->{quantity} ne 'all');

          $related_rs = $related_rs->search(
            {},
            { order_by => $rule->{order_by} }
          ) if ($rule->{order_by});

        }
        if ($set->{has_many}{quantity} &&
            $set->{has_many}{quantity} =~ /^\d+$/) {
          $related_rs = $related_rs->search(
            {},
            { rows => $set->{has_many}->{quantity} }
          );
        }

        my %c_params = %{$params};
        # inherit date param
        my %mock_set = map {
          $_ => $set->{$_}
        } grep { $set->{$_} } @inherited_attrs;

        $c_params{set} = \%mock_set;
        $c_params{set} = merge( $c_params{set}, $rule)
          if $rule && $rule->{fetch};

        $self->dump_rs($related_rs, \%c_params);
      }
    }
  }

  return unless $set && $set->{fetch};
  foreach my $fetch (@{$set->{fetch}}) {
    # inherit date param
    $fetch->{$_} = $set->{$_} foreach
      grep { !$fetch->{$_} && $set->{$_} } @inherited_attrs;
    my $related_rs = $object->related_resultset($fetch->{rel});
    my $rule = $set->{rules}->{$related_rs->result_source->source_name};

    if ($rule) {
      my $info = $object->result_source->relationship_info($fetch->{rel});
      if ($info->{attrs}{accessor} eq 'multi') {
        $fetch = merge( $fetch, $rule );
      } elsif ($rule->{fetch}) {
        $fetch = merge( $fetch, { fetch => $rule->{fetch} } );
      }
    }

    die "relationship $fetch->{rel} does not exist for " . $src->source_name
      unless ($related_rs);

    if ($fetch->{cond} and ref $fetch->{cond} eq 'HASH') {
      # if value starts with \ assume it's meant to be passed as a scalar ref
      # to dbic.  ideally this would substitute deeply
      $fetch->{cond} = { map {
          $_ => ($fetch->{cond}->{$_} =~ s/^\\//) ? \$fetch->{cond}->{$_}
                                                  : $fetch->{cond}->{$_}
      } keys %{$fetch->{cond}} };
    }

    $related_rs = $related_rs->search(
      $fetch->{cond},
      { join => $fetch->{join} }
    ) if $fetch->{cond};

    $related_rs = $related_rs->search(
      {},
      { rows => $fetch->{quantity} }
    ) if $fetch->{quantity} && $fetch->{quantity} ne 'all';
    $related_rs = $related_rs->search(
      {},
      { order_by => $fetch->{order_by} }
    ) if $fetch->{order_by};

    $self->dump_rs($related_rs, { %{$params}, set => $fetch });
  }
}

sub _generate_schema {
  my $self = shift;
  my $params = shift || {};
  require DBI;
  $self->msg("\ncreating schema");

  my $schema_class = $self->schema_class || "DBIx::Class::Fixtures::Schema";
  eval "require $schema_class";
  die $@ if $@;

  my $pre_schema;
  my $connection_details = $params->{connection_details};

  $namespace_counter++;

  my $namespace = "DBIx::Class::Fixtures::GeneratedSchema_$namespace_counter";
  Class::C3::Componentised->inject_base( $namespace => $schema_class );

  $pre_schema = $namespace->connect(@{$connection_details});
  unless( $pre_schema ) {
    return DBIx::Class::Exception->throw('connection details not valid');
  }
  my @tables = map { $self->_name_for_source($pre_schema->source($_)) } $pre_schema->sources;
  $self->msg("Tables to drop: [". join(', ', sort @tables) . "]");
  my $dbh = $pre_schema->storage->dbh;

  # clear existing db
  $self->msg("- clearing DB of existing tables");
  $pre_schema->storage->txn_do(sub {
    $pre_schema->storage->with_deferred_fk_checks(sub {
      foreach my $table (@tables) {
        eval {
          $dbh->do("drop table $table" . ($params->{cascade} ? ' cascade' : '') )
        };
      }
    });
  });

  # import new ddl file to db
  my $ddl_file = $params->{ddl};
  $self->msg("- deploying schema using $ddl_file");
  my $data = _read_sql($ddl_file);
  foreach (@$data) {
    eval { $dbh->do($_) or warn "SQL was:\n $_"};
	  if ($@ && !$self->{ignore_sql_errors}) { die "SQL was:\n $_\n$@"; }
  }
  $self->msg("- finished importing DDL into DB");

  # load schema object from our new DB
  $namespace_counter++;
  my $namespace2 = "DBIx::Class::Fixtures::GeneratedSchema_$namespace_counter";
  Class::C3::Componentised->inject_base( $namespace2 => $schema_class );
  my $schema = $namespace2->connect(@{$connection_details});
  return $schema;
}

sub _read_sql {
  my $ddl_file = shift;
  my $fh;
  open $fh, "<$ddl_file" or die ("Can't open DDL file, $ddl_file ($!)");
  my @data = split(/\n/, join('', <$fh>));
  @data = grep(!/^--/, @data);
  @data = split(/;/, join('', @data));
  close($fh);
  @data = grep { $_ && $_ !~ /^-- / } @data;
  return \@data;
}

=head2 dump_config_sets

Works just like L</dump> but instead of specifying a single json config set
located in L</config_dir> we dump each set named in the C<configs> parameter.

The parameters are the same as for L</dump> except instead of a C<directory>
parameter we have a C<directory_template> which is a coderef expected to return
a scalar that is a root directory where we will do the actual dumping.  This
coderef get three arguments: C<$self>, C<$params> and C<$set_name>.  For
example:

    $fixture->dump_all_config_sets({
      schema => $schema,
      configs => [qw/one.json other.json/],
      directory_template => sub {
        my ($fixture, $params, $set) = @_;
        return io->catdir('var', 'fixtures', $params->{schema}->version, $set);
      },
    });

=cut

sub dump_config_sets {
  my ($self, $params) = @_;
  my $available_config_sets = delete $params->{configs};
  my $directory_template = delete $params->{directory_template} ||
    DBIx::Class::Exception->throw("'directory_template is required parameter");

  for my $set (@$available_config_sets) {
    my $localparams = $params;
    $localparams->{directory} = $directory_template->($self, $localparams, $set);
    $localparams->{config} = $set;
    $self->dump($localparams);
    $self->dumped_objects({}); ## Clear dumped for next go, if there is one!
  }
}

=head2 dump_all_config_sets

    my %local_params = %$params;
    my $local_self = bless { %$self }, ref($self);
    $local_params{directory} = $directory_template->($self, \%local_params, $set);
    $local_params{config} = $set;
    $self->dump(\%local_params);


Works just like L</dump> but instead of specifying a single json config set
located in L</config_dir> we dump each set in turn to the specified directory.

The parameters are the same as for L</dump> except instead of a C<directory>
parameter we have a C<directory_template> which is a coderef expected to return
a scalar that is a root directory where we will do the actual dumping.  This
coderef get three arguments: C<$self>, C<$params> and C<$set_name>.  For
example:

    $fixture->dump_all_config_sets({
      schema => $schema,
      directory_template => sub {
        my ($fixture, $params, $set) = @_;
        return io->catdir('var', 'fixtures', $params->{schema}->version, $set);
      },
    });

=cut

sub dump_all_config_sets {
  my ($self, $params) = @_;
  $self->dump_config_sets({
    %$params,
    configs=>[$self->available_config_sets],
  });
}

=head2 populate

=over 4

=item Arguments: \%$attrs

=item Return Value: 1

=back

 $fixtures->populate( {
   # directory to look for fixtures in, as specified to dump
   directory => '/home/me/app/fixtures',

   # DDL to deploy
   ddl => '/home/me/app/sql/ddl.sql',

   # database to clear, deploy and then populate
   connection_details => ['dbi:mysql:dbname=app_dev', 'me', 'password'],

   # DDL to deploy after populating records, ie. FK constraints
   post_ddl => '/home/me/app/sql/post_ddl.sql',

   # use CASCADE option when dropping tables
   cascade => 1,

   # optional, set to 1 to run ddl but not populate
   no_populate => 0,

   # optional, set to 1 to run each fixture through ->create rather than have
   # each $rs populated using $rs->populate. Useful if you have overridden new() logic
   # that effects the value of column(s).
   use_create => 0,

   # optional, same as use_create except with find_or_create.
   # Useful if you are populating a persistent data store.
   use_find_or_create => 0,

   # Dont try to clean the database, just populate over whats there. Requires
   # schema option. Use this if you want to handle removing old data yourself
   # no_deploy => 1
   # schema => $schema
 } );

In this case the database app_dev will be cleared of all tables, then the
specified DDL deployed to it, then finally all fixtures found in
/home/me/app/fixtures will be added to it. populate will generate its own
DBIx::Class schema from the DDL rather than being passed one to use. This is
better as custom insert methods are avoided which can to get in the way. In
some cases you might not have a DDL, and so this method will eventually allow a
$schema object to be passed instead.

If needed, you can specify a post_ddl attribute which is a DDL to be applied
after all the fixtures have been added to the database. A good use of this
option would be to add foreign key constraints since databases like Postgresql
cannot disable foreign key checks.

If your tables have foreign key constraints you may want to use the cascade
attribute which will make the drop table functionality cascade, ie 'DROP TABLE
$table CASCADE'.

C<directory> is a required attribute.

If you wish for DBIx::Class::Fixtures to clear the database for you pass in
C<dll> (path to a DDL sql file) and C<connection_details> (array ref  of DSN,
user and pass).

If you wish to deal with cleaning the schema yourself, then pass in a C<schema>
attribute containing the connected schema you wish to operate on and set the
C<no_deploy> attribute.

=cut

sub populate {
  my $self = shift;
  my ($params) = @_;
  DBIx::Class::Exception->throw('first arg to populate must be hash ref')
    unless ref $params eq 'HASH';

  DBIx::Class::Exception->throw('directory param not specified')
    unless $params->{directory};

  my $fixture_dir = io->dir(delete $params->{directory});
  DBIx::Class::Exception->throw("fixture directory '$fixture_dir' does not exist")
    unless -d "$fixture_dir";

  my $ddl_file;
  my $dbh;
  my $schema;
  if ($params->{ddl} && $params->{connection_details}) {
    $ddl_file = io->file(delete $params->{ddl});
    unless (-e "$ddl_file") {
      return DBIx::Class::Exception->throw('DDL does not exist at ' . $ddl_file);
    }
    unless (ref $params->{connection_details} eq 'ARRAY') {
      return DBIx::Class::Exception->throw('connection details must be an arrayref');
    }
    $schema = $self->_generate_schema({
      ddl => "$ddl_file",
      connection_details => delete $params->{connection_details},
      %{$params}
    });
  } elsif ($params->{schema} && $params->{no_deploy}) {
    $schema = $params->{schema};
  } else {
    DBIx::Class::Exception->throw('you must set the ddl and connection_details params');
  }


  return 1 if $params->{no_populate};

  $self->msg("\nimporting fixtures");
  my $tmp_fixture_dir = io->dir(tempdir());
  my $config_set_path = io->file($fixture_dir, '_config_set');
  my $config_set = -e "$config_set_path" ? do { my $VAR1; eval($config_set_path->slurp); $VAR1 } : '';

  my $v = Data::Visitor::Callback->new(
    plain_value => sub {
      my ($visitor, $data) = @_;
      my $subs = {
       ENV => sub {
          my ( $self, $v ) = @_;
          if (! defined($ENV{$v})) {
            return "";
          } else {
            return $ENV{ $v };
          }
        },
        ATTR => sub {
          my ($self, $v) = @_;
          if(my $attr = $self->config_attrs->{$v}) {
            return $attr;
          } else {
            return "";
          }
        },
        catfile => sub {
          my ($self, @args) = @_;
          io->catfile(@args);
        },
        catdir => sub {
          my ($self, @args) = @_;
          io->catdir(@args);
        },
      };

      my $subsre = join( '|', keys %$subs );
      $_ =~ s{__($subsre)(?:\((.+?)\))?__}{ $subs->{ $1 }->( $self, $2 ? split( /,/, $2 ) : () ) }eg;

      return $_;
    }
  );

  $v->visit( $config_set );


  my %sets_by_src;
  if($config_set) {
    %sets_by_src = map { delete($_->{class}) => $_ }
      @{$config_set->{sets}}
  }

  if (-e "$tmp_fixture_dir") {
    $self->msg("- deleting existing temp directory $tmp_fixture_dir");
    $tmp_fixture_dir->rmtree;
  }
  $self->msg("- creating temp dir");
  $tmp_fixture_dir->mkpath();
  for ( map { $self->_name_for_source($schema->source($_)) } $schema->sources) {
    my $from_dir = io->catdir($fixture_dir, $_);
    next unless -e "$from_dir";
    $from_dir->copy( io->catdir($tmp_fixture_dir, $_)."" );
  }

  unless (-d "$tmp_fixture_dir") {
    DBIx::Class::Exception->throw("Unable to create temporary fixtures dir: $tmp_fixture_dir: $!");
  }

  my $fixup_visitor;
  my $formatter = $schema->storage->datetime_parser;
  unless ($@ || !$formatter) {
    my %callbacks;
    if ($params->{datetime_relative_to}) {
      $callbacks{'DateTime::Duration'} = sub {
        $params->{datetime_relative_to}->clone->add_duration($_);
      };
    } else {
      $callbacks{'DateTime::Duration'} = sub {
        $formatter->format_datetime(DateTime->today->add_duration($_))
      };
    }
    $callbacks{object} ||= "visit_ref";
    $fixup_visitor = new Data::Visitor::Callback(%callbacks);
  }

  my @sorted_source_names = $self->_get_sorted_sources( $schema );
  $schema->storage->txn_do(sub {
    $schema->storage->with_deferred_fk_checks(sub {
      foreach my $source (@sorted_source_names) {
        $self->msg("- adding " . $source);
        my $rs = $schema->resultset($source);
        my $source_dir = io->catdir($tmp_fixture_dir, $self->_name_for_source($rs->result_source));
        next unless (-e "$source_dir");
        my @rows;
        while (my $file = $source_dir->next) {
          next unless ($file =~ /\.fix$/);
          next if $file->is_dir;
          my $contents = $file->slurp;
          my $HASH1;
          eval($contents);
          $HASH1 = $fixup_visitor->visit($HASH1) if $fixup_visitor;
          if(my $external = delete $HASH1->{external}) {
            my @fields = keys %{$sets_by_src{$source}->{external}};
            foreach my $field(@fields) {
              my $key = $HASH1->{$field};
              my $content = decode_base64 ($external->{$field});
              my $args = $sets_by_src{$source}->{external}->{$field}->{args};
              my ($plus, $class) = ( $sets_by_src{$source}->{external}->{$field}->{class}=~/^(\+)*(.+)$/);
              $class = "DBIx::Class::Fixtures::External::$class" unless $plus;
              eval "use $class";
              $class->restore($key, $content, $args);
            }
          }
          if ( $params->{use_create} ) {
            $rs->create( $HASH1 );
          } elsif( $params->{use_find_or_create} ) {
            $rs->find_or_create( $HASH1 );
          } else {
            push(@rows, $HASH1);
          }
        }
        $rs->populate(\@rows) if scalar(@rows);

        ## Now we need to do some db specific cleanup
        ## this probably belongs in a more isolated space.  Right now this is
        ## to just handle postgresql SERIAL types that use Sequences
        ## Will completely ignore sequences in Oracle due to having to drop
        ## and recreate them

        my $table = $rs->result_source->name;
        for my $column(my @columns =  $rs->result_source->columns) {
          my $info = $rs->result_source->column_info($column);
          if(my $sequence = $info->{sequence}) {
             $self->msg("- updating sequence $sequence");
            $rs->result_source->storage->dbh_do(sub {
              my ($storage, $dbh, @cols) = @_;
              if ( $dbh->{Driver}->{Name} eq "Oracle" ) {
                $self->msg("- Cannot change sequence values in Oracle");
              } else {
                $self->msg(
         my $sql = sprintf("SELECT setval(?, (SELECT max(%s) FROM %s));",$dbh->quote_identifier($column),$dbh->quote_identifier($table))
             );
                my $sth = $dbh->prepare($sql);
                   $sth->bind_param(1,$sequence);

                my $rv = $sth->execute or die $sth->errstr;
                $self->msg("- $sql");
              }
            });
          }
        }

      }
    });
  });
  $self->do_post_ddl( {
    schema=>$schema,
    post_ddl=>$params->{post_ddl}
  } ) if $params->{post_ddl};

  $self->msg("- fixtures imported");
  $self->msg("- cleaning up");
  $tmp_fixture_dir->rmtree;
  return 1;
}

# the overall logic is modified from SQL::Translator::Parser::DBIx::Class->parse
sub _get_sorted_sources {
  my ( $self, $dbicschema ) = @_;


  my %table_monikers = map { $_ => 1 } $dbicschema->sources;

  my %tables;
  foreach my $moniker (sort keys %table_monikers) {
    my $source = $dbicschema->source($moniker);

    my $table_name = $source->name;
    my @primary = $source->primary_columns;
    my @rels = $source->relationships();

    my %created_FK_rels;
    foreach my $rel (sort @rels) {
      my $rel_info = $source->relationship_info($rel);

      # Ignore any rel cond that isn't a straight hash
      next unless ref $rel_info->{cond} eq 'HASH';

      my @keys = map {$rel_info->{cond}->{$_} =~ /^\w+\.(\w+)$/} keys(%{$rel_info->{cond}});

      # determine if this relationship is a self.fk => foreign.pk (i.e. belongs_to)
      my $fk_constraint;
      if ( exists $rel_info->{attrs}{is_foreign_key_constraint} ) {
        $fk_constraint = $rel_info->{attrs}{is_foreign_key_constraint};
      } elsif ( $rel_info->{attrs}{accessor}
          && $rel_info->{attrs}{accessor} eq 'multi' ) {
        $fk_constraint = 0;
      } else {
        $fk_constraint = not $source->_compare_relationship_keys(\@keys, \@primary);
      }

      # Dont add a relation if its not constraining
      next unless $fk_constraint;

      my $rel_table = $source->related_source($rel)->source_name;
      # Make sure we don't create the same relation twice
      my $key_test = join("\x00", sort @keys);
      next if $created_FK_rels{$rel_table}->{$key_test};

      if (scalar(@keys)) {
        $created_FK_rels{$rel_table}->{$key_test} = 1;

        # calculate dependencies: do not consider deferrable constraints and
        # self-references for dependency calculations
        if (! $rel_info->{attrs}{is_deferrable} and $rel_table ne $table_name) {
          $tables{$moniker}{$rel_table}++;
        }
      }
    }
    $tables{$moniker} = {} unless exists $tables{$moniker};
  }

  # resolve entire dep tree
  my $dependencies = {
    map { $_ => _resolve_deps ($_, \%tables) } (keys %tables)
  };

  # return the sorted result
  return sort {
    keys %{$dependencies->{$a} || {} } <=> keys %{ $dependencies->{$b} || {} }
      ||
    $a cmp $b
  } (keys %tables);
}

sub _resolve_deps {
  my ( $question, $answers, $seen ) = @_;
  my $ret = {};
  $seen ||= {};

  my %seen = map { $_ => $seen->{$_} + 1 } ( keys %$seen );
  $seen{$question} = 1;

  for my $dep (keys %{ $answers->{$question} }) {
    return {} if $seen->{$dep};
    my $subdeps = _resolve_deps( $dep, $answers, \%seen );
    $ret->{$_} += $subdeps->{$_} for ( keys %$subdeps );
    ++$ret->{$dep};
  }
  return $ret;
}

sub do_post_ddl {
  my ($self, $params) = @_;

  my $schema = $params->{schema};
  my $data = _read_sql($params->{post_ddl});
  foreach (@$data) {
    eval { $schema->storage->dbh->do($_) or warn "SQL was:\n $_"};
	  if ($@ && !$self->{ignore_sql_errors}) { die "SQL was:\n $_\n$@"; }
  }
  $self->msg("- finished importing post-populate DDL into DB");
}

sub msg {
  my $self = shift;
  my $subject = shift || return;
  my $level = shift || 1;
  return unless $self->debug >= $level;
  if (ref $subject) {
	print Dumper($subject);
  } else {
	print $subject . "\n";
  }
}

# Helper method for ensuring that the name used for a given source
# is always the same (This is used to name the fixture directories
# for example)

sub _name_for_source {
    my ($self, $source) = @_;

    return ref $source->name ? $source->source_name : $source->name;
}

=head1 AUTHOR

  Luke Saunders <luke@shadowcatsystems.co.uk>

  Initial development sponsored by and (c) Takkle, Inc. 2007

=head1 CONTRIBUTORS

  Ash Berlin <ash@shadowcatsystems.co.uk>

  Matt S. Trout <mst@shadowcatsystems.co.uk>

  John Napiorkowski <jjnapiork@cpan.org>

  Drew Taylor <taylor.andrew.j@gmail.com>

  Frank Switalski <fswitalski@gmail.com>

  Chris Akins <chris.hexx@gmail.com>

  Tom Bloor <t.bloor@shadowcat.co.uk>

  Samuel Kaufman <skaufman@cpan.org>

=head1 LICENSE

  This library is free software under the same license as perl itself

=cut

1;
