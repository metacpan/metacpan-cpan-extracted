package CPANPLUS::Dist::GitHook;
BEGIN {
  $CPANPLUS::Dist::GitHook::VERSION = '0.02';
}

#ABSTRACT: Use Git::CPAN::Hook to commit each install in a Git repository

use strict;
use warnings;
use CPANPLUS::Error;
use Module::Load::Conditional qw[can_load];
use base qw[CPANPLUS::Dist::Base];

my $format_available;

sub format_available {
 return $format_available if defined $format_available;
 my $mod = 'Git::CPAN::Hook';
 unless( can_load( modules => { $mod => '0.03' }, nocache => 1 ) ) {
    error( loc( "You do not have '%1' -- '%2' not available",
                 $mod, __PACKAGE__ ) );
    return;
 }
 $format_available = 1;
}

sub init {
  require Git::CPAN::Hook;
  return 1;
}

sub install {
 my $self = shift;
 my $mod  = $self->parent;
 my $stat = $self->status;

 my $success = $self->SUPER::install( @_ );
 $stat->installed($success);

 if ( $success ) {
   ( my $dist = join '/', $mod->path, $mod->package ) =~ s!authors/id/!!;
   Git::CPAN::Hook->commit( $dist );
 }

 return $success;
}

sub uninstall {
 my $self = shift;
 my $mod  = $self->parent;
 my $stat = $self->status;

 my $success = $self->SUPER::uninstall( @_ );
 $stat->uninstalled($success);

 if ( $success ) {
   ( my $dist = join '/', $mod->path, $mod->package ) =~ s!authors/id/!!;
   Git::CPAN::Hook->commit( $dist );
 }

 return $success;
}

q[And now here is Hooky and the boys];


__END__
=pod

=head1 NAME

CPANPLUS::Dist::GitHook - Use Git::CPAN::Hook to commit each install in a Git repository

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  # CPANPLUS configuration

  cpanp> s conf dist_type CPANPLUS::Dist::GitHook

  cpanp> s save

  # Git::CPAN::Hook configuration

  # put your local::lib under Git control
  $ perl -MGit::CPAN::Hook -e init ~/perl5

  # Use cpanp/CPANPLUS normally.

  # or use cpan2dist

  $ cpan2dist --format CPANPLUS::Dist::GitHook --install Some::Funky::Module

=head1 DESCRIPTION

CPANPLUS::Dist::GitHook integrates Philippe Bruhat's L<Git::CPAN::Hook> module into L<CPANPLUS>.

Commits are made after any C<install> or C<uninstall> that L<CPANPLUS> undertakes.

=head1 METHODS

The following methods are provided. They are not meant to be called directly by the user.

=over

=item C<install>

Called to install a distribution. This will in turn call the parent install method, check the
return status and call L<Git::CPAN::Hook>'s C<commit> method.

=item C<uninstall>

Called to uninstall a distribution. This will in turn call the parent uninstall method, check the
return status and call L<Git::CPAN::Hook>'s C<commit> method.

=back

=head1 SEE ALSO

L<CPANPLUS>

L<Git::CPAN::Hook>

L<cpan2dist>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

