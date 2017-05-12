package Ace::Local;

require 5.004;

use strict;
use IPC::Open2;
use Symbol;
use Fcntl qw/F_SETFL O_NONBLOCK/;

use vars '$VERSION';

$VERSION = '1.05';

use Ace qw/rearrange STATUS_WAITING STATUS_PENDING STATUS_ERROR/;
use constant DEFAULT_HOST=>'localhost';
use constant DEFAULT_PORT=>200005;
use constant DEFAULT_DB=>'/usr/local/acedb';

# Changed readsize to be 4k rather than 5k.  Most flavours of UNIX
# have a page size of 4kb or a multiple thereof.  It improves
# efficiency to read an integer number of pages
# -- tim.cutts@incyte.com 08 Sep 1999

use constant READSIZE   => 1024 * 4;  # read 4k units

# this seems gratuitous, but don't delete it just yet
# $SIG{'CHLD'} = sub { wait(); } ;

sub connect {
  my $class = shift;
  my ($path,$program,$host,$port,$nosync) = rearrange(['PATH','PROGRAM','HOST','PORT','NOSYNC'],@_);
  my $args;
  
  # some pretty insane heuristics to handle BOTH tace and aceclient
  die "Specify either -path or -host and -port" if ($program && ($host || $port));
  die "-path is not relevant for aceclient, use -host and/or -port"
    if defined($program) && $program=~/aceclient/ && defined($path);
  die "-host and -port are not relevant for tace, use -path"
    if defined($program) && $program=~/tace/ and (defined $port || defined $host);
  
  # note, this relies on the programs being included in the current PATH
  my $prompt = 'acedb> ';
  if ($host || $port) {
    $program ||= 'aceclient';
    $prompt = "acedb\@$host> ";
  } else {
    $program ||= 'giface';
  }
  if ($program =~ /aceclient/) {
    $host ||= DEFAULT_HOST;
    $port ||= DEFAULT_PORT;
    $args = "$host -port $port";
  } else {
    $path ||= DEFAULT_DB;
    $path = _expand_twiddles($path);
    $args = $path;
  }
  
  my($rdr,$wtr) = (gensym,gensym);
  my($pid) = open2($rdr,$wtr,"$program $args");
  unless ($pid) {
    $Ace::Error = <$rdr>;
    return undef;
  }

  # Figure out the prompt by reading until we get zero length,
  # then take whatever's at the end.
  unless ($nosync) {
    local($/) = "> ";
    my $data = <$rdr>;
    ($prompt) = $data=~/^(.+> )/m;
    unless ($prompt) {
      $Ace::Error = "$program didn't open correctly";
      return undef;
    }
  }

  return bless {
		'read'   => $rdr,
		'write'  => $wtr,
		'prompt' => $prompt,
		'pid'    => $pid,
		'auto_save' => 1,
		'status' => $nosync ? STATUS_PENDING : STATUS_WAITING,  # initial stuff to read
	       },$class;
}

sub debug {
  my $self = shift;
  my $d = $self->{debug};
  $self->{debug} = shift if @_;
  $d;
}

sub DESTROY {
  my $self = shift;
  return unless kill 0,$self->{'pid'};
  if ($self->auto_save) {
    # save work for the user...
    $self->query('save'); 
    $self->synch;
  }
  $self->query('quit');

  # just for paranoid reasons. shouldn't be necessary
  close $self->{'write'} if $self->{'write'};  
  close $self->{'read'}  if $self->{'read'};
  waitpid($self->{pid},0) if $self->{'pid'};
}

sub encore {
  my $self = shift;
  return $self->status == STATUS_PENDING;
}

sub auto_save {
  my $self = shift;
  $self->{'auto_save'} = $_[0] if defined $_[0];
  return $self->{'auto_save'};
}

sub status {
  return $_[0]->{'status'};
}

sub error {
  my $self = shift;
  return $self->{'error'};
}

sub query {
  my $self = shift;
  my $query = shift;
  warn "query($query)\n" if $self->debug;
  if ($self->debug) {
    my $msg = $query || '';
    warn "\tquery($msg)";
  }

  return undef if $self->{'status'} == STATUS_ERROR;
  do $self->read() until $self->{'status'} != STATUS_PENDING;
  my $wtr = $self->{'write'};
  print $wtr "$query\n";
  $self->{'status'} = STATUS_PENDING;
}

sub low_read {  # hack to accomodate "uninitialized database" warning from tace
  my $self = shift;
  my $rdr = $self->{'read'};
  return undef unless $self->{'status'} == STATUS_PENDING;
  my $rin = '';
  my $data = '';
  vec($rin,fileno($rdr),1)=1;
  unless (select($rin,undef,undef,1)) {
    $self->{'status'} = STATUS_WAITING;
    return undef;
  }
  sysread($rdr,$data,READSIZE);
  return $data;
}

sub read {
  my $self = shift;
  return undef unless $self->{'status'} == STATUS_PENDING;
  my $rdr  = $self->{'read'};
  my $len  = defined $self->{'buffer'} ? length($self->{'buffer'}) : 0;
  my $plen = length($self->{'prompt'});
  my ($result, $bytes, $pos, $searchfrom);

  while (1) {

    # Read the data directly onto the end of the buffer

    $bytes = sysread($rdr, $self->{'buffer'},
		     READSIZE, $len);

    unless ($bytes > 0) {
      $self->{'status'} = STATUS_ERROR;
      return;
    }

    # check for prompt

    # The following checks were implemented using regexps and $' and
    # friends.  I have changed this to use {r}index and substr (a)
    # because they're much faster than regexps and (b) because using
    # $' and $` causes all regexps in a program to execute
    # very slowly due to excessive and unnecessary pre/post-match
    # copying -- tim.cutts@incyte.com 08 Sep 1999

    # Note, don't need to search the whole buffer for the prompt;
    # just need to search the new data and the prompt length from
    # any previous data.

    $searchfrom = ($len <= $plen) ? 0 : ($len - $plen);

    if (($pos = index($self->{'buffer'},
		      $self->{'prompt'},
		      $searchfrom)) > 0) {
      $self->{'status'} = STATUS_WAITING;
      $result = substr($self->{'buffer'}, 0, $pos);
      $self->{'buffer'} = '';
      return $result;
    }

    # return partial results for paragraph breaks

    if (($pos = rindex($self->{'buffer'}, "\n\n")) > 0) {
      $result = substr($self->{'buffer'}, 0, $pos + 2);
      $self->{'buffer'} = substr($self->{'buffer'},
				 $pos + 2);
      return $result;
    }

    $len += $bytes;

  }

  # never get here
}

# just throw away everything
sub synch {
  my $self = shift;
  $self->read() while $self->status == STATUS_PENDING;
}

# expand ~foo syntax
sub _expand_twiddles {
  my $path = shift;
  my ($to_expand,$homedir);
  return $path unless $path =~ m!^~([^/]*)!;

  if ($to_expand = $1) {
    $homedir = (getpwnam($to_expand))[7];
  } else {
    $homedir = (getpwuid($<))[7];
  }
  return $path unless $homedir;

  $path =~ s!^~[^/]*!$homedir!;
  return $path;
}

__END__

=head1 NAME

Ace::Local - use giface, tace or gifaceclient to open a local connection to an Ace database

=head1 SYNOPSIS

  use Ace::Local
  my $ace = Ace::Local->connect(-path=>'/usr/local/acedb/elegans');
  $ace->query('find author Se*');
  die "Query unsuccessful" unless $ace->status;
  $ace->query('show');
  while ($ace->encore) {
    print $ace->read;
  }

=head1 DESCRIPTION

This class is provided for low-level access to local (non-networked)
Ace databases via the I<giface> program.  You will generally not need
to access it directly.  Use Ace.pm instead.

For the sake of completeness, the method can also use the I<aceclient>
program for its access.  However the Ace::AceDB class is more efficient
for this purpose.

=head1 METHODS

=head2 connect()

  $accessor = Ace::Local->connect(-path=>$path_to_database);

Connect to the database at the indicated path using I<giface> and
return a connection object (an "accessor").  I<Giface> must be on the
current search path.  Multiple accessors may be open simultaneously.

Arguments include:

=over 4

=item B<-path>

Path to the database (location of the "wspec/" directory).

=item B<-program>

Used to indicate the location of the desired I<giface> or
I<gifaceclient> executable.  You may also use I<tace> or I<aceclient>,
but in that case the asGIF() functionality will nog work.  Can be used
to override the search path.

=item B<-host>

Used when invoking I<gifaceclient>.  Indicates the host to connect to.

=item B<-port>

Used when invoking I<gifaceclient>.  Indicates the port to connect to.

=item B<-nosync>

Ordinarily Ace::Local synchronizes with the tace/giface prompt,
throwing out all warnings and copyright messages.  If this is set,
Ace::Local will not do so.  In this case you must call the low_read()
method until it returns undef in order to synchronize.

=back

=head2 query()

  $status = $accessor->query('query string');

Send the query string to the server and return a true value if
successful.  You must then call read() repeatedly in order to fetch
the query result.

=head2 read()

Read the result from the last query sent to the server and return it
as a string.  ACE may return the result in pieces, breaking between
whole objects.  You may need to read repeatedly in order to fetch the
entire result.  Canonical example:

  $accessor->query("find Sequence D*");
  die "Got an error ",$accessor->error() if $accessor->status == STATUS_ERROR;
  while ($accessor->status == STATUS_PENDING) {
     $result .= $accessor->read;
  }

=head2 low_read()

Read whatever data's available, or undef if none.  This is only used
by the ace.pl replacement for giface/tace.

=head2 status()

Return the status code from the last operation.  Status codes are
exported by default when you B<use> Ace.pm.  The status codes you may
see are:

  STATUS_WAITING    The server is waiting for a query.
  STATUS_PENDING    A query has been sent and Ace is waiting for
                    you to read() the result.
  STATUS_ERROR      A communications or syntax error has occurred

=head2 error()

May return a more detailed error code supplied by Ace.  Error checking
is not fully implemented.

=head2 encore()

This method will return true after you have performed one or more
read() operations, and indicates that there is more data to read.
B<encore()> is functionally equivalent to:

   $encore = $accessor->status == STATUS_PENDING;

In fact, this is how it's implemented.

=head2 auto_save()

Sets or queries the I<auto_save> variable.  If true, the "save"
command will be issued automatically before the connection to the
database is severed.  The default is true.

Examples:

   $accessor->auto_save(1);
   $flag = $accessor->auto_save;

=head1 SEE ALSO

L<Ace>, L<Ace::Object>, L<Ace::Iterator>, L<Ace::Model>

=head1 AUTHOR

Lincoln Stein <lstein@w3.org> with extensive help from Jean
Thierry-Mieg <mieg@kaa.crbm.cnrs-mop.fr>

Copyright (c) 1997-1998, Lincoln D. Stein

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut
