package Bundler::MultiGem::Command::setup;

use 5.006;
use strict;
use warnings;

use Bundler::MultiGem -command;
use YAML::Tiny;
use Bundler::MultiGem::Model::Directories;
use Bundler::MultiGem::Model::Gem;

=head1 NAME

Bundler::MultiGem::Command::setup - Create multiple gem versions out of a configuration file (alias: install i s)

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

This module includes the commands to create multiple versions of the same gem out of a config yml file

  bundle-multigem [-f] [long options...] <path>

    -f --file     provide the yaml configuration file (default:
                  ./.bundle-multigem.yml)


=head1 SUBROUTINES/METHODS

=head2 command_names

Command aliases: C<setup, install, i, s>

=cut

sub command_names {
  qw(setup install i s)
}

=head2 usage_desc

=cut

sub usage_desc { "bundle-multigem %o <path>" }

=head2 opt_spec

=cut

sub opt_spec {
  return (
    [ "file|f=s", "provide the yaml configuration file (default: ./.bundle-multigem.yml)" ],
  );
}

=head2 validate_args

=cut

sub validate_args {
  my ($self, $opt, $args) = @_;

  if (!defined $opt->{file}) {
    $opt->{file} = '.bundle-multigem.yml';
  }
  if (!-f $opt->{file}){
    $self->usage_error("You should provide a valid path ($opt->{file} does not exists)");
  }
  $self->usage_error("No args allowed") if @$args;
}

=head2 execute

Load the YAML configuration file, validates the directories provided and apply the gem creation

=cut

sub execute {
  my ($self, $opt, $args) = @_;

  my $yaml = YAML::Tiny->read($opt->{file});

  my $gem = Bundler::MultiGem::Model::Gem->new($yaml->[0]{gem});
  my $dir = Bundler::MultiGem::Model::Directories->new({
    cache => $yaml->[0]{cache},
    directories => $yaml->[0]{directories},
  });

  $dir->validates;
  $dir->apply_cache;

  $gem->apply($dir);

  print "Completed!";
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
