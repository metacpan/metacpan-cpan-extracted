package Bot::BasicBot::Pluggable::Module::Notes::Store::DBIC;

use strict;
use warnings;

use Carp;
use Bot::BasicBot::Pluggable::Module::Notes::Store::DBIC::Schema;
use DBIx::Class::ResultClass::HashRefInflator;
use Data::Dumper 'Dumper';

my $dsn = 'dbi:SQLite';

sub new {
    my ($class, $db_file) = @_;

    my $schema = Bot::BasicBot::Pluggable::Module::Notes::Store::DBIC::Schema->connect("${dsn}:$db_file");

    my $self = {};
    bless $self, $class;

    $self->{schema} = $schema;
    $self->ensure_db_schema_correct or die "Database not initialised";
    return $self;
    
}

sub ensure_db_schema_correct {
    my ($self) = @_;

    my $dbh = $self->dbh;
    my $notes_table = $self->{schema}->source('Note')->name;

    my $sql = "SELECT name FROM sqlite_master WHERE type='table'
               AND name=?";
    my $sth = $dbh->prepare($sql)
      or croak "ERROR: " . $dbh->errstr;
    $sth->execute($notes_table);

    my ($ok) = $sth->fetchrow_array;
    return 1 if $ok;

    $self->{schema}->deploy;
    return 1;
}

sub dbh {
    my ($self) = @_;

    return $self->{schema}->storage->dbh;
}

sub store {
    my ($self, %args) = @_;
    
    $args{tags} ||= [];
    $args{tags} = [ map { +{tag => lc($_)} } @{$args{tags}} ];
    
    my $note = $self->{schema}->resultset('Note')->create( 
        {
            %args
        });
    
    return $note;
}

sub get_notes {
    my ($self, %args) = @_;

    my %opts;
    for (qw<page rows>) {
        if (exists $args{$_}) {
            $opts{$_} = delete $args{$_};
        }
    }

    if(exists $args{tags}) {
        ## We want to create: select * from notes where id IN (select matching rows from tags)
        ## .. but only where tags search was asked for
        my $tag_search = $self->{schema}->resultset('Tag')->search(
            {
                'me.tag' => [ @{ delete $args{tags} } ]
            },
            {
                columns => ['note_id'],
            }
            );
        $args{id} = { '-in' => $tag_search->as_query };
    }
#    warn "dbic get_notess: ".Dumper([\%args, \%opts]);

    my $rs = $self->{schema}->resultset('Note')->search(\%args, \%opts);
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');

    my $ret = [$rs->all];
    #warn Dumper($ret);
    return $ret;
}

1;
