package Bundler::MultiGem::Model::Directories;

use 5.006;
use strict;
use warnings;

use File::Spec::Functions qw(catpath);
use Bundler::MultiGem::Utl::Directories qw(mk_dir rm_dir);
use constant REQUIRED_KEYS => qw(cache directories);

=head1 NAME

Bundler::MultiGem::Model::Directory - Manipulate directories and cache

=head1 VERSION

Version 0.02

=cut
our $VERSION = '0.02';

=head1 SYNOPSIS

This package contain an object to manipulate directories and cache

=head1 SUBROUTINES

=head2 new

Takes an optional hash reference parameter

    my $empty = Bundler::MultiGem::Model::Directories->new(); # {}

    my $config = {
      foo => 'bar',
      cache => [],
      directories => [],
    };
    my $foo = Bundler::MultiGem::Model::Directories->new($config);

=cut
sub new {
  my ($class, $self) = @_;
  if (!defined $self) { $self = {}; }
  bless $self, $class;
  return $self;
}

=head2 validates

C<validates> current configuration to contain REQUIRED_KEYS:

     use constant REQUIRED_KEYS => qw(cache directories);
     $dir->validates;

=cut
sub validates {
  my $self = shift;
  my %keys = map { $_ => 1 } keys(%$self);
  foreach my $k (REQUIRED_KEYS) {
    if (! defined($keys{$k}) ) {
      die "Missing key: $k for Bundler::MultiGem::Model::Directories";
    }
  }
  return $self;
}

=head2 cache

C<cache> getter: if no arguments, return an hash reference

    $dir->{cache} = { foo => 1 };
    $dir->cache; # { foo => 1 }
    $dir->cache('foo'); # 'bar'
    $dir->cache('baz'); # undef

=cut
sub cache {
  my ($self, $key) = @_;
  if (!defined $key) {
    return $self->{cache};
  }
  return $self->{cache}->{$key}
}

=head2 dirs

C<dirs> getter: if no arguments, return an hash reference

    $dir->{directories} = { foo => 'bar/' };
    $dir->dirs; # { foo => 'bar/' }
    $dir->dirs('foo'); # '/root/bar'
    $dir->dirs('baz'); # undef

=cut

sub dirs {
  my ($self, $key) = @_;
  if (!defined $key) {
    return $self->{directories};
  }
  elsif ($key eq 'root') {
    return $self->{directories}->{root};
  }
  return catpath($self->dirs('root'), $self->{directories}->{$key});
}

=head2 apply_cache

C<apply_cache> handle configuration cache on the folder:

    $dir->cache('foo'); # 1
    $dir->dirs('foo'); # creates foo dir if not existing

    $dir->cache('bar'); # 0
    $dir->dirs('bar'); # deletes bar dir if existing and recreate it

=cut
sub apply_cache {
  my $self = shift;
  my $root = $self->dirs('root');
  mk_dir($root);
  foreach my $k (keys(%{$self->cache})){
    if (! $self->cache->{$k}) {
      rm_dir $self->dirs($k);
    }
    mk_dir $self->dirs($k);
  }
}

=head1 AUTHOR

Mauro Berlanda, C<< <kupta at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/mberlanda/Bundler-MultiGem/issues>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bundler::MultiGem::Directories


You can also look for information at:

=over 2

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bundler-MultiGem>

=item * Github Repository

L<https://github.com/mberlanda/Bundler-MultiGem>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Mauro Berlanda.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;
