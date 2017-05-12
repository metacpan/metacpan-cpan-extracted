#
# Copyright (c) 2008, 2009  Eugene Bragin
#
# See COPYRIGHT section in pod text below for usage and distribution rights.
#

package Cache::Memcached::Tags;

use strict;
use warnings;

use base 'Cache::Memcached';

use vars qw($VERSION);

$VERSION = '0.02';

sub add_tags {
  my $self = shift;
  my $key  = shift;
  my @tags = @_;

  my $sock = $self->get_sock($key);
  foreach my $tag (@tags) {
    my $cmd = "tag_add $tag $self->{namespace}$key\r\n";
    my $res = $self->_write_and_read($sock, $cmd);

    die "tag_add command returned ERROR, please make sure your memcached servers support tags: http://code.google.com/p/memcached-tags/"
      if $res eq "ERROR\r\n";

    return 0 unless $res eq "TAG_STORED\r\n";
  }

  return 1;
}

*add_tag = \&add_tags;
*tag_add = \&add_tags;

sub delete_by_tags {
  my $self = shift;
  my @tags = @_;

  my $cmd = 'tags_delete '. join(' ', @tags) ."\r\n";
  my $items_deleted = 0;

  my @hosts = @{$self->{'buckets'}};
  foreach my $host (@hosts) {
      my $sock = $self->sock_to_host($host);
      my $res = $self->_write_and_read($sock, $cmd);
      warn "tag_add command returned ERROR, please make sure your memcached servers support tags: http://code.google.com/p/memcached-tags/"
        if $res eq "ERROR\r\n";

      if ($res =~ /^(\d+) ITEMS_DELETED/) {
        $items_deleted += $1;
      }
  }
  
  return $items_deleted;
}

*tag_delete  = \&delete_by_tags;
*tags_delete = \&delete_by_tags;

sub set {
  my $self = shift;
  my ($key, $value, $exptime, @tags) = @_;

  my $result = $self->SUPER::set($key, $value, $exptime);

  $self->add_tags($key, @tags)
    if @tags && $result;
    
  return $result;
}

1;
__END__

=head1 NAME

Cache::Memcached::Tags - Cache::Memcached based client library for memcached-tags:
	http://code.google.com/p/memcached-tags/

=head1 SYNOPSIS

  use Cache::Memcached::Tags;

  $memd = new Cache::Memcached::Tags {
    'servers' => [ "10.0.0.15:11211", "10.0.0.15:11212", "/var/sock/memcached",
                   "10.0.0.17:11211", [ "10.0.0.17:11211", 3 ] ],
  };

  $memd->set("my_key", "Some value");
  $memd->add_tags("my_key", "tag1", "tag2", "tag3");

  $memd->set("my_key2", "Other value", undef, "tag1", "tag2");

  $memd->delete_by_tags("tag1", "tag2");

=head1 DESCRIPTION

This is the Perl API for memcached-tags version of memceched
More information is available at:

	http://memcached-tags.googlecode.com
	
This module is based on Cache::Memcached, so you can use it as you would use Cache::Memcached plus couple of new methods

=head1 METHODS

=over 4
	
=item C<All Cache::Memcached methods>

=item C<add_tags>

$memd->add_tags($key1, @tags);
marks item with tags

=item C<delete_by_tags>

$memd->delete_by_tags($tag1, $tag2, $tag3, ...);
deletes items that were marked by these tags

=item C<set>

$memd->set($key, $value[, $exptime[, @tags]]);
same Cache::Memcached set method, except it accepts tags for the item to mark


=head1 COPYRIGHT

This module is Copyright (c) 2009 Eugene Bragin.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 WARRANTY

This is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 FAQ

See the memcached website:
	http://www.danga.com/memcached/
And memcached-tags branch:
	http://code.google.com/p/memcached-tags/

=head1 AUTHORS

Eugene Bragin <eugene.bragin+memd@gmail.com>

	