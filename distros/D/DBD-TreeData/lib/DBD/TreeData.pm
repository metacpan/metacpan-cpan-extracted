##############################################################################
# DBD::TreeData Module                                                       #
# E-mail: Brendan Byrd <Perl@resonatorsoft.org>                              #
##############################################################################

##############################################################################
# DBD::TreeData

package DBD::TreeData;

use sanity;

use parent qw(DBD::AnyData);

# ABSTRACT: DBI driver for any abstract hash/array tree

our $VERSION = '0.90'; # VERSION
our $drh      = undef;         # holds driver handle once initialized
our $err      = 0;             # DBI::err
our $errstr   = "";            # DBI::errstr
our $sqlstate = "";            # DBI::state

our $methods_already_installed = 0;

sub driver {
   return $drh if $drh;      # already created - return same one
   my ($class, $attr) = @_;

   $drh = $class->DBI::DBD::SqlEngine::driver({  # DBD::AnyData doesn't pass over our $attr stuff, so let DBI::DBD::SqlEngine handle it
      'Name'        => 'TreeData',
      'Version'     => $VERSION,
      'Err'         => \$DBD::TreeData::err,
      'Errstr'      => \$DBD::TreeData::errstr,
      'State'       => \$DBD::TreeData::state,
      'Attribution' => 'DBD::TreeData by Brendan Byrd',
   }) || return undef;

   unless ( $methods_already_installed++ ) {
      DBD::TreeData::dr->install_method('tree_process_hash_tree');

      # because of the DBD::AnyData driver by-pass, we have to do its dirty work
      DBD::TreeData::db->install_method('ad_import');
      DBD::TreeData::db->install_method('ad_catalog');
      DBD::TreeData::db->install_method('ad_convert');
      DBD::TreeData::db->install_method('ad_export');
      DBD::TreeData::db->install_method('ad_clear');
      DBD::TreeData::db->install_method('ad_dump');
   }

   return $drh;
}

sub CLONE {
   undef $drh;
}

1;


##############################################################################
# DBD::TreeData::dr

package   # hide from PAUSE
   DBD::TreeData::dr; # ====== DRIVER ======

use sanity 0.94;
use DBI 1.619;  # first version with tree_ prefix
use DBD::AnyData 0.110;
use parent qw(-norequire DBD::AnyData::dr);  # no such file as ::dr.pm

use List::AllUtils qw(none any uniq firstidx indexes);
use Scalar::Util qw(reftype looks_like_number);
use Lingua::EN::Inflect::Phrase qw(to_PL to_S);
use Data::Dumper;

use subs qw(foundin notin col2word print_debug);

our @dbh;
our $debug = 0;
our $VERSION  = $DBD::TreeData::VERSION;
our $imp_data_size = 0;
our ($tables, $columns, $ids, $types, $can_null);

sub connect {
   my ($drh, $dr_dsn, $user, $auth, $attr) = @_;

   if ($dr_dsn =~ /\;|\=/) {  # is DSN notation
      foreach my $var (split /\;/, $dr_dsn) {
         my ($attr_name, $attr_value) = split(/\=/, $var, 2);
         return $drh->set_err($DBI::stderr, "Can't parse DSN part '$var'", '08001') unless (defined $attr_value);

         $attr_name = lc($attr_name);
         $attr_name = 'tree_'.$attr_name unless ($attr_name =~ /^tree_/o);
         $attr->{$attr_name} = $attr_value;
      }
   }
   else {
      $attr->{tree_table_name} ||= $dr_dsn;
   }
   $attr->{tree_table_name} ||= 'tree_data';
   $debug = $attr->{tree_debug} || $attr->{TraceLevel} || $drh->{TraceLevel};

   # Run through the tree conversion
   $attr->{tree_data} or return $drh->set_err($DBI::stderr, "Data! Data! Data!  I cannot make bricks without clay!", '08004');
   $drh->tree_process_hash_tree($attr->{tree_table_name}, $attr->{tree_data}, 0);

   # remove global data and keep the local tree in $tref
   my $tref = $tables;
   $attr->{tree_columns} = {
      names => { map { $_ => $tref->{$_}{columns} } keys %$tref },
      types => $types,
      nulls => $can_null,
   };
   $attr->{tree_cardinality}  = $ids->{table};

   ### TODO: Clean this up ###
   undef $tables;
   undef $columns;
   undef $ids;
   undef $types;
   undef $can_null;

   # Add into our $dbh object, using AnyData's methods
   my ($outer_dbh, $dbh) = DBI::_new_dbh($drh, {
      Name => $attr->{tree_table_name},
   }, $attr);
   $dbh->func( 0, "init_default_attributes" );  # make sure we get all of the right sql_* vars in place
   $dbh->func("init_done");
   $dbh->STORE('Active', 1);

   ### TODO: Need error checking for tree_rename_tables ###

   foreach my $table (keys %$tref) {
      my $table_name = exists $attr->{'tree_rename_tables'} ?
         ($attr->{'tree_rename_tables'}{$table} || $table) : $table;

      $dbh->func($table_name, 'ARRAY', [@{$tref->{$table}{data}}], {
         col_names => join(',', @{$tref->{$table}{columns}}),
      }, 'ad_import');
   }

   # Using the DBD::AnyData $dbh for the rest of the work
   push @dbh, $dbh;
   return $outer_dbh;
}

sub data_sources {
   # Typically no need for parameters, as the defaults work just fine...
   return ('dbi:TreeData:');
}

sub disconnect_all {
   while (my $dbh = shift @dbh) {
      ref $dbh && $dbh->disconnect;
   }
   return 1;
}

sub tree_process_hash_tree ($$$;$) {
   my ($drh, $col, $tree, $depth) = @_;
   my ($col_id, $serialized_tree);

   if ($depth > 100) {
      $drh->set_err(0, "Too deep down the rabbit hole; crawling back...");
      return $col => undef;
   }

   print_debug($depth, "$depth - $col => ".(reftype($tree) || substr($tree, 0, 30)));

   state $id_names = ['group', 'matrix', 'cube', 'hypercube'];  # if you go past here, you've gone too far...

   given (reftype $tree) {
      # Common code for both HASHs and ARRAYs
      when (/HASH|ARRAY/) {
         $col =  to_S(col2word($col));
         $col =~ s/ /_/g;
         $col_id = $col.'_id';

         # compare serialized trees for the same IDs
         if ($depth) {  # no point if this is the first node
            $serialized_tree = Data::Dumper->new([$tree], ['*XXXX'])->
               # (options for consistency, for exact matches)
               Reset->Sortkeys(1)->
               # (options designed to use the smallest possible footprint, as these can get rather large)
               Indent(0)->Quotekeys(0)->Pair('=')->Dump;

            # cycle through possible ID names
            my @list = ('', (reftype $tree eq 'ARRAY') ? @$id_names : ());
            foreach my $suffix (@list) {
               my $id_name = $col.($suffix ? '_'.$suffix : '').'_id';
               my $tree = $serialized_tree;
               $tree =~ s/^(\W{1,2})XXXX/$1$id_name/;

               # already exists, makes this easier
               my $id = $ids->{trees}{$tree};
               if ($id) {
                  print_debug($depth+1, "TREE <=== Dumper match ID ".join(' => ', split(/\|/, $id)));
                  return split(/\|/, $id);
               }
            }
         }
         continue;
      }
      # HASHs control the main tables, providing column names and data for the rows
      # Table = $col (plural)
      # ID = $col.'_id'
      when ('HASH') {
         # parse out a table name (with plural form)
         my $table_name = $depth ? to_PL($col) : $col;
         $table_name =~ s/ /_/g;

         # now run through the columns and data (with recursive loop goodness)
         my %data = map {
            my ($dat, $id) = ($$tree{$_}, $_);
            # clean up the column names
            $id = col2word($id);
            $id =~ s/ /_/g;
            $drh->tree_process_hash_tree($id => $dat, $depth + 1);
         } keys %$tree;
         ### FIXME: don't forget about undef in keys ###

         # check the new column names to see if we've seen this table before
         my @cols = ($col_id, sort keys %data);  # new ID column first
         my $col_key = join('|', @cols);

         if ($columns->{$col_key}) {       # known table
            $table_name = $columns->{$col_key};

            print_debug($depth+1, "HASH ===> Found known table '$table_name'");
         }
         elsif ($tables->{$table_name}) {  # errr, known table, but not with this column structure
            my $t;
            foreach my $j ('', 2 .. 200) {  # loop through a bunch of potential table names
               my $tname = $table_name.$j;

               if ($t = $tables->{$tname}) {
                  my @tcols = @{$t->{columns}};
                  my @ucols = uniq(@cols, @tcols);
                  # have to be the same ID columns  && need to have at least one field in common
                  # (remove keys while we're at it)
                  if (shift(@tcols) eq shift(@cols) && uniq(@cols, @tcols) < (@tcols + @cols)) {
                     my @extra_cols = notin(\@tcols, \@cols);

                     # new table has extra columns to add
                     if (@extra_cols) {
                        # add new column names and resort
                        my @old_cols = @{$t->{columns}};
                        my @new_cols = ($col_id, sort(@tcols, @extra_cols));
                        my @diff_idx = grep { $old_cols[$_] ne $new_cols[$_] } (0 .. (@new_cols - 1));
                        $t->{columns} = \@new_cols;

                        unless ($diff_idx[0] > @{$t->{columns}}-1) {
                           # well, the new columns aren't on the end, so old data needs to be shuffled
                           for (my $l = 0; $l < @{$t->{data}}; $l++) {
                              my @data = @{$t->{data}[$l]};
                              my %data = map { $old_cols[$_] => $data[$_] } (0 .. (@data - 1));  # change to hash
                                 @data = map { $data{$_} } @new_cols;                            # change to array
                              $t->{data}[$l] = \@data;
                           }
                        }

                        # remove the old column key and replace with a new one
                        delete $columns->{ join('|', @old_cols) };
                     }

                     # if the new table is missing certain columns, they will insert undefs as needed naturally below
                     # however, nullability checks might be in order
                     my @missing_cols = notin(\@cols, \@tcols);
                     $can_null->{$_} = 1 for (@missing_cols, @extra_cols);

                     print_debug($depth+1, "HASH ===> Found known table with different columns '$table_name'");
                     last;
                  }

                  # wrong table to use; try next name
                  next;
               }
               else {  # just treat this as as new table, then
                  $drh->set_err(0, "Found a table with a dupe name, but totally different columns; calling it '$tname'...") if ($j);
                  $table_name = $tname;
                  $tables->{$table_name} = $t = {
                     columns => [@cols],
                     data    => [],
                  };

                  print_debug($depth+1, "HASH ===> Creating new table '$table_name' because of conflicting columns");
                  last;
               }
            }

            $col_key = join('|', @{$t->{columns}});
            $columns->{$col_key} = $table_name;
         }
         else {                            # new table
            $tables->{$table_name} = {
               columns => [@cols],
               data    => [],
            };
            $columns->{$col_key} = $table_name;

            print_debug($depth+1, "HASH ===> Creating new table '$table_name'");
         }

         # Add new row
         my $t = $tables->{$table_name};
         my $id = ++($ids->{table}{$table_name});
         $serialized_tree =~ s/^(\W{1,2})XXXX/$1$col_id/;
         $ids->{trees}{$serialized_tree} = $col_id.'|'.$id;
         push(@{$t->{data}}, [ $id, map { $data{$_} } grep { $_ ne $col_id } @{$t->{columns}} ]);

         # Since we're done with this table, send back the col_id and id#
         print_debug($depth+1, "HASH <=== $col_id => $id");
         $types->{$col_id} = 'ID';
         return $col_id => $id;
      }
      # ARRAYs provide ID grouping tables, capturing the individual rows in a group
      # These are going to be two-column tables with two different IDs
      # Table = $col.'_groups' (plural)
      # ID = $col.(group|matrix|cube|etc.).'_id'
      when ('ARRAY') {
         # Pass the data on down first (ARRAY of ARRAYS to prevent de-duplication of keys)
         my @data = map {
            my $dat = $_;
            [ $drh->tree_process_hash_tree($col => $dat, $depth + 1) ]
         } @$tree;

         # Okay, we could end up with several different scenarios:

         # A. All items have the same column name (as a ID)
         # B. All items appear to be some form of data
         # C. A mixture of IDs and data (scary!)

         # Process both groups individually (and hope for the best)
         my @id_cols   = grep { $data[$_]->[0] =~ /_id$/; } (0 .. (@data - 1));
         my @data_cols = grep { $data[$_]->[0] !~ /_id$/; } (0 .. (@data - 1));
         @id_cols = () unless ($depth);  # skip any group ID tables if this is the very first node

         $drh->set_err(0, "Inconsistant sets of data within an array near '$col'; going to process it as best as possible...") if (@id_cols && @data_cols);

         # Items of IDs
         ### TODO: Clean this up; the logic is a bit of a mess... ###
         my (@max_id, @group_id);
         foreach my $ii (@id_cols, @data_cols) {
            # In all cases, there will be two tables to populate: a group/id table, and a id/data (or id/id) table
            my ($icol, $item) = @{$data[$ii]};
            my $is_id = ($icol =~ /_id$/i);

            # IDs are singular; table names are plural
            my $strip = to_S(col2word($icol));
            $icol = $strip;
            $icol =~ s/ /_/g;
            $icol .= '_id' if ($is_id);

            # Process group ID names
            # ncol = N+1, icol = N (as in _group_id => _id, or _matrix_id => _group_id)
            my $ncol = $icol;
            $ncol =~ s/_id$//i;
            my $i = firstidx { $ncol =~ s/(?<=_)$_$//; } @$id_names;  # that's underscore + $_ + EOL
            # $i = -1 if not found, which then ++$i = 0 and id_names = _group

            if (++$i > 3) {   # start whining here
               $ncol .= '_hypercube_'.$id_names->[$i -= 4];

               $drh->set_err(0, "Seriously?!  We're using ridiculous names like '$ncol"."_id' at this point...");
            }
            else { $ncol .= '_'.$id_names->[$i]; }
            $i++;  # prevent -1 on @_id arrays

            # Parse out a group table name (with plural form)
            my $grp_table_name = to_S(col2word($ncol));
            $grp_table_name = to_PL($grp_table_name);  # like blah_groups
            $grp_table_name =~ s/ /_/g;

            $icol .= '_id' unless ($icol =~ /_id$/);
            $ncol .= '_id' unless ($ncol =~ /_id$/);
            $max_id[$i] = $ncol;
            print_debug($depth+1, "ARRAY ===> max_id = $i/$ncol");

            # Create new group table (if it doesn't already exist)
            my $t;
            if ($depth) {  # skip any group ID tables if this is the very first node
               unless ($tables->{$grp_table_name}) {
                  ### FIXME: Assuming that table doesn't exist with the same columns ###
                  print_debug($depth+1, "ARRAY ===> Creating new group table '$grp_table_name'");

                  $tables->{$grp_table_name} = {
                     columns => [ $ncol, $icol ],
                     data    => [],
                  };
               }
               $t = $tables->{$grp_table_name};
               my $col_key = join('|', @{$t->{columns}});
               $columns->{$col_key} = $grp_table_name;
            }

            # Add new row
            $group_id[$i] = ++($ids->{table}{$grp_table_name}) unless ($group_id[$i]);  # only increment once (per group type)
            if ($is_id) {  # ID column: $item = ID, and this goes in a group table (id/data table already processed)
               print_debug($depth+1, "ARRAY ===> $grp_table_name => [ $group_id[$i], $item ] (new ID row for an group table)");
               push(@{$t->{data}}, [ $group_id[$i], $item ]);
            }
            else {        # data column: $item = data, and we process both tables
               my $itbl_name = to_PL($strip);  # like blahs
               $itbl_name =~ s/ /_/g;
               my $data_col = $strip;
               $data_col =~ s/ /_/g;

               # Create new id table (if it doesn't already exist)
               unless ($tables->{$itbl_name}) {
                  print_debug($depth+1, "ARRAY ===> Creating new ID table '$itbl_name'");

                  $tables->{$itbl_name} = {
                     columns => [ $icol, $data_col ],
                     data    => [],
                  };
               }
               my $n = $tables->{$itbl_name};
               my $col_key = join('|', @{$n->{columns}});
               $columns->{$col_key} = $itbl_name;
               $types->{$icol} = 'ID';

               $max_id[$i-1] = $icol;
               print_debug($depth+1, "ARRAY ===> max_id = ".int($i-1)."/$icol");
               ### FIXME: Assuming that table doesn't exist with the same columns ###

               # First, check serial tree with single value
               my $stree = Data::Dumper->new([$item], ['*'.$icol])->Reset->Indent(0)->Dump;
               if ($ids->{trees}{$stree} && $depth) {
                  # Add new group row (with proper col_id)
                  my $id = (split(/\|/, $ids->{trees}{$stree}))[1];
                  print_debug($depth+1, "ARRAY ===> $grp_table_name => [ $group_id[$i], $id ] (serial tree found)");
                  push(@{$t->{data}}, [ $group_id[$i], $id ] );

                  # (no need to add into main table; already exists)
               }
               else {
                  # Add new group row (with proper col_id)
                  my $id = ++($ids->{table}{$itbl_name});
                  if ($depth) {
                     print_debug($depth+1, "ARRAY ===> $grp_table_name => [ $group_id[$i], $id ] (new group row)");
                     push(@{$t->{data}}, [ $group_id[$i], $id ]);
                  }

                  # Add new id row
                  $ids->{trees}{$stree} = $icol.'_id|'.$id;
                  print_debug($depth+2, "ARRAY ===> $itbl_name => [ $id, $item ] (new ID/data row)");
                  push(@{$n->{data}}, [ $id, $item ]);
               }
            }
         }

         # Pass back an ID
         my ($gid_col, $gid) = (pop(@max_id) || $col, pop(@group_id));  # undef @max_id might happen with an empty array

         print_debug($depth+1, "ARRAY <=== $gid_col => $gid");
         $serialized_tree =~ s/^(\W{1,2})XXXX/$1$gid_col/;
         $ids->{trees}{$serialized_tree} = $gid_col.'|'.$gid;
         $types->{$gid_col} = 'ID';
         return $gid_col => $gid;
      }
      # An actual scalar; return back the proper column name and data
      when ('' || undef) {
         return type_detect($col, $tree);
      }
      # De-reference
      when (/SCALAR|VSTRING/) {
         return type_detect($col, $$tree);
      }
      # Warn and de-reference
      when (/Regexp|LVALUE/i) {
         $drh->set_err(0, "Found a ".(reftype $tree)."; just going to treat this like a SCALAR...");
         return type_detect($col, $$tree);
      }
      # Warn and de-reference (for further examination)
      when ('REF') {
         $drh->set_err(0, "Found a REF; going to dive in the rabbit hole...");
         return $drh->tree_process_hash_tree($col => $$tree, $depth + 1);
      }
      # Warn and de-reference (for further examination)
      when ('GLOB') {
         foreach my $t (qw(Regexp VSTRING IO FORMAT LVALUE GLOB REF CODE HASH ARRAY SCALAR)) {  # scalar last, since a ref is still a scalar
            if (defined *$$tree{$t}) {
               $drh->set_err(0, "Found a GLOB (which turn out to be a $t); going to dive in the rabbit hole...");
               return $drh->tree_process_hash_tree($col => *$$tree{$t}, $depth + 1);
            }
         }
         $drh->set_err(0, "Found a GLOB, but it didn't point to anything...");
         return $col => undef;
      }
      # Warn and throw away
      when ('CODE') {
         ### TODO: Warn immediately, eval block with timer to use as output, then continue ###
         ### Definitely need a switch, though ###
         $drh->set_err(0, "Found a CODE block; not going to even touch this one...");
         return $col => undef;
      }
      default {
         $drh->set_err(0, "Found a ".(reftype $tree)."; WTF is this?  Can't use this at all...");
         return $col => undef;
      }
   }

   die "WTF?!  Perl broke my given/when!  Alert the Pumpking!!!";
}

# Find items in @B that are in @A
sub foundin (\@\@) {
   my ($A, $B) = @_;
   return grep { my $i = $_; any { $i eq $_ } @$A; } @$B;
}

# Find items in @B that are not in @A
sub notin (\@\@) {
   my ($A, $B) = @_;
   return grep { my $i = $_; none { $i eq $_ } @$A; } @$B;
}

sub col2word ($) {
   my $word = $_[0];
   $word = lc($word);
   $word =~ s/[\W_]+/ /g;
   $word =~ s/^\s+|\s+(?:id)?$//g;
   return $word;
}

sub type_detect ($;$) {
   my ($col, $val) = @_;
   my $is_num = looks_like_number($val);

   $col = to_S(col2word($col));  # if we're at this point, it's a single item
   $col =~ s/ /_/g;
   unless (defined $val) {
      $can_null->{$_} = 1;
      return $col => undef;
   }

   $types->{$col}   = 'STRING' if (!$is_num && $types->{$col});  # any non-number data invalidates the NUMBER type
   $types->{$col} ||= $is_num ? 'NUMBER' : 'STRING';
   return $col => $val;
}

sub print_debug ($$) {
   my ($depth, $msg) = @_;
   return unless ($debug);

   print ("   " x $depth);
   say $msg;
}

1;

##############################################################################
# DBD::TreeData::db

package   # hide from PAUSE
   DBD::TreeData::db; # ====== DATABASE ======

our $imp_data_size = 0;
use DBD::AnyData;
use parent qw(-norequire DBD::AnyData::db);  # no such file as ::db.pm

use Config;
use List::AllUtils qw(first);

# Overriding the package here to add some *_info methods

### TODO: get_info ###

sub table_info {
   my ($dbh, $catalog, $schema, $table) = @_;
   my $names = [qw( TABLE_QUALIFIER TABLE_OWNER TABLE_NAME TABLE_TYPE REMARKS )];

   $table = '^'.$table.'$' if length $table;

   return sponge_sth_loader($dbh, 'TABLE_INFO', $names, [
      grep { !$table || $_->[2] =~ /$table/i } $dbh->func("get_avail_tables")
   ] );
}

sub column_info {
   my ($dbh, $catalog, $schema, $table, $column) = @_;
   my $type = 'COLUMN_INFO';
   my $names = [qw(
      TABLE_CAT TABLE_SCHEM TABLE_NAME COLUMN_NAME DATA_TYPE TYPE_NAME COLUMN_SIZE BUFFER_LENGTH DECIMAL_DIGITS
      NUM_PREC_RADIX NULLABLE REMARKS COLUMN_DEF SQL_DATA_TYPE SQL_DATETIME_SUB CHAR_OCTET_LENGTH ORDINAL_POSITION IS_NULLABLE
      CHAR_SET_CAT CHAR_SET_SCHEM CHAR_SET_NAME COLLATION_CAT COLLATION_SCHEM COLLATION_NAME UDT_CAT UDT_SCHEM UDT_NAME
      DOMAIN_CAT DOMAIN_SCHEM DOMAIN_NAME SCOPE_CAT SCOPE_SCHEM SCOPE_NAME MAX_CARDINALITY DTD_IDENTIFIER IS_SELF_REF
   )];

   $table  = '^'.$table .'$' if length $table;
   $column = '^'.$column.'$' if length $column;

   my @tables = $dbh->func("get_avail_tables");
   my @col_rows = ();
   my $tc = $dbh->{tree_columns};

   # De-mangle types
   my $types = $dbh->type_info_all;
   shift(@$types);  # helper "column key" row
   my %types = map { $_->[0] => $_ } @$types;

   foreach my $tbl (sort { $a->[2] cmp $b->[2] } @tables) {  # ->[2] = table name
      next unless ($tbl);
      next unless (!$table || $tbl->[2] =~ /$table/i);

      my $id = 0;
      foreach my $col ( @{$tc->{names}{$tbl->[2]}} ) {
         next unless (!$column || $col =~ /$column/i);
         my $ti = $types{ $id ? uc($tc->{types}{$col}) : 'PID' };
         my $can_null = $id && $tc->{nulls}{$col} || 0;

         my $col_row = [
            # 0=TABLE_CAT TABLE_SCHEM TABLE_NAME COLUMN_NAME DATA_TYPE TYPE_NAME COLUMN_SIZE BUFFER_LENGTH DECIMAL_DIGITS
            undef, undef, $tbl->[2], $col, $ti->[0], $ti->[1], $ti->[2], undef, $ti->[17] ? int($ti->[14] * log($ti->[17])/log(10)) : undef,  # log(r^l) = l * log(r)
            # 9=NUM_PREC_RADIX NULLABLE REMARKS COLUMN_DEF SQL_DATA_TYPE SQL_DATETIME_SUB CHAR_OCTET_LENGTH ORDINAL_POSITION IS_NULLABLE
            $ti->[17], $can_null, undef, undef, $ti->[15], $ti->[16], $ti->[17] ? undef : $ti->[2], $id, $can_null ? 'YES' : 'NO',
            # 18=CHAR_SET_CAT CHAR_SET_SCHEM CHAR_SET_NAME COLLATION_CAT COLLATION_SCHEM COLLATION_NAME UDT_CAT UDT_SCHEM UDT_NAME
            undef, undef, undef, undef, undef, undef, undef, undef, undef,
            # DOMAIN_CAT DOMAIN_SCHEM DOMAIN_NAME SCOPE_CAT SCOPE_SCHEM SCOPE_NAME MAX_CARDINALITY DTD_IDENTIFIER IS_SELF_REF
            undef, undef, undef, undef, undef, undef, undef, undef, undef,
         ];

         push @col_rows, $col_row;
         $id++;
      }
   }

   return sponge_sth_loader($dbh, $type, $names, \@col_rows);
}

sub primary_key_info {
   my ($dbh, $catalog, $schema, $table) = @_;
   my $type = 'PRIMARY_KEY_INFO';

   my $cols = $dbh->{tree_columns}{names}{$table} || return $dbh->set_err($DBI::stderr, "No such table name: $table", '42704');
   my $pkey = $cols->[0];

   return sponge_sth_loader($dbh, $type,
      [qw(TABLE_CAT TABLE_SCHEM TABLE_NAME COLUMN_NAME KEY_SEQ PK_NAME)],
      [ [ undef, undef, $table, $pkey, 1, $pkey.'_pkey' ] ]
   );
}

sub foreign_key_info {
   my ($dbh, $pk_catalog, $pk_schema, $pk_table, $fk_catalog, $fk_schema, $fk_table) = @_;
   my $type = 'FOREIGN_KEY_INFO';
   my $names = [qw(
      PKTABLE_CAT PKTABLE_SCHEM PKTABLE_NAME PKCOLUMN_NAME FKTABLE_CAT FKTABLE_SCHEM FKTABLE_NAME FKCOLUMN_NAME
      KEY_SEQ UPDATE_RULE DELETE_RULE FK_NAME PK_NAME DEFERRABILITY UNIQUE_OR_PRIMARY
   )];

   my $colnames = $dbh->{tree_columns}{names};
   my $pkey = $pk_table && $colnames->{$pk_table} ? $colnames->{$pk_table}[0] : undef;
   my $fkey = $fk_table && $colnames->{$fk_table} ? $colnames->{$fk_table}[0] : undef;
   my ($pk_list, $fk_list) = ([$pk_table], [$fk_table]);
   my @dbi_data;

   # If both PKT and FKT are given, the function returns the foreign key, if any,
   # in table FKT that refers to the primary (unique) key of table PKT.
   if ($pkey && $fkey) {
      $fkey = first { $_ eq $pkey } $colnames->{$fk_table};  # pkey or bust
   }

   # If only PKT is given, then the result set contains the primary key of that table
   # and all foreign keys that refer to it.
   elsif ($pkey) { $fk_list = [ grep { $colnames->{$_} ~~ /^$pkey$/ } keys %$colnames ]; }

   # If only FKT is given, then the result set contains all foreign keys in that table
   # and the primary keys to which they refer.
   elsif ($fkey) {
      my @cols = @{$colnames->{$fk_table}};
      shift @cols;  # remove primary key

      $pk_list = [];
      foreach my $col (@cols) {
         my $tbl = (first { $colnames->{$_}[0] eq $col } keys %$colnames) || next;
         push @$pk_list, $tbl;
      }
   }
   else { return sponge_sth_loader($dbh, $type, $names, []); }

   # main loop
   foreach my $pt (@$pk_list) {
      foreach my $ft (@$fk_list) {
         my $key = $colnames->{$pt}[0];  # key links are named the same
         push @dbi_data, [
            # 0=PKTABLE_CAT PKTABLE_SCHEM PKTABLE_NAME PKCOLUMN_NAME FKTABLE_CAT FKTABLE_SCHEM FKTABLE_NAME FKCOLUMN_NAME
            undef, undef, $pt, $key, undef, undef, $ft, $key,
            # 8=KEY_SEQ UPDATE_RULE DELETE_RULE FK_NAME PK_NAME DEFERRABILITY UNIQUE_OR_PRIMARY
            1, 3, 3, join('_', $ft, $key, 'fkey'), $key.'_pkey', 7, 'PRIMARY',
         ];
      }
   }

   return sponge_sth_loader($dbh, $type, $names, \@dbi_data);
}

sub statistics_info {
   my ($dbh, $catalog, $schema, $table, $unique_only, $quick) = @_;
   my $type = 'STATISTICS_INFO';

   my $cols = $dbh->{tree_columns}{names}{$table} || return $dbh->set_err($DBI::stderr, "No such table name: $table", '42704');
   my $pkey = $cols->[0];
   my $rows = $dbh->{tree_cardinality}{$table};

   return sponge_sth_loader($dbh, $type,
      [qw(
         TABLE_CAT TABLE_SCHEM TABLE_NAME NON_UNIQUE INDEX_QUALIFIER INDEX_NAME TYPE ORDINAL_POSITION
         COLUMN_NAME ASC_OR_DESC CARDINALITY PAGES FILTER_CONDITION
      )],
      [
         [
            undef, undef, $table, 0, undef, undef, 'table', undef,
            undef, undef, $rows, undef, undef
         ],
         [
            undef, undef, $table, 0, undef, $pkey.'_pkey', 'content', 1,
            $pkey, 'A', $rows, undef, undef
         ],
      ],
   );
}

sub sponge_sth_loader {
   my ($dbh, $tbl_name, $names, $rows) = @_;

   # (mostly a straight copy from DBI::DBD::SqlEngine)
   my $dbh2 = $dbh->func("sql_sponge_driver");
   my $sth = $dbh2->prepare(
                            $tbl_name,
                            {
                               rows => $rows || [],
                               NAME => $names,
                            }
                          );
   $sth or $dbh->set_err( $DBI::stderr, $dbh2->errstr, $dbh2->state );
   return $sth;
}

sub type_info_all {
   # We are basically just translating Perl variable types to SQL,
   # though once everything has been flattened, it's basically just
   # string and number.

   # Perl's number size varies between 32/64-bit versions
   my $nbits = $Config{ptrsize} * 16 - 11;

   return [
      {
         TYPE_NAME          => 0,
         DATA_TYPE          => 1,
         COLUMN_SIZE        => 2,     # was PRECISION originally
         LITERAL_PREFIX     => 3,
         LITERAL_SUFFIX     => 4,
         CREATE_PARAMS      => 5,
         NULLABLE           => 6,
         CASE_SENSITIVE     => 7,
         SEARCHABLE         => 8,
         UNSIGNED_ATTRIBUTE => 9,
         FIXED_PREC_SCALE   => 10,    # was MONEY originally
         AUTO_UNIQUE_VALUE  => 11,    # was AUTO_INCREMENT originally
         LOCAL_TYPE_NAME    => 12,
         MINIMUM_SCALE      => 13,
         MAXIMUM_SCALE      => 14,
         SQL_DATA_TYPE      => 15,
         SQL_DATETIME_SUB   => 16,
         NUM_PREC_RADIX     => 17,
         INTERVAL_PRECISION => 18,
      },
      # Name      DataType             Max    Literals      Params         Null   Case Search Unsign  Fixed  Auto   LocalTypeName   M/M Scale     SQLDataType         DateTime_Sub  Radix  ItvPrec
      [ "PID",    DBI::SQL_INTEGER(),      32, undef, undef,        undef,     0,     0,     3,     1,     1,     0,          "PID",     0,     0, DBI::SQL_INTEGER(),        undef,     2, undef],
      [ "ID",     DBI::SQL_INTEGER(),      32, undef, undef,        undef,     1,     0,     3,     1,     1,     0,           "ID",     0,     0, DBI::SQL_INTEGER(),        undef,     2, undef],
      [ "NUMBER", DBI::SQL_NUMERIC(),  $nbits, undef, undef,        undef,     1,     0,     3,     0,     0,     0,       "Number",     0,$nbits, DBI::SQL_NUMERIC(),        undef,     2, undef],
      [ "STRING", DBI::SQL_VARCHAR(),   2**31,   "'",   "'",        undef,     1,     1,     3, undef, undef, undef,       "String", undef, undef, DBI::SQL_VARCHAR(),        undef, undef, undef],
   ];
}

1;

##############################################################################
# DBD::TreeData::st

package   # hide from PAUSE
   DBD::TreeData::st; # ====== STATEMENT ======

our $imp_data_size = 0;
use DBD::AnyData;
use parent qw(-norequire DBD::AnyData::st);  # no such file as ::st.pm

1;

##############################################################################
# DBD::TreeData::Statement

package   # hide from PAUSE
   DBD::TreeData::Statement; # ====== SqlEngine::Statement ======

our $imp_data_size = 0;
use DBD::AnyData;
use parent qw(-norequire DBD::AnyData::Statement);  # no such file as ::Statement.pm

1;

##############################################################################
# DBD::TreeData::Table

package   # hide from PAUSE
   DBD::TreeData::Table; # ====== SqlEngine::Table ======

our $imp_data_size = 0;
use DBD::AnyData;
use parent qw(-norequire DBD::AnyData::Table);  # no such file as ::Table.pm

1;

__END__
=pod

=head1 NAME

DBD::TreeData - DBI driver for any abstract hash/array tree

=head1 SYNOPSIS

    use DBI;
    use JSON::Any;
    use LWP::Simple;
 
    # Example JSON object
    my $json = get 'http://maps.googleapis.com/maps/api/geocode/json?address=1600+Pennsylvania+Ave+NW,+20500&region=us&language=en&sensor=false';
    my $obj = JSON::Any->jsonToObj($json);
 
    my $dbh = DBI->connect('dbi:TreeData:', '', '', {
       tree_table_name => 'geocode',
       tree_data       => $obj,
    });
 
    # Informational dump
    use Data::Dump;
    dd ($dbh->table_info->fetchall_arrayref);
    dd (map { [ @{$_}[2 .. 6] ] } @{
       $dbh->column_info('','','','')->fetchall_arrayref
    });
 
    # DBIC dump
    use DBIx::Class::Schema::Loader 'make_schema_at';
    make_schema_at(
       'My::Schema', {
          debug => 1,
          dump_directory  => './lib',
       },
       [ 'dbi:TreeData:geocode', '', '', { tree_data => $obj } ],
    );

=head1 DESCRIPTION

DBD::TreeData provides a DBI driver to translate any sort of tree-based data set (encapsulated in a Perl object) into a flat set of tables,
complete with real SQL functionality.  This module utilizes L<DBD::AnyData> to create the new tables, which uses L<SQL::Statement> to support
the SQL parsing.  (Any caveats with those modules likely applies here.)

This module can be handy to translate JSON, XML, YAML, and many other tree formats to be used in class sets like L<DBIx::Class>.  Unlike
L<DBD::AnyData>, the format of the data doesn't have to be pre-flattened, and will be spread out into multiple tables.

Also, this driver fully supports all of the C<<< *_info >>> methods, making it ideal to shove into modules like L<DBIx::Class::Schema::Loader>.
(The C<<< table_info >>> and C<<< column_info >>> filters use REs with beginE<sol>end bounds pre-set.)

=encoding utf8

=head1 CONNECT ATTRIBUTES

=head2 tree_data

The actual tree object.  Of course, this attribute is required.

=head2 tree_table_name

The name of the starting table.  Not required, but recommended.  If not specified, defaults to 'tree_data', or the value of the driver
DSN string (after the C<<< dbi:TreeData: >>> part).

=head2 tree_debug

Boolean.  Print debug information while translating the tree.

=head2 tree_rename_tables

Hashref of table names.  If you don't like the name of an auto-created table, you can rename them while the database is being built.  Within
the hashref, the keysE<sol>values are the oldE<sol>new names, respectively.

=head1 TRANSLATION BEHAVIOR

The tree translation into flat tables is done using a recursive descent algorithm.  It starts with a check of the current node's reference
type, which dictates how it interprets the children.  The goal is to create a fully L<4NF|http://en.wikipedia.org/wiki/Fourth_normal_form>
database from the tree.

Arrays are interpreted as a list of rows, and typically get rolled up into "group" tables.  Hashes are interpreted as a list of column names
and values.  Non-references are considered values.  Scalar refs and VStrings are de-referenced first.  Other types of refs are processed as
best as possible, but the driver will complain.  (Code ref blocks are currently NOT executed and discarded.)

Nested arrays will create nested group tables with different suffixes, like C<<< matrix >>>, C<<< cube >>>, and C<<< hypercube >>>.  If it has to go beyond
that (and you really shouldn't have structures like that), it'll start complaining (sarcastically).

In almost all cases, the table name is derived from a previous key.  Table names also use L<Lingua::EN::Inflect::Phrase> to create
pluralized names.  Primary IDs will have singular names with a C<<< _id >>> suffix.

For example, this tree:

    address_components => [
       {
          long_name  => 1600,
          short_name => 1600,
          types      => [ "street_number" ]
       },
       {
          long_name  => "President's Park",
          short_name => "President's Park",
          types      => [ "establishment" ]
       },
       {
          long_name  => "Pennsylvania Avenue Northwest",
          short_name => "Pennsylvania Ave NW",
          types      => [ "route" ]
       },
       {
          long_name  => "Washington",
          short_name => "Washington",
          types      => [ "locality", "political" ]
       },
       ... etc ...,
    ],

Would create the following tables:

    <main_table>
       address_component_groups
          address_components
             type_groups
                types

In this case, C<<< address_components >>> has most of the columns and data, but it also has a tie to an ID of C<<< address_component_groups >>>.

Since C<<< types >>> points to an array, it will have its own dedicated table.  That table would have data like:

    type_id │ type
    ════════╪════════════════
          1 │ street_number
          2 │ establishment
          3 │ route
          4 │ locality
          5 │ political
        ... │ ...

Most of the C<<< type_groups >>> table would be a 1:1 match.  However, the last component entry has more than one value in the C<<< types >>> array, so the
C<<< type_group_id >>> associated to that component would have multiple entries (4 & 5).  Duplicate values are also tracked, so that IDs are reused.

=head1 CAVEATS

=head2 DBI E<sol> DBD::AnyData Conflict

As of the time of this writing, the latest version of L<DBI> (1.623) and the latest version of L<DBD::AnyData> (0.110) do not work together.
Since TreeData relies on L<DBD::AnyData> for table creation, you will need to downgrade to L<DBI> 1.622 to use this driver, until a new
version of L<DBD::AnyData> comes out.

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/DBD-TreeData/wiki>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/DBD::TreeData/>.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and join this channel: #dbi then talk to this person for help: SineSwiper.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests via L<L<https://github.com/SineSwiper/DBD-TreeData/issues>|GitHub>.

=head1 AUTHOR

Brendan Byrd <BBYRD@CPAN.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

