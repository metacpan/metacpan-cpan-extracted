package CPAN::Maker::Bootstrapper::Role::LLM::ReleaseNotes;

use strict;
use warnings;

use open ':std', ':encoding(UTF-8)';

use Archive::Tar;
use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(slurp);
use CPAN::Maker::Bootstrapper::Constants qw(:all);
use Data::Dumper;
use English qw(-no_match_vars);
use File::Path qw(make_path);
use Git::ReleaseDiffs;
use IO::Scalar;
use Pod::Extract qw(extract_pod);

use Role::Tiny;

########################################################################
sub cmd_release_notes {
########################################################################
  my ($self) = @_;

  eval { require Git::Raw; 1; } or do {
    die "ERROR: Git::Raw must be installed to use this command.\n";
  };

  my ( $version, $api_key ) = $self->get_args;

  if ( !$version ) {
    $version = eval { slurp('VERSION'); };
    if ($version) {
      chomp $version;
    }
  }

  die "ERROR: usage cpan-maker-bootstrapper release-notes [api-key]\n"
    if !$version;

  die "ERROR: invalid version\n"
    if $version !~ /\A\d+[.]\d+[.]\d+\z/xsm;

  my $llm = $self->_check_llm($api_key);

  # produce release artifacts from staged changes
  my $release = Git::ReleaseDiffs->new( release_version => $version );
  $release->write_diffs;
  $release->write_list;
  $release->write_tarball;

  # verify artifacts exist
  my @file_list = map {"release-$version.$_"} qw(diffs lst tar.gz);

  foreach my $file (@file_list) {
    die "ERROR: $file not found or empty!\n"
      if !-e $file || !-s $file;
  }

  # truncate ChangeLog to current release section only (in memory)
  my $changelog_excerpt = _extract_changelog_section('ChangeLog');

  my @prompt;

  push @prompt, $llm->text('Produce release notes in markdown format for this Perl CPAN distribution release.');

  push @prompt,
    $llm->document(
    data  => slurp("release-$version.diffs"),
    title => 'Diffs'
    );

  push @prompt,
    $llm->document(
    data  => slurp("release-$version.lst"),
    title => 'Changed Files Listing'
    );

  if ($changelog_excerpt) {
    push @prompt,
      $llm->document(
      data  => $changelog_excerpt,
      title => 'ChangeLog'
      );
  }

  # send updated files from tarball, stripping POD from Perl sources
  my $iter = Archive::Tar->iter( "release-$version.tar.gz", 1 );

  my $file_limit = $self->get_max_diff_files;
  my $file_count = 0;

  while ( my $file = $iter->() ) {

    next if $file->is_dir;
    next if $file->name =~ /[.](png|jpg|gif|gz|zip|tar)\z/xsmi;

    die sprintf "ERROR: max number of files (%s) in diff listing has been reached. Use --max-diff-files to increase\n",
      $file_limit
      if $file_limit && $file_count == $file_limit;

    my $file_content = $file->get_content;

    next if !defined $file_content || $file_content eq q{};

    # strip POD from Perl sources to reduce token cost
    if ( $file->name =~ /[.]p[ml][.]in\z/xsm ) {
      $file_content = _strip_pod($file_content);
    }

    push @prompt,
      $llm->document(
      data  => $file_content,
      title => $file->name
      );

    $file_count++;
  }

  my $llm_rsp = $self->_submit_prompt( $llm, \@prompt );

  my $content = $llm_rsp->content;

  if ( !$content || !$content->text ) {
    print {*STDERR} $llm_rsp->raw_content;
    return $FAILURE;
  }

  if ( $llm_rsp->was_cutoff ) {
    warn "WARNING: response was truncated (hit max_tokens). Increase --max-tokens for a complete response.\n";
  }

  my $release_notes_dir  = 'release-notes';
  my $release_notes_file = sprintf '%s/release-notes-%s.md', $release_notes_dir, $version;
  my $release_notes_link = 'release-notes.md';

  make_path($release_notes_dir);

  open my $fh, '>', $release_notes_file
    or die "ERROR: could not open $release_notes_file for writing\n$OS_ERROR";

  print {$fh} $content->text;

  close $fh
    or warn "WARNING: could not close $release_notes_file: $OS_ERROR\n";

  # create/update symlink release-notes.md -> release-notes/release-notes-VERSION.md
  unlink $release_notes_link
    if -l $release_notes_link;

  symlink $release_notes_file, $release_notes_link
    or warn "WARNING: could not create symlink $release_notes_link: $OS_ERROR\n";

  $self->_print_token_usage( $llm_rsp, 'Release Notes: Token Usage Report' );

  return $SUCCESS;
}

########################################################################
sub _extract_changelog_section {
########################################################################
  my ($changelog_file) = @_;

  return q{} if !-e $changelog_file;

  open my $fh, '<', $changelog_file
    or return q{};

  my $section = q{};
  my $blocks  = 0;

  while ( my $line = <$fh> ) {
    $blocks++ if $line !~ /^\s/xsm && $line =~ /\S/xsm;
    last      if $blocks > 1;
    $section .= $line;
  }

  close $fh;

  return $section;
}

########################################################################
sub _strip_pod {
########################################################################
  my (@args) = @_;

  my $content = @args > 1 && ref $args[0] ? $args[1] : $args[0];

  my $obj = ref $content ? ${$content} : $content;

  my $fh = IO::Scalar->new( \$obj );

  my ( undef, $code ) = extract_pod($fh);

  return $code // $content;
}

1;
