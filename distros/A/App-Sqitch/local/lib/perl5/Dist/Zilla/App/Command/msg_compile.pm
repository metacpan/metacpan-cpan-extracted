package Dist::Zilla::App::Command::msg_compile;

# ABSTRACT: Compile language translation files

use Dist::Zilla::App -command;
use strict;
use warnings;
use Path::Tiny qw(path cwd);
use Dist::Zilla::Plugin::LocaleTextDomain;
use IPC::Run3;
use namespace::autoclean;

our $VERSION = '0.91';

sub command_names { qw(msg-compile) }

sub abstract { 'compile language translation files' }

sub usage_desc { '%c %o [<language_code> ...]' }

sub opt_spec {
    return (
        [ 'dest-dir|d=s' => 'location in which to save complied files' ],
        [ 'msgfmt|m=s'   => 'location of msgfmt utility'               ],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    if ( my $msgfmt = $opt->{msgfmt} ) {
        require IPC::Cmd;
        $self->zilla->log_fatal(
            qq{Cannot find "$msgfmt": Are the GNU gettext utilities installed?}
        ) unless IPC::Cmd::can_run($msgfmt);
    }

    if ( my $dir = $opt->{dest_dir} ) {
        $opt->{dest_dir} = path $dir;
    }
}

sub _po_files {
    my ( $self, $plugin ) = @_;
    require File::Find::Rule;
    my $lang_ext = $plugin->lang_file_suffix;
    return File::Find::Rule->file->name("*.$lang_ext")->in($plugin->lang_dir);
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $plugin = $self->zilla->plugin_named('LocaleTextDomain')
        or $self->zilla->log_fatal('LocaleTextDomain plugin not found in dist.ini!');

    my $lang_dir = $plugin->lang_dir;
    my $dest_dir = $opt->{dest_dir} || cwd;
    my $lang_ext = $plugin->lang_file_suffix;
    my $bin_ext  = $plugin->bin_file_suffix;
    my $txt_dom  = $plugin->textdomain;
    my $log      = sub { $plugin->log(@_) };

    my @cmd = (
        $opt->{msgfmt} || $plugin->msgfmt,
        '--check',
        '--statistics',
        '--verbose',
        '--output-file',
    );

    my @pos = @{ $args } ? @{ $args } : $self->_po_files( $plugin );
    $plugin->log_fatal("No language catalog files found") unless @pos;

    $dest_dir->mkpath;

    for my $file (@pos) {
        $file = path $file;
        ( my $lang = $file->basename ) =~ s{[.][^.]*$}{};
        my $dest = $dest_dir->child('LocaleData', $lang, 'LC_MESSAGES',
            "$txt_dom.$bin_ext");
        $dest->parent->mkpath;
        run3 [@cmd, $dest, $file], undef, $log, $log;
        $plugin->log_fatal("Cannot compile $file") if $?;
    }
}

__END__

=head1 Name

Dist::Zilla::App::Command::msg_compile - Compile language translation files

=head1 Synopsis

In F<dist.ini>:

  [LocaleTextDomain]
  textdomain = My-App
  lang_dir = po

On the command line:

  dzil msg-compile po/fr.po

=head1 Description

This command compiles one or more
L<GNU gettext|http://www.gnu.org/software/gettext/>-style language catalogs
into a directory in your distribution. The idea is to be able to easily
compile a catalog while working on it, to see how it works, without having to
compile the entire distribution. It can either compile the specified
translation files, or will scan the language directory to compile all the
translation files in the distribution. It relies on the settings from the
L<C<LocaleTextDomain> plugin|Dist::Zilla::Plugin::LocaleTextDomain> for its
settings, and requires that the GNU gettext utilities be available.

=head2 Options

=head3 C<-d>

=head3 C<--dest-dir>

Destination directory for the compiled catalogs. The compiled language files
will be stored in this directory as
F<LocaleData/$language/LC_MESSAGES/$textdomain.mo>. As long as the specified
directory is in Perl's C<@INC>, Locale::TextDomain should be able to find them
there. Defaults to the current directory.

=head3 C<--msgfmt>

The location of the C<msgfmt> program, which is distributed with
L<GNU gettext|http://www.gnu.org/software/gettext/>. Defaults to just
C<msgfmt> (or C<msgfmt.exe> on Windows), which should work if it's in your
path.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Contributor

Charles McGarvey <ccm@cpan.org>

=head1 Copyright and License

This software is copyright (c) 2012-2017 by David E. Wheeler.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
