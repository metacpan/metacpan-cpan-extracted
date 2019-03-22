#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019 by Gérald Sédrati-Dinet.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use 5.014;
use utf8;
package App::SpreadRevolutionaryDate::Config;
$App::SpreadRevolutionaryDate::Config::VERSION = '0.07';
# ABSTRACT: Companion class of L<App::SpreadRevolutionaryDate>, to handle configuration file and command line arguments, subclass of L<AppConfig>.

use Moose;
use MooseX::NonMoose;
extends 'AppConfig';
use AppConfig qw(:argcount);
use File::HomeDir;
use Class::Load ':all';
use Encode;
use namespace::clean;


sub new {
  my ($class, $filename) = @_;
  # If filename is not a file path but a GLOB or an opend filehandle
  # we'll need to rewind it to the beginning before reading it twice
  my $file_start;
  $file_start = tell $filename if $filename && ref($filename);

  # Backup command line arguments to be consumed twice
  my @orig_argv = @ARGV;

  # Find targets
  my $config_targets = AppConfig::new($class, {CREATE => 1},
                                      'targets' => {ARGCOUNT => ARGCOUNT_LIST, ALIAS => 'tg'},
                                      'acab' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'a'},
                                      'test' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'no|n'},
                                      'locale' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'l'},
                                      'twitter' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 't'},
                                      'mastodon' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'm'},
                                      'freenode' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'f'});
  $config_targets->parse_file($filename);
  $config_targets->parse_command_line;

  # Add targets defined with targets option
  my @targets = @{$config_targets->targets};

  # For backward compatibility, add targets defined directly
  my %potential_targets = $config_targets->varlist(".");
  foreach my $potential_target (keys %potential_targets) {
    next unless $potential_targets{$potential_target};
    next if $potential_target =~ /_/;
    if ($potential_target !~ /^(?:acab|test|locale|targets)$/) {
      push @targets, $potential_target;
    }
  }

  # Set default targets if no target specified
  if (!$config_targets->twitter && !$config_targets->mastodon && !$config_targets->freenode && !scalar(@targets)) {
    push @targets, 'twitter', 'mastodon', 'freenode';
    $config_targets->targets(@targets);
    $config_targets->twitter(1);
    $config_targets->mastodon(1);
    $config_targets->freenode(1);
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
      my $target_meta_attribute_argcount = $target_meta_attribute_type =~ /ArrayRef/ ? ARGCOUNT_LIST : $target_meta_attribute_type =~ /HashRef/ ? ARGCOUNT_HASH : ARGCOUNT_ONE;
      $target_attributes{$target . '_' . $target_meta_attribute->name} = { ARGCOUNT => $target_meta_attribute_argcount };
      $target_attributes{$target} = { ARGCOUNT => ARGCOUNT_NONE };
    }
  }

  # Build actual instance
  my $self = AppConfig::new($class,
    %target_attributes,
    'targets' => {ARGCOUNT => ARGCOUNT_LIST, ALIAS => 'tg'},
    'acab' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'a'},
    'test' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'no|n'},
    'locale' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'l'},
    # Overwrite found attributes for default targets
    # for backward compatibility with aliases
    'twitter' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 't'},
    'mastodon' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'm'},
    'freenode' => {ARGCOUNT => ARGCOUNT_NONE, ALIAS => 'f'},
    'twitter_consumer_key' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'tck'},
    'twitter_consumer_secret' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'tcs'},
    'twitter_access_token' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'tat'},
    'twitter_access_token_secret' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'tats'},
    'mastodon_instance' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'mi'},
    'mastodon_client_id' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'mci'},
    'mastodon_client_secret' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'mcs'},
    'mastodon_access_token' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'mat'},
    'freenode_nickname' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'fn'},
    'freenode_password' => {ARGCOUNT => ARGCOUNT_ONE, ALIAS => 'fp'},
    'freenode_test_channels' => {ARGCOUNT => ARGCOUNT_LIST, ALIAS => 'ftc'},
    'freenode_channels' => {ARGCOUNT => ARGCOUNT_LIST, ALIAS => 'fc'},
  );

  # Rewind configuration file if needed and read it
  seek $filename, $file_start, 0 if $file_start;
  $self->parse_file($filename);

  # Rewind command line arguments and process them
  @ARGV = @orig_argv;
  $self->parse_command_line;

  # Add targets defined with targets option
  @targets = @{$self->targets};

  # For backward compatibility, add targets defined directly
  my %confvars = $self->varlist(".");
  foreach my $potential_target (keys %confvars) {
    next unless $confvars{$potential_target};
    next if $potential_target =~ /_/;
    if ($potential_target !~ /^(?:acab|test|locale|targets)$/) {
      push @targets, $potential_target;
      $self->targets($potential_target);
    }
  }

  # Set default targets if no target specified
  if (!$self->twitter && !$self->mastodon && !$self->freenode && !scalar(@targets)) {
    push @targets, 'twitter', 'mastodon', 'freenode';
    map { $self->targets($_); } @targets;
    $self->twitter(1);
    $self->mastodon(1);
    $self->freenode(1);
  }

  # Check mandatory arguments for each target
  foreach my $target (@targets) {
    $self->check_target_mandatory_options($target);
  }

  return $self;
}


sub parse_file {
  my $self = shift;
  my $filename = shift;
  foreach my $default_path (
                File::HomeDir->my_home . '/.config/spread-revolutionary-date/spread-revolutionary-date.conf',
                File::HomeDir->my_home . '/.spread-revolutionary-date.conf') {
    $filename = $default_path if (!$filename && -f $default_path)
  }
  $self->file($filename);
}


sub parse_command_line {
  my $self = shift;
  $self->args;
}


sub check_target_mandatory_options {
  my $self = shift;
  my $target = shift;

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
    my $target_mandatory_option = $target . '_' . $target_meta_attribute->name;
    die "Cannot spread to $target, mandatory configuraton parameter "
        . $target_meta_attribute->name . " missing\n"
      unless !!$self->$target_mandatory_option;
  }
}


sub get_target_arguments {
  my $self = shift;
  my $target = lc(shift);

  my %target_args = $self->varlist("^${target}_", 1);

  # Process test options
  foreach my $arg (keys %target_args) {
    if ($arg =~ /^test_(.+)$/ && $target_args{$1}) {
      $target_args{$1} = delete $target_args{$arg} if $self->test;
    }
  }
  return %target_args;
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

version 0.07

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

Takes one mandatory argument: C<target> as a string in lower case, without any underscore (like C<'twitter'>, C<'mastodon'> or C<'freenode'>). Returns a hash with configuration options relative to the passed C<target> argument. If C<test> option is true, any value for an option starting with C<"test_"> will be set for the option with the same name without C<"test_"> (eg. values of C<test_channels> are set to option C<channels> for C<Freenode> target).

=head1 SEE ALSO

=over

=item L<spread-revolutionary-date|https://metacpan.org/pod/distribution/App-SpreadRevolutionaryDate/bin/spread-revolutionary-date>

=item L<App::SpreadRevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::Target>

=item L<App::SpreadRevolutionaryDate::Target::Twitter>

=item L<App::SpreadRevolutionaryDate::Target::Mastodon>

=item L<App::SpreadRevolutionaryDate::Target::Freenode>

=item L<App::SpreadRevolutionaryDate::Target::Freenode::Bot>

=back

=head1 AUTHOR

Gérald Sédrati-Dinet <gibus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Gérald Sédrati-Dinet.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
