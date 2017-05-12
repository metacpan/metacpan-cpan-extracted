package DBD::Log;

# hartog/20041208 - 0.10 - created
# hartog/20050114 - 0.20 - made ready for release
# hartog/20050504 - 0.21 - tests added, packaged.
# hartog/20050524 - 0.22 - warnings prevented, loglines altered.

BEGIN {
  $DBD::Log::VERSION = "0.22";
}

use strict;
no strict 'refs';

use Carp qw(croak);

use DBD::Log::Sth;
my %sthCache = ();

use Class::AccessorMaker {
  logThis => [],
  logFH   => "",

  dbiLogging => 0,

  dbi => "",
}, "new_init";

sub init {
  my $self = shift;

  $self->logThis([ qw(insert update delete select create drop) ])
    if !@{$self->logThis};

  if ( !$self->logFH ) {
    croak("DBD::Log: Need an IO::File object to log into");
  }
}

sub logStatement {
  my ( $self, $statement, @rest ) = @_;

  # all references are not to be logged.
  @rest = grep { !ref($_) } @rest;

  # should we even log this?
  my ($command) = lc($statement) =~ /^(\w+)/;
  if ( $self->logThis->[0] ne "all" 
       && !grep { $_ eq $command } @{$self->logThis}
     ) {
    return undef;
  }

  if ( my ( $fullSQL, @sqlRest ) = $self->composeStatement($statement, @rest) ) {
    $self->printLog($fullSQL, @sqlRest);

  } else {
    # we couldn't compile the statement.
    $self->printLog('s', $statement, @rest);
  }
}

sub logAction {
  my ( $function, $self, $statement, @rest ) = @_;

  # do we log DBI actions?
  return undef if !$self->dbiLogging;

  # do we log this statement?
  my ($command) = lc($statement) =~ /^(\w+)/;
  if ( $self->logThis->[0] ne "all"
       && !grep { $_ eq $command } @{$self->logThis}
     ) {
    return undef;
  }

  $self->printLog("[$function]", $statement, @rest);
}

sub composeStatement {
  my ( $self, $statement, @rest ) = @_;

  # can we complete the statement with the values?
  if ( my @parts = split(/\?/, $statement) ) {
    # ? replacement.

    for ( 0..$#parts ) {
      # add quotes if not fully numeric.
      $rest[$_] = "'$rest[$_]'" if $rest[$_] =~ /\D+/;

      # insert the value into the statement.
      $parts[$_] .= $rest[$_];
    }

    # make completed SQL
    $statement = join("", @parts);

    # if there is more to @rest then to @parts make sure to print it.
    @rest = splice(@rest, $#parts+1, $#rest);

    return ( $statement, @rest );

  } elsif ( $statement =~ /\:\w+/ ) {
    # oracle style replacement

  }

  return undef;
}

sub printLog {
  my ( $self, @components ) = @_;

  # print fast and add newlines.
  local $\ = "\n";
  local $| = 1;

  my $fh;
  unless ( $fh = $self->logFH ) {
    warn "No FH to log to! Using STDERR";
    open($fh, ">&STDERR")
  }

  print $fh join("\t", time, map {
    # replace new-lines
    s/[\r\n]+//g;
    # replace tabs.
    s/\t/    /g;

    $_
  } @components);
}

sub prepare {
  my ( $self, $statement, @rest ) = @_;

  # prepare is somewhat special - we want to setup a fake $sth.

  my $action =
    [caller(1)]->[3] && [caller(1)]->[3] =~ /prepare_cached/ ? "prepare_cached" : "prepare";

  logAction($action, @_);

  my $sth = DBD::Log::Sth->new( dbi        => $self->dbi,
				logFH      => $self->logFH,
                                logThis    => $self->logThis,
				dbiLogging => $self->dbiLogging,
				statement  => $statement,
				rest       => [ @rest ],
			      );

  return $sth;
}


sub prepare_cached {
  my ( $self, $statement, @rest ) = @_;
  my $KEY = $statement . $rest[0];

  # let's try to do this caching stuff our selves.

  # prevent warnings.
  exists $sthCache{$self} || ( $sthCache{$self} = {} );

  # return cached STH
  exists $sthCache{$self}->{$KEY} && return $sthCache{$self}->{$KEY};

  my $sth = $self->prepare($statement, @rest);
  $sthCache{$self}->{$KEY} = $sth;

  return $sth;
}

# define the actions that need to be logged.
foreach my $sub ( qw( do selectall_arrayref selectcol_arrayref
		      selectrow_array selectrow_arrayref
		      selectrow_hashref )
		) {

  *{"DBD::Log::$sub"} = sub {
    my ( $self, $statement, @rest ) = @_;

    logAction($sub, @_);
    $self->logStatement($statement, @rest);

    return $self->dbi->$sub($statement, @rest);
  }

}

sub DESTROY {
  my $self = shift;

  # make all cached sth's done.
  foreach ( keys %{$sthCache{$self}} ) {
    $sthCache{$self}->{$_}->destroy;
    $sthCache{$self}->{$_}->DESTROY;
  }

  # clear the cache.
  %sthCache = ();

  $self->dbi->disconnect;
  $self->dbi({});

  $self = undef;
}

sub AUTOLOAD {

  # any of the DBI routines we missed, or want not logged, are
  # autoloaded.

  no strict;

  my ($routine) = $AUTOLOAD =~ /\:\:(\w+)$/;
  my ( $self, @rest ) = @_;

  return $self->dbi->$routine(@rest);
}

1;

__END__

=pod

=head1 NAME

DBD::Log - a logging mechanism for the DBI.

=head1 SYNOPSIS

  use strict;
  use IO::File;
  use DBD::mysql;
  use DBD::Log;

  my $dbh = DBI->connect("DBI:mysql:database=test");

  my $fh = new IO::File "file", O_WRONLY|O_APPEND;
  $dbh = DBD::Log->new( dbi     => $dbh,
			logFH   => $fh,
			logThis => [ 'update', 'select' ],
		      );

  my $sth = $dbh->prepare("UPDATE table SET field=?, other=?, foo=?");
  $sth->execute('green', 'good', 'bar');

  # this logs into 'file':
  #
  # 1105018817    UPDATE table SET field='green', other='good', foo='bar'

  $dbh->dbiLogging(1);
  $sth = $dbh->prepare("SELECT * FROM the_other_table WHERE username LIKE ?");
  $sth->execute('%-idiots');
  $sth->execute('%-guests');

  # this logs
  #
  # 1105018818    [prepare] SELECT * FROM the_other_table WHERE username LIKE ?
  # 1105018818    SELECT * FROM the_other_table WHERE username LIKE '%-idiots'
  # 1105018819    SELECT * FROM the_other_table WHERE username LIKE '%-guests'

=head1 DESCRIPTION

Appends logging to the DBI interface, but limits to the executed
sql-statements. Written to support all the DBD::Drivers out there, but
some (like Oracle) might cause problems.

Do not expect to overload the DBI without any consequences.

=head1 REQUIRMENTS

DBI, DBD::Something, IO::File & Carp

=head1 FUNCTIONS

=head2 logThis()

array-ref of sql-commands (eg: insert, update, delete, etc) to log. If
left empty logs; insert, update, delete, select, create & drop

If set to [ 'all' ] logs everything.

=head2 logFH()

The filehandle used for logging. You must supply your own, since I
just could not figure out if you like to append or overwrite.

=head2 dbiLogging()

0 or 1.

If set to 1 will log all the actions/function-calls of/to the DBI
interface as well.

=head2 dbi()

the $dbh of your script goes in here. $dbh->{LongReadLen} should be
set as $dbi->dbi->{LongReadLen}

=head1 LOGFORMAT

The logs are tab-seperated and in the following format:

  time    ([$function])    statement    @rest

=head2 time

CORE::time of the writedown of the line.

=head2 [$function]

The called DBI function. Only when $self->dbiLogging is TRUE.

=head2 statement.

The compiled statement.

=head2 rest

Any excess parameters to the function that DBD::Log could not parse.

=head1 BUGS / QUIRKS / CAVEATS

=head2 This does not work well with DBD::Something!

I have not had the opportunity, nor the time, to test this package
against all the DBD::Drivers out there. Things might break do to your
specific needs.

=head2 Why is $dbh->{mysql_insertid} empty?

Since the real DBI is stored in ->dbi, all those special flags are
stored there 2. To get to mysql_insert_id(), go fetch
$dbi->dbi->{mysql_insert_id}

=head1 SEE ALSO

L<DBI>, L<DBD::Log::Sth>

=head1 AUTHORS

  Hartog C. de Mik   <hartog@2organize.com>   Lead Developer

=head1 COPYRIGHT

(c) 2004 - 2organize, all rights reserved.
