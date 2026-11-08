package JSEmailTest;

# Shared helpers for the offline Data::JSEmail tests.
#
# The proxy that uses this module (jmap-perl, JMAP/DB.pm) sets
# $Email::MIME::ContentType::STRICT_PARAMS = 0 for the whole process, so
# Email::MIME accepts the unquoted and otherwise sloppy parameters real
# mail is full of.  Data::JSEmail localises that setting itself, so the
# result must not depend on it: the tests run the proxy's way by default
# and in strict mode with JSEMAIL_STRICT_PARAMS=1 (t/globals.t checks
# both in one process).

use strict;
use warnings;

use Email::MIME::ContentType;
BEGIN { $Email::MIME::ContentType::STRICT_PARAMS = $ENV{JSEMAIL_STRICT_PARAMS} // 0 }

use Data::JSEmail;
use Exporter 'import';
use File::Basename qw(dirname);
use File::Spec;

our @EXPORT_OK = qw(
  fixture parse_fixture part_ids leaves leaf_by_id hdr header_values
  prop_value blob_store
);

my $DATA = File::Spec->catdir(dirname(__FILE__), '..', 'data');

# The raw octets of t/data/$name, with every line ending made CRLF (the
# fixtures are kept with LF so they are easy to read and edit).
sub fixture {
  my ($name) = @_;
  my $path = File::Spec->catfile($DATA, $name);
  open my $fh, '<:raw', $path or die "$path: $!";
  local $/;
  my $raw = <$fh>;
  $raw =~ s/\r?\n/\r\n/g;
  return $raw;
}

sub parse_fixture {
  my ($name) = @_;
  return Data::JSEmail::parse(fixture($name), $name =~ s/\W/-/gr);
}

# The partIds of a list of EmailBodyParts, for comparing classifications.
sub part_ids {
  my ($parts) = @_;
  return [ map { $_->{partId} } @{ $parts || [] } ];
}

# Every leaf of a bodyStructure, depth first.
sub leaves {
  my ($node) = @_;
  return ($node) unless $node->{subParts};
  return map { leaves($_) } @{ $node->{subParts} };
}

sub leaf_by_id {
  my ($msg, $id) = @_;
  my ($leaf) = grep { ($_->{partId} // '') eq $id } leaves($msg->{bodyStructure});
  return $leaf;
}

# The unfolded values of every instance of header $name in a raw message.
sub hdr {
  my ($msg, $name) = @_;
  my ($head) = split /\r\n\r\n/, $msg, 2;
  $head =~ s/\r\n[ \t]+/ /g;
  return map { /^\Q$name\E:[ \t]*(.*)$/i ? $1 : () } split /\r\n/, $head;
}

# The raw values of header $name in an EmailHeader[] list.
sub header_values {
  my ($headers, $name) = @_;
  return map { $_->{value} } grep { lc $_->{name} eq lc $name } @{ $headers || [] };
}

# The value of a "header:Name[:asForm][:all]" property computed from an
# EmailHeader[] list, exactly as the proxy computes it
# (JMAP/API/Email.pm _header_prop_value): the Raw value of each instance
# handed to the Data::JSEmail function named after the form.
sub prop_value {
  my ($headers, $prop) = @_;
  my (undef, $name, @mods) = split /:/, $prop;
  my $all = @mods && $mods[-1] eq 'all';
  pop @mods if $all;
  my $form = $mods[0] // 'asRaw';
  my @values = header_values($headers, $name);
  my $conv = $form eq 'asRaw' ? sub { $_[0] } : Data::JSEmail->can($form);
  die "no such form $form" unless $conv;
  return [ map { $conv->($_) } @values ] if $all;
  return @values ? $conv->($values[-1]) : undef;
}

# A getblob callback over a hash of blobId => [type, octets], as the
# proxy's get_blob returns them.
sub blob_store {
  my (%blobs) = @_;
  return sub {
    my ($id) = @_;
    my $b = $blobs{$id} or return;
    return @$b;
  };
}

1;
