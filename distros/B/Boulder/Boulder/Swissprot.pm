package Boulder::Swissprot;
use Boulder::Stream;

=head1 NAME

Boulder::SwissProt - Fetch SwissProt data records as parsed Boulder Stones

=head1 SYNOPSIS

 == missing ==

=head1 DESCRIPTION

 == missing ==

=head1 SEE ALSO

L<Boulder>, L<Boulder::Blast>, L<Boulder::Genbank>

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>.
Luca I.G. Toldo <luca.toldo@merck.de>

Copyright (c) 1997 Lincoln D. Stein
Copyright (c) 1999 Luca I.G. Toldo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

require Exporter;
@ISA = qw(Exporter Boulder::Stream);
@EXPORT = ();
@EXPORT_OK = ();

use Carp;

$VERSION = 1.0;

# Hard-coded defaults - must modify for your site
use constant YANK            =>  '/usr/local/bin/yank';
use constant DEFAULT_SW_PATH =>  'new_seq.dat';

# Genbank entry parsing constants
# (may need to adjust!)
$KEYCOL=0;
$VALUECOL=12;
$FEATURECOL=5;
$FEATUREVALCOL=21;

# new() takes named parameters:
# -accessor=> Reference to an object class that will return a series of
#          Swissprot records.  Predefined objects include 'Yank', 'Entrez' and 'File'.
#           (defaults to 'Entrez').
# -param=>  Parameters to pass to the subroutine.  Can be a list of accession numbers
#           or an entrez query.
# -out=>    Output filehandle.  Defaults to STDOUT.
#
# If you don't use named parameters, then will assume method 'yank' on
# a list of accession numbers.
# e.g.
#        $sw = new Boulder::Swissprot(-accessor=>'Yank',-param=>[qw/M57939 M28274 L36028/]);
sub new {
    my($package,@parameters) = @_;
    # superclass constructor
    my($self) = new Boulder::Stream;
    
    # figure out whether parameters are named.  Look for
    # an initial '-'
    if ($parameters[0]=~/^-/) {
	my(%parameters) = @parameters;
	$self->{'accessor'}=$parameters{'-accessor'} || 'Entrez';
	$self->{'param'}=$parameters{'-param'};
	$self->{'OUT'}=$parameters{'-out'} || 'main::STDOUT';
    } else {
	$self->{'accessor'}='Yank';
	$self->{'param'}=[@parameters];
    }
    
    croak "Require parameters" unless defined($self->{'param'});
    $self->{'accessor'} = new {$self->{'accessor'}}($self->{'param'});
    
    return bless $self,$package;
}

sub read_record {
    my($self,@tags) = @_;
    my($s);

    if (wantarray) {
	my(@result);
	while (!$self->{'done'}) {
	    $s = $self->read_one_record(@tags);
	    next unless $s;
	    next if $query && !(&$query);
	    push(@result,$s);
	}
	return @result;
    } 

    # we get here if in a scalar context
    while (!$self->{'done'}) {
	$s = $self->read_one_record(@tags);
	next unless $s;
	return $s unless $query;
	return $s if &$query;
    }
    return undef;
}

sub parse {
  my $self = shift;
  my $record = shift;
  return unless $record;

  my $tags = shift;
  my %ok;
  %ok = map {$_ => 1} @$tags if ref($tags) eq 'ARRAY';
  
  my($s,@lines,$line,$accumulated,$key,$keyword,$value,$feature,@features);
  
  $s = new Stone;
  @lines = split("\n",$record);
  
  foreach $line (@lines) {
    # special case for the sequence itself
    if ($line=~/^SQ/) {
      $self->_addToStone($key,$accumulated,$s,\%ok) if $key;
      last;
    }    
    if ($line=~/^ID   /) {
       ($key,$id)=split(/\s+/,$line);
	$self->_addToStone('Identifier',$id,$s,\%ok);
      next;
    } elsif ($line =~/^AC  /) {
       ($key,$acc)=split(/\s+/,$line); $acc=~s/\;//g;
	$self->_addToStone('Accession',$acc,$s,\%ok);
      next;
    } elsif ($line =~/^DE  /) {
       ($key,$des)=split(/\s+/,$line); $des=~s/\;//g;
	$self->_addToStone('Description',$des,$s,\%ok);
      next;
    } elsif ($line =~/^OS  /) {
       ($key,$os)=split(/\s+/,$os); $os=~s/\;//g;
	$self->_addToStone('Organism',$os,$s,\%ok);
      next;
    } elsif ($line =~/^GN  /) {
       ($key,$gn)=split(/\s+/,$line); $gn=~s/\.//g;
	$self->_addToStone('Gene_name',$gn,$s,\%ok);
      next;
    } elsif ($line=~/^CC   -!- FUNCTION:/) {
    } elsif ($line=~/^CC   -!- SUBCELLULAR LOCATION:/) {
    } elsif ($line=~/^CC   -!- SUBUNIT:/) {
    } elsif ($line=~/^CC   -!- SIMILARITY: :/) {
    }
  }
  ($sequence)=$record=~/\nSQ.*\n([\s\S]+)/;
  $sequence=~s/[\s0-9-]+//g;  # remove white space
  $self->_addToStone('Sequence',$sequence,$s,\%ok);
  return $s;
}

sub read_one_record {
  my($self,@tags) = @_;
  my(%ok);
  
  my $accessor = $self->{'accessor'};
  my $record   = $accessor->fetch_next();
  unless ($record) {
    $self->{'done'}++;
    return undef;
  }

  return $self->parse($record,\@tags);
}


sub _trim {
    my($v) = @_;
    $v=~s/^\s+//;
    $v=~s/\s+$//;
    return $v;
}

sub _canonicalize {
  my $h = shift;
  substr($h,0)=~tr/a-z/A-Z/;
  substr($h,1,length($h)-1)=~tr/A-Z/a-z/;
  $h;
}

sub _addToStone {
    my($self,$label,$value,$stone,$ok) = @_;
    return unless !%{$ok} || $ok->{$label};
    $stone->insert(_canonicalize($label),$value);
}

sub _addFeaturesToStone {
    my($self,$features,$basecount,$stone,$ok) = @_;

    # first add the basecount
    if (!%{$ok} || $ok->{'BASECOUNT'}) {
	my(%counts) = $basecount=~/(\d+)\s+([gatcGATC])/g;
	%counts = reverse %counts;
	$stone->insert('Basecount',new Stone(%counts));
    }
    
    if (!%{$ok} || $ok->{'FEATURES'}) {
	# now add the features
	my($f) = new Stone;
	foreach (@$features) {
	    my($q) = $_->{'value'};
	    my($label) = _canonicalize($_->{'label'});
	    my($position) = $q=~m!^([^/]+)!;
	    my @qualifiers = $q=~m!/(\w+)=([^/]+)!g;
	    my %qualifiers;
	    while (my($key,$value) = splice(@qualifiers,0,2)) {
	      $value =~ s/^\s*\"//;
	      $value =~s/\"\s*$//;
	      $value=~s/\s+//g if uc($key) eq 'TRANSLATION';  # get rid of spaces in protein translation
	      $qualifiers{_canonicalize($key)} = $value;
	    }
	    $f->insert($label=>new Stone('Position'=>$position,%qualifiers));
	}
	$stone->insert('Features',$f);
    }
}

# ----------------------------------------------------------------------------------------
# -------------------------- DEFINITION OF ACCESSOR OBJECTS ------------------------------
package SwissprotAccessor;
use Carp;

sub new {
    my($class,@parameters) = @_;
    croak "SwissprotAccessor::new:  Abstract class\n";
}

sub fetch_next {
    my($self) = @_;
    croak "SwissprotAccessor::fetch_next: Abstract class\n";
}

sub DESTROY {
}

package Yank;
use Carp;

@ISA=qw(SwissprotAccessor);
$YANK = Boulder::Swissprot::YANK();

sub new {
    my($package,$param) = @_;
    croak "Yank::new(): need at least one Swissprot acccession number" unless $param;
    croak "Yank::new(): yank executable not found" unless -x $YANK;
    my (@accession) = ref($param) eq 'ARRAY' ? @$param : $param;
    my($tmpfile) = "/usr/tmp/yank$$";
    open (TMP,">$tmpfile") || croak "Yank::new(): couldn't open tmpfile $tmpfile for write: $!";
    print TMP join("\n",@accession),"\n";
    close TMP;
    open(YANK,"$YANK < $tmpfile |") || croak "Yank::new(): couldn't open pipe from yank: $!";
    return bless {'tmpfile'=>$tmpfile,'fh'=>YANK},$package;
}

sub fetch_next {
    my($self) = @_;
    return undef unless $self->{'fh'};
    local($/) = "//\n";
    my($line);
    my($fh) = $self->{'fh'};
    chomp($line = <$fh>);
    return $line;
}

sub DESTROY {
    my($self) = shift;
    close $self->{'fh'} if $self->{'fh'};
    unlink $self->{'tmpfile'} if $self->{'tmpfile'}
}

package File;
use Carp;
@ISA=qw(SwissprotAccessor);
$DEFAULT_PATH = Boulder::Swissprot::DEFAULT_SW_PATH();

sub new {
    my($package,$path) = @_;
    $path = $DEFAULT_PATH unless $path;
    open (SW,$path) or croak "File::new(): couldn't open $path: $!";
    # read the junk at the beginning
    my $found;
    $_ = <SW>;
    return bless {'fh'=>SW},$package;
}

sub fetch_next {
    my $self = shift;
    return undef unless $self->{'fh'};
    local($/)="//\n";
    my($line);
    my($fh) = $self->{'fh'};
    chomp($line = <$fh>);
    return $line;
}

package Entrez;
use Carp;
use IO::Socket;

use constant HOST  => 'www.ncbi.nlm.nih.gov';
use constant URI   => '/htbin-post/Entrez/query?form=6&Dopt=g&html=no';
use constant PROTO => 'HTTP/1.0';
use constant CRLF  => "\r\n";

@ISA=qw(SwissprotAccessor);

sub new {
    my($package,$param) = @_;
    croak "Entrez::new(): usage [list of accession numbers] or {args => values}" 
      unless $param;
    my $self = {};

    $self->{query}     = $param       unless ref($param);
    $self->{accession} = $param       if ref($param) eq 'ARRAY';
    %$self             = map { s/^-//; $_; } %$param  if ref($param) eq 'HASH';
    $self->{query} || $self->{accession} 
                   || croak "Must provide a 'query' or 'accession' argument";
    $self->{max}   ||= 100;
    $self->{'db'}  ||= 'n';
    return bless $self,$package;
}

sub fetch_next {
    my $self = shift;

    # if any additional records are left, then return them
    if (@{$self->{'records'}}) {
      my $data = shift @{$self->{'records'}};
      if ($data=~/\S/) {
	$self->_cleanup(\$data);
	return $data;
      } else {
	$self->{'records'} = [];
      }
    }

    # if we have a socket open, then read a record
    if ($self->{'socket'}) {
      my $data = $self->{'socket'}->getline;
      $self->_cleanup(\$data);
      return $data;
    }

    # otherwise if we are reading from a series of accession numbers,
    # do a one-time fetch
    if (exists $self->{'accession'}) {
      my $accession = shift @{$self->{'accession'}};
      return unless $accession;

      my $sock     = $self->_request(URI . "&db=$self->{db}&uid=$accession");
      return unless $sock;

      @{$self->{'records'}} = $sock->getlines;
      my $data = shift @{$self->{'records'}};
      $self->_cleanup(\$data);
      return $data;
    }

    # Otherwise we are running a query.  Need to set up the socket
    $self->{query} =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
    my $search = URI . "&db=$self->{db}&dispmax=$self->{max}&term=$self->{query}";
    $search .= "&relpubdate=$self->{age}" if $self->{age} > 0;
    $self->{'socket'} = $self->_request($search);
    return unless $self->{'socket'};

    my $data = $self->{'socket'}->getline;
    $self->_cleanup(\$data);
    return $data;
}

sub _cleanup {
  my ($self,$d) = @_;
  $$d =~ s/\A\s+//;
  $$d=~s!//\n$!!;
}

sub _request {
  my $self = shift;
  my $uri  = shift;
  my $sock = IO::Socket::INET->new(
				   PeerAddr => HOST,
				   PeerPort => 'http(80)',
				   Proto    => 'tcp'
				  );
  return unless $sock;
  print $sock "GET $uri ",PROTO,CRLF,CRLF;
  $sock->input_record_separator( CRLF . CRLF);
  my $header = $sock->getline;
  return unless $header;
  return unless $header =~ /^HTTP\/[\d.]+ 200/;
  # read until we get to the '----' line
  $sock->input_record_separator("\n");
  while ($_ = $sock->getline) {
    return undef if /^ERROR/;
    if (/^------/) {
      $sock->input_record_separator("//\n");
      return $sock;
    }
  }
  return;
}

1;

__END__

