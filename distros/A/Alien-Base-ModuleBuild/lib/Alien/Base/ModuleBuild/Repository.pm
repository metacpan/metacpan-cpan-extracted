package Alien::Base::ModuleBuild::Repository;

use strict;
use warnings;
use Carp;
use Alien::Base::ModuleBuild::File;
use Alien::Base::ModuleBuild::Utils qw/pattern_has_capture_groups/;

# ABSTRACT: Private class
our $VERSION = '1.17'; # VERSION

sub new {
  my $class = shift;
  my (%self) = ref $_[0] ? %{ shift() } : @_;

  my $obj = bless \%self, $class;

  $obj->{c_compiler_required} = 1
    unless defined $obj->{c_compiler_required};

  my $location = $obj->{location};
  $location = '' unless defined $location;

  if(defined $obj->{exact_filename} && $location !~ m{/$}) {
    $obj->{location} = $location . '/'
  }

  return $obj;
}

sub protocol { return shift->{protocol} }

sub host {
  my $self = shift;
  $self->{host} = shift if @_;
  return $self->{host};
}

sub location {
  my $self = shift;
  $self->{location} = shift if @_;
  return $self->{location};
}

sub is_network_fetch {
  die "must override in the subclass";
}

sub is_secure_fetch {
  die "must override in the subclass";
}

sub has_digest
{
  my($self) = @_;
  defined $self->{exact_filename} && $self->{exact_version} && (defined $self->{sha1} || defined $self->{sha256});
}

sub probe {
  my $self = shift;

  require Alien::Base::ModuleBuild;
  if(!Alien::Base::ModuleBuild->alien_install_network && $self->is_network_fetch) {
    die "network fetch is disabled via ALIEN_INSTALL_NETWORK";
  }

  my $rule = Alien::Base::ModuleBuild->alien_download_rule;
  if($rule eq 'warn') {

    unless($self->is_secure_fetch || $self->has_digest) {
      warn "!!! NOTICE OF FUTURE CHANGE IN BEHAVIOR !!!\n";
      warn "A future version of Alien::Base::ModuleBuild will die here by default with this exception: File fetch is insecure and has no digest.  Required by ALIEN_DOWNLOAD_RULE=digest_or_encrypt.";
      warn "!!! NOTICE OF FUTURE CHANGE IN BEHAVIOR !!!\n";
    }

  } elsif($rule eq 'digest') {

    unless($self->has_digest) {
      die "File fetch has no digest.  Required by ALIEN_DOWNLOAD_RULE=digest.";
    }

  } elsif($rule eq 'encrypt') {

    unless($self->is_secure_fetch) {
      die "File fetch is insecure.  Secure fetch required by ALIEN_DOWNLOAD_RULE=encrypt.";
    }

  } elsif($rule eq 'digest_or_encrypt') {

    unless($self->is_secure_fetch || $self->has_digest) {
      die "File fetch is insecure and has no digest.  Required by ALIEN_DOWNLOAD_RULE=digest_or_encrypt.";
    }

  } elsif($rule eq 'digest_and_encrypt') {

    unless($self->is_secure_fetch && $self->has_digest) {
      die "File fetch is insecure and has no digest.  Both are required by ALIEN_DOWNLOAD_RULE=digest_and_encrypt.";
    }

  } else {
    die 'internal error';
  }

  my $pattern = $self->{pattern};

  my @files;

  if ($self->{exact_filename}) {
    # if filename provided, use that specific file
    @files = ($self->{exact_filename});
  } else {
    @files = $self->list_files;

    if ($pattern) {
      @files = grep { $_ =~ $pattern } @files;
    }

    carp "Could not find any matching files" unless @files;
  }

  @files = map { +{
    repository => $self,
    platform   => $self->{platform},
    filename   => $_,
  } } @files;

  if ($self->{exact_filename} and $self->{exact_version}) {
    # if filename and version provided, use a specific version
    $files[0]->{version} = $self->{exact_version};
    $files[0]->{sha1} = $self->{sha1} if defined $self->{sha1};
    $files[0]->{sha256} = $self->{sha256} if defined $self->{sha256};
  } elsif ($pattern and pattern_has_capture_groups($pattern)) {
    foreach my $file (@files) {
      $file->{version} = $1
        if $file->{filename} =~ $pattern;
    }
  }

  @files =
    map { Alien::Base::ModuleBuild::File->new($_) }
    @files;

  return @files;
}

# subclasses are expected to provide
sub connection { croak "$_[0] doesn't provide 'connection' method" }
sub list_files { croak "$_[0] doesn't provide 'list_files' method" }
# get_file must return filename actually used
sub get_file  { croak "$_[0] doesn't provide 'get_files' method"  }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Base::ModuleBuild::Repository - Private class

=head1 VERSION

version 1.17

=head1 SEE ALSO

=over 4

=item L<Alien>

=item L<Alien::Base>

=back

=head1 AUTHOR

Original author: Joel A Berger E<lt>joel.a.berger@gmail.comE<gt>

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

David Mertens (run4flat)

Mark Nunberg (mordy, mnunberg)

Christian Walde (Mithaldu)

Brian Wightman (MidLifeXis)

Graham Ollis (plicease)

Zaki Mughal (zmughal)

mohawk2

Vikas N Kumar (vikasnkumar)

Flavio Poletti (polettix)

Salvador Fandiño (salva)

Gianni Ceccarelli (dakkar)

Pavel Shaydo (zwon, trinitum)

Kang-min Liu (劉康民, gugod)

Nicholas Shipp (nshp)

Petr Písař (ppisar)

Alberto Simões (ambs)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2022 by Joel A Berger.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
