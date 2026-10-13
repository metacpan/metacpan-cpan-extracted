package CPAN::Maker::Bootstrapper::Role::LLM::ChangeLog;

use strict;
use warnings;

use open ':std', ':encoding(UTF-8)';

use Archive::Tar;
use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(slurp choose);
use CPAN::Maker::Bootstrapper::Constants qw(:all);
use Data::Dumper;
use English qw(-no_match_vars);
use Git::ReleaseDiffs;
use IO::Scalar;
use Pod::Extract qw(extract_pod);

use Role::Tiny;

########################################################################
sub cmd_change_log {
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

  die "ERROR: usage cpan-maker-bootstrapper change-log [version] [api-key]\n"
    if !$version;

  die "ERROR: invalid version\n"
    if $version !~ /\A\d+[.]\d+[.]\d+\z/xsm;

  my $output_file = sprintf 'ChangeLog-%s.tmp', $version;

  die "ERROR: $output_file already exists\n" if -e $output_file;

  my $llm = $self->_check_llm($api_key);

  # produce release artifacts from staged changes
  my $release = Git::ReleaseDiffs->new( release_version => $version );
  $release->write_diffs;
  $release->write_list;
  $release->write_status;
  $release->write_tarball;

  # verify artifacts exist
  my @file_list = map {"release-$version.$_"} qw(diffs lst status tar.gz);

  foreach my $file (@file_list) {
    die "ERROR: $file not found or empty!\n"
      if !-e $file || !-s $file;
  }

  # truncate ChangeLog to current release section only (in memory)
  my $changelog_excerpt = $self->_extract_changelog_section('ChangeLog');

  my @prompt;

  if ( !-e '.prompts/change-log.prompt' ) {
    $self->_install_prompts('change-log.prompt');
  }

  my $prompt_text = choose {

    return slurp('.prompts/change-log.prompt')
      if -f '.prompts/change-log.prompt';

    return 'Produce a file-oriented ChangeLog entry for this Perl CPAN distribution release.';
  };

  if ( !$self->get_dryrun ) {
    push @prompt, $llm->text($prompt_text);

    push @prompt,
      $llm->document(
      data  => slurp("release-$version.status"),
      title => 'Git File Status'
      );

    push @prompt,
      $llm->document(
      data  => slurp("release-$version.diffs"),
      title => 'Release Diffs'
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
      $file_content = $self->_strip_pod_from_content($file_content);
    }

    push @prompt,
      $llm->document(
      data  => $file_content,
      title => $file->name
      ) if !$self->get_dryrun;

    $file_count++;
  }

  return $SUCCESS
    if $self->get_dryrun;

  my $llm_rsp = $self->_submit_prompt( $llm, \@prompt );

  my $content = $llm_rsp->content;

  if ( !$content || !$content->text ) {
    print {*STDERR} $llm_rsp->raw_content;
    return $FAILURE;
  }

  if ( $llm_rsp->was_cutoff ) {
    warn "WARNING: response was truncated (hit max_tokens). Increase --max-tokens for a complete response.\n";
  }

  open my $fh, '>', $output_file
    or die "ERROR: could not open $output_file for writing\n$OS_ERROR";

  print {$fh} $content->text;

  close $fh
    or die "ERROR: could not close $output_file: $OS_ERROR\n";

  print "Created $output_file\n";

  $self->_print_token_usage( $llm_rsp, 'ChangeLog: Token Usage Report' );

  return $SUCCESS;
}

1;
