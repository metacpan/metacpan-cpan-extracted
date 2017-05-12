# ================================================================
package App::iTan::Utils;
# ================================================================
use utf8;
use Moose::Role;
use MooseX::App::Role;
use 5.0100;

use Path::Class;
use Params::Coerce;
use MooseX::Types::Path::Class;
use File::HomeDir;

use Term::ReadKey;
use DBI;
use Crypt::Twofish;
use DateTime;

=head1 NAME

App::iTan::Utils - Utility methods role

=head1 METHODS

=head2 Accessors

=head3 database

Path to the database as a L<Path::Class::File> object.

=head3 dbh

Active database handle

=head3 cipher 

L<Crypt::Twofish> cipher object

=head2 Methods

=head3 get

 my $tandata = $self->get($index);

Fetches a valid iTan with the given index.

=head3 mark

 $self->mark($index[,$memo]);

=head3 crypt_string

 my $crypt = $self->crypt_string($string);

Encrpyts a string

=head3 decrypt_string

 my $string = $self->decrypt_string($crypt);

Decrpyts a string

=cut

option 'database' => (
    is            => 'ro',
    isa           => 'Path::Class::File',
    required      => 1,
    coerce        => 1,
    documentation => q[Path to the iTAN database file. Defaults to ~/.itan],
    default       => sub {
        return Path::Class::File->new( File::HomeDir->my_home, '.itan' );
    },
);

has 'dbh' => (
    is      => 'ro',
    lazy    => 1,
    isa     => 'DBI::db',
    builder => '_build_dbh'
);

has 'cipher' => (
    is      => 'rw',
    lazy    => 1,
    isa     => 'Crypt::Twofish',
    builder => '_build_cipher'
);

#sub DEMOLISH {
#    my ($self) = @_;
#
#    $self->dbh->disconnect();
#    return;
#}

sub _build_dbh {
    my ($self) = @_;

    unless ( -e -f $self->database->stringify ) {
        $self->database->touch
    }

    my $dbh = DBI->connect("dbi:SQLite:dbname=" .$self->database->stringify,"","",{
        RaiseError => 1,
    }) or die "ERROR: Cannot connect: " . $DBI::errstr;


    my @list;
    my $sth = $dbh->prepare('SELECT name 
        FROM sqlite_master 
        WHERE type=? 
        ORDER BY name');
    $sth->execute('table');
    while (my $name = $sth->fetchrow_array) {
        push @list,$name;
    }
    $sth->finish();
    
    unless ( grep { $_ eq 'itan' } @list ) {
        say "Initializing iTAN database ...";

        my $password = $self->_get_password();
        $self->cipher(Crypt::Twofish->new($password));
        my $crypted  = $self->crypt_string($password);
        
        $dbh->do(
            q[CREATE TABLE itan (
                tindex INTEGER NOT NULL, 
                itan VARCHAR NOT NULL, 
                imported VARCHAR NOT NULL, 
                used VARCHAR, 
                valid VARCHAR, 
                memo VARCHAR
            )]
        ) or die "ERROR: Cannot execute: " . $dbh->errstr();
        
        $dbh->do(
            q[CREATE TABLE system (
                name VARCHAR NOT NULL, 
                value VARCHAR NOT NULL
            )]
        ) or die "ERROR: Cannot execute: " . $dbh->errstr();
        
        my $sth = $dbh->prepare(q[INSERT INTO system (name,value) VALUES (?,?)]);
        $sth->execute('password',$crypted);
        $sth->execute('version',$App::iTan::VERSION);
        $sth->finish;
    }

#    $dbh->{'csv_tables'}->{'itan'}
#        = { 'col_names' => [ "tindex", "itan", "imported", "used", "valid", "memo" ] };
#
#    $dbh->{'csv_tables'}->{'system'}
#        = { 'col_names' => [ "name", "value" ] };

    return $dbh;
}

sub _build_cipher {
    my ($self) = @_;

    my $password = $self->_get_password();
    
    my $cipher = Crypt::Twofish->new($password);
    
    $self->cipher($cipher);
    
    my $stored_password = $self->dbh->selectrow_array("SELECT value FROM system WHERE name = 'password'")   
        or die "ERROR: Cannot query: " . $self->dbh->errstr();
    
    unless ( $self->decrypt_string($stored_password) eq $password) {
        die "ERROR: Invalid password";
    }
    
    return $cipher;
}

sub _parse_date {
    my ( $self, $date ) = @_;

    return
        unless defined $date && $date =~ m/^
            (?<year>\d{4})
            \/
            (?<month>\d{1,2})
            \/
            (?<day>\d{1,2})
            \s
            (?<hour>\d{1,2})
            :
            (?<minute>\d{1,2})
            $/x;

    return DateTime->new(
        year   => $+{year},
        month  => $+{month},
        day    => $+{day},
        hour   => $+{hour},
        minute => $+{minute},
    );
}

sub crypt_string {
    my ( $self, $string ) = @_;

    use bytes;
    while (1) {
        last if length($string) % 16 == 0;
        $string .= ' ';
    }

    return $self->cipher->encrypt($string);
}

sub decrypt_string {
    my ( $self, $data ) = @_;

    my $tan = $self->cipher->decrypt($data);
    $tan =~ s/\s+//g;
    return $tan;
}

sub _date {
    return DateTime->now->format_cldr('yyyy/MM/dd HH:mm');
}

sub _get_password {
    my $password;

    ReadMode 2;
    say 'Please enter your password:';
    while ( not defined( $password = ReadLine(-1) ) ) {
        # no key pressed yet
    }
    ReadMode 0;
    chomp($password);

    my $length;
    {
        use bytes;
        $length = length $password;
    }
    
    if ($length == 16) {
        # ok
    } elsif ($length < 4) {
        die('ERROR: Password is too short (Min 4 bytes required)');
    } elsif ($length > 16) {
        die('ERROR: Password is too long (Max 16 bytes allowed)');
    } else {
        while (1) {
            $password .= '0';
            last 
                if length $password == 16;
        }
    }
    
    return $password;
}

sub get {
    my ($self,$index) = @_;
    
    my $sth = $self->dbh->prepare('SELECT 
            tindex,
            itan,
            imported,
            used,
            memo 
        FROM itan 
        WHERE tindex = ? 
        AND valid = 1')
        or die "ERROR: Cannot prepare: " . $self->dbh->errstr();
    $sth->execute($index)
        or die "ERROR: Cannot execute: " . $sth->errstr();
    
    my $data = $sth->fetchrow_hashref();
    
    unless (defined $data) {
        die "ERROR: Could not find iTAN  ".$index;
    }

    $data->{imported} = $self->_parse_date($data->{imported});
    $data->{used} = $self->_parse_date($data->{used});
    #$data->{itan} = $self->decrypt_tan($data->{itan}); 
    
    return $data;
}

sub mark {
    my ($self,$index,$memo) = @_;
    
    my $sth = $self->dbh->prepare(
        q[UPDATE itan SET used = ?,memo = ?, valid = 0 WHERE tindex = ?]
    ) or die "ERROR: Cannot prepare: " . $self->dbh->errstr();
    
    $sth->execute($self->_date,$memo,$index)
       or die "ERROR: Cannot execute: " . $sth->errstr(); 
    
    $sth->finish();
    
    return 1;
}

1;
