# --*-Perl-*--
# $Id: File.pm 18 2004-12-12 07:41:44Z tandler $
#

package Biblio::File;
use 5.006;
use strict;
use warnings;
#use English;

# for debug:
use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 18 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}


# This class is a subclass of DBI::db, exported by the DBI module.
use Biblio::BP;
# select destination format etc.
Biblio::BP::format("auto", "canon:8859-1");

use Carp;


sub new {
    my $self = shift;
    my $class = ref($self) || $self;
    my %args = @_;
    $self = { %args	};
    return bless $self, $class;
}



sub DESTROY ($) {
  my $self = shift;
  $self->disconnect();
}

sub disconnect {
	# as long as we don't have to save anything, ignore this!
}

#
#
# methods
#
#

sub getCiteKeys {
# return all paper IDs
	my $self = shift;
	return keys %{$self->refs()};
}



sub queryPapers {
# query papers, look in $queryFields for $pattern
	my $self = shift;
	my ($pattern, $queryFields, $resultFields, $ignoreCase) = @_;
	$ignoreCase = 1 if not defined($ignoreCase);
	$pattern = lc($pattern) if($ignoreCase);
	# no query yet ...
	return $self->refs();
}

sub queryPaperWithId ($$) {
	my ($self, $id) = @_;
	return $self->refs()->{$id};
}

#
#
# add & update papers
#
#


sub storePaper {
	my ($self, $ref, $update) = @_;
	my $id = $ref->{'CiteKey'};
	my $old_ref = $self->queryPaperWithId($id);

	print STDERR "storePaper not yet supported ...\n";
}



#
#
# shortcuts
#
#

sub replaceShortcuts {
# look in $text and replace all shortcuts
  my ($self, $text) = @_;
  return undef unless defined($text);
  # check, if there is any {} field at all -> this is *much* faster!
  return $text unless $text =~ /\{/;
  my $shortcuts = $self->shortcuts();
  my $pattern = join("|", map( /:$/ ? "$_.*" : $_, (keys(%{$shortcuts}))));
#print $pattern;
  $text =~ s/\{($pattern)\}/ $self->expandShortcut($shortcuts, $1) /ge;
  return $text;
}
sub expandShortcut {
	my ($self, $shortcuts, $text) = @_;
	my @pars = split(/:/, $text);
	my $k = shift @pars; if( @pars ) { $k = "$k:"; }
	my $v = $shortcuts->{$k};
	$v =~ s/%(\d)/ $pars[$1-1] /ge;
	#print "\n\n$k ---- $v\n\n";
	return $v;
}

sub shortcuts {
	my ($self) = @_;
	return $self->{'shortcuts'} if defined($self->{'shortcuts'});
	return {};
}

sub updateShortcuts {
	my ($self) = @_;
	#  delete $self->{'shortcuts'};
}


#
#
# private file access
#
#

sub refs {
# return all papers as defined in DB
  my $self = shift;
  my $refs = $self->{'refs'};
  if( not defined($refs) ) {
	# maybe handle multiple files if file() points to an array
    $refs = $self->readFile($self->file());
    $self->{'refs'} = $refs;
  }
  return $refs;
}

sub file { return shift->{'file'} || 'biblio.bib'; }

sub readFile {
	my ($self, $file) = @_;
	print STDERR "Read $file ...\n" unless $self->{quiet};
	my $fmt = Biblio::BP::open($file);
	return undef unless defined $fmt;
	my ($ref, $key);
	my $refs = {};
	my $rn = 0;
	while ( defined($ref = Biblio::BP::readpbib()) ) {
		$rn++;
		$key = $ref->{'CiteKey'};
		$refs->{$key} = $ref;
	}
	print STDERR "$rn records read from $file" unless $self->{quiet};
	Biblio::BP::print_error_totals() unless $self->{quiet};
	print STDERR ".\n" unless $self->{quiet};
	Biblio::BP::close();
	return $refs;
}

1;

#
# $Log: File.pm,v $
# Revision 1.2  2003/04/14 09:43:55  ptandler
# fixed prototype
#
# Revision 1.1  2003/01/21 10:25:08  ptandler
# support for Biblio::File
#
