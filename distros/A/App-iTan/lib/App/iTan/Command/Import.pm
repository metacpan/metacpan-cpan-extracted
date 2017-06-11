# ================================================================
package App::iTan::Command::Import;
# ================================================================
use utf8;
use Moose;
use 5.0100;

use MooseX::App::Command;
with qw(App::iTan::Utils);

option 'file' => (
    is            => 'ro',
    isa           => 'Path::Class::File',
    required      => 1,
    coerce        => 1,
    documentation => q[Path to a file containing the iTANs to be imported],
);

option 'deletefile' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
    documentation => q[Delete import file after a successfull import],
);

option 'overwrite' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
    documentation => q[Overwrite duplicate index numbers],
);


sub execute {
    my ( $self, $opts, $args ) = @_;

    my @itans = $self->file->slurp(chomp => 1)
        or die ('Cannot read file '.$self->file->stringify);

    my $date = $self->_date();

    say "Start importing iTan ...";

    my $sth = $self->dbh->prepare("INSERT INTO itan (tindex,itan,imported,valid,used,memo) VALUES (?,?,'$date',1,NULL,NULL)")
        or die "ERROR: Cannot prepare: " . $self->dbh->errstr();

    foreach my $line (@itans) {
        my ($index,$tan);
        unless ($line =~ m/^(?<index>\d{1,4})\D+(?<tan>\d{4,8})$/) {
            say "... did not import '$line' (could not parse)";
        } else {
            $index = $+{index};
            $tan   = $self->crypt_string( $+{tan} );
            if ($index eq '0') {
                my $nextindex = $self->dbh->selectrow_array("SELECT MAX(tindex) FROM itan WHERE valid = 1");
                $nextindex ++;
                $index = $nextindex;
            }
            eval {
                $self->get($index);
            };
            if ($@) {
                say "... import $index";
                $sth->execute($index,$tan)
                     or die "Cannot execute: " . $sth->errstr();
            } elsif ($self->overwrite) {
                $self->dbh->do('UPDATE itan SET valid = 0 WHERE tindex = '.$index)
                    or die "ERROR: Cannot execute: " . $self->dbh->errstr();
                say "... import $index (overwrite old index)";
                $sth->execute($index,$tan)
                     or die "Cannot execute: " . $sth->errstr();
            } else {
                say "... did not import $index (duplicate index)";
            }
        }
    }
    $sth->finish();

    if ($self->deletefile) {
        $self->file->remove();
    }

    return;
}

__PACKAGE__->meta->make_immutable;
1;

=pod

=encoding utf8

=head1 NAME

App::iTan::Command::Import - Imports a list of iTans into the database

=head1 SYNOPSIS

 itan import --file IMPORT_FILE [--deletefile] [--overwrite]

=head1 DESCRIPTION

Imports a list of iTans into the database form a file with one iTAN per line.

The file must contain two columns (separated by any non numeric characters).
The first  column must be the index number. The second column must be the tan
number. If your online banking application does not use index numbers just set
the first column to zero.

 10 434167
 11 937102
 OR
 0 320791
 0 823602

=head1 OPTIONS

=head2 file

Path to a file containing the iTANs to be imported.

=head2 deletefile

Delete import file after a successfull import

=head2 overwrite

Overwrite duplicate index numbers.

Index numbers must be unique. Default behaviour is to skip duplicate iTan
indices. When this flag is enabled the duplicate iTans will be overwritten.

=cut