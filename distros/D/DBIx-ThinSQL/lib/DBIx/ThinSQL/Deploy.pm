package DBIx::ThinSQL::Deploy;
use strict;
use warnings;
use Log::Any qw/$log/;
use Carp qw/croak carp confess/;
use Path::Tiny;

our $VERSION = '0.0.48';

sub _split_sql {
    my $input = shift;
    my $end   = '';
    my $item  = '';
    my @items;

    $input =~ s/^\s*--.*\n//gm;
    $input =~ s!/\*.*?\*/!!gsm;

    while ( $input =~ s/(.*\n)// ) {
        my $try = $1;

        if ($end) {
            if ( $try =~ m/$end/ ) {
                $item .= $try;

                if ( $try =~ m/;/ ) {
                    $item =~ s/(^[\s\n]+)|(\s\n]+$)//;
                    push( @items, { sql => $item } );
                    $item = '';
                }

                $end = '';
            }
            else {
                $item .= $try;
            }

        }
        elsif ( $try =~ m/;/ ) {
            $item .= $try;
            $item =~ s/(^[\s\n]+)|(\s\n]+$)//;
            push( @items, { sql => $item } );
            $item = '';
        }
        elsif ( $try =~ m/^\s*CREATE( OR REPLACE)? FUNCTION.*AS (\S*)/i ) {
            $end = $2;
            $end =~ s/\$/\\\$/g;
            $item .= $try;
        }
        elsif ( $try =~ m/^\s*CREATE TRIGGER/i ) {
            $end = qr/(EXECUTE PROCEDURE)|(^END)/i;
            $item .= $try;
        }
        else {
            $item .= $try;
        }
    }

    foreach my $item (@items) {
        $item->{sql} =~ s/;[\s\n]*$//;
    }
    return \@items;
}

sub _load_file {
    my $file = path(shift);
    my $type = lc $file;

    $log->debug( '_load_file(' . $file . ')' );

    confess "fatal: missing extension/type: $file\n"
      unless $type =~ s/.*\.(.+)$/$1/;

    if ( $type eq 'sql' ) {

        # TODO add file name to hashrefs
        return _split_sql( $file->slurp_utf8 );
    }
    elsif ( $type eq 'pl' ) {
        return [ { $type => $file->slurp_utf8 } ];
    }

    die "Cannot load file of type '$type': $file";
}

sub run_arrayref {
    my $self = shift;
    my $ref  = shift;

    local $self->{ShowErrorStatement} = 1;
    local $self->{RaiseError}         = 1;

    $log->debug( 'running ' . scalar @$ref . ' statements' );
    my $i = 1;

    foreach my $cmd (@$ref) {
        if ( exists $cmd->{sql} ) {
            $self->do( $cmd->{sql} );
        }
        elsif ( exists $cmd->{pl} ) {
            $log->debug( "-- _run_cmd\n" . $cmd->{pl} );
            my $tmp = Path::Tiny->tempfile;
            print $tmp $cmd->{pl};
            system( $^X, $tmp->filename ) == 0 or die "system failed";
        }
        else {
            confess "Missing 'sql' or 'pl' key";
        }

        $i++;
    }

    return scalar @$ref;
}

sub run_sql {
    my $self = shift;
    my $sql  = shift;

    $log->debug("run_sql");
    $self->run_arrayref( _split_sql($sql) );
}

sub run_file {
    my $self = shift;
    my $file = shift;

    $log->debug("run_file($file)");
    my $result = eval { $self->run_arrayref( _load_file($file) ) };
    if ($@) {
        die "$file\n" . $@;
    }
    return $result;
}

sub run_dir {
    my $self = shift;
    my $dir = path(shift) || confess 'deploy_dir($dir)';

    confess "directory not found: $dir" unless -d $dir;
    $log->debug("run_dir($dir)");

    my @files;
    my $iter = $dir->iterator;
    while ( my $file = $iter->() ) {
        push( @files, $file )
          if $file =~ m/.+\.((sql)|(pl))$/ and -f $file;
    }

    $self->run_file($_) for sort { $a->stringify cmp $b->stringify } @files;
}

sub _setup_deploy {
    my $self   = shift;
    my $driver = $self->{Driver}->{Name};

    $log->debug("_setup_deploy");

    if ( defined &static::find ) {
        my $src = 'auto/share/dist/DBIx-ThinSQL/Deploy/' . $driver . '.sql';
        my $sql = static::find($src)
          or croak 'Driver not supported for deploy: ' . $driver;
        return $self->run_sql($sql);
    }

    return $self->run_dir( $self->share_dir->child( 'Deploy', $driver ) );
}

sub last_deploy_id {
    my $self = shift;
    my $app = shift || 'default';

    my $sth = $self->table_info( '%', '%', '_deploy' );
    return 0 unless ( @{ $sth->fetchall_arrayref } );

    return $self->selectrow_array(
        'SELECT COALESCE(MAX(seq),0) FROM _deploy WHERE app=?',
        undef, $app );
}

sub deploy_arrayref {
    my $self = shift;
    my $ref  = shift;
    my $app  = shift || 'default';

    confess 'deploy(ARRAYREF)' unless ref $ref eq 'ARRAY';
    local $self->{ShowErrorStatement} = 1;
    local $self->{RaiseError}         = 1;

    my @current =
      $self->selectrow_array( 'SELECT COUNT(app) from _deploy WHERE app=?',
        undef, $app );

    unless ( $current[0] ) {
        $self->do( '
                    INSERT INTO _deploy(app)
                    VALUES(?)
                ', undef, $app );
    }

    my $latest_change_id = $self->last_deploy_id($app);
    $log->debug( 'Current Change ID:',   $latest_change_id );
    $log->debug( 'Requested Change ID:', scalar @$ref );

    die "Requested Change ID("
      . ( scalar @$ref )
      . ") is less than current: $latest_change_id"
      if @$ref < $latest_change_id;

    my $count = 0;
    foreach my $cmd (@$ref) {
        $count++;
        next unless ( $count > $latest_change_id );

        exists $cmd->{sql}
          || exists $cmd->{pl}
          || confess "Missing 'sql' or 'pl' key for id " . $count;

        if ( exists $cmd->{sql} ) {
            $log->debug("-- change #$count\n");
            $self->do( $cmd->{sql} );
            $self->do( "
UPDATE 
    _deploy
SET
    type = ?,
    data = ?
WHERE
    app = ?
",
                undef, 'sql', $cmd->{sql}, $app );
        }

        if ( exists $cmd->{pl} ) {
            $log->debug( "# change #$count\n" . $cmd->{pl} );
            my $tmp = Path::Tiny->tempfile;
            $tmp->spew_utf8( $cmd->{pl} );

            # TODO stop and restart the transaction (if any) around
            # this
            system( $^X, $tmp ) == 0 or die "system failed";
            $self->do( "
UPDATE 
    _deploy
SET
    type = ?,
    data = ?
WHERE
    app = ?
",
                undef, 'pl', $cmd->{pl}, $app );
        }
    }
    $log->debug( 'Deployed to Change ID:', $count );
    return ( $latest_change_id, $count );
}

sub deploy_sql {
    my $self = shift;
    my $sql  = shift;
    my $app  = shift || 'default';

    $log->debug("deploy_sql($app)");
    $self->_setup_deploy;
    $self->deploy_arrayref( _split_sql($sql), $app );
}

sub deploy_file {
    my $self = shift;
    my $file = shift;
    my $app  = shift;
    $log->debug("deploy_file($file)");
    $self->_setup_deploy;
    $self->deploy_arrayref( _load_file($file), $app );
}

sub deploy_dir {
    my $self = shift;
    my $dir  = path(shift) || confess 'deploy_dir($dir)';
    my $app  = shift;

    confess "directory not found: $dir" unless -d $dir;
    $log->debug("deploy_dir($dir)");
    $self->_setup_deploy;

    my @files;
    my $iter = $dir->iterator;
    while ( my $file = $iter->() ) {
        if ( $file =~ m/.+\.((sql)|(pl))$/ and -f $file ) {
            push( @files, $file );
        }
        else {
            warn "Cannot deploy file: $file";
        }
    }

    my @items = map { @{ _load_file($_) } }
      sort { $a->stringify cmp $b->stringify } @files;

    $self->deploy_arrayref( \@items, $app );
}

sub deployed_table_info {
    my $self     = shift;
    my $dbschema = shift;
    my $driver   = $self->{Driver}->{Name};

    if ( !$dbschema ) {
        if ( $driver eq 'SQLite' ) {
            $dbschema = 'main';
        }
        elsif ( $driver eq 'Pg' ) {
            $dbschema = 'public';
        }
        else {
            $dbschema = '%';
        }
    }

    my $sth = $self->table_info( '%', $dbschema, '%',
        "'TABLE','VIEW','GLOBAL TEMPORARY','LOCAL TEMPORARY'" );

    my %tables;

    while ( my $table = $sth->fetchrow_arrayref ) {
        my $sth2 = $self->column_info( '%', '%', $table->[2], '%' );
        $tables{ $table->[2] } = $sth2->fetchall_arrayref;
    }

    return \%tables;
}

{
    no strict 'refs';
    *{'DBIx::ThinSQL::db::last_deploy_id'}      = \&last_deploy_id;
    *{'DBIx::ThinSQL::db::_split_sql'}          = \&_split_sql;
    *{'DBIx::ThinSQL::db::_load_file'}          = \&_load_file;
    *{'DBIx::ThinSQL::db::run_sql'}             = \&run_sql;
    *{'DBIx::ThinSQL::db::run_arrayref'}        = \&run_arrayref;
    *{'DBIx::ThinSQL::db::run_file'}            = \&run_file;
    *{'DBIx::ThinSQL::db::run_dir'}             = \&run_dir;
    *{'DBIx::ThinSQL::db::_setup_deploy'}       = \&_setup_deploy;
    *{'DBIx::ThinSQL::db::deploy_arrayref'}     = \&deploy_arrayref;
    *{'DBIx::ThinSQL::db::deploy_sql'}          = \&deploy_sql;
    *{'DBIx::ThinSQL::db::deploy_file'}         = \&deploy_file;
    *{'DBIx::ThinSQL::db::deploy_dir'}          = \&deploy_dir;
    *{'DBIx::ThinSQL::db::deployed_table_info'} = \&deployed_table_info;
}

1;
