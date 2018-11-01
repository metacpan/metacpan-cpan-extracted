package Bundler::MultiGem::Utl::InitConfig;

use 5.006;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT = qw(ruby_constantize merge_configuration);

use Storable qw(dclone dclone);
use Hash::Merge qw(merge);
use common::sense;

=head1 NAME

Bundler::MultiGem::Utl::InitConfig - The utility to install multiple versions of the same ruby gem

=head1 VERSION

Version 0.02

=cut
our $VERSION = '0.02';

=head1 SYNOPSIS

This module contains a default configuration for the package to work and the utility functions to manipulate it.

=cut

=head1 DEFAULT_CONFIGURATION

Default configuration used to build the yaml configuration file:

    our $DEFAULT_CONFIGURATION = {
      'gem' => {
        'source' => 'https://rubygems.org',
        'name' => undef,
        'main_module' => undef,
        'versions' => [()]
      },
      'directories' => {
        'root' => undef,
        'pkg' => 'pkg',
        'target' => 'versions'
      },
      'cache' => {
        'pkg' => 1,
        'target' => 0
      }
    };

=cut

our $DEFAULT_CONFIGURATION = {
  'gem' => {
    'source' => 'https://rubygems.org',
    'name' => undef,
    'main_module' => undef,
    'versions' => [()]
  },
  'directories' => {
    'root' => undef,
    'pkg' => 'pkg',
    'target' => 'versions'
  },
  'cache' => {
    'pkg' => 1,
    'target' => 0
  }
};

=head1 EXPORTS

=head2 merge_configuration

Wrapper for merging a custom configuration with C<$DEFAULT_CONFIGURATION>

=cut
sub merge_configuration {
  my $custom_config = shift;
  my $result = merge($custom_config, dclone($DEFAULT_CONFIGURATION));
  default_main_module($result);
}

=head2 default_main_module

Assing a default C<main_module> name to a gem if not set

    my $gem_config = $custom_config->{gem};
    ruby_constantize($gem_config->{name});

E.g. C<foo> -> C<Foo>, C<foo_bar> -> C<FooBar>, C<foo-bar> -> C<Foo::Bar>

=cut

sub default_main_module {
  my $custom_config = shift;
  my $gem_config = $custom_config->{gem};
  if ( !defined $gem_config->{main_module}) {
    $gem_config->{main_module} = ruby_constantize($gem_config->{name});
  }
  $custom_config
}

=head2 ruby_constantize

Format string as a ruby constant

    ruby_constantize("foo"); # Foo
    ruby_constantize("foo_bar"); # FooBar
    ruby_constantize("foo-bar"); # Foo::Bar
    ruby_constantize("foo-bar_baz"); # Foo::BarBaz

=cut

sub ruby_constantize {
  my $name = shift;
  for ($name) {
    s/_(\w)/\U$1/g;
    s/-(\w)/::\U$1/g;
  }
  ucfirst $name;
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
