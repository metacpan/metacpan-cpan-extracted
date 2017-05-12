################################################################################
#
# MODULE: Convert::Binary::C::Cached
#
################################################################################
#
# DESCRIPTION: Cached version of Convert::Binary::C module
#
################################################################################
#
# Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

package Convert::Binary::C::Cached;

use strict;
use Convert::Binary::C;
use Carp;
use vars qw( @ISA $VERSION );

@ISA = qw(Convert::Binary::C);

$VERSION = '0.78';

sub new
{
  my $class = shift;
  my $self = $class->SUPER::new;

  $self->{cache}      = undef;
  $self->{parsed}     = 0;
  $self->{uses_cache} = 0;

  @_ % 2 and croak "Number of configuration arguments to new must be even";

  @_ and $self->configure(@_);

  return $self;
}

sub configure
{
  my $self = shift;

  if (@_ < 2 and not defined wantarray) {
    $^W and carp "Useless use of configure in void context";
    return;
  }

  if (@_ == 0) {
    my $cfg = $self->SUPER::configure;
    $cfg->{Cache} = $self->{cache};
    return $cfg;
  }
  elsif (@_ == 1 and $_[0] eq 'Cache') {
    return $self->{cache};
  }

  my @args;

  if (@_ == 1) {
    @args = @_;
  }
  elsif (@_ % 2 == 0) {
    while (@_) {
      my %arg = splice @_, 0, 2;
      if (exists $arg{Cache}) {
        if ($self->{parsed}) {
          croak 'Cache cannot be configured after parsing';
        }
        elsif (ref $arg{Cache}) {
          croak 'Cache must be a string value, not a reference';
        }
        else {
          if (defined $arg{Cache}) {
            my @missing;
            eval { require Data::Dumper };
            $@ and push @missing, 'Data::Dumper';
            eval { require IO::File };
            $@ and push @missing, 'IO::File';
            if (@missing) {
              $^W and carp "Cannot load ", join(' and ', @missing), ", disabling cache";
              undef $arg{Cache};
            }
          }
          $self->{cache} = $arg{Cache};
        }
      }
      else { push @args, %arg }
    }
  }

  my $opt = $self;

  if (@args) {
    $opt = eval { $self->SUPER::configure(@args) };
    $@ =~ s/\s+at.*?Cached\.pm.*//s, croak $@ if $@;
  }

  $opt;
}

sub clean
{
  my $self = shift;

  delete $self->{$_} for grep !/^(?:|cache|parsed|uses_cache)$/, keys %$self;

  $self->{parsed}     = 0;
  $self->{uses_cache} = 0;

  $self->SUPER::clean;
}

sub clone
{
  my $self = shift;

  unless (defined wantarray) {
    $^W and carp "Useless use of clone in void context";
    return;
  }

  my $clone = $self->SUPER::clone;

  for (keys %$self) {
    if ($_) {
      $clone->{$_} = ref $_ eq 'ARRAY' ? [@{$self->{$_}}] : $self->{$_};
    }
  }

  $clone;
}

sub parse_file
{
  my $self = shift;
  my($warn,$error) = $self->__parse('file', $_[0]);
  for my $w ( @$warn ) { carp $w }
  defined $error and croak $error;
  defined wantarray and return $self;
}

sub parse
{
  my $self = shift;
  my($warn,$error) = $self->__parse('code', $_[0]);
  for my $w ( @$warn ) { carp $w }
  defined $error and croak $error;
  defined wantarray and return $self;
}

sub dependencies
{
  my $self = shift;

  $self->{parsed} or croak "Call to dependencies without parse data";

  unless (defined wantarray) {
    $^W and carp "Useless use of dependencies in void context";
    return;
  }

  $self->{files} || $self->SUPER::dependencies;
}

sub __uses_cache
{
  my $self = shift;
  $self->{uses_cache};
}

sub __parse
{
  my $self = shift;

  if (defined $self->{cache}) {
    $self->{parsed} and croak "Cannot parse more than once for cached objects";

    $self->{$_[0]} = $_[1];

    if ($self->__can_use_cache) {
      my @WARN;
      {
        local $SIG{__WARN__} = sub { push @WARN, $_[0] };
        eval { $self->SUPER::parse_file($self->{cache}) };
      }
      unless ($@ or @WARN) {
        $self->{parsed}     = 1;
        $self->{uses_cache} = 1;
        return;
      }
      $self->clean;
    }
  }

  $self->{parsed} = 1;

  my(@warnings, $error);
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    if ($_[0] eq 'file') {
      eval { $self->SUPER::parse_file($_[1]) };
    }
    else {
      eval { $self->SUPER::parse($_[1]) };
    }
  }

  if ($@) {
    $error = $@;
    $error =~ s/\s+at.*?Cached\.pm.*//s;
  }
  else {
    defined $self->{cache} and $self->__save_cache;
  }

  for (@warnings) { s/\s+at.*?Cached\.pm.*//s }

  (\@warnings, $error);
}

sub __can_use_cache
{
  my $self = shift;
  my $fh = new IO::File;

  unless (-e $self->{cache} and -s _) {
    $ENV{CBCC_DEBUG} and print STDERR "CBCC: cache file '$self->{cache}' doesn't exist or is empty\n";
    return 0;
  }

  unless ($fh->open($self->{cache})) {
    $^W and carp "Cannot open '$self->{cache}': $!";
    $ENV{CBCC_DEBUG} and print STDERR "CBCC: cannot open cache file '$self->{cache}'\n";
    return 0;
  }

  my @warnings;
  my @config = do {
    my $config;
    unless (defined($config = <$fh>)) {
      $ENV{CBCC_DEBUG} and print STDERR "CBCC: cannot read configuration\n";
      return 0;
    }
    unless ($config =~ /^#if\s+0/) {
      $ENV{CBCC_DEBUG} and print STDERR "CBCC: invalid configuration\n";
      return 0;
    }
    local $/ = $/.'#endif';
    chomp($config = <$fh>);
    $config =~ s/^\*//gms;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    eval $config;
  };

  # corrupt config
  if ($@ or @warnings or @config % 2) {
    $ENV{CBCC_DEBUG} and print STDERR "CBCC: broken configuration\n";
    return 0;
  }

  my %config = @config;

  my $what = exists $self->{code} ? 'code' : 'file';

  unless (exists $config{$what} and
          $config{$what} eq $self->{$what} and
          __reccmp($config{cfg}, $self->configure)) {
    if ($ENV{CBCC_DEBUG}) {
      print STDERR "CBCC: configuration has changed\n";
      print STDERR "CBCC: what='$what', \$config{$what}='$config{$what}' \$self->{$what}='$self->{$what}'\n";
      my $dump = Data::Dumper->Dump([$config{cfg}, $self->configure], ['config', 'self']);
      $dump =~ s/^/CBCC: /mg;
      print STDERR $dump;
    }
    return 0;
  }

  while (my($file, $spec) = each %{$config{files}}) {
    unless (-e $file) {
      $ENV{CBCC_DEBUG} and print STDERR "CBCC: file '$file' deleted\n";
      return 0;
    }
    my($size, $mtime, $ctime) = (stat(_))[7,9,10];
    unless ($spec->{size} == $size and
            $spec->{mtime} == $mtime and
            $spec->{ctime} == $ctime) {
      $ENV{CBCC_DEBUG} and print STDERR "CBCC: size/mtime/ctime of '$file' changed\n";
      return 0;
    }
  }

  $self->{files} = $config{files};

  $ENV{CBCC_DEBUG} and print STDERR "CBCC: '$self->{cache}' is usable\n";
  return 1;
}

sub __save_cache
{
  my $self = shift;
  my $fh = new IO::File;

  $fh->open(">$self->{cache}") or croak "Cannot open '$self->{cache}': $!";

  my $what = exists $self->{code} ? 'code' : 'file';

  my $config = Data::Dumper->new([{ $what => $self->{$what},
                                    cfg   => $self->configure,
                                    files => scalar $self->SUPER::dependencies,
                                 }], ['*'])->Indent(1)->Dump;
  $config =~ s/[^(]*//;
  $config =~ s/^/*/gms;

  print $fh "#if 0\n", $config, "#endif\n\n",
            do { local $^W; $self->sourcify({ Context => 1 }) };
}

sub __reccmp
{
  my($ref, $val) = @_;

  !defined($ref) && !defined($val) and return 1;
  !defined($ref) || !defined($val) and return 0;

  ref $ref or return $ref eq $val;

  if (ref $ref eq 'ARRAY') {
    @$ref == @$val or return 0;
    for (0..$#$ref) {
      __reccmp($ref->[$_], $val->[$_]) or return 0;
    }
  }
  elsif (ref $ref eq 'HASH') {
    keys %$ref == keys %$val or return 0;
    for (keys %$ref) {
      __reccmp($ref->{$_}, $val->{$_}) or return 0;
    }
  }
  else { return 0 }

  return 1;
}

1;

__END__

=head1 NAME

Convert::Binary::C::Cached - Caching for Convert::Binary::C

=head1 SYNOPSIS

  use Convert::Binary::C::Cached;
  use Data::Dumper;
  
  #------------------------
  # Create a cached object
  #------------------------
  $c = Convert::Binary::C::Cached->new(
         Cache   => '/tmp/cache.c',
         Include => [
           '/usr/lib/gcc/i686-pc-linux-gnu/4.5.2/include',
           '/usr/lib/gcc/i686-pc-linux-gnu/4.5.2/include-fixed',
           '/usr/include',
         ],
       );
  
  #----------------------------------------------------
  # Parse 'time.h' and dump the definition of timespec
  #----------------------------------------------------
  $c->parse_file('time.h');
  
  print Dumper($c->struct('timespec'));

=head1 DESCRIPTION

Convert::Binary::C::Cached simply adds caching capability to
Convert::Binary::C. You can use it in just the same way that
you would use Convert::Binary::C. The interface is exactly
the same.

To use the caching capability, you must pass the C<Cache> option
to the constructor. If you don't pass it, you will receive
an ordinary Convert::Binary::C object. The argument to
the C<Cache> option is the file that is used for caching
this object.

The caching algorithm automatically detects when the cache
file cannot be used and the original code has to be parsed.
In that case, the cache file is updated. An update of the
cache file can be triggered by one or more of the following
factors:

=over 2

=item *

The cache file doesn't exist, which is obvious.

=item *

The cache file is corrupt, i.e. cannot be parsed.

=item *

The object's configuration has changed.

=item *

The embedded code for a L<C<parse>|Convert::Binary::C/"parse"> method
call has changed.

=item *

At least one of the files that the object depends on
does not exist or has a different size or a different
modification or change timestamp.

=back

=head1 LIMITATIONS

You cannot
call L<C<parse>|Convert::Binary::C/"parse"> or L<C<parse_file>|Convert::Binary::C/"parse_file"> more
that once when using a Convert::Binary::C::Cached object. This isn't
a big problem, as you usually don't call them multiple times.

If a dependency file changes, but the change affects neither
the size nor the timestamps of that file, the caching
algorithm cannot detect that an update is required.

=head1 COPYRIGHT

Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

See L<Convert::Binary::C>.

=cut

