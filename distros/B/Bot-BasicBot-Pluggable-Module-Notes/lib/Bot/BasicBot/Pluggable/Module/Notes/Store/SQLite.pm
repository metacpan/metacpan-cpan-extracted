package Bot::BasicBot::Pluggable::Module::Notes::Store::SQLite;

use strict;
use Data::Dumper;
use DateTime::Format::Strptime;
use vars qw( $VERSION );
$VERSION = '0.02';

# use base qw(Bot::BasicBot::Pluggable::Module);

use Carp;
use DBD::SQLite;

=head1 NAME

Bot::BasicBot::Pluggable::Module::Notes::Store::SQLite - SQLite storage for Bot::BasicBot::Pluggable::Module::Notes.

=head1 SYNOPSIS

  use Bot::BasicBot::Pluggable::Module::Notes::Store::SQLite;

  my $blog_store =
    Bot::BasicBot::Pluggable::Module::Notes::Store::SQLite->new(
      "/home/bot/brane.db" );

=head1 DESCRIPTION

Store notes in a sqlite database for
L<Bot::BasicBot::Pluggable::Module::Notes>.

=head1 METHODS

=over 4

=item B<new>

  my $blog_store =
    Bot::BasicBot::Pluggable::Module::Notes::Store::SQLite->new(
      "/home/bot/brane.db" );

You must supply a filename writeable by the user the bot runs as. The
file need not already exist; it will be created and the correct
database schema set up as necessary.

Croaks if L<DBD::SQLite> fails to connect to the file.

=cut

use constant TABLENAME => 'notes';

sub new {
    my ($class, $filename) = @_;

    my $dbh = DBI->connect("dbi:SQLite:dbname=$filename", "", "",
        {RaiseError => 1, AutoCommit => 1})
      or croak "ERROR: Can't connect to sqlite database: " . DBI->errstr;

    my $self = { };
    bless $self, $class;

    $self->{dbh} = $dbh;
    $self->ensure_db_schema_correct or return;
    return $self;
}

=item B<dbh>

  my $dbh = $store->dbh;

Returns the store's database handle.

=cut

sub dbh {
    my $self = shift;
    return $self->{dbh};
}

sub ensure_db_schema_correct {
    my $self = shift;
    my $dbh  = $self->{dbh};

    my $sql = "SELECT name FROM sqlite_master WHERE type='table'
               AND name=?";
    my $sth = $dbh->prepare($sql)
      or croak "ERROR: " . $dbh->errstr;
    $sth->execute(TABLENAME());
    my ($ok) = $sth->fetchrow_array;
    return 1 if $ok;

    $dbh->do("CREATE TABLE " . TABLENAME() . 
         "( id INTEGER PRIMARY KEY, timestamp text, name text, channel text, notes text )" )
      or croak "ERROR: " . $dbh->errstr;
    return 1;
}

=item B<store>

  $store->store( timestamp => $timestamp,
                 name      => $who,
                 channel   => $channel,
                 notes     => $message);

Stores the given information in the database.  Croaks on error.

=cut

sub store {
    my ($self, %args) = @_;
    my $dbh = $self->{dbh};

    my $sth = $dbh->prepare( qq{
        INSERT INTO } . TABLENAME() . q{ (timestamp, name, channel, notes)
               VALUES (?, ?, ?, ?)
    }) or croak "Error: can't prepare db query for insert: " . $dbh->errstr;

    $sth->execute( @args{ qw( timestamp name channel notes ) } )
      or croak "Error: can't insert into database: " . $dbh->errstr;

    return 1;
}

sub get_notes {
    my ($self, %args) = @_;

#    warn Data::Dumper::Dumper(\%args);
    my $dbh = $self->{dbh};

    my %allowed = map { ($_ => 1) } ( qw/datetime channel name notes/ );
    my @select_vals = ();
    my @select_keys = ();

    foreach my $arg (keys %args) {
        if ($arg && defined $args{$arg} && exists $allowed{$arg}) {
            push @select_keys, "$arg LIKE ?"; 
            push @select_vals, $args{$arg}; 
        }
    }
    my $where_extra = " channel <> 'msg' " if(!$args{private});
    my $where = join(' AND ', @select_keys, $where_extra);

    my $page = $args{page} || 1;
    my $limit = $args{rows} || 10;
    
    my $sql = qq{
        SELECT id, timestamp, channel, name, notes FROM } 
        . TABLENAME() 
        . ($where ? " WHERE $where" : '') 
        . q{ ORDER BY } . ($args{order_ind} || 'channel') . " " . ($args{sort_order} || 'DESC')
# channel, timestamp desc}
        . q{ LIMIT } . ($limit * $page - $limit) . ', ' . $limit;
    #warn "SQLite: <<$sql>>" ;
    my $sth = $dbh->prepare($sql
    ) or croak "Error: can't prepare db query for select: " . $dbh->errstr;

    $sth->execute( @select_vals );

    my $notes = $sth->fetchall_arrayref({});

#   warn "Notes: ", Dumper($notes);

    ## hack to fake date/time fields:
    my $dt_formatter = DateTime::Format::Strptime->new( pattern => '%F %T',
                                                        locale => 'en_GB',
                                                        time_zone => 'UTC'
        );
    foreach my $row (@$notes){
        my $dt = $dt_formatter->parse_datetime( $row->{timestamp} )
            or die "Badly formatted timestamp: $row->{timestamp}";
        $row->{date} = $dt->ymd;
        $row->{time} = $dt->hms;
    }

#    warn "Notes: ", Dumper($notes);
    return $notes;
}

=head1 BUGS

No retrieval methods yet.

=head1 SEE ALSO

=over 4

=item * L<Bot::BasicBot::Pluggable::Module::Notes>

=back

=head1 AUTHOR

Jess Robinson <castaway@desert-island.me.uk>

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
