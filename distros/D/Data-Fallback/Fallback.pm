#!/usr/bin/perl -w
# use whole path on item packages
# if :: swap for slashes, use Data::Fallback for not

package CacheHash;

use strict;
use vars qw(@ISA @EXPORT_OK $VERSION);
use Exporter;
use Carp qw(confess);

@ISA = ('Exporter');
@EXPORT_OK  = qw( cache_hash );
$VERSION = "0.16";

sub new {
  my $type = shift;
  my $hash_ref = $_[0];
  my @PASSED_ARGS = (ref $hash_ref eq 'HASH') ? %{$_[0]} : @_;
  my $cache_object;
  my @DEFAULT_ARGS = (
    ttl             => "1 day",
    periods_to_keep => 2,
  );
  my %ARGS = (@DEFAULT_ARGS, @PASSED_ARGS);
  $cache_object = bless \%ARGS, $type;

  return $cache_object;
}

sub expired_check {
  my $self = shift;
  my $_sub_hash = shift;
  my $diff = $self->{int_time} - $_sub_hash;
  if($diff >= $self->{periods_to_keep}) {
    return 1;
  } else {
    return 0;
  }
}

sub cleanup {
  my $self = shift;
  my ($hash, $key) = @_;
  delete $hash->{$key};
}

sub handle_ttl {
  my $self = shift;

  if($self->{ttl} =~ /^\d+$/) {
    # do nothing
  } elsif($self->{ttl} =~ s/^(\d+)\s*(\D+)$/$1/) {
    $self->{ttl} =  $1 if defined $1;
    my $units = (defined $2) ? $2 : '';
    if(($units =~ /^s/i) || (!$units)) {
      $self->{ttl} = $self->{ttl};
    } elsif ($units =~ /^m/i) {
      $self->{ttl} *= 60;
    } elsif ($units =~ /^h/i) {
      $self->{ttl} *= 3600;
    } elsif ($units =~ /^d/i) {
      $self->{ttl} *= 86400;
    } elsif ($units =~ /^w/i) {
      $self->{ttl} *= 604800;
    } else {
       die "invalid ttl '$self->{ttl}', bad units '$units'";
    }
  } else {
    die "invalid ttl '$self->{ttl}', not just number and couldn't find units";
  }
}

sub cache_hash {
  my $self = $_[0];

  unless($self->{base_hash} && ref $self->{base_hash} && ref $self->{base_hash} eq 'HASH') {
    confess "need a hash ref for base_hash";
  }

  $self->handle_ttl;

  unless(exists $self->{base_hash}{$self->{ttl}}) {
    $self->{base_hash}{$self->{ttl}} = {};
  }

  
  $self->{int_time} = (int(time/$self->{ttl}));

  if(exists $self->{base_hash}{$self->{ttl}}{$self->{int_time}}) {

  } else {
    foreach my $key (keys %{$self->{base_hash}{$self->{ttl}}}) {

      if($self->expired_check($key)) {
        $self->cleanup($self->{base_hash}{$self->{ttl}}, $key);
      }
    }
    $self->{base_hash}{$self->{ttl}}{$self->{int_time}} = {};
  }
  return $self->{base_hash}{$self->{ttl}}{$self->{int_time}};
}

package Data::Fallback;

use strict;
use vars qw($VERSION);
use Exporter;

$VERSION = "0.01";

use Carp qw(confess);

sub new {
  my $type  = shift;
  my @PASSED_ARGS = (ref $_[0] eq 'HASH') ? %{$_[0]} : @_;
  my @DEFAULT_ARGS = (
    cache               => {},

    # cache_level looks like 
    # session.group
    # session.item
    # all.group
    # all.item
    cache_level         => 'session',
    cache_order         => ['session', 'all', 0],
    cache_type          => ['item', 'group'],

    list                => [],
    list_name           => '',

    use_zeroth_hash      => 1,
  );
  my %ARGS = (@DEFAULT_ARGS, @PASSED_ARGS);
  my $self = bless \%ARGS, $type;
  if($self->{use_zeroth_hash}) {
    $self->set_zeroth_hash($self->{zeroth_hash}) 
  } else {
    delete $self->{use_zeroth_hash};
  }
  
  return $self;
}

sub set_zeroth_hash {
  my $self = shift;
  my $passed_zeroth_hash = shift;
  $passed_zeroth_hash ||= {};
  my %zeroth_hash = ( (
    zeroth_hash   => 1,
    accept_update => 'item',
    package       => 'Memory',
    ), %{$passed_zeroth_hash}
  );
  $self->{zeroth_hash} = \%zeroth_hash;
  if($self->{zeroth_hash}{ttl}) {
    $self->{zeroth_hash}{cache_hash} = CacheHash->new({
      ttl => $self->{zeroth_hash}{ttl},
    });
    delete $self->{zeroth_hash}{ttl};
  }
}

sub get {
  my $self = shift;
  my $chunk = shift;

  my ($primary_key, $items);
  if($chunk =~ m@^/(.+?)/(.+)$@) {
    ($primary_key, $items) = ($1, $2);
  } else {
    $items = $chunk;
  }
  die "need a \$self->{list_name}" unless( (defined $self->{list_name}) && length $self->{list_name});
  die "\$self->{list} is required" unless $self->{list};
  die "\$self->{list} needs to be an array ref" unless(ref $self->{list} && ref $self->{list} eq 'ARRAY');
  die "\$self->{list} needs to be an array ref of hash refs" unless(ref $self->{list}[0] && ref $self->{list}[0] eq 'HASH');
  die "usage: \$self->get('item1,item2') ($chunk)" unless( (defined $items) && length $items);

  if($self->{use_zeroth_hash} && !$self->{list}[0]{zeroth_hash}) {
    unshift @{$self->{list}}, $self->{zeroth_hash};
  }

  $self->{update} = {};
  my $return = [];
  $self->{history} = [];
  foreach my $item (split /\s*,\s*/, $items) {

    $self->{item} = $item;

    $self->{got_item_from} = "";
    $self->{from_cache}    = "";

    for($self->{i}=0;$self->{i}<@{$self->{list}};$self->{i}++) {
      $self->{hash} = $self->{list}[$self->{i}];
      $self->{hash}{item} = $item;

      $self->{this_primary_key} = $primary_key || $self->{hash}{primary_key} || $self->{primary_key} || '';


      my $clean_hash_content = 0;
      my $orig_hash_content = '';
      if($self->{hash}{content} && $self->{hash}{content} =~ /\$primary_key\b/) {
        
        $orig_hash_content = $self->{hash}{content};
        $self->{hash}{content} =~ s/\$primary_key\b/$self->{this_primary_key}/;

        $clean_hash_content = 1;

      }

      die "need a content" if(!$self->{hash}{content} && !$self->{hash}{zeroth_hash});

      $self->{hash}{package} ||= $self->{package};
      die "need a package" if(!$self->{hash}{package});

      $self->morph($self->{hash}{package});
      $self->{hash}{content} ||= '';
      if($self->_GET) {
        $self->{got_item_from} = $self->{hash}{package};
        $self->{got_item_from} .= " ($self->{from_cache})" if($self->{from_cache});
        push @{$return}, $self->{update}{item};
        push @{$self->{history}}, {
          content       => $self->{hash}{content},
          got_item_from => $self->{got_item_from},
          item          => $self->{item},
          value         => $self->{update}{item},
        };
        if($clean_hash_content) {
          $self->{hash}{content} = $orig_hash_content;
          $self->{true_content} = $orig_hash_content;
        }
        $self->list_update($self->{i});
        last;
      } else {
        if($clean_hash_content) {
          $self->{hash}{content} = $orig_hash_content;
          $self->{true_content} = $orig_hash_content;
        }
      }
    }
    unless($self->{got_item_from}) {
      # I didn't find a value, so add on undef
      push @{$return}, '';
      push @{$self->{history}}, {
        content       => $self->{true_content},
        got_item_from => 'nowhere',
        item => $self->{item},
        value         => 'NULL',
      };
    }
    foreach(qw(i item update)) {
      delete $self->{$_};
    }
  }
  if(scalar @{$return} == 0) {
    # gonna return undef
  } elsif( scalar @{$return} == 1) {
    $return = $return->[0];
  } else {
    $return = wantarray ? @{$return} : $return;
  }
  return $return;
}

sub get_accept_update {
  my $self = shift;
  my $accept_update = 0;
  if( (defined $self->{hash}{accept_update}) && length $self->{hash}{accept_update}) {
    $accept_update = $self->{hash}{accept_update};
  } elsif( (defined $self->{accept_update}) && length $self->{accept_update}) {
    $accept_update = $self->{accept_update};
  }
  return $accept_update;
}

sub list_update {
  my $self = shift;
  my $i = shift;
  for(my $j=($i - 1);$j>=0;$j--) {
    $self->{hash} = $self->{list}[$j];
    my $accept_update = $self->get_accept_update;
    next unless($accept_update);

    my $delete_hash_primary_key;
    if(!exists $self->{hash}{primary_key} && exists $self->{set_primary_key}) {
      $self->{hash}{primary_key} = $self->{set_primary_key};
    }

    if(!ref $accept_update) {
      $self->_list_update_helper($accept_update);
    } else {
      if(ref $accept_update eq 'ARRAY') {
        for(my $i=0;$i<@{$accept_update};$i++) {
          my $this_update = $accept_update->[$i];
          if(ref $this_update) {
            if(ref $this_update eq 'Regexp') {
              if($self->{got_item_from} && $self->{got_item_from} =~ /$this_update/) {
                if($accept_update->[($i + 1)]) {
                  $self->_list_update_helper($accept_update->[($i + 1)]);
                }
              }
            } elsif(ref $this_update eq 'CODE') {
              my $return = &{$this_update}($self);
              $self->_list_update_helper($return);
            }
          }
        }
      }
    }
    delete $self->{hash}{primary_key} if($delete_hash_primary_key);
  }
}

sub _list_update_helper {
  my $self = shift;
  my $update_type = shift;
  if($update_type eq 'item') {
    $self->update_item;
  } elsif($update_type eq 'group') {
    $self->update_group;
  } elsif($update_type eq 'all') {
    $self->update_item;
    $self->update_group;
  } else {
    confess "unknown \$update_type: $update_type";
  }
}

sub update_item {
  my $self = shift;
  if(exists $self->{update}{item}) {
    $self->morph($self->{hash}{package});
    $self->SET_ITEM;
  }
}

sub update_group {
  my $self = shift;
  if( (defined $self->{update}{item}) && length $self->{update}{item}) {
    $self->morph($self->{hash}{package});
    $self->SET_GROUP;
  }
}

sub set_list_name {
  my $self = shift;
  my $list_name = shift || die "need a list_name";
  $self->{list_name} = $list_name;
}

sub set_list {
  my $self = shift;
  my $list = shift;
  die "need a list" unless($list);
  die "list needs to be an ARRAY ref" unless(ref $list && ref $list eq 'ARRAY');
  $self->{list} = $list;
}

sub INITIALIZE_PACKAGE {
  return;
}

### this turns the object into the correct type
### thanks to Paul Seamons for the start of this code
sub morph {
  my $self = shift;
  my $package = shift;

  my $tmp_package = $package;
  $tmp_package =~ s@::@/@g;
  ### polymorph

  my $at = '';
  # this little trick should allow users to write their own overriding
  # fallback methods, thanks to Rob Brown for the idea
  if($tmp_package =~ m@/@) {
    eval {
      require "$tmp_package.pm";
    };
    if($@) {
      $at .= $@;
    } else {
      bless $self, $package;
    }
  } else {

    # likely a Data::Fallback package
    eval {
      require "Data/Fallback/$tmp_package.pm";
    };
    if( $@ ){
      $at .= $@;
      # this is just for sort of top level stuff like CGI
      eval {
        require "$tmp_package.pm";
      };

      if($@) {
        $at .= $@;
      } else {
        $at = '';
        bless $self, $package;
      }

    } else {
      bless $self, "Data::Fallback::$package";
    }
  }
  die "bad stuff on require of $tmp_package: $at" if($at);
  $self->INITIALIZE_PACKAGE($package);
  return $self;
}

sub SET_SESSION_ITEM {
  die "need to write a SET_SESSION_ITEM method";
}

sub SET_SESSION_CONTENT {
  die "need to write a SET_SESSION_CONTENT method";
}

sub SET_ITEM {
  die "need to write a SET_ITEM method";
}

sub SET_GROUP {
  die "need to write a SET_GROUP method";
}

sub delete_list {
  my $self = shift;
  delete $self->{list};
}

sub get_cache_level {
  my $self = shift;
  my $return = $self->{cache_level};
  # just going to look in two places, the hash, then the object
  if( (defined $self->{hash}{cache_level}) && length $self->{hash}{cache_level}) {
    $return = $self->{hash}{cache_level};
  } elsif( (defined $self->{cache_level}) && length $self->{cache_level}) {
    $return = $self->{cache_level};
  }
  unless(grep {$return eq $_} @{$self->{cache_order}}) {
    confess "Unknown cache_level: $return. Known cache_order: " . join(", ", @{$self->{cache_order}});
  }
  return $return;
}

sub check_cache {
  my $self = shift;
  my ($package, $type, $key) = @_;
  my ($found_in_cache, $content) = (0, 0, 0);
  foreach my $cache_level (@{$self->{cache_order}}) {
    last unless($cache_level);
    next unless( 
        $self->{cache}                                                    && 
        $self->{cache}{$package}                                          && 
        $self->{cache}{$package}{$cache_level}                            &&
        $self->{cache}{$package}{$cache_level}{$self->{list_name}}        &&
        $self->{cache}{$package}{$cache_level}{$self->{list_name}}{$type});

    my $ref;
    if($self->cache_hashed) {
      $self->{hash}{cache_hash}{base_hash} = $self->{cache}{$package}{$cache_level}{$self->{list_name}}{$type};
      $ref = $self->{hash}{cache_hash}->cache_hash;
    } else {
      $ref = $self->{cache}{$package}{$cache_level}{$self->{list_name}};
    }
    if(defined $ref->{$type}{$key}) {
      $found_in_cache = 1;
      $content = $ref->{$type}{$key};
      $self->{from_cache} = "cache - $type";
      $self->{from_cache} .= " ttl ($self->{hash}{cache_hash}{int_time})" if($self->cache_hashed);
      last;
    }
  }
  return ($found_in_cache, $content);
}

sub set_cache {
  my $self = shift;
  my ($package, $type, $key, $value) = @_;
  unless(grep {$type eq $_} @{$self->{cache_type}}) {
    confess "Unknown cache_type: $type. Known cache_types: " . join(", ", @{$self->{cache_type}});
  }
  confess "need a cache \$key" unless($key);
  confess "need a cache \$value" unless( (defined $value) && length $value);
  my $cache_level = $self->get_cache_level;
  return unless($cache_level);
  $self->{cache}{$package} ||= {};
  $self->{cache}{$package}{$cache_level} ||= {};
  $self->{cache}{$package}{$cache_level}{$self->{list_name}} ||= {};
  $self->{cache}{$package}{$cache_level}{$self->{list_name}}{$type} ||= {};
  my $ref;
  if($self->cache_hashed) {
    $self->{hash}{cache_hash}{base_hash} = $self->{cache}{$package}{$cache_level}{$self->{list_name}}{$type};
    $ref = $self->{hash}{cache_hash}->cache_hash;
  } else {
    $ref = $self->{cache}{$package}{$cache_level}{$self->{list_name}}{$type};
  }
  $ref->{$key} = $value;
}

sub cache_hashed {
  my $self = shift;
  return $self->{hash}{cache_hash} && $self->{hash}{cache_hash}{ttl};
}

sub get_cache_key {
  my $self = shift;
  my $key = shift;
  return $self->{"this_$key"} || $self->{hash}{$key} || $self->{$key} || '';
}


=head1 NAME

Data::Fallback - fallback through an array of levels till you find your data, cacheing where desired

=head1 DESCRIPTION

The simplest, good example for Data::Fallback, is cacheing a database to a conf file, then to memory.  In general, the user
supplies an array ref of hash refs (an object property named list), where each hash ref explains how to get data for that step.  Each
hash ref needs a package, which currently can be Memory, ConfFile, DBI, or WholeFile.  Update acceptance can be set for each level.

Data::Fallback then goes through the array, checking for data, stopping when it finds said data, updates up the array, 
as requested, and returns the data.

A group can be thought of as a row and an item a column.

=head1 INFORMAL EXAMPLE

Start with a table foo.

  column       data

  ------       ----
  id           1
  name         Chopper

and a file foo.cache.  I offer two sets of hits, in a mod_perl of daemon environment, both trying to 

  SELECT id FROM foo WHERE name = 'Chopper'

  Set 1
    Hit 1a
      Check memory    -> data not there
      Check foo.cache -> data not there
      Check db        -> data is there
      Update foo.cache
      Update memory
      Return id = 1

    Hit 1b
      Check memory    -> data is there
      Return id = 1

  Set 2, after a restart
    Hit 2a
      Check memory    -> data not there
      Check foo.cache -> data is there
      Update memory
      Return id = 1

    Hit 2b
      Check memory    -> data is there
      Return id = 1

So, even after the restart, the database only gets hit once.

=head1 EXAMPLE

  #!/usr/bin/perl -w

  use strict;
  use Data::Fallback;
  use Carp qw(confess);

  # I use dumper just to show some complex structures
  use Data::Dumper;

  # here I write out a couple files which I late clean up
  # the idea is that the over file, overrides the default file

  my $over_file    = "/tmp/data_fallback_over";
  my $default_file = "/tmp/data_fallback_default";

  open (FILE, ">$over_file") || confess "couldn't open $over_file: $!";
  print FILE "key2 over2";
  close(FILE);

  open (FILE, ">$default_file") || confess "couldn't open $default_file: $!";
  print FILE "key1 default1\nkey2 default2";
  close(FILE);

  my $self = Data::Fallback->new({

  # list is an array ref of hash refs to fall through looking for data

    list => [
      {
        # accept_update says to update the conf
        accept_update => 'group',

        # this means to cache everything
        cache_level => 'all',

        # where to get the content
        content => $over_file,
      },
      {
        cache_level => 'all',
        content     => $default_file,
      },
    ],

    # need to name list
    list_name => 'test',

    # object global for package
    package => 'ConfFile',

    zeroth_hash => {
      ttl => '5 seconds',
    },
  });
  print $self->get('key2') . "\n";
  print Dumper $self->{history};
  print $self->get('key2') . "\n";
  print Dumper $self->{history};
  print $self->get('key1') . "\n";
  print Dumper $self->{history};
  print $self->get('key1') . "\n";
  print Dumper $self->{history};
  unlink $over_file, $default_file;

=head1 PACKAGES

You are able to write your own packages that aren't a part of Data::Fallback.  Such packages would look something like this

#!/usr/bin/perl -w

package Mine;

use strict;
use Data::Fallback;
use vars qw(@ISA);

@ISA = qw(Data::Fallback);

1;

and methods for at least each of the following _GET, SET_ITEM, SET_GROUP, SET_SESSION_ITEM, SET_SESSION_CONTENT.  This
functionality allows you to build your content however you like, from wherever you like.  For example, let's supposing you have
your own objects that build entire pages.  You could simply wrap around said objects with the above methods.  Put a nice
WholeFile cache that accepts updates in front of your personal object.  On the first hit, your content gets generated, in some
potentially very expensive way.  On the second hit you cache from either the Memory package, or the WholeFile level you inserted.
Currently, there are cacheing issues, but I hope yo clear them up in time.

=head1 APOLOGIES

This perldoc isn't the best, but I plan on continued development for sometime.  In other words, a better perldoc is to come.
And a better test suite.  If you feel so inclined to use Data::Fallback::Daemon, do so realizing that the protocol is sure to change.
The TO_DO shows where the poject is headed.

=head1 THANKS

Thanks to Rob Brown, Paul Seamons, Allen Bettilyon and Dan Hanks for listening to my babblings and offering feedback.  Thanks to Rob
Brown for testing my first version.  Also, thanks to Paul for Net::Server and helping me set up Data::Fallback::Daemon.  Lincoln Stein's
AUTHOR INFORMATION was borrowed from heavily.

=head1 AUTHOR

Copyright 2001-2002, Earl J. Cahill.  All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Address bug reports and comments to: cpan@spack.net.

When sending bug reports, please provide the version of Data::Fallback, the version of Perl, and the name and version of the operating
system you are using.

=cut

1;
