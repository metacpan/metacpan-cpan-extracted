=head1 NAME

DBD::iPod::db - the database handle (dbh)

=head1 SYNOPSIS

 #identical, mountpoint is optional
 $dbh = DBI->connect('dbi:iPod:');
 $dbh = DBI->connect('dbi:iPod:/mnt/iPod');

 #use an alternate mountpoints for multiple iPodia
 $dbh1 = DBI->connect('dbi:iPod:/mnt/iPod1');
 $dbh2 = DBI->connect('dbi:iPod:/mnt/iPod2');

You should really read the DBI perldoc if you don't get it.

=head1 DESCRIPTION

Database handle implementation for the iPod.

=head1 AUTHOR

Author E<lt>allenday@ucla.eduE<gt>

=head1 SEE ALSO

L<DBD::_::db>.

=head1 COPYRIGHT AND LICENSE

GPL

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a '_'.  Methods are
in alphabetical order for the most part.

=cut

package DBD::iPod::db;
use strict;
use base qw(DBD::_::db);
our $VERSION = '0.01';

use vars qw($imp_data_size $columns);

use DBI;
use DBD::iPod::parser;
use Data::Dumper;
use SQL::Statement;

$imp_data_size = 0;

$columns = join ', ', sort qw(
                              bitrate
                              fdesc
                              stoptime
                              songs
                              time
                              srate
                              rating
                              cdnum
                              cds
                              playcount
                              starttime
                              id
                              prerating
                              volume
                              songnum
                              path
                              genre
                              filesize
                              artist
                              album
                              comment
                              title
                              uniq
                             );

=head2 prepare()

L<DBI>.

=cut

sub prepare {
  my ($dbh, $statement, @attr) = @_;
  my ($sth, $parsed, $stmt, $ipod, $search, $search_opts);

  ###FIXME yeah, i know, it's a hack
  $statement =~ s/^SELECT\s+\*/SELECT $columns/is;

  my $parser = DBD::iPod::parser->new;

  ($stmt) = eval {
    SQL::Statement->new($statement,$parser);
  };
  if ($@) {
    die "Cannot parse statement: $@";
  }

  # Get the ipod instance
  $ipod = $dbh->FETCH('driver_ipod');

  #
  # FIXME: Mac::iPod::GNUpod doesn't have a method for getting
  # all files nicely, so we look at the internal data structure.
  # Yikes!
  #

  #warn $statement;
  #warn $stmt;
  #warn Dumper($parsed);

  $search = [ grep {defined $_} @{$ipod->{files}}];

  $sth = DBI::_new_sth($dbh, {
                              'Statement'  => $stmt,
                              'iPodSearch' => $search,
                             });

  # ?
  $sth->STORE('driver_params', [ ]);
  return $sth;
}

# ----------------------------------------------------------------------
# These next five methods are taken directly from DBI::DBD
# ----------------------------------------------------------------------

=head2 STORE()

L<DBI>.

=cut

sub STORE {
    my ($dbh, $attr, $val) = @_;
    if ($attr eq 'AutoCommit') {
        return 1;
    }

    if ($attr =~ m/^driver_/) {
        $dbh->{$attr} = $val;
        return 1;
    }

    $dbh->SUPER::STORE($attr, $val);
}

=head2 FETCH()

L<DBI>.

=cut

sub FETCH {
    my ($dbh, $attr) = @_;

    if ($attr eq 'AutoCommit') {
        return 1
    }
    elsif ($attr =~ m/^driver_/) {
        return $dbh->{$attr};
    }

    $dbh->SUPER::FETCH($attr);
}

=head2 commit()

L<DBI>.

=cut

sub commit {
    my $dbh = shift;

    warn "Commit ineffective while AutoCommit is on"
        if $dbh->FETCH('Warn');

    1;
}

=head2 rollback()

L<DBI>.

=cut

sub rollback {
    my $dbh = shift;

    warn "Rollback ineffective while AutoCommit is on"
        if $dbh->FETCH('Warn');

    0;
}

=head2 get_info()

L<DBI>, L<DBD::iPod::GetInfo>.

=cut


sub get_info {
    my($dbh, $info_type) = @_;
    require DBD::iPod::GetInfo;
    my $v = $DBD::iPod::GetInfo::info{int($info_type)};
    $v = $v->($dbh) if ref $v eq 'CODE';
    return $v;
}

1;

__END__
