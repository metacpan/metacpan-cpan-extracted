#!/usr/bin/perl -w

package Data::Fallback::ConfFile;

use strict;

use Data::Fallback;
use vars qw(@ISA);
@ISA = qw(Data::Fallback);

sub get_conffile_filename {
  my $self = shift;
  
  # allows for /tmp/fallback/$primary_key
  # to cache information for numerous keys like 1, 2, 7 for
  # SELECT * FROM foo WHERE key = ?
  # for example
  my $primary_key = $self->get_cache_key('primary_key');

  my $return = $self->{hash}{content};
  $return =~ s/\$primary_key/$primary_key/g if($primary_key);
  return $return;
}

sub _GET {
  my $self = shift;

  my $return = 0;

  my $key = $self->get_conffile_filename . ".$self->{item}";

  my ($found_in_cache, $content) = 
    $self->check_cache('ConfFile', 'item', $key);

  if($found_in_cache) {
    $self->{update}{item} = $content;
    $return = 1;
  } else {
    my $contents = $self->get_content;
    my $from_file_hash = contentToHash(\$contents);
    if( $from_file_hash && (defined $from_file_hash->{$self->{hash}{item}}) && length $from_file_hash->{$self->{hash}{item}}) {
      $self->{update}{group} = $from_file_hash;
      $self->{update}{item} = $from_file_hash->{$self->{hash}{item}};
      $self->set_cache('ConfFile', 'item', $self->get_conffile_filename . ".$self->{hash}{item}", $self->{update}{item});
      $return = 1;
    }
  }

  return $return;
}

sub SET_ITEM {
  my $self = shift;
  my $filename = $self->get_conffile_filename;
  if($filename && -e $filename) {
    my $content = Include($filename);
    my $file_hash = contentToHash(\$content);
    unless( (defined $file_hash->{$self->{item}}) && $file_hash->{$self->{item}} eq $self->{update}{item}) {
      $file_hash->{$self->{item}} = $self->{update}{item};
      write_conf_file($filename, $file_hash);
    }
  }
}

sub SET_GROUP {
  my $self = shift;
  return write_conf_file($self->get_conffile_filename, $self->{update}{group});
}

sub get_content {
  my $self = shift;

  my $filename = $self->get_conffile_filename;
  my ($found_in_cache, $content) = 
    $self->check_cache('ConfFile', 'group', $filename);

  if($found_in_cache) {
    # already set in $content, so we're done
  } elsif(-e $filename) {
    $content = Include($filename);
    $self->set_cache('ConfFile', 'group', $filename, $content);
  } else {
    # no value, no file => do nothing
  }
  return $content;
}

sub contentToHash {
  my $text_ref = shift;
  my %hash = $$text_ref =~ /(.+?)\s+(.+)/g;
  return \%hash;
}

sub hashToContent {
  my $hash_ref = shift;
  my $content = '';
  foreach(sort keys %{$hash_ref}) {
    next unless($hash_ref->{$_});
    $content .= "$_     $hash_ref->{$_}\n";
  }
  return $content;
}

sub Include {
  my $filename = shift;
  return unless(-e $filename);
  open(FILE, $filename);
  my $content = join("", <FILE>);
  close(FILE);
  return $content;
}

sub write_conf_file {
  my ($filename, $hash_ref) = @_;
  my $txt = hashToContent($hash_ref);
  open (FILE, ">$filename");
  print FILE $txt;
  close(FILE);
}

=head1 NAME

Data::Fallback::ConfFile - conf file package for Data::Fallback 

=head1 DESCRIPTION

Data::Fallback looks through an array ref of hash refs, where each hash ref (a level) describes how to get data
from  that level.  Here's a typical level

{
  # refers to Data::Fallback::ConfFile
  package => 'ConfFile',

  # content is a filename, $primary_key gets parsed in with the primary key for a given request
  content => '/tmp/fallback/state_$primary_key',

  # this says the conf file will be updated with information from subsequent levels
  accept_update => 'group',

  # this would say to only allow updates of individual items
  #accept_update => 'item',
},


Please refer to the Data::Fallback perldoc for more information about lists and levels.

=head1 EXAMPLE

Let's say you have a list of directories that contain parallel conf files, like so

  # the 12 is some arbitrary primary key
  /tmp/dir1/file_12
  key1 key1 from dir1
  key2 key2 from dir1

  /tmp/dir2/file_12
  key2 key2 from dir2
  key3 key3 from dir2


The code below could be used to fallback through them.

#!/usr/bin/perl -w

use strict;
use Data::Fallback;

my $self = Data::Fallback->new({

list => [
    {
      # filename
      content => '/tmp/dir1/file_$primary_key',
    },
    {
      content => '/tmp/dir2/file_$primary_key',
    },
  ],

  # the package looks first to the level, then to the object
  # so if each level has the same package, you can just specify it in the object
  package => 'ConfFile',

  # lists must be names
  list_name => 'test_list',
});

# 12 is the primary key (use // if no primary key), and key3 is the name of the key to retrieve
my $got = $self->get("/12/key3");

=head1 FILE PARSING

Right now, I just do something like

split /\s+/, $line, 2

to get a key/value pair for each line in the conf file.  This is done through the method contentToHash, which you can
easily override for more complicated parsing.  The actual line looks like something like this

my %hash = $line =~ /(.+?)\s+(.+)/g;

=head1 AUTHOR

Copyright 2001-2002, Earl J. Cahill.  All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Address bug reports and comments to: cpan@spack.net.

When sending bug reports, please provide the version of Data::Fallback, the version of Perl, and the name and version of the operating
system you are using.

=cut

1;
