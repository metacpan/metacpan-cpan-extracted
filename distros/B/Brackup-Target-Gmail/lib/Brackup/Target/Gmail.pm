package Brackup::Target::Gmail;

use strict;
use Net::FS::Gmail;
use File::Temp qw/tempfile/;
use base 'Brackup::Target';

our $VERSION = "0.1";
our $CACHE_TABLE = "gmail_key_exists";

=head1 NAME

Brackup::Target::Gmail - a GMail target to Brackup

=head1 SYNOPSIS

See Brackup for a details

=head1 EXTREMELY SERIOUS WARNING AND GENERAL ASS COVERING

This is completely alpha software. It hasn't even been tested properly. 

It will almost certainly destroy all your data then come round your house,
empty any the bags of flour all over the kitchen, kick in your TV, 
scratch the screen of your iPod Nano, get jam fingerprints on your favourite
limited edition "Me First and the Gimmie Gimmies" CDs and then urinate in
your laundry basket.

In fact, to paraphrase Neal Stephenson: Unless you are as smart as Johann Karl 
Friedrich Gauss, savvy as a half-blind Calcutta bootblack, tough as General 
William Tecumseh Sherman, rich as the Queen of England, emotionally resilient as 
a Red Sox fan, and as generally able to take care of yourself as the average 
nuclear submarine commander, you should never have been allowed near this module. 
Please dispose of it as you would any piece of high-level radioactive waste and 
then arrange with a qualified surgeon to amputate your arms at the elbows and gouge 
your eyes from their sockets. 

If you ignore this warning, read on at your peril -- you are dead certain to lose 
everything you've got and live out your final decades beating back waves of termites 
in a Mississippi Delta leper colony.

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2006, Simon Wistow

Distributed under the same terms as Perl itself.

=cut

# NOTE
# the cache stuff is ripped off Brackup::Target::Amazon
# and could probably be merged to give a generic hash implementation


sub new {
    my ($class, $confsec) = @_;
    my $self = bless {}, $class;
    my $user  = $confsec->value("gmail_username");
    my $pass  = $confsec->value("gmail_password");
    $self->{_gmail} = Net::FS::Gmail->new( username => "$user", password => "$pass" );

    if (my $cache_file = $confsec->value("exist_cache")) {
        $self->{dbh} = DBI->connect("dbi:SQLite:dbname=$cache_file","","", { RaiseError => 1, PrintError => 0 }) or
            die "Failed to connect to SQLite filesystem digest cache database at $cache_file: " . DBI->errstr;

        eval {
            $self->{dbh}->do("CREATE TABLE ${CACHE_TABLE} (key TEXT PRIMARY KEY, value TEXT)");
        };
        die "Error: $@" if $@ && $@ !~ /table ${CACHE_TABLE} already exists/;
    }



    return $self;
}


# returns bool
sub has_chunk {
    my ($self, $chunk) = @_;
    my $dig = $chunk->backup_digest;   # "sha1:sdfsdf" format scalar

    if (my $dbh = $self->{dbh}) {
        my $ans = $dbh->selectrow_array("SELECT COUNT(*) FROM ${CACHE_TABLE} WHERE key=?", undef, $dig);
        warn "gmail database for $dig is = $ans\n";
        return 1 if $ans;
    }

    my %files = eval { map { $_ => 1 } $self->{_gmail}->files() };
    my $ret = !$@ && exists $files{$dig};
    $self->_cache_existence_of($dig) if ($ret);
    return $ret;

}


sub _cache_existence_of {
    my ($self, $dig) = @_;
    if (my $dbh = $self->{dbh}) {
        $dbh->do("INSERT INTO ${CACHE_TABLE} VALUES (?,1)", undef, $dig);
    }
}

# returns true on success, or returns false or dies otherwise.
sub store_chunk {
    my ($self, $chunk) = @_;
    my ($fh, $filename) = tempfile( UNLINK => 1 );
    print $fh ${ $chunk->chunkref };
    close($fh);
    $self->{_gmail}->store($filename, $chunk->backup_digest);
}

sub store_backup_meta {
    my ($self, $name, $file) = @_;
    my ($fh, $filename) = tempfile( UNLINK => 1 );
    print $fh $file;
    close($fh);
    $self->{_gmail}->store($filename, $name);

}

1;
