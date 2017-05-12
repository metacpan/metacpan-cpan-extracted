package CPAN::Search::Lite::PPM;
use strict;
use LWP::UserAgent;
use SOAP::Lite;
use LWP::Simple;
use HTTP::Date;
use XML::SAX;
use CPAN::Search::Lite::Util qw($repositories has_data);
use CPAN::Search::Lite::DBI::Index;
use CPAN::Search::Lite::DBI qw($dbh);
our $VERSION = 0.77;

our $dbh = $CPAN::Search::Lite::DBI::dbh;
our %wanted = map {$_ => 1} qw(SOFTPKG ABSTRACT ARCHITECTURE);
our $arch = '';
my %arch = ('5.6' => 'MSWin32-x86-multi-thread',
	    '5.8' => 'MSWin32-x86-multi-thread-5.8',
	   );

my %months = ('Jan' => '01',
	      'Feb' => '02',
	      'Mar' => '03',
	      'Apr' => '04',
	      'May' => '05',
	      'Jun' => '06',
	      'Jul' => '07',
	      'Aug' => '08',
	      'Sep' => '09',
	      'Oct' => '10',
	      'Nov' => '11',
	      'Dec' => '12',
	     );
my @tries = qw(searchsummary.ppm package.lst);

sub new {
    my ($class, %args) = @_;
    foreach (qw(db user passwd dists) ) {
      die "Must supply a '$_' argument" unless defined $args{$_};
    }
    my $cdbi = CPAN::Search::Lite::DBI::Index->new(%args);
    my $self = {dists => $args{dists}, ppms => {}, setup => $args{setup},
		curr_mtimes => {}, update_mtimes => {}};
    bless $self, $class;
}

sub fetch_info {
  my $self = shift;
  unless ($self->{setup}) {
    $self->fetch_mtime() or return;
  }
  my $dists = $self->{dists};
  my $ppm = {};
  for my $id (keys %$repositories) {
    my $location = $repositories->{$id}->{LOCATION};
    print "Getting ppm information from $location\n";
    my $packages = $self->summary($id, $location);
    next unless $packages;
    if (ref($packages) eq 'HASH') {
      foreach my $package (keys %$packages) {
	next unless $dists->{$package};
	my $version = ppd2cpan_version($packages->{$package}->{version});
	my $abstract = $packages->{$package}->{abstract};
	$dists->{$package}->{description} = $abstract
	  unless $dists->{$package}->{description};
	$ppm->{$id}->{$package} = {
				   version => $version,
				   abstract => $abstract,
				  };
      }
    }
    else {
      $ppm->{$id} = 1;
    }
  }
  $self->{ppms} = $ppm;
  $self->update_mtime() if (has_data($self->{update_mtimes}));
  return 1;
}

sub fetch_mtime {
  my $self = shift;
  my $mtimes = {};
  unless ($dbh) {
    $self->{error_msg} = q{No db handle available};
    return;
  }
  my $sql = q{ SELECT rep_id,mtime FROM reps };
  my $sth = $dbh->prepare($sql);
  $sth->execute() or do {
    $self->db_error($sth);
    return;
  };
  while (my ($rep_id, $mtime) = $sth->fetchrow_array) {
    next unless $rep_id;
    $mtimes->{$rep_id} = $mtime;
  }
  $sth->finish;
  $self->{curr_mtimes} = $mtimes;
  return 1;
}

sub update_mtime {
  my $self = shift;
  my $mtimes = $self->{update_mtimes};
  unless ($dbh) {
    $self->{error_msg} = q{No db handle available};
    return;
  }
  my $sth;
  foreach my $id(keys %$mtimes) {
    my $mtime = $mtimes->{$id};
    next unless (defined $id and defined $mtime);
    my $sql = q{ UPDATE LOW_PRIORITY reps } .
      qq{ SET mtime="$mtime" WHERE rep_id=$id};
    $sth = $dbh->prepare($sql);
    $sth->execute() or do {
      $self->db_error($sth);
      return;
    };
    $sth->finish;
  }
  $dbh->commit or do {
    $self->db_error($sth);
    return;
  };
  return 1;
}

sub summary {
  my ($self, $id, $url) = @_;
  $url .= '/' unless $url =~ m@/$@;
  my $file;
  my ($type, $length, $mtime, $expires, $server);
  foreach my $try (@tries) {
    ($type, $length, $mtime, $expires, $server) = head("$url$try");
    if (defined $mtime) {
      $file = $try;
      last;
    }
  }
  unless (defined $mtime) {
    print "Could not get ppm info from $url\n";
    return;
  }

  my $mtimes = $self->{curr_mtimes};
  my $string = time2str($mtime);
  my ($wday, $day, $month, $year, $time, $tz) = split ' ', $string;
  my $stamp = "$year-$months{$month}-$day $time";
  if (defined $mtimes->{$id} and $mtimes->{$id} eq $stamp) {
    print "$url is up to date\n";
    return 1;
  }

  $arch = $arch{$repositories->{$id}->{PerlV}};
  my $packages = parse($url, $file);
  unlink $file;
  unless (has_data($packages)) {
    print "Info from $url contains no data\n";
    return;
  }
  $self->{update_mtimes}->{$id} = $stamp;
  return $packages;
}

sub parse {
  my ($url, $file) = @_;
  $url .= '/' unless ($url =~ m@/$@);
  my $remote = $url . $file;
  unless (is_success(getstore($remote, $file) )) {
    print "Cannot obtain $file from $url";
    return;
  }

  XML::SAX->add_parser(q(XML::SAX::ExpatXS));
  my $factory = XML::SAX::ParserFactory->new();
  my $handler = PPMHandler->new();
  my $parser = $factory->parser( Handler => $handler);

  eval { $parser->parse_uri($file); };
  if ($@) {
    print "Error in parsing $file: $@\n";
    return;
  }
  my $pkgs = $handler->{pkgs};
  return $pkgs;
}

sub ppd2cpan_version {
  local $_ = shift;
  s/(,0)*$//;
  tr/,/./;
  return $_;
}

sub db_error {
  my ($obj, $sth) = @_;
  return unless $dbh;
  $sth->finish if $sth;
  $obj->{error_msg} = q{Database error: } . $dbh->errstr;
}

# begin the in-line package
package PPMHandler;
use strict;
use warnings;

my $curr_el = '';
sub new {
    my $type = shift;
    return bless {text => '', pkgs => {}, ppd => {}}, $type;
}

sub start_document {
  my ($self) = @_;
  # print "Starting document\n";
  $self->{text} = '';
}

sub start_element {
  my ($self, $element) = @_;
  $curr_el = $element->{Name};
  return unless $wanted{$curr_el};
  #print "Starting $element->{Name}\n";
  my $ppd = $self->{ppd};
  $ppd->{keep} = 0 if $curr_el eq 'SOFTPKG';
  $self->display_text();
  foreach my $ak (keys %{ $element->{Attributes} } ) {
    my $at = $element->{Attributes}->{$ak};
    my $name = $at->{Name};
    my $value = $at->{Value};
    $ppd->{keep} = 1 if ($curr_el eq 'ARCHITECTURE' and $value eq $arch);
    $ppd->{$curr_el}->{$name} = $value if $curr_el eq 'SOFTPKG';
    #print qq(Attribute $at->{Name} = "$at->{Value}"\n);
  }
}

sub characters {
  my ($self, $characters) = @_;
  my $text = $characters->{Data};
  $text =~ s/^\s*//;
  $text =~ s/\s*$//;
  $self->{text} .= $text;
}

sub end_element {
  my ($self, $element) = @_;
  $curr_el = $element->{Name};
  return unless $wanted{$curr_el};
  $self->display_text();
  if ($curr_el eq 'SOFTPKG') {
    my $ppd = $self->{ppd};
    if ($ppd->{keep}) {
      $self->{pkgs}->{$ppd->{SOFTPKG}->{NAME}} = 
	{version => $ppd->{SOFTPKG}->{VERSION},
	 abstract => $ppd->{ABSTRACT}->{value}
	};
    }
  }
  # print "Ending $element->{Name}\n";
}

sub display_text {
  my $self = shift;
  my $ppd = $self->{ppd};
  if ( defined( $self->{text} ) && $self->{text} ne "" ) {
    $ppd->{$curr_el}->{value} = $self->{text};
    #print " text: [$self->{text}]\n";
    $self->{text} = '';
  }
}

sub end_document {
  my ($self) = @_;
  # print "Document finished\n";
}

1; #Ye Olde 'Return True' for the in-line package..

__END__

=head1 NAME

CPAN::Search::Lite::PPM - extract ppm package information from repositories

=head1 DESCRIPTION

This module gets information on available ppm packages on remote 
repositories. The repositories searched are specified in
C<$respositories> of I<CPAN::Search::Lite::Util>. Only those
distributions whose names appear from I<CPAN::Search::Lite::Info>
are saved. After creating a I<CPAN::Search::Lite::PPM> object through
the C<new> method and calling the C<fetch_info> method, the 
information is available as:

   my $ppms = $ppm_obj->{ppms};
   for my $rep_id (keys %{$ppms}) {
     print "For repository with id = $rep_id:\n";
     for my $package (keys %{$ppms->{$id}}) {
       print << "END";
 
 Package: $package
 Version: $ppms->{$rep_id}->{$package}->{version}
 Abstract: $ppms->{$rep_id}->{$package}->{abstract}

 END
     }
   }

=head1 SEE ALSO

L<CPAN::Search::Lite::Index>

=cut

=cut

