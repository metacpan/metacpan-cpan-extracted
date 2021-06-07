package App::Git::IssueManager;
#ABSTRACT: main MooseX class for git issue manager
use strict;
use warnings;
use Moose;
use MooseX::App qw(Color BashCompletion);

# the version of the module
our $VERSION = '0.1';



app_exclude 'App::Git::IssueManager::Config','App::Git::IssueManager::Webinterface';
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Git::IssueManager - main MooseX class for git issue manager

=head1 VERSION

version 0.2

=head1 DESCRIPTION

GIT IssueManager

Manages issues within your repository using a "issues" branch.

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
