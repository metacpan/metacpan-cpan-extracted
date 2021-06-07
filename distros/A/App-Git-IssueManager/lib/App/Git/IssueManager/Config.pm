package App::Git::IssueManager::Config;
#ABSTRACT: Class for using gits configuration file for the IssueManager App
use Moose;
extends 'Config::GitLike';
use Config::GitLike;

sub dir_file
{
  my $self = shift;

  return "config";
}


sub global_file
{
  my $self = shift;

  return "";
}


sub user_file
{
  my $self  = shift;

  return "~/.gitconfig";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Git::IssueManager::Config - Class for using gits configuration file for the IssueManager App

=head1 VERSION

version 0.2

=head1 AUTHOR

Dominik Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dominik Meyer.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/App::Git::IssueManager/>.

=head1 BUGS

Please report any bugs or feature requests by email to
L<byterazor@federationhq.de|mailto:byterazor@federationhq.de>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dominik Meyer.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
