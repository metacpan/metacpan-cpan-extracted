package CPAN::Maker::Bootstrapper::Role::LLM::ReleaseNotes;

use strict;
use warnings;

use open ':std', ':encoding(UTF-8)';

use Archive::Tar;
use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(slurp);
use CPAN::Maker::Bootstrapper::Constants qw(:all);
use English qw(-no_match_vars);

use Role::Tiny;

########################################################################
sub cmd_release_notes {
########################################################################
  my ($self) = @_;

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

  my @documents;

  my @file_list = map {"release-$version.$_"} qw(diffs lst tar.gz);

  foreach my $file (@file_list) {
    die "ERROR: $file not found or empty!\n"
      if !-e $file || !-s $file;
  }

  foreach my $file (@file_list) {
    next if $file =~ /[.]tar[.]gz$/xsm;

    push @documents, slurp $file;
  }

  my @prompt;

  push @prompt, $llm->text('Produce release notes in markdown format for this Perl CPAN distribution release.');

  push @prompt,
    $llm->document(
    data  => $documents[0],
    title => 'Diffs'
    );

  push @prompt,
    $llm->document(
    data  => $documents[1],
    title => 'Changed Files Listing'
    );

  # this looks like we are sending a lot files, but in fact we only
  # send the updated files in the repo to the LLM...but worth capping
  my $iter = Archive::Tar->iter( "release-$version.tar.gz", 1 );

  my $file_limit = $self->get_max_diff_files;
  my $file_count = 0;

  # if there are more files in the tarball then $file_limit we dir
  while ( my $file = $iter->() ) {

    next if $file->is_dir;
    next if $file->name =~ /[.](png|jpg|gif|gz|zip|tar)\z/xsmi;

    die sprintf "ERROR: max number of files (%s) in diff listing has been reached. Use --max-diff-files to increase\n",
      $file_limit
      if $file_limit && $file_count == $file_limit;

    my $file_content = $file->get_content;
    next if !defined $file_content || $file_content eq q{};

    push @prompt,
      $llm->document(
      data  => $file_content,
      title => $file->name
      );

    $file_count++;
  }

  my $llm_rsp = $self->_submit_prompt( $llm, \@prompt );

  my $content = $llm_rsp->content;

  if ( !defined $content ) {
    print {*STDERR} $llm_rsp->raw_content;
    return $FAILURE;
  }

  my $release_notes = sprintf 'release-notes-%s.md', $version;

  open my $fh, '>', $release_notes
    or die "ERROR: could not open $release_notes for writing\n$OS_ERROR";

  print {$fh} $content->text;

  close $fh
    or warn "WARNING: could not close $release_notes: $OS_ERROR\n";

  $self->_print_token_usage( $llm_rsp, 'Release Notes: Token Usage Report' );

  return $SUCCESS;
}

1;
