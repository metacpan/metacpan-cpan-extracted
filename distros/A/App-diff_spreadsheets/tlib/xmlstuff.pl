#!/usr/bin/perl
use strict; use warnings; use feature qw/say state/;
use Data::Dumper::Interp;
use open IO => ':locale';

#-----------------------------------------------------
package MyXML;
our @ISA = ('Archive::Zip');
use Carp;
use Data::Dumper::Interp;
use Encode qw(encode decode);
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use XML::Twig ();

use Test2::V0; #for 'note' and 'diag'

use constant DEFAULT_MEMBER_NAME => "content.xml";

sub encode_xml($$;$) {
  my ($chars, $encoding, $desc) = @_;
  confess "bug" unless defined($chars) && defined($encoding);
  $chars =~ s/(<\?xml[^\?]*encoding=")([^"]+)("[^\?]*\?>)/$1${encoding}$3/s
    or confess qq(Could not find <?xml ... encoding="..."?>),
               ($desc ? " in $desc" : "");
  my $octets = encode($encoding, $chars, Encode::FB_CROAK|Encode::LEAVE_SRC);
  $octets
}

sub decode_xml($;$) {
  my ($octets, $desc) = @_;
  my $chars;
  my $encoding;
  if (length($octets) == 0) {
    $chars = "";
  } else {
    ($encoding) = ($octets =~ /<\?xml[^\?]*encoding="([^"]+)"[^\?]*\?>/);
    confess qq(Could not find <?xml ... encoding="..."?>),
            ($desc ? " in $desc" : "")
      unless $encoding;
    $chars = decode($encoding, $octets, Encode::FB_CROAK);
  }
  wantarray ? ($chars, $encoding) : $chars
}

sub new {
  my ($class, $path, %opts) = @_;
  my $self = bless {%opts}, $class;
  my $zip = $self->{zip} = $self->SUPER::new(); # Archive::Zip->new();
  note "> Opening ",qsh($path)," at ",(caller(0))[2] if $self->{debug};
  confess "Error reading $path ($!)"
    unless $zip->read($path) == AZ_OK;
  $self->{orig_path} //= $path;
  $self
}

sub get_raw_content {
  my $self = shift;
  my $member_name = $_[0] // DEFAULT_MEMBER_NAME;

  my $zip = $self->{zip};

  my $member = $zip->memberNamed($member_name)
    // confess "No such member ",visq($member_name);

  $member->contents()
}

sub get_content {
  my $self = shift;
  decode_xml( $self->get_raw_content(@_) );
}

sub replace_content {  # $obj->set_content($chars, encoding => "...")
  my $self = shift;
  my ($chars, %opts) = @_;
  my $member_name = $opts{member_name} // DEFAULT_MEMBER_NAME;
  my $encoding = $opts{encoding};
  confess "encoding must be specified" unless $encoding;

  my $octets = encode_xml($chars, $encoding, "new content");

  my $zip = $self->{zip};
  my $member = $zip->memberNamed($member_name)
    // confess "No such member ",visq($member_name);
  $zip->removeMember($member_name);
  my $new_member = $zip->addString($octets, $member_name);
  $new_member->desiredCompressionMethod( COMPRESSION_DEFLATED );
}

sub store {
  my ($self, $dest_path) = @_;
  confess "Destination path missing" unless $dest_path;
  my $zip = $self->{zip};
  note "> Writing ",qsh($dest_path)," at ",(caller(0))[2] if $self->{debug};
  $zip->writeToFileNamed($dest_path) == AZ_OK
    or confess "Write error ($!)";
}
sub memberNames { my $s=shift; $s->{zip}->memberNames(@_) }
sub members     { my $s=shift; $s->{zip}->members(@_) }
sub contents    { my $s=shift; $s->{zip}->contents(@_) }

#-----------------------------------------------------
package main;

#my $path = "./Foo.xlsx";
#my $path = "Bar.xlsx";
my $path = "/tmp/unisample.docx";

my $obj = MyXML->new($path);

my @names = $obj->memberNames;
my ($mname) = grep{$_ eq 'word/document.xml'} @names;
my ($octets, $enc) = $obj->get_raw_content($mname);

say dvis '$mname $enc $octets';
