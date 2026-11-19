package inc::Pvim::Build;
use Moose;
use Dist::Zilla::File::InMemory;
with 'Dist::Zilla::Role::VersionProvider', 'Dist::Zilla::Role::FileGatherer';

sub runtime_source {
    my ($self) = @_;
    my $path = $self->zilla->root . '/pvim';
    open my $fh, '<', "$path" or die "Read $path: $!";
    local $/;
    my $source = <$fh>;
    close $fh or die $!;
    return $source;
}
sub provide_version {
    my ($self) = @_;
    my ($version) = $self->runtime_source =~ /our\s+\$VERSION\s*=\s*'([^']+)'/;
    $self->log_fatal('Cannot determine version from standalone pvim') unless defined $version;
    return $version;
}
sub gather_files {
    my ($self) = @_;
    my $version = $self->provide_version;
    $self->add_file(Dist::Zilla::File::InMemory->new(
        name => 'script/pvim', content => $self->runtime_source, mode => 0755,
    ));
    my $module = <<'MODULE';
package App::Pvim;
use 5.010;
use strict;
use warnings;
our $VERSION = '__VERSION__';
1;
__END__

=head1 NAME

App::Pvim - a portable Vim replacement for restricted environments

=head1 SYNOPSIS

  pvim file.pl
  printf 'hi\n' | pvim
  pvim -v
  pvim --help
  pvim --manual

=head1 DESCRIPTION

pvim is for systems where Perl is available but Vim isn't, and you don't have
install privileges. Think cheap shared web hosting or a minimal Unix install
without gcc, make, or access to the package manager. I'd still like a capable
editor on those accounts.

The goal is a highly capable, Perl-centric Vim replacement that stays in one
Perl file and runs on Perl 5.10+ with core modules. Copy the standalone file into
your account, make it executable, and use it. No root or compiler needed.
Perl::Tidy is optional if you want formatting.

This distribution installs the C<pvim> command. The App::Pvim module holds the
namespace and version; all editing code and the full manual live in the command.
Use C<man pvim> or C<pvim --manual> for controls, stdin import, shell filters,
large-file handling and file safety. Use C<pvim --help> for a short reminder.

It is still early: visual selection, tabs, splits, dot-repeat, Vimscript and
plugins aren't implemented. Editing is byte oriented and there is no crash
recovery. Interactive tests cover Linux and macOS; native Windows has batch
support. The wiki lists current features, limits and tested platforms.

Installing this tarball needs the usual Perl build tools, including make, but
no C compiler for pvim itself. If make is missing, use the standalone file from
L<https://github.com/oodler577/pvim/releases>. It needs a full Perl standard
library, a POSIX terminal and writable temporary space, plus permission to run
your own scripts. No Dist::Zilla or Moose is needed on the target account.

=head1 BUGS AND SUPPORT

Please report bugs at L<https://github.com/oodler577/pvim/issues>. Include
C<pvim -v>, the OS and terminal, and the smallest example that shows the problem.
Try it on copies of your files first, and leave private data out of bug reports.

=head1 LINKS

L<https://github.com/oodler577/pvim>

L<https://github.com/oodler577/pvim/wiki>

=head1 AUTHOR

Brett Estrade E<lt>OODLER@cpan.orgE<gt>

=head1 LICENSE

Copyright 2026 Brett Estrade. Available under the same terms as Perl 5 itself.

=cut
MODULE
    $module =~ s/__VERSION__/$version/g;
    $self->add_file(Dist::Zilla::File::InMemory->new(
        name => 'lib/App/Pvim.pm', content => $module,
    ));
}
__PACKAGE__->meta->make_immutable;
1;
