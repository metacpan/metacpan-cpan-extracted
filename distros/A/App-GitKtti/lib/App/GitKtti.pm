package App::GitKtti;

use strict;
use warnings;
use POSIX qw(strftime);
use Cwd qw(getcwd);

our $VERSION = '2.0.0';

=head1 NAME

App::GitKtti - Git flow helper scripts for safe branch management

=head1 SYNOPSIS

    use App::GitKtti;
    
    # Use the command-line tools:
    # gitktti-checkout
    # gitktti-delete
    # gitktti-fix
    # gitktti-fixend
    # gitktti-move
    # gitktti-tag
    # gitktti-tests

=head1 DESCRIPTION

The gitktti scripts are provided to help developers safely use git flow.
This module provides a collection of tools for managing git branches
following git-flow methodology.

=head1 FEATURES

=over 4

=item * Safe branch operations with validation

=item * Colorized output for better readability

=item * Support for feature, hotfix, and release workflows

=item * Automatic branch cleanup and management

=back

=head1 AUTHOR

saumon <sshrekrobu@gmail.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# Codes de couleurs ANSI
use constant {
  RESET     => "\033[0m",
  BOLD      => "\033[1m",
  DIM       => "\033[2m",

  # Couleurs de texte
  BLACK     => "\033[30m",
  RED       => "\033[31m",
  GREEN     => "\033[32m",
  YELLOW    => "\033[33m",
  BLUE      => "\033[34m",
  MAGENTA   => "\033[35m",
  CYAN      => "\033[36m",
  WHITE     => "\033[37m",

  # Couleurs vives
  BRIGHT_RED     => "\033[91m",
  BRIGHT_GREEN   => "\033[92m",
  BRIGHT_YELLOW  => "\033[93m",
  BRIGHT_BLUE    => "\033[94m",
  BRIGHT_MAGENTA => "\033[95m",
  BRIGHT_CYAN    => "\033[96m",
  BRIGHT_WHITE   => "\033[97m",

  # Couleurs de fond
  BG_RED    => "\033[41m",
  BG_GREEN  => "\033[42m",
  BG_YELLOW => "\033[43m",
  BG_BLUE   => "\033[44m",
};

sub showVersion {
  showLogo();
  print(BRIGHT_MAGENTA . BOLD . "🚀 gitktti " . BRIGHT_WHITE . "v" . $VERSION . RESET . " " . DIM . "by saumon™" . RESET . "\n\n");
}

# Fonctions d'affichage coloré
sub printSuccess {
  my $message = $_[0];
  print(BRIGHT_GREEN . "✅ " . $message . RESET . "\n");
}

sub printError {
  my $message = $_[0];
  print(BRIGHT_RED . "❌ " . $message . RESET . "\n");
}

sub printWarning {
  my $message = $_[0];
  print(BRIGHT_YELLOW . "⚠️  " . $message . RESET . "\n");
}

sub printInfo {
  my $message = $_[0];
  print(BRIGHT_BLUE . "ℹ️  " . $message . RESET . "\n");
}

sub printCommand {
  my $command = $_[0];
  print(DIM . "\$ " . RESET . CYAN . $command . RESET . "\n");
}

sub printSection {
  my $title = $_[0];
  my $title_length = length($title);
  my $separator = "═" x ($title_length + 2);

  print("\n" . BRIGHT_MAGENTA . "╔" . $separator . "╗" . RESET . "\n");
  print(BRIGHT_MAGENTA . "║ " . BOLD . BRIGHT_WHITE . $title . RESET . BRIGHT_MAGENTA . " ║" . RESET . "\n");
  print(BRIGHT_MAGENTA . "╚" . $separator . "╝" . RESET . "\n");
}

sub printSubSection {
  my $title = $_[0];
  print("\n" . BRIGHT_CYAN . "▶ " . BOLD . $title . RESET . "\n");
}

sub printBranch {
  my $branch = $_[0];
  my $type = $_[1] || "default";

  my $color = CYAN;
  my $icon = "🌿";

  if ($type eq "master" || $type eq "main") {
    $color = BRIGHT_RED;
    $icon = "🏠";
  } elsif ($type eq "develop" || $type eq "dev") {
    $color = BRIGHT_GREEN;
    $icon = "🔨";
  } elsif ($type eq "feature") {
    $color = BRIGHT_BLUE;
    $icon = "✨";
  } elsif ($type eq "hotfix") {
    $color = BRIGHT_YELLOW;
    $icon = "🔥";
  } elsif ($type eq "release") {
    $color = BRIGHT_MAGENTA;
    $icon = "🚀";
  }

  print($color . $icon . " " . BOLD . $branch . RESET);
}

sub printTag {
  my $tag = $_[0];
  print(BRIGHT_YELLOW . "🏷️  " . BOLD . $tag . RESET);
}

##############################################################################
## Fonction launch
## Permet d executer une commande shell. Prend en entree la commande
## a executer et retourne une liste contenant le resultat d execution de la
## fonction.
##############################################################################
sub launch {
  my $command   = $_[0];
  my $ref_state = $_[1];
  my @out = ();

  $$ref_state = 99;

  if ( length($command) == 0 ) {
    printError("launch : command is empty !");
    return @out;
  }

  printCommand($command);

  open my $cmd_fh, '-|', "$command 2>&1" or die "launch : ERROR !";
  my $output = "";
  my @lines = ();
  while(my $ligne = <$cmd_fh>) {
    chomp($ligne);
    push(@out, $ligne);
    push(@lines, $ligne);
  }
  close($cmd_fh);

  # Affichage de la sortie avec indentation et couleur grise
  if (@lines > 0) {
    foreach my $line (@lines) {
      print(DIM . "  │ " . $line . RESET . "\n");
    }
    # Supprimer le dernier \n pour ajouter le symbole de statut
    print("\033[1A"); # Remonter d'une ligne
    print("\033[K");  # Effacer la ligne
    my $last_line = $lines[-1];
    print(DIM . "  │ " . $last_line . RESET);
  }

  ## Get output state
  $$ref_state = $? >> 8;

  if ( $$ref_state ne 0 ) {
    # Ajouter le X rouge et le code d'erreur à la fin de la sortie
    if (@lines > 0) {
      print(BRIGHT_RED . " ✗ (" . $$ref_state . ")" . RESET . "\n");
    } else {
      print(DIM .  "  │ " . BRIGHT_RED . "Command failed " . RESET . BRIGHT_RED . "✗ (" . $$ref_state . ")" . RESET . "\n");
    }
  } else {
    # Ajouter le checkmark à la fin de la sortie
    if (@lines > 0) {
      print(BRIGHT_GREEN . " ✔" . RESET . "\n");
    } else {
      print(DIM  . "  │ " . BRIGHT_GREEN . "Command executed successfully " . RESET . BRIGHT_GREEN . "✔" . RESET . "\n");
    }
  }

  print("\n");
  return @out;
}

sub isResponseYes {
  my $question = $_[0];
  my $rep = "";

  do
  {
    $rep = lc(getResponse($question . " " . BRIGHT_GREEN . "(y)" . RESET . "/" . BRIGHT_RED . "(n)" . RESET));
  }
  while ( $rep !~ /^y$/ && $rep !~ /^n$/ );

  if ( $rep eq 'y' ) {
    return 1;
  }
  else {
    return 0;
  }
}

sub getResponse {
  my $question = $_[0];
  my $default = $_[1];
  my $rep = "";

  print("\n");
  print(BRIGHT_CYAN . "❓ " . BOLD . $question . RESET);
  if ( defined($default) && length($default) > 0 ) {
    print(" " . DIM . "[default: " . BRIGHT_WHITE . $default . RESET . DIM . "]" . RESET);
  }
  print("\n" . BRIGHT_CYAN . "➤ " . RESET);

  $rep = <STDIN>;
  print("\n");

  chomp($rep);

  if ( defined($default) && length($default) > 0 && length($rep) == 0 ) {
    $rep = $default;
  }

  return($rep);
}

sub getSelectResponse {

  my $rep         = "";
  my $i_rep       = 0;
  my $nb_elts     = scalar @_;
  my $max_len_rep = 0;

  if ( $nb_elts <= 1 ) {
    die("ERROR: getSelectResponse, missing args !");
  }

  my $question = $_[0];

  print("\n");
  printSubSection($question);

  for(my $i = 1; $i < $nb_elts; $i++) {
    my @list = split(/\|/, $_[$i]);
    my $len = length($list[0]);
    if ( $len > $max_len_rep ) { $max_len_rep = $len };
  }

  for(my $i = 1; $i < $nb_elts; $i++) {
    my @list = split(/\|/, $_[$i]);
    my $number = BRIGHT_CYAN . sprintf("%2d", $i) . RESET;
    my $option = BRIGHT_WHITE . BOLD . RPad($list[0], $max_len_rep, ' ') . RESET;
    my $line = "   " . $number . ") " . $option;

    if ( scalar @list > 1 ) {
      $line .= " " . DIM . "(" . $list[1] . ")" . RESET;
    }

    print($line . "\n");
  }

  do {
    print("\n" . BRIGHT_CYAN . "🎯 Your choice: " . RESET);
    $i_rep = <STDIN>;
  }
  while ( $i_rep !~ /^\d+$/ || ($i_rep < 1) || ($i_rep > ($nb_elts - 1)) );

  if ( ($i_rep >= 1) && ($i_rep < $nb_elts) ) {
    my @list = split(/\|/, $_[$i_rep]);
    $rep = $list[0];
    printSuccess("You have chosen: " . BOLD . $rep . RESET);
  }

  print("\n");

  chomp($rep);

  return($rep);
}

#---------------------------------------------------------------------
# LPad
#---------------------------------------------------------------------
# Pads a string on the left end to a specified length with a specified
# character and returns the result.  Default pad char is space.
#---------------------------------------------------------------------

sub LPad {
  my ($str, $len, $chr) = @_;
  $chr = " " unless (defined($chr));
  return substr(($chr x $len) . $str, -1 * $len, $len);
} # LPad

#---------------------------------------------------------------------
# RPad
#---------------------------------------------------------------------
# Pads a string on the right end to a specified length with a specified
# character and returns the result.  Default pad char is space.
#---------------------------------------------------------------------

sub RPad {
  my ($str, $len, $chr) = @_;
  $chr = " " unless (defined($chr));
  return substr($str . ($chr x $len), 0, $len);
} # RPad

sub directoryExists {
  my $path      = $_[0];
  my $directory = $_[1];
  my $found     = 0;

  opendir(my $dh, $path) or die("ERROR: directoryExists, bad path given !");

  while ( !$found && (my $file = readdir($dh)) ) {
    if ( -d "$path/$file" && $file =~ /^$directory$/ ) {
      $found = 1;
    }
    }
  closedir($dh);

  return $found;
}

sub git_getTrackedRemoteBranch {
  my $ref_ret = $_[0];
  my %index_remotebranch = ();

  $index_remotebranch{"remote"} = "";
  $index_remotebranch{"branch"} = "";

  my @remotebranch = launch('git rev-parse --abbrev-ref --symbolic-full-name @{u}', $ref_ret);

  if($$ref_ret == 0 && @remotebranch >= 1 && $remotebranch[0] =~ /^(\w+)\/(.+)$/) {
    $index_remotebranch{"remote"} = $1;
    $index_remotebranch{"branch"} = $2;
  }

  return %index_remotebranch
}

sub git_getGitRootDirectory {

  my $ret       = 99;
  my $directory = "";

  $directory = (launch('git rev-parse --show-toplevel', \$ret))[0];

  ## Exit if checkout fails
  if ( $ret ne 0 ) {
    print("ERROR: getGitRootDirectory failed ! Aborted !\n");
    exit(2);
  }

  return $directory;
}

sub git_isRepoClean {
  my $ret   = 99;
  my $clean = 1;

  my @files = launch('git status --porcelain', \$ret);

  if(@files > 0) {
    $clean = 0;
  }

  return $clean;
}

sub trim {
  my $s = shift;
  $s =~ s/^\s+|\s+$//g;
  return $s
}

sub super_scp {
  my $rep_src    = $_[0];
  my $rep_dest   = $_[1];
  my $srv_user   = $_[2];
  my $srv_ip     = $_[3];
  my $ret        = 99;

  print("SRC  : $rep_src\n");
  print("DEST : $rep_dest\n");
  print("USER : $srv_user\n");
  print("HOST : $srv_ip\n");

  if ( isResponseYes("Synchronize [SRC] to [DEST] ? (with 'scp')") ) {

    # Without redirecting to /dev/tty I get no output...
    launch("scp -r $rep_src $srv_user\@$srv_ip:$rep_dest >/dev/tty", \$ret);

    ## Exit if scp fails
    if ( $ret ne 0 ) {
      print("ERROR: scp failed ! Aborted !\n");
      exit(2);
    }
  }
}

sub super_rsync_ssh {
  my $rep_src    = $_[0];
  my $rep_dest   = $_[1];
  my $srv_user   = $_[2];
  my $srv_ip     = $_[3];
  my $use_delete = $_[4];
  my $opt_delete = "";
  my $ret        = 99;

  print("SRC  : $rep_src\n");
  print("DEST : $rep_dest\n");
  print("USER : $srv_user\n");
  print("HOST : $srv_ip\n");

  if ( isResponseYes("Synchronize [SRC] to [DEST] ? (with 'rsync')") ) {

    ## Warning: using [--delete] can be dangerous !!!
    if ( $use_delete && isResponseYes("Use option [--delete] ? (WARNING: can be dangerous) !") ) {
      $opt_delete = "--delete";
    }

    launch("rsync -e ssh -avz --progress $opt_delete $rep_src $srv_user\@$srv_ip:$rep_dest", \$ret);

    ## Exit if rsync fails
    if ( $ret ne 0 ) {
      print("ERROR: rsync failed ! Aborted !\n");
      exit(2);
    }
  }
}

sub super_rsync_ssh_with_exclude {
  my $rep_src          = $_[0];
  my $rep_dest         = $_[1];
  my $srv_user         = $_[2];
  my $srv_ip           = $_[3];
  my $use_delete       = $_[4];
  my $use_fakesuper    = $_[5];
  my $skip_confirm     = $_[6];
  my $ref_list_exclude = $_[7];
  my $opt_delete       = "";
  my $opt_fakesuper    = "";
  my $opt_exclude      = "";
  my $ret              = 99;
  my $go               = 0;

  print("SRC  : $rep_src\n");
  print("DEST : $rep_dest\n");

  foreach my $exclude (@{$ref_list_exclude}) {
    print("EXCL : $exclude\n");

    $opt_exclude .= "--exclude '$exclude' ";
  }

  if ( $use_fakesuper ) {
    $opt_fakesuper = "--rsync-path='rsync --fake-super' ";
  }

  print("USER : $srv_user\n");
  print("HOST : $srv_ip\n");

  if ( $skip_confirm ) {
    $go = 1;
  }
  else {
    $go = isResponseYes("Synchronize [SRC] to [DEST] ? (with 'rsync')");
  }

  if ( $go ) {

    ## Warning: using [--delete] can be dangerous !!!
    if ( $use_delete && isResponseYes("Use option [--delete] ? (WARNING: can be dangerous) !") ) {
      $opt_delete = "--delete ";
    }

    ## Launch rsync command
    launch("rsync -avzhe ssh " . $opt_fakesuper . $opt_delete . $opt_exclude . "$rep_src $srv_user\@$srv_ip:$rep_dest", \$ret);

    # Exit if rsync fails
    if ( $ret ne 0 ) {
      print("ERROR: rsync failed ! Aborted !\n");
      exit(2);
    }
  }
}

sub git_checkoutBranch {
  my $arg_branch = $_[0];
  my $ret        = 99;

  if (isResponseYes("Checkout branch " . BOLD . $arg_branch . RESET . "?") ) {

    launch("git checkout $arg_branch", \$ret);

    ## Exit if checkout fails
    if ( $ret ne 0 ) {
      printError("checkout failed ! Aborted !");
      exit(2);
    }
  }
}

sub git_checkoutBranchNoConfirm {
  my $arg_branch = $_[0];
  my $ret        = 99;

  launch("git checkout $arg_branch", \$ret);

  ## Exit if checkout fails
  if ( $ret ne 0 ) {
    printError("checkout failed ! Aborted !");
    exit(2);
  }
}

sub git_deleteLocalBranch {
  my $arg_branch = $_[0];
  my $ret        = 99;
  my $done       = 0;

  if (isResponseYes("Delete local branch " . BOLD . $arg_branch . RESET . "?") ) {

    ## Delete current branch
    launch("git branch -D $arg_branch", \$ret);

    ## Exit if command fails
    if ( $ret ne 0 ) {
      printError("delete failed ! Aborted !");
      exit(2);
    }

    $done = 1;
  }

  return $done;
}

sub git_getLocalBranches {
  my $ref_ret = $_[0];
  return (launch("git branch | awk -F ' +' '! /\\(no branch\\)/ {print \$2}'", $ref_ret));
}

sub git_getLocalBranchesFilter {
  return launch("git branch | awk -F ' +' '! /\\(no branch\\)/ {print \$2}' | grep -E \"$_[0]\"", $_[1]);
}

sub git_getRemoteBranchesFilter {

  my $arg_remote = $_[0];
  my $arg_filter = $_[1];
  my $ref_ret    = $_[2];
  my @branches   = ();

  if ( $arg_remote ne "" ) {
    push(@branches, launch("git branch --remote | awk -F ' +' '! /\\(no branch\\)/ {print \$2}' | grep -E \"$arg_filter\"", $ref_ret));
  }

  return @branches;
}

sub git_getAllBranchesFilter {

  my $arg_remote = $_[0];
  my $arg_filter = $_[1];
  my $ref_ret    = $_[2];
  my @branches   = ();

  push(@branches, git_getRemoteBranchesFilter($arg_remote, $arg_filter, $ref_ret));
  push(@branches, git_getLocalBranchesFilter($arg_filter, $ref_ret));

  return @branches;
}

sub git_getCurrentBranch {
  my $ref_ret = $_[0];
  return (launch('git rev-parse --abbrev-ref HEAD', $ref_ret))[0];
}

sub git_fetch {
  my $ref_ret = $_[0];
  launch("git fetch", $ref_ret);
}

sub git_getLastTagFromAllBranches {
  my $ref_ret = $_[0];
  my @out = launch('git describe --tags $(git rev-list --tags --max-count=1)', $ref_ret);

  if(@out > 0) {
    return $out[0];
  }
  else {
    return "";
  }
}

sub git_getLastTagFromCurrentBranch {
  my $ref_ret = $_[0];
  my @out = launch('git describe --abbrev=0 --tags', $ref_ret);

  if(@out > 0) {
    return $out[0];
  }
  else {
    return "";
  }
}

sub git_cleanLocalTags {
  my $ref_ret = $_[0];
  return (launch('git tag -l | xargs git tag -d', $ref_ret))[0];
}

sub git_fetchTags {
  my $ref_ret = $_[0];
  return (launch('git fetch --tags', $ref_ret))[0];
}

sub git_fetchPrune {
  my $ref_ret = $_[0];
  return (launch('git fetch --all --prune', $ref_ret))[0];
}

sub git_remotePrune {
  my $arg_remote = $_[0];
  my $ref_ret    = $_[1];
  return (launch("git remote prune $arg_remote", $ref_ret))[0];
}

## ATTENTION :
##  - ne marche pas a 100% (va a l'encontre de la logique git)
##  - des commits avec des [ ] cassent la fonction
##    Exemple : "[G401-439] Page not found"
## warning, this one is hard like chuck norris's dick
sub git_getParentBranch {
  my $ref_ret = $_[0];
  ## git show-branch -a | grep '\*' | grep -v `git rev-parse --abbrev-ref HEAD` | head -n1 | sed 's/.*\[\(.*\)\].*/\1/' | sed 's/[\^~].*//'
  #return (launch("git show-branch -a | grep '\\*' | grep -v `git rev-parse --abbrev-ref HEAD` | head -n1 | sed 's/.*\\[\\(.*\\)\\].*/\\1/' | sed 's/[\\^~].*//'", $ref_ret))[0];

  ## git show-branch | sed "s/].*//" | grep "\*" | grep -v "$(git rev-parse --abbrev-ref HEAD)" | head -n1 | sed "s/^.*\[//"
  #return (launch("git show-branch | sed \"s/].*//\" | grep \"\\*\" | grep -v \"$(git rev-parse --abbrev-ref HEAD)\" | head -n1 | sed \"s/^.*\\[//\"", $ref_ret))[0];

  ## git show-branch | grep '*' | grep -v "$(git rev-parse --abbrev-ref HEAD)" | head -n1 | sed 's/.*\[\(.*\)\].*/\1/' | sed 's/[\^~].*//'
  return (launch("git show-branch | grep '*' | grep -v \"\$(git rev-parse --abbrev-ref HEAD)\" | head -n1 | sed 's/.*\\[\\(.*\\)\\].*/\\1/' | sed 's/[\\^~].*//'", $ref_ret))[0];
}

sub git_tagBranch {
  my $branch  = $_[0];
  my $tagname = $_[1];
  my $lasttag = $_[2];

  my $ret          = 99;
  my $tagging_done = 0;
  my $question     = "Create tag " . BOLD . $tagname . RESET . " on branch " . BOLD . $branch . RESET;

  if ( $tagname eq "" ) {
    printError("git_tagBranch, no tagname provided !");
    exit(2);
  }

  if ( $lasttag ne "" ) {
    $question .= " (old tag is " . DIM . $lasttag . RESET . ")";
  }

  ## Check current branch name
  if(git_getCurrentBranch(\$ret) !~ /^$branch$/) {
    printError("git_tagBranch, bad branch ! (you should be on branch '$branch')");
    exit(2);
  }

  $question .= "?";

  if (isResponseYes($question) ) {
    ## Tags current branch...
    launch("git tag -a $tagname -m 'version $tagname'", \$ret);

    ## Exit if tagging fails
    if ( $ret ne 0 ) {
      printError("tagging failed ! Aborted !");
      exit(2);
    }
    else {
      printSuccess("Tag " . BOLD . $tagname . RESET . " created !");
      $tagging_done = 1;
    }

    ## Get tracked remote branch...
    my %tracked_branch = git_getTrackedRemoteBranch(\$ret);

    if ( $tracked_branch{"remote"} ne "" &&  $tracked_branch{"branch"} ne "" ) {
      if (isResponseYes("Push tag " . BOLD . $tagname . RESET . "?") ) {
        ## Pushes tag to remote...
        launch("git push --follow-tags", \$ret);

        ## Exit if checkout fails
        if ( $ret ne 0 ) {
          printError("push failed ! Aborted !");
          exit(2);
        }
      }
    }
    else {
      printInfo("No remote, no push, no chocolate !");
    }
  }
  else {
    printWarning("Tagging aborted !");
  }

  return $tagging_done;
}

sub git_pullCurrentBranch {
  my $arg_remote                 = $_[0];
  my $arg_tracking_remote_branch = $_[1];

  my $ret = 99;

  if ( $arg_remote ne "" && $arg_tracking_remote_branch ne "" ) {

    ## Pulls branch...
    launch("git pull", \$ret);

    ## Exit if pull fails
    if ( $ret ne 0 ) {
      printError("pull failed ! Aborted !");
      exit(2);
    }
  }
  # else {
  #   printInfo("pullCurrentBranch : no remote, no pull, no chocolate...");
  # }
}

sub git_deleteCurrentBranch {
  my $arg_current_branch         = $_[0];
  my $arg_remote                 = $_[1];
  my $arg_tracking_remote_branch = $_[2];

  my $ret = 99;

  if (isResponseYes("Delete branch " . BOLD . $arg_current_branch . RESET . "?") ) {

    ## Delete current branch
    launch("git branch -d $arg_current_branch", \$ret);

    ## Delete remote branch
    if ( $arg_remote ne "" && $arg_tracking_remote_branch ne "" ) {
      if (isResponseYes("Delete tracking remote branch " . BOLD . $arg_remote . "/" . $arg_tracking_remote_branch . RESET . "?") ) {
        launch("git push " . $arg_remote . " --delete " . $arg_tracking_remote_branch, \$ret);
      }
    }
  }
}

sub git_mergeIntoBranch {
  my $arg_branch_into     = $_[0];
  my $arg_branch_to_merge = $_[1];

  my $ret        = 99;
  my $merge_done = 0;

  if (isResponseYes("Merge branch " . BOLD . $arg_branch_to_merge . RESET . " into " . BOLD . $arg_branch_into . RESET . "?") ) {
    launch("git checkout $arg_branch_into", \$ret);

    ## Exit if checkout fails
    if ( $ret ne 0 ) {
      printError("checkout failed ! Aborted !");
      exit(2);
    }

    ## Get tracked remote branch...
    my %tracked_branch_into = git_getTrackedRemoteBranch(\$ret);

    ## Pull it
    git_pullCurrentBranch($tracked_branch_into{"remote"}, $tracked_branch_into{"branch"});

    launch("git merge --no-ff $arg_branch_to_merge", \$ret);

    ## Exit if merge fails
    if ( $ret ne 0 ) {
      printError("merge failed ! Aborted !");
      exit(2);
    }
    else {
      $merge_done = 1;
    }

    if ( $tracked_branch_into{"remote"} ne "" &&  $tracked_branch_into{"branch"} ne "" ) {
      if (isResponseYes("Push " . BOLD . $arg_branch_into . RESET . "?") ) {
        launch("git push", \$ret);

        ## Exit if push fails
        if ( $ret ne 0 ) {
          printError("push failed ! Aborted !");
          exit(2);
        }
      }
    }
  }

  return $merge_done;
}

sub git_duplicateRepository {
  my $old_repository = $_[0];
  my $new_repository = $_[1];

  my $ret       = 99;
  my $temp_repo = "";

  if ( $old_repository eq "" ) {
    print("ERROR: old_repository is empty !\n");
    exit(2);
  }

  if ( $new_repository eq "" ) {
    print("ERROR: new_repository is empty !\n");
    exit(2);
  }

  $temp_repo = "TEMPREPO_" . strftime("%Y%m%d_%H%M%S", localtime);

  ## Step 1: clone old repository
  launch("git clone --bare $old_repository $temp_repo", \$ret);

  if ( $ret ne 0 ) {
    print("ERROR: clone failed ! Aborted !\n");
    exit(2);
  }

  ### Step 2: push to new repository
  chdir($temp_repo);
  print("now here : " . getcwd() . "\n");

  launch("git push --mirror $new_repository", \$ret);

  if ( $ret ne 0 ) {
    print("ERROR: push failed ! Aborted !\n");
    exit(2);
  }

  ## Step 3: clean temp repositoy
  chdir("..");
  print("now here : " . getcwd() . "\n");

  launch("rm -rf $temp_repo", \$ret);

  if ( $ret ne 0 ) {
    print("ERROR: cd failed ! Aborted !\n");
    exit(2);
  }

  print("Repository successfuly duplicated !\n");
  print("From [$old_repository]\n");
  print("To   [$new_repository]\n");
}

sub showLogo {
  print "\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;6;6;6m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m
\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;37;24;64m.\033[0m\033[38;2;89;56;163m,\033[0m\033[38;2;117;73;217m:\033[0m\033[38;2;122;77;229m:\033[0m\033[38;2;106;68;198m;\033[0m\033[38;2;64;42;118m.\033[0m\033[38;2;5;3;8m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m
\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;2;2;2m \033[0m\033[38;2;44;28;78m.\033[0m\033[38;2;99;64;183m;\033[0m\033[38;2;123;79;233m:\033[0m\033[38;2;122;80;234mc\033[0m\033[38;2;122;81;234mc\033[0m\033[38;2;121;81;234mc\033[0m\033[38;2;121;82;234mc\033[0m\033[38;2;120;82;235mc\033[0m\033[38;2;113;77;220m:\033[0m\033[38;2;68;47;130m.\033[0m\033[38;2;9;7;17m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m
\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;14;14;14m \033[0m\033[38;2;53;34;96m.\033[0m\033[38;2;122;81;234mc\033[0m\033[38;2;121;82;234mc\033[0m\033[38;2;120;83;234mc\033[0m\033[38;2;120;84;235mc\033[0m\033[38;2;119;84;234mc\033[0m\033[38;2;59;42;115m.\033[0m\033[38;2;118;86;235mc\033[0m\033[38;2;117;87;236mc\033[0m\033[38;2;117;88;236mc\033[0m\033[38;2;116;88;237mc\033[0m\033[38;2;113;86;229mc\033[0m\033[38;2;70;54;142m'\033[0m\033[38;2;14;11;27m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m
\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;1;1;1m \033[0m\033[38;2;42;27;76m.\033[0m\033[38;2;8;5;14m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;11;11;11m \033[0m\033[38;2;59;59;59m \033[0m\033[38;2;50;35;98m.\033[0m\033[38;2;118;86;236mc\033[0m\033[38;2;117;87;235mc\033[0m\033[38;2;109;81;217m:\033[0m\033[38;2;56;43;107m.\033[0m\033[38;2;112;87;224mc\033[0m\033[38;2;114;91;237mc\033[0m\033[38;2;113;93;237mc\033[0m\033[38;2;112;94;238mc\033[0m\033[38;2;112;95;238mc\033[0m\033[38;2;111;96;239mc\033[0m\033[38;2;110;95;235mc\033[0m\033[38;2;73;64;154m,\033[0m\033[38;2;17;15;35m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m
\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;1;1;2m \033[0m\033[38;2;53;36;97m.\033[0m\033[38;2;108;73;204m;\033[0m\033[38;2;122;84;236mc\033[0m\033[38;2;118;81;227m:\033[0m\033[38;2;74;52;141m'\033[0m\033[38;2;15;10;26m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;9;9;9m \033[0m\033[38;2;57;57;57m \033[0m\033[38;2;40;31;80m.\033[0m\033[38;2;114;92;238mc\033[0m\033[38;2;113;94;237mc\033[0m\033[38;2;112;96;238mc\033[0m\033[38;2;111;98;239mc\033[0m\033[38;2;110;99;239mc\033[0m\033[38;2;110;101;240mc\033[0m\033[38;2;109;102;240mc\033[0m\033[38;2;108;103;240mc\033[0m\033[38;2;107;104;241mc\033[0m\033[38;2;107;105;241mc\033[0m\033[38;2;106;104;240mc\033[0m\033[38;2;74;74;165m,\033[0m\033[38;2;21;21;45m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m
\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;3;2;4m \033[0m\033[38;2;56;39;105m.\033[0m\033[38;2;110;76;210m:\033[0m\033[38;2;122;86;237mc\033[0m\033[38;2;121;87;237mc\033[0m\033[38;2;120;88;237mc\033[0m\033[38;2;119;89;238mc\033[0m\033[38;2;119;90;238mc\033[0m\033[38;2;117;88;234mc\033[0m\033[38;2;77;60;154m,\033[0m\033[38;2;18;14;34m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;8;8;8m \033[0m\033[38;2;23;23;23m \033[0m\033[38;2;13;13;13m \033[0m\033[38;2;23;23;23m \033[0m\033[38;2;52;52;52m \033[0m\033[38;2;47;44;102m.\033[0m\033[38;2;107;105;241mc\033[0m\033[38;2;106;107;241ml\033[0m\033[38;2;105;108;241ml\033[0m\033[38;2;104;109;241ml\033[0m\033[38;2;80;83;183m;\033[0m\033[38;2;104;111;242ml\033[0m\033[38;2;103;113;243ml\033[0m\033[38;2;101;114;243ml\033[0m\033[38;2;73;86;177m;\033[0m\033[38;2;24;30;58m.\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m
\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;6;4;10m \033[0m\033[38;2;62;44;116m.\033[0m\033[38;2;112;80;215m:\033[0m\033[38;2;121;88;237mc\033[0m\033[38;2;120;89;238mc\033[0m\033[38;2;119;91;238mc\033[0m\033[38;2;117;91;237mc\033[0m\033[38;2;60;47;120m.\033[0m\033[38;2;115;94;238mc\033[0m\033[38;2;115;96;239mc\033[0m\033[38;2;113;97;239mc\033[0m\033[38;2;112;98;239mc\033[0m\033[38;2;63;55;133m'\033[0m\033[38;2;1;1;1m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;8;8;18m \033[0m\033[38;2;104;110;241ml\033[0m\033[38;2;104;111;242ml\033[0m\033[38;2;103;112;242ml\033[0m\033[38;2;87;93;200m:\033[0m\033[38;2;3;3;7m \033[0m\033[38;2;83;93;194m:\033[0m\033[38;2;99;119;243ml\033[0m\033[38;2;98;122;245ml\033[0m\033[38;2;96;125;245ml\033[0m\033[38;2;94;127;245ml\033[0m\033[38;2;70;99;186m:\033[0m\033[38;2;29;42;76m.\033[0m\033[38;2;1;1;1m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m
\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;8;6;15m \033[0m\033[38;2;68;48;129m'\033[0m\033[38;2;116;83;225m:\033[0m\033[38;2;120;89;238mc\033[0m\033[38;2;119;90;238mc\033[0m\033[38;2;118;92;238mc\033[0m\033[38;2;117;93;239mc\033[0m\033[38;2;116;95;239mc\033[0m\033[38;2;92;75;184m;\033[0m\033[38;2;8;7;16m \033[0m\033[38;2;96;83;198m:\033[0m\033[38;2;112;102;240mc\033[0m\033[38;2;110;104;241mc\033[0m\033[38;2;108;106;241ml\033[0m\033[38;2;98;98;220mc\033[0m\033[38;2;19;19;41m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;32;32;32m \033[0m\033[38;2;12;13;28m \033[0m\033[38;2;100;117;243ml\033[0m\033[38;2;99;120;244ml\033[0m\033[38;2;98;121;245ml\033[0m\033[38;2;86;106;209mc\033[0m\033[38;2;97;124;245ml\033[0m\033[38;2;95;127;245ml\033[0m\033[38;2;94;129;246ml\033[0m\033[38;2;92;132;246ml\033[0m\033[38;2;91;134;247mo\033[0m\033[38;2;89;137;248mo\033[0m\033[38;2;87;140;249mo\033[0m\033[38;2;69;117;202mc\033[0m\033[38;2;29;52;86m.\033[0m\033[38;2;2;2;2m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m
\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;15;11;26m \033[0m\033[38;2;75;53;141m'\033[0m\033[38;2;117;84;229mc\033[0m\033[38;2;120;89;238mc\033[0m\033[38;2;119;90;238mc\033[0m\033[38;2;118;92;239mc\033[0m\033[38;2;117;93;239mc\033[0m\033[38;2;116;95;239mc\033[0m\033[38;2;114;97;240mc\033[0m\033[38;2;113;100;240mc\033[0m\033[38;2;111;101;240mc\033[0m\033[38;2;105;97;224mc\033[0m\033[38;2;109;106;241ml\033[0m\033[38;2;107;108;242ml\033[0m\033[38;2;106;110;242ml\033[0m\033[38;2;104;113;242ml\033[0m\033[38;2;103;114;242ml\033[0m\033[38;2;102;115;242ml\033[0m\033[38;2;71;81;165m;\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;1;1;2m \033[0m\033[38;2;35;41;85m.\033[0m\033[38;2;2;2;2m \033[0m\033[38;2;2;2;2m \033[0m\033[38;2;43;43;43m \033[0m\033[38;2;101;101;101m \033[0m\033[38;2;90;118;231mc\033[0m\033[38;2;94;129;246ml\033[0m\033[38;2;93;131;246ml\033[0m\033[38;2;92;133;246mo\033[0m\033[38;2;91;134;247mo\033[0m\033[38;2;70;105;190m:\033[0m\033[38;2;15;22;40m \033[0m\033[38;2;86;142;248mo\033[0m\033[38;2;83;147;249mo\033[0m\033[38;2;82;150;249mo\033[0m\033[38;2;79;153;250mo\033[0m\033[38;2;67;135;215ml\033[0m\033[38;2;32;67;104m.\033[0m\033[38;2;1;2;3m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m
\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;19;14;34m \033[0m\033[38;2;81;57;153m'\033[0m\033[38;2;120;86;234mc\033[0m\033[38;2;120;88;238mc\033[0m\033[38;2;119;90;239mc\033[0m\033[38;2;118;91;239mc\033[0m\033[38;2;117;94;239mc\033[0m\033[38;2;115;95;239mc\033[0m\033[38;2;88;73;181m;\033[0m\033[38;2;97;84;204m:\033[0m\033[38;2;112;101;240mc\033[0m\033[38;2;110;104;241ml\033[0m\033[38;2;108;107;241ml\033[0m\033[38;2;106;109;242ml\033[0m\033[38;2;105;112;242ml\033[0m\033[38;2;104;114;243ml\033[0m\033[38;2;102;116;243ml\033[0m\033[38;2;101;117;243ml\033[0m\033[38;2;100;119;244ml\033[0m\033[38;2;98;121;244ml\033[0m\033[38;2;80;99;195m:\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;1;2;3m \033[0m\033[38;2;94;122;246ml\033[0m\033[38;2;80;107;207mc\033[0m\033[38;2;37;50;94m.\033[0m\033[38;2;1;1;1m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;35;35;35m \033[0m\033[38;2;97;97;97m \033[0m\033[38;2;126;126;126m \033[0m\033[38;2;120;120;120m \033[0m\033[38;2;30;48;85m.\033[0m\033[38;2;84;142;246mo\033[0m\033[38;2;77;133;226ml\033[0m\033[38;2;81;150;250mo\033[0m\033[38;2;79;153;250mo\033[0m\033[38;2;78;156;250mo\033[0m\033[38;2;76;160;251md\033[0m\033[38;2;74;162;251md\033[0m\033[38;2;72;165;252md\033[0m\033[38;2;64;149;225ml\033[0m\033[38;2;32;76;113m'\033[0m\033[38;2;2;3;5m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m
\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;2;2;4m \033[0m\033[38;2;83;57;155m,\033[0m\033[38;2;121;85;236mc\033[0m\033[38;2;120;87;239mc\033[0m\033[38;2;118;89;239mc\033[0m\033[38;2;117;91;239mc\033[0m\033[38;2;116;93;240mc\033[0m\033[38;2;115;95;240mc\033[0m\033[38;2;114;97;240mc\033[0m\033[38;2;107;91;220mc\033[0m\033[38;2;18;15;35m \033[0m\033[38;2;23;20;46m \033[0m\033[38;2;108;101;230mc\033[0m\033[38;2;108;108;242ml\033[0m\033[38;2;106;111;242ml\033[0m\033[38;2;104;114;243ml\033[0m\033[38;2;103;116;243ml\033[0m\033[38;2;101;118;243ml\033[0m\033[38;2;99;115;237ml\033[0m\033[38;2;70;81;163m;\033[0m\033[38;2;98;123;244ml\033[0m\033[38;2;96;125;245ml\033[0m\033[38;2;77;103;195m:\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;2;2;3m \033[0m\033[38;2;91;127;247ml\033[0m\033[38;2;91;132;247ml\033[0m\033[38;2;90;134;247mo\033[0m\033[38;2;78;118;215mc\033[0m\033[38;2;17;26;47m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;6;6;6m \033[0m\033[38;2;43;43;43m \033[0m\033[38;2;30;57;93m.\033[0m\033[38;2;77;157;251mo\033[0m\033[38;2;75;159;251mo\033[0m\033[38;2;73;162;251md\033[0m\033[38;2;71;165;251md\033[0m\033[38;2;70;168;252md\033[0m\033[38;2;68;170;253md\033[0m\033[38;2;67;172;253md\033[0m\033[38;2;65;173;253md\033[0m\033[38;2;60;159;231mo\033[0m\033[38;2;22;55;79m.\033[0m\033[38;2;0;0;0m \033[0m
\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;10;7;19m \033[0m\033[38;2;121;86;238mc\033[0m\033[38;2;119;88;239mc\033[0m\033[38;2;117;90;239mc\033[0m\033[38;2;116;93;240mc\033[0m\033[38;2;115;95;241mc\033[0m\033[38;2;113;97;241mc\033[0m\033[38;2;112;99;241mc\033[0m\033[38;2;111;102;241mc\033[0m\033[38;2;110;103;241mc\033[0m\033[38;2;99;93;214m:\033[0m\033[38;2;99;97;218mc\033[0m\033[38;2;107;110;242ml\033[0m\033[38;2;104;113;242ml\033[0m\033[38;2;103;115;243ml\033[0m\033[38;2;102;118;244ml\033[0m\033[38;2;92;109;222mc\033[0m\033[38;2;99;122;245ml\033[0m\033[38;2;98;124;245ml\033[0m\033[38;2;96;125;244ml\033[0m\033[38;2;94;128;246ml\033[0m\033[38;2;93;130;246ml\033[0m\033[38;2;75;106;196m:\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;1;2;3m \033[0m\033[38;2;88;131;247ml\033[0m\033[38;2;89;137;248mo\033[0m\033[38;2;87;139;248mo\033[0m\033[38;2;86;142;249mo\033[0m\033[38;2;12;19;33m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;10;19;29m \033[0m\033[38;2;73;162;252md\033[0m\033[38;2;71;165;252md\033[0m\033[38;2;61;152;229mo\033[0m\033[38;2;118;118;118m \033[0m\033[38;2;54;145;211ml\033[0m\033[38;2;64;176;254md\033[0m\033[38;2;63;177;254md\033[0m\033[38;2;62;178;254md\033[0m\033[38;2;61;178;253md\033[0m\033[38;2;41;114;162m;\033[0m\033[38;2;0;0;0m \033[0m
\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;6;6;6m \033[0m\033[38;2;67;67;67m \033[0m\033[38;2;65;51;133m'\033[0m\033[38;2;115;95;240mc\033[0m\033[38;2;113;97;240mc\033[0m\033[38;2;112;99;241mc\033[0m\033[38;2;110;102;241mc\033[0m\033[38;2;108;104;242mc\033[0m\033[38;2;107;107;242ml\033[0m\033[38;2;106;109;242ml\033[0m\033[38;2;105;111;242ml\033[0m\033[38;2;104;113;243ml\033[0m\033[38;2;103;115;243ml\033[0m\033[38;2;102;117;244ml\033[0m\033[38;2;100;119;244ml\033[0m\033[38;2;98;117;238ml\033[0m\033[38;2;31;36;71m.\033[0m\033[38;2;88;110;216mc\033[0m\033[38;2;95;128;245ml\033[0m\033[38;2;93;130;246ml\033[0m\033[38;2;92;133;246mo\033[0m\033[38;2;90;134;246mo\033[0m\033[38;2;73;110;197m:\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;1;2;3m \033[0m\033[38;2;86;135;248mo\033[0m\033[38;2;87;140;248mo\033[0m\033[38;2;85;143;249mo\033[0m\033[38;2;84;146;249mo\033[0m\033[38;2;66;118;199mc\033[0m\033[38;2;13;23;38m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;11;21;33m \033[0m\033[38;2;57;127;197mc\033[0m\033[38;2;69;167;253md\033[0m\033[38;2;67;170;253md\033[0m\033[38;2;59;154;223mo\033[0m\033[38;2;31;81;115m'\033[0m\033[38;2;55;153;217ml\033[0m\033[38;2;61;179;254md\033[0m\033[38;2;60;180;254md\033[0m\033[38;2;59;180;253md\033[0m\033[38;2;0;1;2m \033[0m\033[38;2;37;37;37m \033[0m\033[38;2;0;0;0m \033[0m
\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;14;14;14m \033[0m\033[38;2;66;66;66m \033[0m\033[38;2;54;49;117m.\033[0m\033[38;2;109;103;242mc\033[0m\033[38;2;107;106;242ml\033[0m\033[38;2;105;108;242ml\033[0m\033[38;2;104;111;242ml\033[0m\033[38;2;103;113;243ml\033[0m\033[38;2;102;115;243ml\033[0m\033[38;2;101;117;243ml\033[0m\033[38;2;100;119;244ml\033[0m\033[38;2;99;122;244ml\033[0m\033[38;2;97;124;245ml\033[0m\033[38;2;96;126;245ml\033[0m\033[38;2;93;124;238ml\033[0m\033[38;2;93;131;245ml\033[0m\033[38;2;92;133;246mo\033[0m\033[38;2;91;135;246mo\033[0m\033[38;2;89;137;247mo\033[0m\033[38;2;88;138;247mo\033[0m\033[38;2;72;113;198mc\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;1;2;3m \033[0m\033[38;2;84;138;248mo\033[0m\033[38;2;85;142;248mo\033[0m\033[38;2;27;45;78m.\033[0m\033[38;2;63;113;190m:\033[0m\033[38;2;80;151;250mo\033[0m\033[38;2;78;153;250mo\033[0m\033[38;2;66;132;212ml\033[0m\033[38;2;56;114;181m:\033[0m\033[38;2;53;113;177m:\033[0m\033[38;2;60;134;208mc\033[0m\033[38;2;70;164;251md\033[0m\033[38;2;68;168;253md\033[0m\033[38;2;66;172;253md\033[0m\033[38;2;64;175;253md\033[0m\033[38;2;62;178;253md\033[0m\033[38;2;60;179;254md\033[0m\033[38;2;59;181;254md\033[0m\033[38;2;56;176;245md\033[0m\033[38;2;115;115;115m \033[0m\033[38;2;43;43;43m \033[0m\033[38;2;1;1;1m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m
\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;11;11;11m \033[0m\033[38;2;61;61;61m \033[0m\033[38;2;35;37;81m.\033[0m\033[38;2;103;112;243ml\033[0m\033[38;2;102;115;243ml\033[0m\033[38;2;100;118;244ml\033[0m\033[38;2;99;120;245ml\033[0m\033[38;2;98;122;244ml\033[0m\033[38;2;44;55;109m.\033[0m\033[38;2;2;3;5m \033[0m\033[38;2;94;125;239ml\033[0m\033[38;2;93;131;246ml\033[0m\033[38;2;91;133;246mo\033[0m\033[38;2;90;136;247mo\033[0m\033[38;2;89;138;247mo\033[0m\033[38;2;88;140;247mo\033[0m\033[38;2;86;141;248mo\033[0m\033[38;2;53;89;154m;\033[0m\033[38;2;92;92;92m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;15;15;15m \033[0m\033[38;2;111;111;111m \033[0m\033[38;2;73;131;224ml\033[0m\033[38;2;76;139;232ml\033[0m\033[38;2;79;151;249mo\033[0m\033[38;2;78;155;251mo\033[0m\033[38;2;76;157;251mo\033[0m\033[38;2;74;160;251md\033[0m\033[38;2;65;147;228mo\033[0m\033[38;2;70;166;252md\033[0m\033[38;2;68;169;253md\033[0m\033[38;2;66;172;253md\033[0m\033[38;2;65;174;253md\033[0m\033[38;2;63;176;254md\033[0m\033[38;2;61;179;254md\033[0m\033[38;2;59;181;254md\033[0m\033[38;2;49;154;215ml\033[0m\033[38;2;111;111;111m \033[0m\033[38;2;38;38;38m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m
\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;7;7;7m \033[0m\033[38;2;57;57;57m \033[0m\033[38;2;27;32;65m.\033[0m\033[38;2;98;123;245ml\033[0m\033[38;2;96;125;245ml\033[0m\033[38;2;95;128;246ml\033[0m\033[38;2;91;124;237ml\033[0m\033[38;2;77;107;198m:\033[0m\033[38;2;92;134;247mo\033[0m\033[38;2;91;136;248mo\033[0m\033[38;2;89;139;248mo\033[0m\033[38;2;88;142;248mo\033[0m\033[38;2;86;144;249mo\033[0m\033[38;2;84;145;248mo\033[0m\033[38;2;53;93;157m;\033[0m\033[38;2;22;22;22m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;45;45;45m \033[0m\033[38;2;71;141;229ml\033[0m\033[38;2;76;158;252mo\033[0m\033[38;2;75;160;252md\033[0m\033[38;2;73;163;252md\033[0m\033[38;2;23;54;81m.\033[0m\033[38;2;57;57;57m \033[0m\033[38;2;13;34;49m \033[0m\033[38;2;65;175;253md\033[0m\033[38;2;63;177;254md\033[0m\033[38;2;62;179;254md\033[0m\033[38;2;61;180;254md\033[0m\033[38;2;46;142;199mc\033[0m\033[38;2;105;105;105m \033[0m\033[38;2;34;34;34m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m
\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;5;5;5m \033[0m\033[38;2;53;53;53m \033[0m\033[38;2;12;17;32m \033[0m\033[38;2;92;133;246mo\033[0m\033[38;2;91;136;247mo\033[0m\033[38;2;89;138;247mo\033[0m\033[38;2;88;140;248mo\033[0m\033[38;2;87;142;249mo\033[0m\033[38;2;74;123;212mc\033[0m\033[38;2;84;147;249mo\033[0m\033[38;2;82;149;249mo\033[0m\033[38;2;81;152;249mo\033[0m\033[38;2;66;127;206mc\033[0m\033[38;2;3;3;3m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;4;8;12m \033[0m\033[38;2;72;157;245mo\033[0m\033[38;2;72;164;252md\033[0m\033[38;2;70;166;253md\033[0m\033[38;2;69;169;253md\033[0m\033[38;2;63;163;241mo\033[0m\033[38;2;41;104;149m;\033[0m\033[38;2;59;163;235mo\033[0m\033[38;2;62;177;254md\033[0m\033[38;2;61;179;254md\033[0m\033[38;2;39;119;167m:\033[0m\033[38;2;96;96;96m \033[0m\033[38;2;28;28;28m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m
\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;2;2;2m \033[0m\033[38;2;47;47;47m \033[0m\033[38;2;5;9;15m \033[0m\033[38;2;85;144;248mo\033[0m\033[38;2;84;146;249mo\033[0m\033[38;2;82;148;249mo\033[0m\033[38;2;56;101;165m;\033[0m\033[38;2;78;146;240mo\033[0m\033[38;2;78;155;250mo\033[0m\033[38;2;76;158;250mo\033[0m\033[38;2;75;160;251md\033[0m\033[38;2;58;127;197mc\033[0m\033[38;2;29;65;98m.\033[0m\033[38;2;16;35;54m.\033[0m\033[38;2;13;28;42m \033[0m\033[38;2;18;41;61m.\033[0m\033[38;2;33;78;118m'\033[0m\033[38;2;61;148;224ml\033[0m\033[38;2;68;168;253md\033[0m\033[38;2;68;169;253md\033[0m\033[38;2;67;171;253md\033[0m\033[38;2;65;173;253md\033[0m\033[38;2;64;175;253md\033[0m\033[38;2;62;177;253md\033[0m\033[38;2;61;178;254md\033[0m\033[38;2;36;110;155m;\033[0m\033[38;2;89;89;89m \033[0m\033[38;2;20;20;20m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m
\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;1;1;1m \033[0m\033[38;2;44;44;44m \033[0m\033[38;2;0;1;1m \033[0m\033[38;2;77;154;250mo\033[0m\033[38;2;76;157;251mo\033[0m\033[38;2;75;159;251mo\033[0m\033[38;2;74;161;251md\033[0m\033[38;2;72;163;252md\033[0m\033[38;2;71;165;252md\033[0m\033[38;2;69;167;252md\033[0m\033[38;2;68;169;253md\033[0m\033[38;2;66;170;253md\033[0m\033[38;2;66;171;253md\033[0m\033[38;2;65;172;254md\033[0m\033[38;2;65;173;254md\033[0m\033[38;2;64;173;253md\033[0m\033[38;2;30;79;116m'\033[0m\033[38;2;64;174;253md\033[0m\033[38;2;63;175;254md\033[0m\033[38;2;62;177;254md\033[0m\033[38;2;61;179;254md\033[0m\033[38;2;33;99;140m,\033[0m\033[38;2;89;89;89m \033[0m\033[38;2;19;19;19m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m
\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;41;41;41m \033[0m\033[38;2;109;109;109m \033[0m\033[38;2;65;154;236mo\033[0m\033[38;2;69;167;252md\033[0m\033[38;2;67;169;253md\033[0m\033[38;2;66;171;253md\033[0m\033[38;2;64;173;253md\033[0m\033[38;2;63;175;254md\033[0m\033[38;2;33;92;133m,\033[0m\033[38;2;61;176;253md\033[0m\033[38;2;61;177;254md\033[0m\033[38;2;61;177;254md\033[0m\033[38;2;60;176;251md\033[0m\033[38;2;46;126;178m:\033[0m\033[38;2;61;177;251md\033[0m\033[38;2;59;179;254md\033[0m\033[38;2;28;87;123m'\033[0m\033[38;2;84;84;84m \033[0m\033[38;2;17;17;17m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m
\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;35;35;35m \033[0m\033[38;2;102;102;102m \033[0m\033[38;2;50;138;201mc\033[0m\033[38;2;61;176;253md\033[0m\033[38;2;60;177;254md\033[0m\033[38;2;57;170;241mo\033[0m\033[38;2;23;65;91m.\033[0m\033[38;2;51;154;217ml\033[0m\033[38;2;58;179;254md\033[0m\033[38;2;58;180;254md\033[0m\033[38;2;57;180;253md\033[0m\033[38;2;57;180;253md\033[0m\033[38;2;20;63;88m.\033[0m\033[38;2;76;76;76m \033[0m\033[38;2;13;13;13m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m
\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;28;28;28m \033[0m\033[38;2;95;95;95m \033[0m\033[38;2;38;116;165m:\033[0m\033[38;2;57;180;254md\033[0m\033[38;2;57;181;254md\033[0m\033[38;2;56;181;254md\033[0m\033[38;2;56;181;254md\033[0m\033[38;2;56;181;254md\033[0m\033[38;2;13;41;58m.\033[0m\033[38;2;66;66;66m \033[0m\033[38;2;7;7;7m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m
\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;20;20;20m \033[0m\033[38;2;87;87;87m \033[0m\033[38;2;120;120;120m \033[0m\033[38;2;126;126;126m \033[0m\033[38;2;108;108;108m \033[0m\033[38;2;58;58;58m \033[0m\033[38;2;4;4;4m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m
\033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m\033[38;2;0;0;0m \033[0m
";
}

1;
