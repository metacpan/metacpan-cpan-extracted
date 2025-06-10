#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019-2025 by Gérald Sédrati.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use 5.014;
use utf8;
package App::SpreadRevolutionaryDate::Config;
$App::SpreadRevolutionaryDate::Config::VERSION = '0.51';
# ABSTRACT: Companion class of L<App::SpreadRevolutionaryDate>, to handle configuration file and command line arguments, subclass of L<AppConfig>.

use Moose;
use MooseX::NonMoose;

extends 'AppConfig';

use Getopt::Long;
use AppConfig qw(:argcount);
use File::HomeDir;
use Class::Load ':all';

use Locale::TextDomain 'App-SpreadRevolutionaryDate';
use namespace::autoclean;

BEGIN {
  unless ($ENV{PERL_UNICODE} && $ENV{PERL_UNICODE} =~ /A/) {
    use Encode qw(decode_utf8);
    @ARGV = map { decode_utf8($_, 1) } @ARGV;
  }
}


sub new {
  my ($class, $filename) = @_;

  # Backup command line arguments to be consumed twice
  my @orig_argv = @ARGV;

  # Parse command line only parameters
  my $config_first = Getopt::Long::Parser->new;
  $config_first->configure('pass_through');

  if ($filename) {
    $config_first->getoptions("version|v" => sub { say $App::SpreadRevolutionaryDate::Config::VERSION; exit 0; },
                              "help|h|?" => \&usage);
  } else {
    $config_first->getoptions("version|v" => sub { say $App::SpreadRevolutionaryDate::Config::VERSION; exit 0; },
                              "help|h|?" => \&usage,
                              "conf|c=s" => \$filename);
  }

  # If filename is not a file path but a GLOB or an opend filehandle
  # we'll need to rewind it to the beginning before reading it twice
  my $file_start;
  $file_start = tell $filename if $filename && ref($filename);

  # Find targets
  my $config_targets = AppConfig::new($class, {CREATE => 1, ERROR => sub {}},
                                      'conf' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'c'},
                                      'version' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'v'},
                                      'help' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'h|?'},
                                      'targets' => {ARGCOUNT => ARGCOUNT_LIST, ALIAS => 'tg'},
                                      'msgmaker' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'mm'},
                                      'test' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'no|n'},
                                      'locale' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'l'},
                                      'acab' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'a'},
                                      'bluesky' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'b'},
                                      'twitter' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 't'},
                                      'mastodon' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'm'},
                                      'freenode' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'f'},
                                      'liberachat' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'lt'});
  # Rewind command line arguments and process them
  @ARGV = @orig_argv;
  $config_targets->parse_file($filename);

  # Record targets in configuration file to be bypassed if defined in command line arguments
  my @config_file_targets =  @{$config_targets->targets};

  $config_targets->parse_command_line;

  # Add targets defined with targets option
  my @targets = @{$config_targets->targets};

  # For backward compatibility, add targets defined directly
  my %potential_targets = $config_targets->varlist(".");
  foreach my $potential_target (keys %potential_targets) {
    next unless $potential_targets{$potential_target};
    next if $potential_target =~ /_/;
    if ($potential_target !~ /^(?:acab|test|locale|targets|msgmaker|conf|version|help)$/) {
      push @targets, $potential_target;
    }
  }

  # Set default targets if no target specified
  if (!$config_targets->bluesky && !$config_targets->twitter && !$config_targets->mastodon && !$config_targets->freenode && !$config_targets->liberachat && !scalar(@targets)) {
    push @targets, 'bluesky', 'twitter', 'mastodon', 'freenode', 'liberachat';
    $config_targets->targets(@targets);
    $config_targets->bluesky(1);
    $config_targets->twitter(1);
    $config_targets->mastodon(1);
    $config_targets->freenode(1);
    $config_targets->liberachat(1);
  }
  if (scalar @targets > scalar @config_file_targets) {
    @targets = splice @targets, scalar @config_file_targets - scalar @targets, scalar @targets;
  }

  # Guess attributes for each target associated class
  my %target_attributes;
  foreach my $target (@targets) {
    my $target_class = 'App::SpreadRevolutionaryDate::Target::' . ucfirst(lc($target));
    my $target_meta;
    try_load_class($target_class)
      or die "Cannot found target class $target_class for target $target\n";
    load_class($target_class);
    eval { $target_meta = $target_class->meta; };
    die "Cannot found target meta class $target_class for target $target: $@\n" if $@;
    foreach my $target_meta_attribute ($target_meta->get_all_attributes) {
      next if $target_meta_attribute->name eq 'obj';
      my $target_meta_attribute_type = $target_meta_attribute->type_constraint;
      my $target_meta_attribute_argcount = $target_meta_attribute_type =~ /ArrayRef/ ? ARGCOUNT_LIST : $target_meta_attribute_type =~ /HashRef/ ? ARGCOUNT_HASH : $target_meta_attribute_type =~ /Bool/ ? ARGCOUNT_NONE : ARGCOUNT_ONE;
      $target_attributes{lc($target) . '_' . $target_meta_attribute->name} = { ARGCOUNT => $target_meta_attribute_argcount };
      $target_attributes{lc($target)} = { ARGCOUNT => ARGCOUNT_NONE };

      if ($target_meta_attribute->has_default) {
        $target_attributes{lc($target) . '_' . $target_meta_attribute->name}{DEFAULT} = $target_meta_attribute->default;
      }
    }
  }

  # Guess attributes for MsgMaker
  my %msgmaker_attributes;
  my $msgmaker = $config_targets->msgmaker || 'RevolutionaryDate';
  my $msgmaker_class = 'App::SpreadRevolutionaryDate::MsgMaker::' . $msgmaker;
  my $msgmaker_meta;
  try_load_class($msgmaker_class)
    or die "Cannot found msgmaker class $msgmaker_class for msgmaker $msgmaker\n";
  load_class($msgmaker_class);
  eval { $msgmaker_meta = $msgmaker_class->meta; };
  die "Cannot found msgmaker meta class $msgmaker_class for msgmaker $msgmaker: $@\n" if $@;
  foreach my $msgmaker_meta_attribute ($msgmaker_meta->get_all_attributes) {
    next if $msgmaker_meta_attribute->name eq 'locale';

    my $msgmaker_meta_attribute_type = $msgmaker_meta_attribute->type_constraint;
    my $msgmaker_meta_attribute_argcount = $msgmaker_meta_attribute_type =~ /ArrayRef/ ? ARGCOUNT_LIST : $msgmaker_meta_attribute_type =~ /HashRef/ ? ARGCOUNT_HASH : $msgmaker_meta_attribute_type =~ /Bool/ ? ARGCOUNT_NONE : ARGCOUNT_ONE;
    $msgmaker_attributes{lc($msgmaker) . '_' . $msgmaker_meta_attribute->name} = { ARGCOUNT => $msgmaker_meta_attribute_argcount };
    $msgmaker_attributes{lc($msgmaker)} = { ARGCOUNT => ARGCOUNT_NONE };

    if ($msgmaker_meta_attribute->has_default) {
      $msgmaker_attributes{lc($msgmaker) . '_' . $msgmaker_meta_attribute->name}{DEFAULT} = $msgmaker_meta_attribute->default;
    }
  }

  # Build actual instance
  my $self = AppConfig::new($class,
    %target_attributes,
    %msgmaker_attributes,
    'conf' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'c'},
    'version' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'v'},
    'help' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'h|?'},
    'targets' => {ARGCOUNT => ARGCOUNT_LIST, ALIAS => 'tg'},
    'msgmaker' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'mm', default => 'RevolutionaryDate'},
    'test' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'no|n'},
    'locale' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'l', default => 'fr'},
    'acab' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'a'},
    # Overwrite found attributes for default targets
    # for backward compatibility with aliases
    'bluesky' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'b'},
    'twitter' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 't'},
    'mastodon' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'm'},
    'freenode' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'f'},
    'liberachat' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'lt'},
    'bluesky_identifier' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'bi'},
    'bluesky_password' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'bp'},
    'twitter_consumer_key' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'tck'},
    'twitter_consumer_secret' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'tcs'},
    'twitter_access_token' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'tat'},
    'twitter_access_token_secret' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'tats'},
    'twitter_api' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'tapi'},
    'mastodon_instance' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'mi'},
    'mastodon_client_id' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'mci'},
    'mastodon_client_secret' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'mcs'},
    'mastodon_access_token' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'mat'},
    'freenode_nickname' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'fn'},
    'freenode_password' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'fp'},
    'freenode_test_channels' => {ARGCOUNT => ARGCOUNT_LIST, ALIAS => 'ftc'},
    'freenode_channels' => {ARGCOUNT => ARGCOUNT_LIST, ALIAS => 'fc'},
    'liberachat_nickname' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'ln'},
    'liberachat_password' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'lp'},
    'liberachat_test_channels' => {ARGCOUNT => ARGCOUNT_LIST, ALIAS => 'ltc'},
    'liberachat_channels' => {ARGCOUNT => ARGCOUNT_LIST, ALIAS => 'lc'},
    'revolutionarydate_acab' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'ra'},
    'promptuser_default' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'pud'},
    'promptuser_img_path' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'pui'},
    'promptuser_img_alt' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'pua'},
    'promptuser_img_url' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'puu'},
    'gemini_api_key' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'ga'},
    'gemini_process' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'g'},
    'gemini_prompt' => {ARGCOUNT => ARGCOUNT_HASH, ALIAS => 'gp'},
    'gemini_intro' => {ARGCOUNT => ARGCOUNT_HASH, ALIAS => 'gi'},
    'gemini_search' => {ARGCOUNT => ARGCOUNT_HASH, ALIAS => 'gs'},
    'gemini_img_path' => {ARGCOUNT => ARGCOUNT_HASH, ALIAS => 'gip'},
    'gemini_img_alt' => {ARGCOUNT => ARGCOUNT_HASH, ALIAS => 'gia'},
    'gemini_img_url' => {ARGCOUNT => ARGCOUNT_HASH, ALIAS => 'giu'},
    'special_birthday_name' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'bn'},
    'special_birthday_day' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'bd'},
    'special_birthday_month' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'bm'},
    'special_birthday_url' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'bu'},
    'special_birthday_gemini' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'bg'},
    'special_birthday_prefix' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'bp'},
    'special_birthday_plural' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'bpl'},
    'special_birthday_gender' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'bge'},
  );

  # Rewind configuration file if needed and read it
  seek $filename, $file_start, 0 if $file_start;
  $self->parse_file($filename);

  # Backup multivalued options so command line arguments can override them
  my %args_list_backup;
  my %args_list = $config_targets->varlist(".");
  foreach my $arg_list (keys %args_list) {
    next unless $self->_argcount($arg_list) == ARGCOUNT_LIST;
    push @{$args_list_backup{$arg_list}}, @{$self->$arg_list};
    $self->_default($arg_list);
  }

  # Rewind command line arguments and process them
  @ARGV = @orig_argv;
  $self->parse_command_line;

  # Restore multivalued options if not overridden by command line arguments
  foreach my $arg_list (keys %args_list_backup) {
    unless (scalar @{$self->$arg_list}) {
      $self->$arg_list($_) foreach (@{$args_list_backup{$arg_list}});
    }
  }

  # Add targets defined with targets option
  @targets = @{$self->targets};

  # For backward compatibility, add targets defined directly
  my %confvars = $self->varlist(".");
  foreach my $potential_target (keys %confvars) {
    next unless $confvars{$potential_target};
    next if $potential_target =~ /_/;
    if ($potential_target !~ /^(?:acab|test|locale|targets|msgmaker|conf|version|help)$/) {
      push @targets, $potential_target;
      $self->targets($potential_target);
    }
  }

  # Set default targets if no target specified
  if (!$self->bluesky && !$self->twitter && !$self->mastodon && !$self->freenode && !$self->liberachat && !scalar(@targets)) {
    push @targets, 'bluesky', 'twitter', 'mastodon', 'freenode', 'liberachat';
    map { $self->targets($_); } @targets;
    $self->bluesky(1);
    $self->twitter(1);
    $self->mastodon(1);
    $self->freenode(1);
    $self->liberachat(1);
  }

  # Check mandatory arguments for each target
  foreach my $target (@targets) {
    $self->check_target_mandatory_options($target);
  }

  return $self;
}


sub parse_file {
  my ($self, $filename) = @_;

  foreach my $default_path (
                File::HomeDir->my_home . '/.config/spread-revolutionary-date/spread-revolutionary-date.conf',
                File::HomeDir->my_home . '/.spread-revolutionary-date.conf') {
    $filename = $default_path if (!$filename && -f $default_path)
  }
  if ($filename && !ref($filename)) {
      my $fh;
      open($fh, '<:encoding(UTF-8)', $filename);
      $self->file($fh);
  } else {
      $self->file($filename);
  }
}


sub parse_command_line {
  my $self = shift;

  $self->args;
}


sub check_target_mandatory_options {
  my ($self, $target) = @_;

  my $target_class = 'App::SpreadRevolutionaryDate::Target::' . ucfirst(lc($target));
  my $target_meta;
  try_load_class($target_class)
    or die "Cannot found target class $target_class for target $target\n";
  load_class($target_class);
  eval { $target_meta = $target_class->meta; };
  die "Cannot found target meta class $target_class for target $target: $@\n" if $@;
  foreach my $target_meta_attribute ($target_meta->get_all_attributes) {
    next if $target_meta_attribute->name eq 'obj';
    next unless $target_meta_attribute->is_required;
    next if $target_meta_attribute->{default};
    my $target_mandatory_option = $target . '_' . $target_meta_attribute->name;
    die "Cannot spread to $target, mandatory configuraton parameter "
        . $target_meta_attribute->name . " missing\n"
      unless !!$self->$target_mandatory_option;
  }
}


sub get_target_arguments {
  my ($self, $target) = @_;
  $target = lc($target);

  my %target_args = $self->varlist("^${target}_", 1);

  # Process test options
  foreach my $arg (keys %target_args) {
    if ($arg =~ /^test_(.+)$/ && $target_args{$1}) {
      $target_args{$1} = delete $target_args{$arg} if $self->test;
    }
  }
  return %target_args;
}


sub get_msgmaker_arguments {
  my ($self, $msgmaker) = @_;
  $msgmaker = lc($msgmaker);

  my %msgmaker_args = $self->varlist("^${msgmaker}_", 1);

  # Add acab option for RevolutionaryDate for backward compatibility
  $msgmaker_args{acab} = $self->acab
    if  $msgmaker eq 'revolutionarydate'
        && !$msgmaker_args{acab}
        && $self->acab;

  # Do not prompt if PromptUser default is set
  if ($msgmaker eq 'promptuser') {
    require App::SpreadRevolutionaryDate::MsgMaker::PromptUser;
    if ($msgmaker_args{default} && $msgmaker_args{default} ne App::SpreadRevolutionaryDate::MsgMaker::PromptUser->meta->get_attribute('default')->default) {
      $ENV{PERL_MM_USE_DEFAULT} = 1
    }
  }

  return %msgmaker_args;
}


sub usage {
 print << "USAGE";
Usage: $0 <OPTIONS>
  with <OPTIONS>:
    --conf|-c <file>: path to configuration file (default: ~/.config/spread-revolutionary-date/spread-revolutionary-date.conf or ~/.spread-revolutionary-date.conf)'
    --version|-v': print out version
    --help|-h|-?': print out this help
    --targets|-tg <target_1> [--targets|-tg <target_2> […--targets|-tg <target_n>]]': define targets (default: mastodon, bluesky, twitter, liberachat, freenode)
    --msgmaker|-mm <MsgMakerClass>: define message maker (default: RevolutionaryDate)
    --locale|-l <fr|en|it|es>: define locale (default: fr for msgmaker=RevolutionaryDate, en otherwise)
    --test|--no|-n: do not spread, just print out message or spread to test channels for Freenode or Liberachat
    --mastodon_instance|-mi <instance>: define Mastodon instance
    --mastodon_client_id|-mci <id>: define Mastodon client id
    --mastodon_client_secret|-mcs <secret>: define Mastodon client secret
    --mastodon_access_token|-mat <token>: define Mastodon access token
    --bluesky_identifier|-bi <key>: define Bluesky identifier
    --bluesky_password|-bp <key>: define Bluesky password
    --twitter_consumer_key|-tck <key>: define Twitter consumer key
    --twitter_consumer_secret|-tcs <secret>: define Twitter consumer secret
    --twitter_access_token|-tat <token>: define Twitter access token
    --twitter_access_token_secret|tats <token_secret>: define Twitter access token secret
    --liberachat_nickname|-ln <nick>: define Liberachat nickname
    --liberachat_password|-lp <passwd>: define Liberachat password
    --liberachat_test_channels|-ltc <channel_1>  [--liberachat_test_channels|-ltc <channel_2> […--liberachat_test_channels|-ltc <channel_n>]]: define Liberachat channels
    --liberachat_channels|-lc <channel_1>  [--liberachat_channels|-lc <channel_2> […--liberachat_channels|-lc <channel_n>]]: define Liberachat test channels
    --freenode_nickname|-fn <nick>: define Freenode nickname
    --freenode_password|-fp <passwd>: define Freenode password
    --freenode_test_channels|-ftc <channel_1>  [--freenode_test_channels|-ftc <channel_2> […--freenode_test_channels|-ftc <channel_n>]]: define Freenode channels
    --freenode_channels|-fc <channel_1>  [--freenode_channels|-fc <channel_2> […--freenode_channels|-fc <channel_n>]]: define Freenode test channels
    --revolutionarydate_acab | -ra: pretend it is 01:31:20 (default: false)
    --promptuser_default|-pud <msg>: define default message when --msgmaker=PromptUser (default: 'Goodbye old world, hello revolutionary worlds')
    --promptuser_img_path|-pui <path/to/image/file>: define image file path when --msgmaker=PromptUser
    --promptuser_img_alt|-pua <alternative text>: define image alternative text when --msgmaker=PromptUser
    --promptuser_img_url|-puu <https://example.com/imgs/my_image.jgp>: define image external url when --msgmaker=PromptUser
    --gemini_api_key|-ga <msg>: define default message when --msgmaker=PromptUser (default: 'Goodbye old world, hello revolutionary worlds')
    --gemini_process|-g <SomePrompt>: tell which prompt to process --msgmaker=Gemini
    --gemini_prompt|-gp "<SomePrompt>=<my prompt string>": define prompt to request for when --msgmaker=Gemini
    --gemini_intro|-gi "<SomePrompt>=<intro msg>": define introduction message to preprend to response when --msgmaker=Gemini
    --gemini_search|-gs "<SomePrompt>=1": use grounding search results when --msgmaker=Gemini
    --gemini_img_path|-gip "<SomePrompt>=<path/to/image/file>": define image file path when --msgmaker=Gemini
    --gemini_img_alt|-gia "<SomePrompt>=<alternative text>": define image alternative text when --msgmaker=Gemini
    --gemini_img_url|-giu "<SomePrompt>=<https://example.com/imgs/my_image.jgp>": define image external url when --msgmaker=Gemini
USAGE
 exit 0;
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

# A module must return a true value. Traditionally, a module returns 1.
# But this module is a revolutionary one, so it discards all old traditions.
# Idea borrowed from Jean Forget's DateTime::Calendar::FrenchRevolutionary.
"Quand le gouvernement viole les droits du peuple,
l'insurrection est pour le peuple le plus sacré
et le plus indispensable des devoirs";

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SpreadRevolutionaryDate::Config - Companion class of L<App::SpreadRevolutionaryDate>, to handle configuration file and command line arguments, subclass of L<AppConfig>.

=head1 VERSION

version 0.51

=head1 METHODS

=head2 new

Constructor class method, subclassing C<AppConfig>. Takes no argument. Returns an C<App::SpreadRevolutionaryDate::Config> object.

=head2 parse_file

Parses configuration file. Takes one optional argument: C<$filename> which should be the file path or an opened file handle of your configuration path, defaults to C<~/.config/spread-revolutionary-date/spread-revolutionary-date.conf> or C<~/.spread-revolutionary-date.conf>.

=head2 parse_command_line

Parses command line options. Takes no argument.

=head2 check_target_mandatory_options

Checks whether target configuration options are set to authenticate on specified target. Takes one mandatory argument: C<target_name> as string. Dies if a mandatory configuration option is missing.

=head2 get_target_arguments

Takes one mandatory argument: C<target> as a string in lower case, without any underscore (like C<'bluesky'>, C<'twitter'>, C<'mastodon'>, C<'freenode'> or C<'liberachat'>). Returns a hash with configuration options relative to the passed C<target> argument. If C<test> option is true, any value for an option starting with C<"test_"> will be set for the option with the same name without C<"test_"> (eg. values of C<test_channels> are set to option C<channels> for C<Liberachat> target).

=head2 get_msgmaker_arguments

Takes one mandatory argument: C<msgmaker> as a string. Returns a hash with configuration options relative to the passed C<msgmaker> argument.

=head2 usage

Prints usage with command line parameters and exits.

=head1 SEE ALSO

=over

=item L<spread-revolutionary-date>

=item L<App::SpreadRevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::BlueskyLite>

=item L<App::SpreadRevolutionaryDate::Target>

=item L<App::SpreadRevolutionaryDate::Target::Bluesky>

=item L<App::SpreadRevolutionaryDate::Target::Twitter>

=item L<App::SpreadRevolutionaryDate::Target::Mastodon>

=item L<App::SpreadRevolutionaryDate::Target::Freenode>

=item L<App::SpreadRevolutionaryDate::Target::Freenode::Bot>

=item L<App::SpreadRevolutionaryDate::Target::Liberachat>

=item L<App::SpreadRevolutionaryDate::Target::Liberachat::Bot>

=item L<App::SpreadRevolutionaryDate::MsgMaker>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Calendar>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::fr>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::en>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::it>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::es>

=item L<App::SpreadRevolutionaryDate::MsgMaker::PromptUser>

=item L<App::SpreadRevolutionaryDate::MsgMaker::Telechat>

=item L<App::SpreadRevolutionaryDate::MsgMaker::Gemini>

=back

=head1 AUTHOR

Gérald Sédrati <gibus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2025 by Gérald Sédrati.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
