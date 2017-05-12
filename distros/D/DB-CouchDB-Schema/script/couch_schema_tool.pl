#! /usr/bin/env perl
use DB::CouchDB::Schema;
use Getopt::Long;
use Pod::Usage;

#TODO(jwall): Write POD and convert useage to do pod2useage
my ($dump,$load,$create,
    $backup, $restore,
    $database,$host,$port,$dsn,
    $file,$help,
   );

my $opts = GetOptions ("dump" => \$dump,
                       "load" => \$load,
                       "create" => \$create,
                       "file=s" => \$file,
                       "help"   => \$help,
                       "db=s"     => \$database,
                       "host=s"   => \$host,
                       "port=i"   => \$port,
                       "backup"    => \$backup,
                       "restore"    => \$restore,
                      );

sub useage {
    my $message = shift;
    my $status = shift;
    $status = 2 if (! defined $status );
    $message = "did not understand options!!$/" if (! defined $message );
    pod2usage( -msg => $message,
               -exitval => $status );
}

sub db_args {
    my %dbargs = (db     => $database,
                  host   => $host);
    $dbargs{port} = $port
        if $port;
    return %dbargs;
}

if ( $help ) {
    useage("", 0);
}

if ($create) {
    if ( $host && $database ) {
        my %dbargs = db_args();
        my $db = DB::CouchDB::Schema->new(%dbargs);
        eval {
            $db->create_new_db(db => $database);
        };
        if ($@) {
            useage("failed to create database: $database with error".$@);
        }
        
    } else {
        useage();
    }
}

if ( $host && $database ) {
    my %dbargs = db_args();
    my $db = DB::CouchDB::Schema->new(%dbargs);
    
    if ($dump && $file) {
        open my $fh, '>:encoding(UTF-8)', $file or die $!;
        my $script = $db->dump(1);
        print $fh $script;
        close $fh;
        exit 0;
    } elsif ($load && $file) {
        open my $fh, '>:encoding(UTF-8)', $file or die $!;
        local $/;
        $script = <$fh>;
        print "loading schema: ", $/, $script;
        $db->wipe();
        $db->load_schema_from_script($script);
        $db->push();
        close $fh;
        exit 0;
    } elsif ($backup && $file) {
        # no the backup and restore code
        open my $fh, '>:encoding(UTF-8)', $file or die $!;
        my $script = $db->dump_whole_db();
        print $fh $script;
        close $fh;
        exit 0;
    } elsif ($restore && $file) {
        # no the backup and restore code
        open my $fh, '>:encoding(UTF-8)', $file or die $!;
        local $/;
        $script = <$fh>;
        print "loading data: ", $/, $script;
        $db->wipe();
        $db->push_from_script($script);
        close $fh;
        exit 0;
    } else {
        useage("Did not understand options!! did you specify one of:", $/,
        "--dump, --load, --backup, or --restore with a --file?", $/);
    }
} else {
    useage("Must have a db and a hostname");
}

__END__
=pod

=head1 NAME

couch_schema_tool.pl - tool to help manage a couchdb schema

=head1 SYNOPSIS

    couch_schema_tool.pl --help #  this useage
     
    # dump the schema to filename
    couch_schema_tool.pl --db=name --host=hostname \
    [--port=<port>] \
    --dump --file=filename
    
    # load the schema from the filename
    couch_schema_tool.pl --db=name --host=hostname \
    [--port=<port>] \
    --load --file=filename
    
    # backup the database to this filename
    couch_schema_tool.pl --db=name --host=hostname \
    [--port=<port>] \
    --backup  --file=filename
    
    # restore the database from this filename
    couch_schema_tool.pl --db=name --host=hostname \
    [--port=<port>] \
    --restore  --file=filename
    
    # create a database 
    couch_schema_tool.pl --create --db=name --host=hostname \
    [--port=<port>]
    
    # create a database and load the schema from the filename
    couch_schema_tool.pl --create --db=name --host=hostname \
    [--port=<port>] \
    --load --file=filename

=cut
