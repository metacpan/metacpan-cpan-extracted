package BitTorrent;

#use 5.008007;
use strict;
use warnings;
use LWP::Simple;
use Digest::SHA1 qw(sha1);

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	getHealth
	getTrackerInfo
);

our $VERSION		= '0.10';
our $TorrentScrape	= "/var/lib/perl/torrent-checker.php";


sub new(){
	
	my $self			= bless {}, shift;
	return $self;
		
}; # new()


sub getTrackerInfo(){

	my $self	= shift;
	my $file	= shift;
	my $content;

	if ( $file =~ /^http/i ) {
		$content = get($file);
	} else {
		open(RH,"<$file") or warn;
		binmode(RH);
		$content = do { local( $/ ) ; <RH> } ;
		close RH;
	};

	my %result;

	my $t = &bdecode(\$content);

	my $info = $t->{'info'};
	my $s = substr($content, $t->{'_info_start'}, $t->{'_info_length'});
	my $hash = bin2hex(sha1($s));
	my $announce = $t->{'announce'};

	$result{'hash'} = $hash;
	$result{'announce'} = $announce;
	$result{'files'} = [];
	my $tsize = 0;
	if(defined($info->{'files'})) {
		foreach my $f (@{$info->{'files'}}) {
			my %file_record = ( 'size' => $f->{'length'});

			$tsize += $f->{'length'};
			my $path = $f->{'path'};

			if(ref($path) eq 'ARRAY') {
				$file_record{'name'} = $info->{'name'}.'/'.$path->[0];
			} else {
				$file_record{'name'} = $info->{'name'}.'/'.$path;
			}
			push @{$result{'files'}}, \%file_record;
		}

	} else {
		$tsize += $info->{'length'},

		push @{$result{'files'}}, 
			{
				'size' => $info->{'length'},
				'name' => $info->{'name'},
			};

	}
	$result{'total_size'} = $tsize;

	return \%result;

}; # sub getTrackerInfo(){


sub getHealth(){

	my $self			= shift;
	my $torrent			= shift;

	# init
	my $Hash = ();
	my %Hash = ();

	# get torrent
	my $random			= int(rand(100000)+1);
	my $TorrentStore	= "/tmp/$random.torrent";
	getstore($torrent, $TorrentStore);
	
	# scrape torrent
	my $returnVal		= `php $TorrentScrape $TorrentStore`;
	
	# extract infos
	my @SeederLeecher	= split('#', $returnVal);
	my $Seeder			= $SeederLeecher[0];
	my $Leecher			= $SeederLeecher[1];
	
	eval {
		$Seeder				=~ s/^\s+//;
		$Seeder				=~ s/\s+$//;
		$Leecher			=~ s/^\s+//;
		$Leecher			=~ s/\s+$//;
	};

	$Hash->{seeder}		= $Seeder;
	$Hash->{leecher}	= $Leecher;


	return $Hash;

}; # sub sub getHealth(){


sub bin2hex() {
  
  my ($d) = @_;
  $d =~ s/(.)/sprintf("%02x",ord($1))/egs;
  $d = lc($d);
  
  return $d;

}; # sub bin2hex() {

sub bdecode {
  my ($dataref) = @_;
  unless(ref($dataref) eq 'SCALAR') {
    die('Function bdecode takes a scalar ref!');
  } # unless
  my $p = 0;
  return benc_parse_hash($dataref,\$p);
} # sub bdecode

sub benc_parse_hash {
  my ($data, $p) = @_;
  my $c = substr($$data,$$p,1);
  my $r = undef;
  if($c eq 'd') { # hash
#    print "Found a hash\n";
    %{$r} = ();
    ++$$p;
    while(($$p < length($$data)) && (substr($$data, $$p, 1) ne 'e')) {
      my $k = benc_parse_string($data, $p);
      my $start = $$p;
      $r->{'_' . $k . '_start'} = $$p if($k eq 'info');
      my $v = benc_parse_hash($data, $p);
      $r->{'_' . $k . '_length'} = ($$p - $start)  if($k eq 'info');
#      print "\t{$k} => $v\n";
      $r->{$k} = $v;
    } # while
    ++$$p;
#    print "End of Hash\n";
  } elsif($c eq 'l') { # list
    @{$r} = \();
    ++$$p;
#    print "Found a list\n";
    while(substr($$data, $$p, 1) ne 'e') {
      push(@{$r},benc_parse_hash($data, $p));
#      print "\t[@{$r}] = $$r[-1]\n";
    } # while
    ++$$p;
  } elsif($c eq 'i') { # number
    $r = 0;
    my $c;
    ++$$p;
    while(($c = substr($$data,$$p,1)) ne 'e') {
      $r *= 10;
      $r += int($c);
      ++$$p;
    }  # while
    ++$$p;
#    print "Found an int: $r\n";
  } elsif($c =~ /\d/) { # string
    $r = benc_parse_string($data, $p);
#    print "Found a string: ", length($r), "\n";
  } else {
    die("Unknown token '$c' at $p!");
  } # case
  return $r;
} # benc_parse

sub benc_parse_string {
  my ($data, $p) = @_;
  my $l = 0;
  my $c = undef;
  my $s;
  while(($c = substr($$data,$$p,1)) ne ':') {
#    print "Char: $c, ", int($c), "\n";
    $l *= 10;
    $l += int($c);
    ++$$p;
  }  # while
  ++$$p;
#  print "Length: $l\n";
  $s = substr($$data,$$p,$l);
  $$p += $l;
#  print "Returning length $l = ", length($s), " ($s)\n";
  return $s;
} # benc_parse_string


1;



# Preloaded methods go here.

1;
__END__


=head1 NAME

BitTorrent - Perl extension for extracting, publishing and maintaining BitTorrent related things 

=head1 SYNOPSIS

	use BitTorrent;
	my $torrentfile = "http://www.mininova.org/get/620364";
	my $obj		= BitTorrent->new();
	my $HashRef1 = $obj->getHealth($torrentfile);
	my $HashRef = $obj->getTrackerInfo($torrentfile);
	
	print "Seeder: " . $HashRef1->{seeder};
	print "Leecher: " . $HashRef1->{leecher};

	print "Size: $HashRef->{'total_size'}\n";
	print "Hash: $HashRef->{'hash'}\n";
	print "Announce: $HashRef->{'announce'}\n";

	foreach my $f ( $HashRef->{'files'}) {
		
		foreach my $_HashRef( @{$f} ) {
		
			print "FileName: $_HashRef->{'name'}\n";
			print "FileSize: $_HashRef->{'size'}\n";
		
		}; # foreach my $_HashRef( @{$f} ) {
		
	}; # foreach my $f ( $HashRef->{'files'}) {


=head1 DESCRIPTION

BitTorrent:
Minor Update Release: 
+ get Seeder and Leecher Infos from given torrent url file.
+ extraction of important information from tracker including filenames, filesize, hash string, announce url

=head2 EXPORT

getHealth():		get Seeder and Leecher Infos
getTrackerInfo():	get filenames, filesize, hash string, announce url from given torrent file

=head1 SEE ALSO

http://search.cpan.org/author/ORCLEV/Net-BitTorrent-File-1.02-fix/lib/Net/BitTorrent/File.pm
http://search.cpan.org/author/JMCADA/Net-BitTorrent-PeerPacket-1.0/lib/Net/BitTorrent/PeerPacket.pm

http://www.zoozle.net
http://www.zoozle.org
http://www.zoozle.biz

=head1 AUTHOR

Marc Qantins, E<lt>qantins@gmail.com<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by M. Quantins, Sebastian Enger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
