package Data::OFAC::SDN;
use strict;
use warnings;
use DBI;
use LWP::UserAgent;
use Archive::Extract;
use Carp;
use Text::CSV;
use Data::OFAC::SDN::Schema;

use constant { SDNURL => 'http://www.treasury.gov/ofac/downloads/sdall.zip' };

sub new {
    my $class = shift;

    my %args = @_;

    my $self = bless {}, $class;

    while ( my ( $key, $value ) = each %args ) {
        $self->{$key} = $value;
    }

    # This logic is probably convoluted.

    my $databaseupdated;

    $databaseupdated = -1 unless ( -f $self->{p}->{database_file} );

    $self->{db}
        = Data::OFAC::SDN::Schema->connect(
        "dbi:SQLite:" . $self->{p}->{database_file} )
        unless defined $self->{db};

    if ( defined $databaseupdated && $databaseupdated == -1 ) {

        # Force database update if no file is present.
        $self->updateDatabase;
        $databaseupdated = 1;


    }

    $self->{_lastupdate} = (stat($self->{p}->{database_file}))[9];

    unless ( defined $databaseupdated || $self->{p}->{auto_update} eq '0' ) {

        my $lupdate = $self->{db}->resultset('Lastupdate')
            ->search( {}, { order_by => 'LASTUPDATEDATETIME' } );
        my $lastupdate = $lupdate->single;

        if ( defined $lastupdate
            && ( time() - $lastupdate->lastupdatedatetime )
            >= ( $self->{p}->{auto_update_frequency} * 3600 ) )
        {
            $self->updateDatabase();
        }

        return $self;
    }

    unless ( $self->{_status} && $self->{_status} eq 'dirty') {
        $self->{_status} = 'clean';
    }

    return $self;
}

sub updateDatabase {
    my $self = shift;

    my $lwp = LWP::UserAgent->new();
    $lwp->timeout(10);
    $lwp->env_proxy;

    my $rsp = $lwp->get(SDNURL);

    if ( $rsp->is_success ) {
        $self->buildDatabase( $rsp->decoded_content );
    }
    else {
        $self->{_status} = 'dirty';
    }

    return 1;
}

sub buildDatabase {
    my $self = shift;
    my $zip  = shift;

    if ( $^O eq 'MSWin32' ) {
        $self->{tempdir} = $ENV{TEMP} . '/';
    }
    else {
        # Seriously? WTF People?
        $self->{tempdir} = ($ENV{TMPDIR} || '/tmp') . '/';
    }

    my $sdnzip = ( $self->{tempdir} || '/tmp/' ) . "sdn.zip";

    open( my $fh, ">", $sdnzip )
        or die "Could not open file: " . $!;

    binmode $fh;
    print $fh $zip;
    close $fh;

    my $sdnfiles = ( $self->{tempdir} || '/tmp/' );

    my $ae = Archive::Extract->new( archive => $sdnzip );

    $ae->extract( to => $sdnfiles );

    # Files are not always cased properly, determine the actual files here

    map { $self->{_z}->{lc($_)} = $_ } @{$ae->files};

    map { $self->{_f}->{$_} = $self->{_z}->{$_} } qw{ sdn.csv sdn_comments.csv add.csv alt.csv};

    unless ( scalar keys %{$self->{_f}} == 4 ) { # Exactly four needed
        $self->{_status} = 'dirty';
        return; # Abort
    }

    # Changed to set up a temporary database to make the swap out quick.

    $self->{dbh}
        = DBI->connect( 'dbi:SQLite:' . ( $self->{p}->{database_file} ) . '_temp',
        "", "", { RaiseError => 1 } );

    unless ( $self->{dbh} ) {
        croak "Could not open the SQLite database: " . DBI->errstr();
    }

    $self->SDNTable;
    $self->ALTTable;
    $self->ADDTable;
    $self->LASTUPDATETable;
    $self->SDNCOMMENTSTable;

    $self->{dbh}->disconnect();

    unlink($self->{p}->{database_file});
    rename($self->{p}->{database_file}.'_temp', $self->{p}->{database_file});

    $self->{db}
        = Data::OFAC::SDN::Schema->connect(
        "dbi:SQLite:" . $self->{p}->{database_file} )
        unless defined $self->{db};

    $self->{csv} = Text::CSV->new();


    # Process the SDN Table

    my @cols = qw{ent_num SDN_Name SDN_Type Program Title Call_Sign Vess_type
        Tonnage GRT Vess_flag Vess_owner remarks};

    $self->processTable( $sdnfiles . $self->{_f}->{'sdn.csv'}, 'Sdn', @cols );

    @cols = qw{ent_num SDN_Name SDN_Type Program Title Call_Sign Vess_type
        Tonnage GRT Vess_flag Vess_owner remarks};

    $self->processTable( $sdnfiles . $self->{_f}->{"sdn_comments.csv"},
        'SdnComment', @cols );

    # Process the ADD Table

    @cols
        = qw{ent_num add_num CityStateProvincePostalCode Country Add_remarks};

    $self->processTable( $sdnfiles . $self->{_f}->{"add.csv"}, 'Address', @cols );

    # Process the ALT Table

    @cols = qw{ent_num alt_num alt_type alt_name alt_remarks};

    $self->processTable( $sdnfiles . $self->{_f}->{"alt.csv"}, 'Alt', @cols );

    my $lu = $self->{db}->resultset('Lastupdate')->first;
    $lu->delete if defined $lu;

    $self->{_lastupdate} = time();

    $lu = $self->{db}->resultset('Lastupdate')
        ->create( { lastupdatedatetime => $self->{_lastupdate} } );
    $lu->update;



    return;

}

sub processTable {
    my $self  = shift;
    my $file  = shift;
    my $table = shift;

    my @cols = @_;

    open( my $fh, "<", $file )
        or croak "Could not open the SDN file: " . $file . " ( " . $! . " )";

    while ( my $row = $self->{csv}->getline($fh) ) {

        my $r = $self->{db}->resultset($table)->create(
            {   map {
                    (   lc( $cols[$_] ) => (
                            ( defined $row->[$_] && $row->[$_] eq '-0- ' )
                            ? undef
                            : $row->[$_]
                        )
                        )
                } 0 .. ( scalar(@cols) - 1 )
            }
        );
        $r->update;
    }

    close $fh;

    return;
}

sub SDNTable {
    my $self = shift;

    $self->{dbh}->do("drop table if exists SDN");
    $self->{dbh}->do( "
CREATE TABLE SDN  (
        ent_num   	NUMERIC NOT NULL,
        SDN_Name  	TEXT,
        SDN_Type  	TEXT,
        Program   	TEXT,
        Title     	TEXT,
        Call_Sign 	TEXT,
        Vess_type 	TEXT,
        Tonnage   	TEXT,
        GRT       	TEXT,
        Vess_flag 	TEXT,
        Vess_owner	TEXT,
        remarks   	TEXT,
        sdn_name_phonetic_phonix   TEXT,
        title_phonetic_phonix      TEXT
)" );
    return;
}

sub SDNCOMMENTSTable {
    my $self = shift;

    $self->{dbh}->do("drop table if exists SDN_COMMENTS");
    $self->{dbh}->do( "
CREATE TABLE SDN_COMMENTS  (
        ent_num   	NUMERIC NOT NULL,
        SDN_Name  	TEXT,
        SDN_Type  	TEXT,
        Program   	TEXT,
        Title     	TEXT,
        Call_Sign 	TEXT,
        Vess_type 	TEXT,
        Tonnage   	TEXT,
        GRT       	TEXT,
        Vess_flag 	TEXT,
        Vess_owner	TEXT,
        remarks   	TEXT,
        sdn_name_phonetic_phonix   TEXT,
        title_phonetic_phonix      TEXT
)" );
    return;
}

sub ADDTable {
    my $self = shift;

    $self->{dbh}->do("drop table if exists \"ADDRESS\"");

    $self->{dbh}->do( "
CREATE TABLE \"ADDRESS\"  (
        ent_num                    	NUMERIC NOT NULL,
        add_num                    	NUMERIC NOT NULL,
        CityStateProvincePostalCode	TEXT,
        Country                    	TEXT,
        Add_remarks                	TEXT,
        CityStateProvincePostalCode_phonetic_phonix	TEXT,
        Country_phonetic_phonix                    	TEXT
)" );
    return;
}

sub ALTTable {
    my $self = shift;

    $self->{dbh}->do("drop table if exists ALT");
    $self->{dbh}->do( "
CREATE TABLE ALT  (
        ent_num    	NUMERIC NOT NULL,
        alt_num    	NUMERIC NOT NULL,
        alt_type   	TEXT,
        alt_name   	TEXT,
        alt_remarks	TEXT,
        alt_name_phonetic_phonix   TEXT
)" );
    return;
}

sub LASTUPDATETable {
    my $self = shift;

    $self->{dbh}->do("drop table if exists LASTUPDATE");
    $self->{dbh}->do( "
                     CREATE TABLE LASTUPDATE  (
        LASTUPDATEDATETIME	TEXT
        )" );
    return;
}

sub search {

    my $self   = shift;
    my $table  = shift;
    my $string = shift;
    my $resultset;

    if ( ((time() - $self->{_lastupdate})) >= ( $self->{p}->{auto_update_frequency} * 3600)) {
        $self->updateDatabase();
    }

    my $search = $self->{db}->resultset($table);

    for (@_) {

        my $result = $search->search_phonetic( { $_ => $string } );
        if ( defined $result ) {
            while ( my $record = $result->next ) {
                push @{$resultset},
                    {
                    entitynumber => $record->ent_num,
                    entityhit    => $record->$_
                    };
            }
        }
    }

    return $resultset;
}

sub searchAddress {
    my $self = shift;
    my $csz  = shift;
    my $ctry = shift;

    if ( ((time() - $self->{_lastupdate})) >= ( $self->{p}->{auto_update_frequency} * 3600)) {
        $self->updateDatabase();
    }

    my $search = $self->{db}->resultset('Address');

    my $result = $search->search_phonetic(
        { CityStateProvincePostalCode => $csz, Country => $ctry } );

    my $resultset;

    if ( defined $result ) {
        while ( my $record = $result->next ) {
            push @{$resultset},
                {
                entitynumber => $record->ent_num,
                entityhit    => $self->{db}->resultset('Sdn')
                    ->search( ent_num => $record->ent_num )->first->SDN_Name
                };
        }

    }
    return $resultset;

}

1;
