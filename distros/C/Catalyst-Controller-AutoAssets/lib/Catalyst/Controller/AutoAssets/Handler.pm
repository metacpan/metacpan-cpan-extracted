package Catalyst::Controller::AutoAssets::Handler;
use strict;
use warnings;

# VERSION

use Moose::Role;
use namespace::autoclean;

requires qw(
  asset_request
  write_built_file
);

use Cwd;
use Path::Class 0.32 qw( dir file );
use Fcntl qw( :DEFAULT :flock );
use Carp;
use File::stat qw(stat);
use Catalyst::Utils;
use Time::HiRes qw(gettimeofday tv_interval);
use Storable qw(store retrieve);
use Try::Tiny;
use Data::Dumper::Concise 'Dumper';

require Digest::SHA1;
require MIME::Types;
require Module::Runtime;

has 'Controller' => (
  is => 'ro', required => 1,
  isa => 'Catalyst::Controller::AutoAssets',
  handles => [qw(type _app action_namespace unknown_asset _build_params _module_version)],
);

# Directories to include
has 'include', is => 'ro', isa => 'ScalarRef|Str|ArrayRef[ScalarRef|Str]', required => 1;

# Optional regex to require files to match to be included
has 'include_regex', is => 'ro', isa => 'Maybe[Str]', default => undef;

# Optional regex to exclude files
has 'exclude_regex', is => 'ro', isa => 'Maybe[Str]', default => undef;

# Whether or not to use qr/$regex/i or qr/$regex/
has 'regex_ignore_case', is => 'ro', isa => 'Bool', default => 0;

# Whether or not to make the current asset available via 307 redirect to the
# real, current checksum/fingerprint asset path
has 'current_redirect', is => 'ro', isa => 'Bool', default => 1;

# What string to use for the 'current' redirect
has 'current_alias', is => 'ro', isa => 'Str', default => 'current';

# Whether or not to make the current asset available via a static path
# with no benefit of caching
has 'allow_static_requests', is => 'ro', isa => 'Bool', default => 0;

# What string to use for the 'static' path
has 'static_alias', is => 'ro', isa => 'Str', default => 'static';

# Extra custom response headers for current/static requests 
has 'current_response_headers', is => 'ro', isa => 'HashRef', default => sub {{}};
has 'static_response_headers', is => 'ro', isa => 'HashRef', default => sub {{}};

# Whether or not to set 'Etag' response headers and check 'If-None-Match' request headers
# Very useful when using 'static' paths
has 'use_etags', is => 'ro', isa => 'Bool', default => 0;

# Max number of seconds before recalculating the fingerprint (sha1 checksum)
# regardless of whether or not the mtime has changed. 0 means infinite/disabled
has 'max_fingerprint_calc_age', is => 'ro', isa => 'Int', default => sub {0};

# Max number of seconds to wait to obtain a lock (to be thread safe)
has 'max_lock_wait', is => 'ro', isa => 'Int', default => 120;

has 'cache_control_header', is => 'ro', isa => 'Str', 
  default => sub { 'public, max-age=31536000, s-max-age=31536000' }; # 31536000 = 1 year

# Whether or not to use stored state data across restarts to avoid rebuilding.
has 'persist_state', is => 'ro', isa => 'Bool', default => sub{0};

# Optional shorter checksum
has 'sha1_string_length', is => 'ro', isa => 'Int', default => sub{40};

# directory to use for relative includes (defaults to the Catalyst home dir);
# TODO: coerce from Str
has 'include_relative_dir', isa => 'Path::Class::Dir', is => 'ro', lazy => 1, default => sub { 
  my $self = shift;
  my $home = $self->_app->config->{home};
  $home = $home && -d $home ? $self->_app->config->{home} : cwd();
  return dir( $home );
};



######################################


sub BUILD {}
before BUILD => sub {
  my $self = shift;
  
  # optionally initialize state data from the copy stored on disk for fast
  # startup (avoids having to always rebuild after every app restart):
  $self->_restore_state if($self->persist_state);

  # init includes
  $self->includes;
  
  Catalyst::Exception->throw("Must include at least one file/directory")
    unless (scalar @{$self->includes} > 0);

  # if the user picks something lower than 5 it is probably a mistake (really, anything
  # lower than 8 is probably not a good idea. But the full 40 is probably way overkill)
  Catalyst::Exception->throw("sha1_string_length must be between 5 and 40")
    unless ($self->sha1_string_length >= 5 && $self->sha1_string_length <= 40);

  # init work_dir:
  $self->work_dir->mkpath($self->_app->debug);
  $self->work_dir->resolve;
  
  $self->prepare_asset;
};

# Main code entry point:
sub request {
  my ( $self, $c, @args ) = @_;
  my $sha1 = $args[0];
  
  return $self->current_request($c, @args) if (
    $self->is_current_request_arg(@args)
  );
  
  return $self->static_request($c, @args) if (
    $self->allow_static_requests
    && $self->static_alias eq $sha1
  );
  
  return $self->handle_asset_request($c, @args);
}

sub is_current_request_arg {
  my ($self, $arg) = @_;
  return $arg eq $self->current_alias ? 1 : 0;
}

sub current_request  {
  my ( $self, $c, $arg, @args ) = @_;
  my %headers = (
    'Cache-Control' => 'no-cache',
    %{$self->current_response_headers}
  );
  $c->response->header( $_ => $headers{$_} ) for (keys %headers);
  $c->response->redirect(join('/',$self->asset_path,@args), 307);
  return $c->detach;
}

sub static_request  {
  my ( $self, $c, $arg, @args ) = @_;
  my %headers = (
    'Cache-Control' => 'no-cache',
    %{$self->static_response_headers}
  );
  $c->response->header( $_ => $headers{$_} ) for (keys %headers);
  # Simulate a request to the current sha1 checksum:
  return $self->handle_asset_request($c, $self->asset_name, @args);
}


sub handle_asset_request {
  my ( $self, $c, $arg, @args ) = @_;
  
  $self->prepare_asset(@args);
  
  if($self->use_etags && $self->client_current_etag($c, $arg, @args)) {
    # Set 304 Not Modified:
    $c->response->status(304);
  }
  else {
    $self->asset_request($c, $arg, @args);
  }
  return $c->detach;
}

sub client_current_etag {
  my ( $self, $c, $arg, @args ) = @_;
  
  my $etag = $self->etag_value(@args);
  $c->response->header( Etag => $etag );
  my $client_etag = $c->request->headers->{'if-none-match'};
  return ($client_etag && $client_etag eq $etag) ? 1 : 0;
}

sub etag_value {
  my $self = shift;
  return '"' . join('/',$self->asset_name,@_) . '"';
}


############################


has 'work_dir', is => 'ro', isa => 'Path::Class::Dir', lazy => 1, default => sub {
  my $self = shift;
  my $c = $self->_app;
  
  my $tmpdir = Catalyst::Utils::class2tempdir($c)
    || Catalyst::Exception->throw("Can't determine tempdir for $c");
    
  return dir($tmpdir, "AutoAssets",  $self->action_namespace($c));
};

has 'built_file', is => 'ro', isa => 'Path::Class::File', lazy => 1, default => sub {
  my $self = shift;
  my $filename = 'built_file';
  return file($self->work_dir,$filename);
};

has 'scratch_dir', is => 'ro', isa => 'Path::Class::Dir', lazy => 1, default => sub {
  my $self = shift;
  
  my $Dir = dir($self->work_dir,'_scratch');
  $Dir->rmtree if (-d $Dir);
  $Dir->mkpath;
  
  return $Dir
};

has 'fingerprint_file', is => 'ro', isa => 'Path::Class::File', lazy => 1, default => sub {
  my $self = shift;
  return file($self->work_dir,'fingerprint');
};

has 'lock_file', is => 'ro', isa => 'Path::Class::File', lazy => 1, default => sub {
  my $self = shift;
  return file($self->work_dir,'lockfile');
};


has 'includes', is => 'ro', isa => 'ArrayRef', lazy => 1, default => sub {
  my $self = shift;
  my $rel = $self->include_relative_dir;

  my @list = ((ref $self->include)||'') eq 'ARRAY' ? @{$self->include} : $self->include;
  my $i = 0;
  return [ map {
    my $inc; $i++;
    if((ref($_)||'') eq 'SCALAR') {
      # New support for ScalarRef includes ... we pre-dump them to a temp file
      $inc = file( $self->scratch_dir, join('','_generated_include_file_',$i) );
      $inc->spew(iomode => '>:raw', $$_);
    }
    else {
      $inc = file($_);
    }
    $inc = $rel->file($inc) unless ($inc->is_absolute);
    $inc = dir($inc) if (-d $inc); #<-- convert to Path::Class::Dir
    $inc->resolve
  } @list ];
};




sub get_include_files {
  my $self = shift;
  
  my @excluded = ();
  my @files = ();
  for my $inc (@{$self->includes}) {
    if($inc->is_dir) {
      $inc->recurse(
        preorder => 1,
        depthfirst => 1,
        callback => sub {
          my $child = shift;
          $self->_valid_include_file($child)
            ? push @files, $child->absolute
            : push @excluded, $child->absolute;
        }
      );
    }
    else {
      $self->_valid_include_file($inc) 
        ? push @files, $inc->absolute 
        : push @excluded, $inc->absolute;
    }
  }
  
  # Some handlers (like Directory) need to know about excluded files
  $self->_record_excluded_files(\@excluded);
  
  # force consistent ordering of files:
  return [sort @files];
}

# optional hook for excluded files:
sub _record_excluded_files {}


has '_include_regexp', is => 'ro', isa => 'Maybe[RegexpRef]', 
 lazy => 1, init_arg => undef, default => sub {
   my $self = shift;
   my $str = $self->include_regex or return undef;
   return $self->regex_ignore_case ? qr/$str/i : qr/$str/;
};
has '_exclude_regexp', is => 'ro', isa => 'Maybe[RegexpRef]', 
 lazy => 1, init_arg => undef, default => sub {
   my $self = shift;
   my $str = $self->exclude_regex or return undef;
   return $self->regex_ignore_case ? qr/$str/i : qr/$str/;
};

sub _valid_include_file {
  my ($self, $file) = @_;
  return (
    $file->is_dir
    || ($self->include_regex && ! ($file =~ $self->_include_regexp))
    || ($self->exclude_regex && $file =~ $self->_exclude_regexp)
  ) ? 0 : 1;
}

has 'last_fingerprint_calculated', is => 'rw', isa => 'Maybe[Int]', default => sub{undef};

has 'built_mtime', is => 'rw', isa => 'Maybe[Str]', default => sub{undef};
sub get_built_mtime {
  my $self = shift;
  return -f $self->built_file ? $self->built_file->stat->mtime : undef;
}

# inc_mtimes are the mtime(s) of the include files. For directory assets
# this is *only* the mtime of the top directory (see subfile_meta below)
has 'inc_mtimes', is => 'rw', isa => 'Maybe[Str]', default => undef;
sub get_inc_mtime_concat {
  my $self = shift;
  my $list = shift;
  return join('-', map { $_->stat->mtime } @$list );
}


sub calculate_fingerprint {
  my $self = shift;
  my $list = shift;
  # include both the include (source) and built (output) in the fingerprint:
  my $sha1 = $self->file_checksum(@$list,$self->built_file);
  $self->last_fingerprint_calculated(time) if ($sha1);
  return $sha1;
}

sub current_fingerprint {
  my $self = shift;
  return undef unless (-f $self->fingerprint_file);
  my $fingerprint = $self->fingerprint_file->slurp(iomode => '<:raw');
  return $fingerprint;
}

sub save_fingerprint {
  my $self = shift;
  my $fingerprint = shift or die "Expected fingerprint/checksum argument";
  return $self->fingerprint_file->spew(iomode => '>:raw', $fingerprint);
}

sub calculate_save_fingerprint {
  my $self = shift;
  my $fingerprint = $self->calculate_fingerprint(@_) or return 0;
  return $self->save_fingerprint($fingerprint);
}

sub fingerprint_calc_current {
  my $self = shift;
  my $last = $self->last_fingerprint_calculated or return 0;
  return 1 if ($self->max_fingerprint_calc_age == 0); # <-- 0 means infinite
  return 1 if (time - $last < $self->max_fingerprint_calc_age);
  return 0;
}

# -----
# Quick and dirty state persistence for faster startup
has 'persist_state_file', is => 'ro', isa => 'Path::Class::File', lazy => 1, default => sub {
  my $self = shift;
  return file($self->work_dir,'state.dat');
};

has '_persist_attrs', is => 'ro', isa => 'ArrayRef', default => sub{[qw(
 built_mtime
 inc_mtimes
 last_fingerprint_calculated
)]};

sub _persist_state {
  my $self = shift;
  return undef unless ($self->persist_state);
  my $data = { map { $_ => $self->$_ } @{$self->_persist_attrs} };
  $data->{_module_version} = $self->_module_version;
  $data->{_build_params} = $self->_build_params;
  store $data, $self->persist_state_file;
  return $data;
}

sub _restore_state {
  my $self = shift;
  return 0 unless (-f $self->persist_state_file);
  my $data;
  try {
    $data = retrieve $self->persist_state_file;
    if($self->_valid_state_data($data)) {
      $self->$_($data->{$_}) for (@{$self->_persist_attrs});
    }
  }
  catch {
    $self->clear_asset; #<-- make sure no partial state data is used
    $self->_app->log->warn(
      'Failed to restore state from ' . $self->persist_state_file
    );
  };
  return $data;
}

sub _valid_state_data {
  my ($self, $data) = @_;
  
  # Make sure the version and config params hasn't changed
  return (
    $self->_module_version eq $data->{_module_version}
    && Dumper($self->_build_params) eq Dumper($data->{_build_params})
  ) ? 1 : 0;
}
# -----


# force rebuild on next request/prepare_asset
sub clear_asset {
  my $self = shift;
  $self->inc_mtimes(undef);
}

sub _build_required {
  my ($self, $d) = @_;
  return (
    $self->inc_mtimes && $self->built_mtime &&
    $d->{inc_mtimes} && $d->{built_mtime} &&
    $self->inc_mtimes eq $d->{inc_mtimes} &&
    $self->built_mtime eq $d->{built_mtime} &&
    $self->fingerprint_calc_current
  ) ? 0 : 1;
}


# Gets the data used throughout the prepare_asset process:
sub get_prepare_data {
  my $self = shift;
  
  my $files = $self->get_include_files;
  my $inc_mtimes = $self->get_inc_mtime_concat($files);
  my $built_mtime = $self->get_built_mtime;
  
  return {
    files => $files,
    inc_mtimes => $inc_mtimes,
    built_mtime => $built_mtime
  };
}

sub before_prepare_asset {}

sub prepare_asset {
  my $self = shift;
  my $start = [gettimeofday];

  # Optional hook:
  $self->before_prepare_asset(@_);

  my $opt = $self->get_prepare_data;
  return 1 unless $self->_build_required($opt);

  ####  -----
  ####  The code above this line happens on every request and is designed
  ####  to be as fast as possible
  ####
  ####  The code below this line is (comparatively) expensive and only
  ####  happens when a rebuild is needed which should be rare--only when
  ####  content is modified, or on app startup (unless 'persist_state' is set)
  ####  -----

  ### Do a rebuild:

  # --- Blocks for up to max_lock_wait seconds waiting to get an exclusive lock
  # The lock is held until it goes out of scope.
  # If we fail to get the lock, we just continue anyway in hopes that the second
  # build won't corrupt the first, which is arguably better than killing the
  # request.
  my $lock= try { $self->_get_lock($self->lock_file, $self->max_lock_wait); };
  # ---
  
  $self->build_asset($opt);
  
  $self->_app->log->debug(
    "Built asset: " . $self->base_path . '/' . $self->asset_name .
    ' in ' . sprintf("%.3f", tv_interval($start) ) . 's'
  ) if ($self->_app->debug);

  # Release the lock and return:
  $self->_persist_state;
  return 1;
}

sub build_asset {
  my ($self, $opt) = @_;
  
  my $files = $opt->{files} || $self->get_include_files;
  my $inc_mtimes = $opt->{inc_mtimes} || $self->get_inc_mtime_concat($files);
  my $built_mtime = $opt->{built_mtime} || $self->get_built_mtime;
  
  # Check the fingerprint to see if we can avoid a full rebuild (if mtimes changed
  # but the actual content hasn't by comparing the fingerprint/checksum):
  my $fingerprint = $self->calculate_fingerprint($files);
  my $cur_fingerprint = $self->current_fingerprint;
  if($fingerprint && $cur_fingerprint && $cur_fingerprint eq $fingerprint) {
    # If the mtimes changed but the fingerprint matches we don't need to regenerate. 
    # This will happen if another process just built the files while we were waiting 
    # for the lock and on the very first time after the application starts up
    $self->inc_mtimes($inc_mtimes);
    $self->built_mtime($built_mtime);
    $self->_persist_state;
    return 1;
  }

  ### Ok, we really need to do a full rebuild:

  my $fd = $self->built_file->openw or die $!;
  binmode $fd;
  $self->write_built_file($fd,$files);
  $fd->close if ($fd->opened);
  
  # Update the fingerprint (global) and cached mtimes (specific to the current process)
  $self->inc_mtimes($opt->{inc_mtimes});
  $self->built_mtime($self->get_built_mtime);
  # we're calculating the fingerprint again because the built_file, which was just
  # regenerated, is included in the checksum data. This could probably be optimized,
  # however, this only happens on rebuild which rarely happens (should never happen)
  # in production so an extra second is no big deal in this case.
  $self->calculate_save_fingerprint($opt->{files});
}

sub file_checksum {
  my $self = shift;
  my $files = ref $_[0] eq 'ARRAY' ? $_[0] : \@_;
  
  my $Sha1 = Digest::SHA1->new;
  foreach my $file ( grep { -f $_ } @$files ) {
    my $fh = $file->openr or die "$! : $file\n";
    binmode $fh;
    $Sha1->addfile($fh);
    $fh->close;
  }

  return substr $Sha1->hexdigest, 0, $self->sha1_string_length;
}

sub asset_name { (shift)->current_fingerprint }

sub base_path {
  my $self = shift;
  my $pfx = try{RapidApp->active_request_context->mount_url} || '';
  return join('/',$pfx,$self->action_namespace($self->_app)); 
}

# this is just used for some internal optimization to avoid calling stat
# duplicate times. It is basically me being lazy, adding an internal extra param
# to asset_path() without changing its public API/arg list
has '_asset_path_skip_prepare', is => 'rw', isa => 'Bool', default => 0;
before asset_path => sub {
  my $self = shift;
  $self->prepare_asset(@_) unless ($self->_asset_path_skip_prepare);
};
sub asset_path {
  my $self = shift;
  return $self->base_path . '/' . $self->asset_name;
}

sub html_head_tags { undef }

# This locks a file or dies trying, and on success, returns a "lock object"
# which will release the lock if it goes out of scope.  At the moment, this
# "object" is just a file handle.
#
# This lock is specifically *not* inherited by child processes (thanks to
# fcntl(FL_CLOEXEC), and in fact, this design principle gives it
# cross-platform compatibility that most lock module sdon't have.
# 
sub _get_lock {
  my ($self, $fname, $timeout)= @_;
  my $fh;
  sysopen($fh, $fname, O_RDWR|O_CREAT|O_EXCL, 0644)
    or sysopen($fh, $fname, O_RDWR)
    or croak "Unable to create or open $fname";
  
  try { fcntl($fh, F_SETFD, FD_CLOEXEC) }
    or carp "Failed to set close-on-exec for $fname (see BUGS in Catalyst::Controller::AutoAssets)";
  
  # Try to get lock until timeout.  We poll because there isn't a sensible
  # way to wait for the lock.  (I don't consider SIGALRM to be very sensible)
  my $deadline= Time::HiRes::time() + $timeout;
  my $locked= 0;
  while (1) {
    last if flock($fh, LOCK_EX|LOCK_NB);
    croak "Can't get lock on $fname after $timeout seconds" if Time::HiRes::time() >= $deadline;
    Time::HiRes::sleep(0.4);
  }
  
  # Succeeded in getting the lock, so write our pid.
  my $data= "$$";
  syswrite($fh, $data, length($data)) or croak "Failed to write pid to $fname";
  truncate($fh, length($data)) or croak "Failed to resize $fname";
  
  return $fh;
}

1;

__END__

=pod

=head1 NAME

Catalyst::Controller::AutoAssets::Handler - Handler type Role and default namespace

=head1 DESCRIPTION

This is the base Role for C<Catalyst::Controller::AutoAssets> Handler classes and is
where the majority of the work is done for the AutoAssets module. The Handler class is 
specified in the 'type' config param and is relative to this namespace. Absolute class
names can also be specified with the '+' prefix, so the following are equivalent:

  type => 'Directory'
  
  type => '+Catalyst::Controller::AutoAssets::Handler::Directory'

Custom Handler classes can be written and used as long as they consume this Role. For examples
of how to write custom Handlers, see the existing Handlers below for reference.

=head1 TYPE HANDLERS

These are the current built in handler classes:

=over

=item L<Catalyst::Controller::AutoAssets::Handler::Directory>

=item L<Catalyst::Controller::AutoAssets::Handler::CSS>

=item L<Catalyst::Controller::AutoAssets::Handler::JS>

=item L<Catalyst::Controller::AutoAssets::Handler::ImageSet>

=item L<Catalyst::Controller::AutoAssets::Handler::IconSet>

=back

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


