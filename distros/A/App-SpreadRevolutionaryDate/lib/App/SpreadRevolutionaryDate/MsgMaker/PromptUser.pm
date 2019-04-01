#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019 by Gérald Sédrati-Dinet.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use 5.014;
use utf8;
package App::SpreadRevolutionaryDate::MsgMaker::PromptUser;
$App::SpreadRevolutionaryDate::MsgMaker::PromptUser::VERSION = '0.10';
# ABSTRACT: MsgMaker class for L<App::SpreadRevolutionaryDate> to build message by prompting user

use Moose;
with 'App::SpreadRevolutionaryDate::MsgMaker';

use namespace::autoclean;
use open qw(:std :utf8);
use IO::Prompt::Hooked;

has 'default' => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
    default => 'Goodbye old world, hello revolutionary worlds',
);

around BUILDARGS => sub {
  my ($orig, $class, %args) = @_;

  # Do not pass default => undef to force default in attribute definition
  delete $args{default}
    if exists $args{default} && !defined $args{default};
  return $class->$orig(%args);
};


sub compute {
  my $self = shift;

  my $confirm = 'n';
  my $msg;
  while (defined $confirm && $confirm !~ /^y/) {
    $msg = prompt('Please, enter message to spread', $self->default);
    $confirm = prompt(
      message  => 'Spread "' . $msg . '", confirm (y/n) or A to abort?',
      default  => 'y',
      validate => qr/^[yn]$/i,
      escape   => qr/^A$/,
      error    => 'Input must be "y" or "n" ("A" to abort input.)' . "\n",
      tries    => 2,
    );
  }
  die "OK not spreading\n" unless $confirm;
  return $msg;
}


no Moose;
__PACKAGE__->meta->make_immutable;

# A module must return a true value. Traditionally, a module returns 1.
# But this module is a revolutionary one, so it discards all old traditions.
# Idea borrowed from Jean Forget's DateTime::Calendar::FrenchRevolutionary.
"Quand le gouvernement viole les droits du peuple,
l'insurrection est pour le peuple le plus sacré
et le plus indispensable des devoirs";

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SpreadRevolutionaryDate::MsgMaker::PromptUser - MsgMaker class for L<App::SpreadRevolutionaryDate> to build message by prompting user

=head1 VERSION

version 0.10

=head1 METHODS

=head2 compute

Prompts user for the message to be spread. Takes no argument. Returns message as string, ready to be spread.

=head1 SEE ALSO

=over

=item L<spread-revolutionary-date|https://metacpan.org/pod/distribution/App-SpreadRevolutionaryDate/bin/spread-revolutionary-date>

=item L<App::SpreadRevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::Config>

=item L<App::SpreadRevolutionaryDate::Target>

=item L<App::SpreadRevolutionaryDate::Target::Twitter>

=item L<App::SpreadRevolutionaryDate::Target::Mastodon>

=item L<App::SpreadRevolutionaryDate::Target::Freenode>

=item L<App::SpreadRevolutionaryDate::Target::Freenode::Bot>

=item L<App::SpreadRevolutionaryDate::Target::MsgMaker>

=item L<App::SpreadRevolutionaryDate::Target::MsgMaker::RevolutionaryDate>

=back

=head1 AUTHOR

Gérald Sédrati-Dinet <gibus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Gérald Sédrati-Dinet.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
