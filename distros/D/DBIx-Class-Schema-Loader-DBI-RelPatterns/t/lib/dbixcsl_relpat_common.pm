package dbixcsl_relpat_common;

use strict;
use warnings;
use Test::More;
use DBIx::Class::Schema::Loader;
use make_dbictest_db_relpat;

use base qw/Exporter/;
our @EXPORT_OK = qw/can_statistics_info get_loader make_schema test_rels/;

use constant WARN_OPTIONAL => 0;

my $SCHEMA_COUNTER = 0;


# makes schema
# optionally with the loader class
# optionally tests the relationships
# optionally tests bypassing statistics_info method
# optionally tests the caught warnings or suppresses them
sub make_schema {
    my %options = @_;
    
    my $loader_class      = delete $options{loader_class};
    my $test_rels         = delete $options{test_rels};
    my $check_statinfo    = delete $options{check_statinfo};
    my $no_increment      = delete $options{no_increment};
    my $warnings_exist    = delete $options{warnings_exist} || [];
    my $warnings_suppress = delete $options{warnings_suppress} || [];
    
    $check_statinfo = 0 if !$test_rels || !$options{rel_constraint} || $options{_disable_uniq_detection};
    
    my $attributes = {};
    if ($loader_class) {
        $attributes->{loader_class} = ($loader_class eq '1') ? '::DBI::RelPatterns' : $loader_class;
    }
    
    my %catch_warnings;
    foreach (
        $warnings_exist,
        $warnings_suppress,
        'quuxs has no primary key', # to silence older Loaders
        'unable to obtain the non-unique index info',
    ) {
        next unless $_;
        my $severity = WARN_OPTIONAL;
        if ($_ eq $warnings_exist) {
            $severity++;
        } elsif ($options{quiet}) {
            $severity--;
        }
        my @warnings = (ref eq 'ARRAY' ? @$_ : $_);
        foreach (@warnings) {
            s{^/(.*)/$}{$1}s if $_ && !ref; # "/.../" strings
            $catch_warnings{$_} ||= $severity;
        }
    }
    
    $SCHEMA_COUNTER++ unless $no_increment;
    my $schema = 'DBICTest::Schema::RelPat';
    $schema .= 'NoStatInfo' if $options{_disable_uniq_detection};
    $schema .= $SCHEMA_COUNTER; # counter is really necessary for versions prior to 0.06000
    
    if ($DBIx::Class::Schema::Loader::VERSION < 0.06000) {
        $schema->_loader_invoked(0) if $no_increment && $schema->can('_loader_invoked');
    }
    
    if ($DBIx::Class::Schema::Loader::VERSION < 0.07003) {
        $options{preserve_case} = 1 unless defined $options{preserve_case};
    }
    
    {
        local $SIG{__WARN__} = warn_handler_suppressed(\%catch_warnings) if %catch_warnings;
        
        $schema = DBIx::Class::Schema::Loader::make_schema_at(
            $schema,
            { naming => 'current', skip_load_external => 1, %options },
            [ $make_dbictest_db_relpat::dsn, $attributes ],
        )->clone;
        
        if (%catch_warnings && (!$options{rel_constraint} || can_statistics_info($schema))) {
            # warnings are not the same without statistics_info
            foreach my $w (sort keys %catch_warnings) {
                next unless $catch_warnings{$w} > WARN_OPTIONAL;
                fail("warning thrown, like /$w/");
            }
        }
    }
    
    test_rels($schema, @$test_rels) if $test_rels;
    
    if ($check_statinfo && !$no_increment && !$options{preserve_case}) {
        subtest "preserve_case test" => sub {
            make_schema(%options,
                loader_class => $loader_class,
                warnings_suppress => $warnings_suppress,
                test_rels => $test_rels,
                quiet => 1,
                preserve_case => 1,
            );
            done_testing;
        };
    }
    
    if ($check_statinfo && can_statistics_info($schema)) {
        subtest "bypass statistics_info" => sub {
            make_schema(%options,
                loader_class => $loader_class,
                warnings_suppress => $warnings_suppress,
                test_rels => $test_rels,
                quiet => 1,
                _disable_uniq_detection => 1,
            );
            done_testing;
        };
    }
    
    return $schema;
}


# tests the relationships
# takes schema and an array with all the relationships
# rels that require statistics_info method have to be prefixed with "?"
# rels that require the absence of statistics_info have to be prefixed with "#"
# fails if any relationship does not exist
# fails if other relationships exist
sub test_rels {
    my ($schema, @rels) = @_;
    
    if (@rels % 2) {
        die "test_rels cannot take an array with odd number of elements; must be even";
    }
    
    my $loader = get_loader($schema);
    
    my $preserve_case = $DBIx::Class::Schema::Loader::VERSION >= 0.07000 && $loader->preserve_case;
    
    # _disable_uniq_detection method not available prior to 0.07008
    my $disable_uniq_detection = $loader->{_disable_uniq_detection} || !can_statistics_info($schema);
    
    my %rel_strings;
    while (@rels) {
        my ($table, $cols)     = split /\./, shift @rels;
        my ($r_table, $r_cols) = split /\./, shift @rels;
        foreach ($cols, $r_cols) {
            $_ = join ',', sort split /,/;
        }
        next if $table =~ s/^\?// && $disable_uniq_detection;
        next if $table =~ s/^#// && !$disable_uniq_detection;
        # rels are set up on boths ends (belongs_to <=> has_many)
        my $rel_string1 = "$table.$cols=>$r_table.$r_cols";
        my $rel_string2 = "$r_table.$r_cols=>$table.$cols";
        unless ($preserve_case) {
            $rel_string1 = lc $rel_string1;
            $rel_string2 = lc $rel_string2;
        }
        $rel_strings{$rel_string1}++;
        $rel_strings{$rel_string2}++;
    }
    
    my %table_sources = map {$_->name =~ /([^.]*)$/ => $_} map $schema->source($_), $schema->sources;
    
    foreach my $table (sort keys %table_sources) {
        my $source = $table_sources{$table};
        foreach my $rel ($source->relationships) {
            my $rel_info   = $source->relationship_info($rel);
            my $rel_cond   = $rel_info->{cond};
            my $rel_source = $schema->source( $rel_info->{source} );
            
            my ($r_table) = $rel_source->name =~ /([^.]*)$/;
            
            my ($cols)   = join ',', sort map /([^.]*)$/, values %$rel_cond;
            my ($r_cols) = join ',', sort map /([^.]*)$/, keys %$rel_cond;
            
            my $rel_string = "$table.$cols=>$r_table.$r_cols";
            $rel_string = lc $rel_string unless $preserve_case;
            
            # for debugging purposes only
            my $accessor = $rel_info->{attrs}{accessor};
            my $is_foreign_key = '; fk';
            foreach my $col (split ',', $cols) {
                $is_foreign_key = '' unless $source->column_info($col)->{is_foreign_key};
            }
            
            ok($rel_strings{$rel_string}, "relationship exists: $rel_string ($accessor$is_foreign_key)");
            
            $rel_strings{$rel_string}-- if $rel_strings{$rel_string};
            
            delete $rel_strings{$rel_string} unless $rel_strings{$rel_string};
        }
    }
    
    foreach (sort keys %rel_strings) {
        fail("relationship should exist: $_");
    }
    
    return;
}


# takes hashref with warnings to suppress
# deletes suppressed warnings from that hashref
# does not fail
# returns __WARN__ handler
sub warn_handler_suppressed {
    my $warnings = shift;
    die "warn_handler_suppressed requires a hashref" if ref $warnings ne 'HASH';
    my $warn_handler = $SIG{__WARN__} || sub { CORE::warn(@_) };
    return sub {
        foreach my $w (keys %$warnings) {
            next unless $w && $_[0] =~ /$w/;
            my $severity = delete $warnings->{$w};
            if ($severity > WARN_OPTIONAL) {
                pass("warning thrown, like /$w/");
            } elsif ($severity == WARN_OPTIONAL) {
                pass("warning suppressed, like /$w/");
            }
            return;
        }
        return $warn_handler->(@_);
    };
}


sub get_loader {
    my $schema = shift;
    if ($DBIx::Class::Schema::Loader::VERSION < 0.07011 && !$schema->can('loader')) {
        return $schema->_loader;
    }
    return $schema->loader;
}


sub can_statistics_info {
    my $schema = shift;
    my $loader = get_loader($schema);
    # dbh method not available prior to 0.07011
    my $dbh = $loader->can('dbh') ? $loader->dbh : $loader->schema->storage->dbh;
    return !!$dbh->can('statistics_info');
}


package DBIx::Class::Schema::Loader::DBI::RelPatterns::Test;

use base qw/DBIx::Class::Schema::Loader::DBI::RelPatterns/;

# SQLite does not impose any length restrictions,
# but let's pretend it does
sub _columns_info_for {
    my $self = shift;
    my ($table) = @_;
    my $result = $self->next::method(@_);
    my $size_map = $self->{relpat_test_size_map};
    if (ref $size_map eq 'HASH') {
        my %size_map_lc = map { lc($_) => $size_map->{$_} } keys %$size_map;
        while (my ($col, $info) = each %$result) {
            $info->{size} ||= $size_map_lc{lc "$table.$col"} if $size_map_lc{lc "$table.$col"};
        }
    }
    return $result;
}

# db_schema is not really supported on SQLite,
# so let's pretend that tables are in different schemas
sub _compat_table {
    my $self = shift;
    my $table = $self->next::method(@_);
    my $schema_map = $self->{relpat_test_schema_map};
    if (ref $schema_map eq 'HASH') {
        my %schema_map_lc = map { lc($_) => $schema_map->{$_} } keys %$schema_map;
        if (my $schema = $schema_map_lc{lc $table->name}) {
            $table->_schema($schema) if $schema ne ($table->_schema || '');
        }
    }
    return $table;
}

1;
