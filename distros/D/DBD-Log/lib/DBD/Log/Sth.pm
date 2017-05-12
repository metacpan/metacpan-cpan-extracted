package DBD::Log::Sth;

# hartog/20041208
# hartog/20050525 - 0.11 - backtracing added

use base 'DBD::Log';

BEGIN {
  $DBD::Log::Sth::VERSION = "0.11";
}

use strict;
no strict 'refs';

use Class::AccessorMaker {
  dbi => "",
  sth => "",

  statement => "",
  rest      => [],
  bound     => [],

  logFH   => "",
  logThis => [],

  dbiLogging  => 0,
  fullLogging => 0,

}, "new_init";

use Carp qw(croak);

sub init {
  my ( $self, $command, @rest ) = @_;

  $self->sth( $self->dbi->prepare( $self->statement, @{$self->rest}) );
}

sub logCall {
  my ( $function, $self, @rest ) = @_;

  # are we logging this?
  return undef if !$self->dbiLogging;

  my ($command) = lc($self->statement) =~ /^(\w+)/;
  if ( $self->logThis->[0] ne "all"
       && !grep { $_ eq $command } @{$self->logThis}
     ) {
    return undef;
  }

  $self->printLog("[$function]", $self->statement, @rest);
}

sub logAction {
  my ( $function, $self, @rest ) = @_;

  # define logging
  @rest = () if !$self->fullLogging;

  my ($command) = lc($self->statement) =~ /^(\w+)/;
  if ( $self->logThis->[0] ne "all"
       && !grep { $_ eq $command } @{$self->logThis}
     ) {
    return undef;
  }

  if ( $function eq "execute" ) {
    $self->printLog( $self->composeStatement(@{$self->bound}), @rest );

  } elsif ( $function eq "execute_array" ) {
    if ( ref($self->bound->[0]) ) {
      foreach my $bound ( @{$self->bound} ) {
	my @print = $self->composeStatement(@$bound);
	$self->printLog( @print, @rest );
      }

    } else {
      $self->printLog( $self->composeStatement(@{$self->bound}), @rest );
    }
  }

}

sub composeStatement {
  my ( $self, @bound ) = @_;

  my $statement = $self->statement;

  if ( $statement =~ /\?/ ) {
    my @parts = split(/\?/, $statement);

    for ( 0..$#parts ) {
      # skip the parts that are not bound.
      next if !defined $bound[$_];

      # if the bound value is NaN, wrap it in quotes.
      my $val = $bound[$_];
      $val =~ /\D+/ && ( $val = "'$val'" );

      $parts[$_] .= $val;
    }

    $statement = join("", @parts);
    if ( ($#parts+1) < $#bound ) {
      @bound = splice(@bound, $#parts+1, $#bound);
    } else {
      @bound = ();
    }

  } elsif ( $statement =~ /\:\w+/ ) {
    # oracle style replacement

    $statement =~ s/(\:\w+)/&oracleSubstitute($1, \@bound)/eg;
    @bound = ();
  }

  return $statement, @bound
}

sub oracleSubstitute{
  my ( $subst, $bound ) = @_;
  my $var = "";

  my @list = grep { $_->[0] eq $subst } @$bound;
  @list && ( $var = $list[0]->[1] );

  ref($var) =~ /scalar/i && ( $var = $$var );
  $var =~ /\D+/ && ( $var = "'$var'" );
  $var ||= "''";

  return $var;
}

## make multiple routines

# logging actions
foreach my $sub ( qw( execute bind_param execute_array bind_param_array bind_param_inout ) ) {

  *{"DBD::Log::Sth::$sub"} = sub {
    my ( $self, @rest ) = @_;

    my @bound = @{$self->bound};

    if ( $#rest >= 0 ) {

      if ( $sub eq "execute" ) {
	# bind litteral
	@bound = @rest;
      } elsif ( $sub eq "execute_array" ) {
	if ( $#rest >= 1 ) {
	  # bind the array
	  @bound = @rest[1..$#rest];
	}

      } elsif ( $#rest >= 1 && $rest[0] =~ /\D+/ ) {
	# oracle style binding
	# rest[0] = :key
	# rest[1] = value
	push @bound, [@rest];

      } else {
	# rest[0] = index (start at 1).
	# rest[1] = value.
	$bound[$rest[0]-1] = $rest[1];

      }

    }

    $self->bound( [ @bound ] );

    logAction($sub, $self, @bound) if $sub =~ /execute/;
    logCall($sub, @_) if $sub !~ /execute/;

    my $res = $self->sth->$sub(@rest);

    if ( my $error = ( $self->dbi->errstr || $self->sth->errstr ) ) {

      my @backtrace;

      # walk through the backtrace trying to find the error.
      for ( 0..5 ) {
	my ( $package, $filename, $line, @xtra ) = caller($_);

	last if !caller($_);

	if ( $package =~ /dbd/i ) {
	  # this is me - ignore.

	} elsif ( $package =~ /dbi/i ) {
	  # this is the dbi - ignore

	} else {
	  $self->dbi->{dbd_log_error} = "$error in $filename at line $line\n";

	}

	unshift @backtrace, ( "$xtra[0](" .
			      join(", ", @{$xtra[1]}) .
			      ") at $filename line $line."
			    );
      }

      $self->dbi->{dbd_log_backtrace} = join("\n", @backtrace);
    }

    return $res;
  };

}

# non-logging actions
foreach my $sub ( qw( bind_col bind_columns fetchrow_array fetchrow_arrayref
		      fetchall_arrayref fetchrow_hashref fetchall_hashref
		      rows )
		) {

  *{"DBD::Log::Sth::$sub"} = sub {
    my ( $self, @rest ) = @_;
    return $self->sth->$sub(@rest);
  };

}

sub DESTROY {
  # kill the object and return the real sth.
  my $self = shift;
  $self->dbi("");
  $self->sth("");
}

sub AUTOLOAD {

  # any of the DBI routines we missed, or want not logged, are
  # autoloaded.

  no strict;

  my ($routine) = $AUTOLOAD =~ /\:\:(\w+)$/;
  my ( $self, @rest ) = @_;

  return $self->sth->$routine(@rest);
}

1;

__END__

=pod

=head1 NAME

DBD::Log::Sth - Statement Handler as used by DBD::Log

=head1 SYNOPSIS

You could use this, but I guess you want DBD::Log to use this for you.

=head1 DESCRIPTION

Logs the actions of the statement handler. If you have a prepared
statement executed with bind parameters, you would like the compiled
statement in your logfile, right? This does that for you.

=head1 LOGING

=head2 these are logged

execute execute_array bind_param bind_param_array

=head2 these are not

bind_col bind_columns fetchrow_array fetchrow_arrayref
fetchall_arrayref fetchrow_hashref fetchall_hashref rows

=head1 SEE ALSO

L<DBD::Log>

=head1 BUGS / QUIRKS

None, so far.

=head1 CAVEATS

Because the actual call of $sth->whatever() is made inside this
package, the messages you receive from the DBI seem to originate from
DBD/Log/Sth.pm.

This is anoying, therefor a backtrace is created and stored in
DBI->{dbd_log_backtrace}

An attempt is made to find the most suitable entry on the backtrace
and it is stored in DBI->{dbd_log_error}

ATTENTION: please also see the CAVEATS section DBD::Log

=head1 AUTHOR

  Hartog C. de Mik   <hartog@2organize.com>   Lead Developer

=head1 COPYRIGHT

(c) 2004 - 2organize, all rights reserved.
