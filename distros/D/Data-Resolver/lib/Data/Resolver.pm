package Data::Resolver;
use v5.24;
use Carp;
use English      qw< -no_match_vars >;
use experimental qw< signatures >;
{ our $VERSION = '0.001001' }

use JSON::PP qw< decode_json >;

use Exporter qw< import >;
my @FACTORIES = qw<
  generate
  resolver_from_dir
  resolver_from_passthrough
  resolver_from_tar
>;
my @INTEGRATION = qw<
  resolved
  resolved_error
  resolved_error_factory
  resolved_factory
>;
my @TRANSFORMERS = qw<
  data_to_fh
  data_to_file
  fh_to_data
  fh_to_file
  file_to_data
  file_to_fh
  transform
>;
our @EXPORT_OK   = (@FACTORIES, @INTEGRATION, @TRANSFORMERS);
our %EXPORT_TAGS = (
   all          => [@EXPORT_OK],
   factories    => [@FACTORIES],
   integration  => [@INTEGRATION],
   transformers => [@TRANSFORMERS],
);

# ----------------------------------------------------------------------
# Factories
sub generate ($spec) {
   $spec = decode_json($spec) unless ref($spec);
   my %args = $spec->%*;

   my $package = delete($args{'-package'}) // __PACKAGE__;
   my $path    = "$package.pm" =~ s{::}{/}rgmxs;
   require $path;

   my $factory_name = delete($args{'-factory'})
     or croak 'undefined factory name';
   my $factory = $package->can($factory_name)
     or croak "no factory '$factory_name' in package '$package'";

   # expand sub-arguments under '-recursed'
   if (my $r = delete($args{'-recursed'})) {
      $args{$_} = [map { __SUB__->($_) } $r->{$_}->@*] for keys $r->%*;
   }

   return $factory->(%args);
} ## end sub generate

sub __dir_tree ($root, $path) {
   return [
      map {
         $_->is_dir
           ? __SUB__->($root, $_)->@*
           : $_->relative($root)->stringify,
      } $path->children
   ];
} ## end sub __dir_tree

sub resolved ($throw, $value, $meta, @rest) {
   $meta = {$meta, @rest} if @rest;
   die $meta              if $throw && ($meta->{type} // '') eq 'error';
   return ($value, $meta) if wantarray;
   return $value;
} ## end sub resolved

sub resolved_error ($throw, $code, $message, @rest) {
   my %meta = @rest == 1 ? $rest[0]->%* : @rest;
   %meta = (type => 'error', code => $code, message => $message, %meta);
   return resolved($throw, undef, \%meta);
}

sub resolved_error_factory ($t) { return sub { resolved_error($t, @_) } }
sub resolved_factory ($throw)   { return sub { resolved($throw, @_) } }

sub resolver_from_alternatives (@args) {
   my %args = @args && ref($args[0]) ? $args[0]->%* : @args;
   my @alts =
     map { ref($_) eq 'CODE' ? $_ : generate($_) } $args{alternatives}->@*;
   my $OK = resolved_factory($args{throw});
   my $NO = resolved_error_factory($args{throw});
   return sub ($key, @type) {
      if (@type && ($type[0] // '') eq 'list') {
         return $NO->(400, 'Unsupported listing in sub-directory')
           if defined($key);
         my %seen;
         my @list = grep { !$seen{$_}++ }
           map { $_->@* }
           grep { defined($_) }
           map { scalar eval { $_->(undef, 'list') } } @alts;
         return $OK->(\@list, type => 'list');
      } ## end if ($type eq 'list')

      for my $candidate (@alts) {
         my @retval;
         eval { @retval = $candidate->($key, @type) } or next;
         return $OK->(@retval) if defined $retval[0];
      }
      return $NO->(404, 'Not Found');
   };
} ## end sub resolver_from_alternatives

sub resolver_from_dir (@args) {
   my %args = @args && ref($args[1]) ? $args[1]->%* : @args;
   require Path::Tiny;
   my $root = Path::Tiny::path($args{root} // $args{path})->realpath;
   my $get  = sub ($key) {
      my $candidate = eval { $root->child($key)->realpath };
      return $candidate
        if $candidate
        && $candidate->exists
        && $root->subsumes($candidate);
      return undef;
   };
   my $OK = resolved_factory($args{throw});
   my $NO = resolved_error_factory($args{throw});
   return sub ($key, $type = 'file') {
      if ($type eq 'list') {
         my $l_root = defined($key) ? $get->($key) : $root;
         return $NO->(404, 'Not Found')       unless defined $l_root;
         return $NO->(400, 'Not a container') unless $l_root->is_dir;
         return $OK->(__dir_tree($root, $l_root), type => 'list');
      } ## end if ($type eq 'list')

      my $path = $get->($key);
      return $NO->(404, 'Not Found')  unless defined $path;
      return $NO->(400, 'Not a file') unless $path->is_file;
      my $ref = transform($path->stringify, file => $type);
      return $NO->(400, "Invalid request type '$type'") unless $ref;
      return $OK->($$ref, type => $type);
   }
} ## end sub resolver_from_dir

sub resolver_from_passthrough (@args) {
   my %args = @args && ref($args[1]) ? $args[1]->%* : @args;
   return sub ($key, $type = undef) {
      return resolved($key, type => $type, %args);
   }
} ## end sub resolver_from_passthrough

sub resolver_from_tar (@args) {
   my %args = @args && ref($args[1]) ? $args[1]->%* : @args;
   require Archive::Tar;
   my $tar = Archive::Tar->new;
   $tar->read($args{archive} // $args{path});
   my $OK  = resolved_factory($args{throw});
   my $NO  = resolved_error_factory($args{throw});
   my $get = sub ($key, $type = 'data') {
      if ($type eq 'list') {
         return $NO->(400, 'Unsupported listing in sub-directory')
           if defined($key);
         return $OK->([grep { !m{/$} } $tar->list_files], type => 'list');
      }

      $key = $key =~ s{\A \./}{}rmxs;
      $key = './' . $key unless $tar->contains_file($key);
      return $NO->(404, 'Not Found') unless $tar->contains_file($key);
      my $ref = transform($tar->get_content($key), data => $type);
      return $NO->(400, "Invalid request type '$type'") unless $ref;
      return $OK->($$ref, type => $type);
   };
} ## end sub resolver_from_tar

# ----------------------------------------------------------------------
# Transformers

sub data_to_fh { file_to_fh(ref($_[0]) ? $_[0] : \$_[0]) }

sub data_to_file {
   my $keep = $_[1] // 0;
   require File::Temp;
   my ($fh, $filename) = File::Temp::tempfile(UNLINK => (!$keep));
   binmode $fh, ':raw';
   print {$fh} ref($_[0]) ? ${$_[0]} : $_[0];
   return $filename;
} ## end sub data_to_file

sub fh_to_data ($fh) { local $/; readline($fh) }

sub fh_to_file ($fh, $keep = 0) { data_to_file(fh_to_data($fh), $keep) }

sub file_to_data ($input) { fh_to_data(file_to_fh($input)) }

sub file_to_fh ($input) {
   open my $fh, '<:raw', $input or croak "open('$input'): $OS_ERROR";
   return $fh;
}

sub transform {
   state $canonical_name_for = {
      fh         => 'filehandle',
      filehandle => 'filehandle',
      data       => 'data',
      file       => 'file',
      path       => 'file',
   };
   my $itype = $canonical_name_for->{$_[1]} or return;
   my $otype = $canonical_name_for->{$_[2]} or return;

   return \$_[0] if $itype eq $otype;

   state $transformer_for = {    # itype, otype
      file => {
         fh         => \&file_to_fh,
         filehandle => \&file_to_fh,
         data       => \&file_to_data,
      },
      filehandle => {
         data => \&fh_to_data,
         file => \&fh_to_file,
         path => \&fh_to_file,
      },
      data => {
         fh         => \&data_to_fh,
         filehandle => \&data_to_fh,
         file       => \&data_to_file,
         path       => \&data_to_file,
      },
   };
   my $value = $transformer_for->{$itype}{$otype}->($_[0]);
   return \$value;
} ## end sub transform

1;
