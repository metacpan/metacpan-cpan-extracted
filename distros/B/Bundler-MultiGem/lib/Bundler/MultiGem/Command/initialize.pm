package Bundler::MultiGem::Command::initialize;

use 5.006;
use strict;
use warnings;

use Bundler::MultiGem -command;
use Cwd qw(realpath);
use Bundler::MultiGem::Utl::InitConfig qw(merge_configuration);
use File::Spec::Functions qw(catfile);
use YAML::Tiny;

=head1 NAME

Bundler::MultiGem::Command::initialize - Generate a configuration file (alias: init bootstrap b)

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

our $app = {};

=head1 SYNOPSIS

This module includes the commands to initialize a yml configuration file for installing multiple versions of the same gem

    bundle-multigem [-f] [long options...] <path>

      --gm --gem-main-module    provide the gem main module (default:
                                constantize --gem-name)
      --gn --gem-name           provide the gem name
      --gs --gem-source         provide the gem source (default:
                                https://rubygems.org)
      --gv --gem-versions       provide the gem versions to install (e.g:
                                --gem-versions 0.0.1 --gem-versions 0.0.2)
      --dp --dir-pkg            directory for downloaded gem pkg (default:
                                pkg)
      --dt --dir-target         directory for extracted versions (default:
                                versions)
      --cp --cache-pkg          keep cache of pkg directory (default: 1)
      --ct --cache-target       keep cache of target directory (default: 0)
      -f --conf-file            choose config file name (default:
                                .bundle-multigem.yml)


Please note that the C<path> passed as argument will be considered as the root path for the project

=head1 SUBROUTINES

=head2 command_names

Command aliases: C<initialize, init, bootstrap, b>

=cut

sub command_names {
  qw(initialize init bootstrap b)
}

=head2 execute

=cut

sub execute {
  my ($self, $opt, $args) = @_;

  foreach my $k (keys %{$opt}) {
    my ($k1, $k2) = split(/_/, $k, 2);
    my $new_key = opt_prefix($k1);
    next unless $new_key;
    $app->{config}->{$new_key}->{$k2} = $opt->{$k};
  }

  $app->{config} = merge_configuration($app->{config});

  my $output_file = $opt->{'conf-file'} || ".bundle-multigem.yml";
  my $yaml = YAML::Tiny->new( $app->{config} );

  if (! -f $output_file ) {
    $output_file = catfile($app->{config}->{directories}->{root}, ".bundle-multigem.yml")
  }

  $yaml->write($output_file);

  print "Configuration generated at: ${output_file}\n";
}

=head2 usage_desc

=cut

sub usage_desc { "bundle-multigem %o <path>" }

=head2 opt_spec

=cut

sub opt_spec {
  return (
    [ "gem-main-module|gm=s", "provide the gem main module (default: constantize --gem-name)" ],
    [ "gem-name|gn=s", "provide the gem name" ],
    [ "gem-source|gs=s", "provide the gem source (default: https://rubygems.org)" ],
    [ "gem-versions|gv=s@", "provide the gem versions to install (e.g: --gem-versions 0.0.1 --gem-versions 0.0.2)" ],
    [ "dir-pkg|dp=s", "directory for downloaded gem pkg (default: pkg)" ],
    [ "dir-target|dt=s", "directory for extracted versions (default: versions)" ],
    [ "cache-pkg|cp=s", "keep cache of pkg directory (default: 1)" ],
    [ "cache-target|ct=s", "keep cache of target directory (default: 0)" ],
    [ "conf-file|f=s", "choose config file name (default: .bundle-multigem.yml)" ],
  );
}

=head2 validate_args

=cut

sub validate_args {
  my ($self, $opt, $args) = @_;

  if (scalar @$args != 1) {
    $self->usage_error("You should provide exactly one argument (<path>)");
  }

  my $root_path = realpath($args->[0]);

  if (! -e $root_path) {
    $self->usage_error("You should provide a valid path ($root_path does not exists)");
  }

  $app->{config}->{directories} = {
    'root' => $root_path
  };
}

=head2 config

=cut

sub config {
  my $app = shift;
  $app->{config} ||= {};
}

our $OPT_PREFIX = {
  'gem' => 'gem',
  'dir' => 'directories',
  'cache' => 'cache'
};

=head2 opt_prefix

Internal. Apply $OPT_PREFIX when collecting arguments

    our $OPT_PREFIX = {
      'gem' => 'gem',
      'dir' => 'directories',
      'cache' => 'cache'
    };

=cut

sub opt_prefix {
  my $k = shift;
  $OPT_PREFIX->{$k};
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
