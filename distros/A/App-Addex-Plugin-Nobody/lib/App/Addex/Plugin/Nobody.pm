use strict;
use warnings;

package App::Addex::Plugin::Nobody 0.006;
use 5.006; # our
use Sub::Install;
# ABSTRACT: automatically add a recipient that goes nowhere

#pod =head1 DESCRIPTION
#pod
#pod The only valid "To" header that doesn't imply delivery somewhere
#pod looks something like this:
#pod
#pod   To: undisclosed-recipients: ;
#pod
#pod This plugin adds a virtual entry to your address book with that address.
#pod
#pod =head1 CONFIGURATION
#pod
#pod First, you have to add the plugin to your Addex configuration file's top
#pod section:
#pod
#pod   plugin = App::Addex::Plugin::Nobody
#pod
#pod You can supply the following options for the plugin:
#pod
#pod   name  - the "full name" to use (default: "Undisclosed Recipients")
#pod   nick  - the nick (if any) to provide (default: nobody)
#pod   group - the name of the address group (default: undisclosed-recipients)
#pod           this option is not well-validated, so maybe you should leave it alone
#pod
#pod The entry will have a true C<skip_hiveminder> field, to avoid bizarre
#pod interactions with the Hiveminder plugin.
#pod
#pod =cut

sub import {
  my ($mixin, %arg) = @_;


  my $group_name = $arg{group} || 'undisclosed-recipients';

  require App::Addex::Entry;

  my $nobody = App::Addex::Entry->new({
    name   => $arg{name} || 'Undisclosed Recipients',
    nick   => exists $arg{nick} ? $arg{nick} : 'nobody',
    fields => { skip_hiveminder => 1 },
    emails => [
      App::Addex::Entry::EmailAddress->new({
        address  => "$group_name: ;",
        sends    => 0,
        receives => 1,
      }),
    ],
  });

  my $caller = caller;
  my $original_sub = $caller->can('entries');

  my $new_entries = sub {
    my ($self) = @_;

    my @entries = $self->$original_sub;

    return (@entries, $nobody);
  };

  Sub::Install::reinstall_sub({
    code => $new_entries,
    into => $caller,
    as   => 'entries',
  });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Addex::Plugin::Nobody - automatically add a recipient that goes nowhere

=head1 VERSION

version 0.006

=head1 DESCRIPTION

The only valid "To" header that doesn't imply delivery somewhere
looks something like this:

  To: undisclosed-recipients: ;

This plugin adds a virtual entry to your address book with that address.

=head1 PERL VERSION SUPPORT

This module has the same support period as perl itself:  it supports the two
most recent versions of perl.  (That is, if the most recently released version
is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 CONFIGURATION

First, you have to add the plugin to your Addex configuration file's top
section:

  plugin = App::Addex::Plugin::Nobody

You can supply the following options for the plugin:

  name  - the "full name" to use (default: "Undisclosed Recipients")
  nick  - the nick (if any) to provide (default: nobody)
  group - the name of the address group (default: undisclosed-recipients)
          this option is not well-validated, so maybe you should leave it alone

The entry will have a true C<skip_hiveminder> field, to avoid bizarre
interactions with the Hiveminder plugin.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
