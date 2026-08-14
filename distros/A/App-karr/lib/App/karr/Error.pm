# ABSTRACT: Turn internal errors into one clean user-facing line

package App::karr::Error;
our $VERSION = '0.500';
use strict;
use warnings;
use Scalar::Util qw( blessed );
use Exporter qw( import );

our @EXPORT_OK = qw( user_error clean_error is_usage_error );


sub clean_error {
  my ($err) = @_;

  # libgit2 exceptions (Git::Libgit2::Error) put the useful text in ->message;
  # everything else in karr's path (Path::Tiny::Error, plain die strings)
  # stringifies usefully.
  my $detail = blessed($err) && $err->can('message') ? $err->message : "$err";

  $detail =~ s/ at \S+ line \d+\.?.*\z//s;   # the call site and all that follows
  $detail =~ s/\n.*\z//s;                    # keep only the first line
  $detail =~ s/\s+\z//;
  return length $detail ? $detail : 'unknown error';
}


sub user_error {
  my (@parts) = @_;
  my $msg = join '', grep { defined } @parts;
  $msg =~ s/\s+\z//;
  # A plain die, not croak: die honours the trailing newline and appends no
  # call site. bin/karr's central handler prints this verbatim and maps it to
  # the exit code (ADR 0002), so messages that should exit 2 rather than 1 have
  # to start with one of its usage markers ("Usage:" is the one for a bad
  # option value).
  die "$msg\n";
}


# The stable leading markers a usage-error die carries (ADR 0002). This used to
# live only in the regex in bin/karr's central handler, which was fine while
# that handler was the only reader. App::karr::Role::TaskMutation's batch runner
# is the second: it has to tell a failure that belongs to one id apart from one
# that condemns the whole invocation, and a second copy of the marker list would
# drift the moment either side gained a marker -- the batch would then quietly
# demote a usage error (2) to a runtime failure (1).
my $USAGE_MARKERS = qr{
    \A (?: Unknown\ command:          # the dispatch guard in App::karr
         | unexpected\ extra\ argument # surplus positionals (Role::CliArgs)
         | Usage:                      # a missing required positional
         | Usage\ error:               # anything usage_error() raises
      )
}x;

sub is_usage_error {
  my ($err) = @_;
  return 0 unless defined $err;
  return "$err" =~ $USAGE_MARKERS ? 1 : 0;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Error - Turn internal errors into one clean user-facing line

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    use App::karr::Error qw( user_error clean_error );

    eval { $dir->mkpath; 1 }
      or user_error( "Could not create $dir: ", clean_error($@) );

=head1 DESCRIPTION

karr's errors are read by humans and by agents scripting the CLI, so a
user-facing message is one line of prose and nothing else. Two things kept
breaking that:

=over 4

=item *

C<croak> appends C<< " at Some/Module.pm line 42." >> B<even when the message
already ends in a newline> -- the trailing-newline convention that C<die>
honours does not apply to L<Carp>. Every C<< croak "...\n" >> in a command path
therefore leaks a module path and a line number at the user.

=item *

Exceptions raised underneath karr (L<Path::Tiny>, libgit2, a captured C<git>
stderr) carry the same call-site suffix plus, often, several more lines of
backend chatter.

=back

C<user_error> raises the first kind and C<clean_error> reduces the second kind
to something fit to embed in the first. Keep C<croak> for programming errors --
a wrong argument to an internal method -- where the call site is the point.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Git>

=head2 clean_error

    my $line = clean_error($@);

Reduces a caught exception to a single line of prose: drops the
C<at FILE line N.> call site, keeps only the first line, and trims trailing
whitespace. Returns C<'unknown error'> when nothing is left. Accepts a plain
string or an exception object (L<Git::Libgit2::Error>-style objects are read
through C<< ->message >>).

=head2 user_error

    user_error("Task $id not found");
    user_error( "Could not install skill for $agent: ", clean_error($@) );

Raises a user-facing error whose message reaches STDERR exactly as written,
with no module path or line number appended. Parts are concatenated, undef
parts are dropped, and trailing whitespace is normalised to the single
terminating newline. Never returns.

=head2 is_usage_error

    exit( is_usage_error($@) ? 2 : 1 );

True when an exception is one of karr's usage errors -- "you called this wrong"
rather than "the operation failed" -- decided by the stable leading markers
listed in F<bin/karr>. Accepts a plain string or an exception object; a new
usage-error die must start with one of those markers, and C<usage_error> in
L<App::karr::Role::ExitCodes> is the generic way to emit one.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/karr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
