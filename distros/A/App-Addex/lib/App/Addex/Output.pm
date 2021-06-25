use strict;
use warnings;

package App::Addex::Output 0.027;
# ABSTRACT: base class for output plugins

use Carp ();

#pod =head1 DESCRIPTION
#pod
#pod This is a base class for output plugins.
#pod
#pod =head1 METHODS
#pod
#pod =head2 new
#pod
#pod   my $output_plugin = App::Addex::Output->new(\%arg);
#pod
#pod This method returns a new outputter.
#pod
#pod =cut

sub new {
  my ($class) = @_;

  return bless {} => $class;
}

#pod =head2 process_entry
#pod
#pod   $output_plugin->process_entry($entry);
#pod
#pod This method is called once for each entry to be processed.  It must be
#pod overridden in output plugin classes, or the base implementation will throw an
#pod exception when called.
#pod
#pod =cut

sub process_entry { Carp::confess "process_entry method not implemented" }

#pod =head2 finalize
#pod
#pod   $output_plugin->finalize;
#pod
#pod This method is called after all entries have been processed.
#pod
#pod =cut

sub finalize { }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Addex::Output - base class for output plugins

=head1 VERSION

version 0.027

=head1 DESCRIPTION

This is a base class for output plugins.

=head1 PERL VERSION SUPPORT

This module has the same support period as perl itself:  it supports the two
most recent versions of perl.  (That is, if the most recently released version
is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 new

  my $output_plugin = App::Addex::Output->new(\%arg);

This method returns a new outputter.

=head2 process_entry

  $output_plugin->process_entry($entry);

This method is called once for each entry to be processed.  It must be
overridden in output plugin classes, or the base implementation will throw an
exception when called.

=head2 finalize

  $output_plugin->finalize;

This method is called after all entries have been processed.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
