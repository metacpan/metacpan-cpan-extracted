package Config::Pit;

use strict;
use 5.8.1;

use base qw/Exporter/;
our @EXPORT = qw/pit_get pit_set pit_switch/;

*pit_get    = \&get;
*pit_set    = \&set;
*pit_switch = \&switch;

use YAML::Syck;
use Path::Class;
use File::HomeDir;
use File::Spec;
use File::Temp;
use List::MoreUtils qw(all);

our $VERSION      = '0.04';
our $directory    = dir(File::HomeDir->my_home, ".pit");
our $config_file  = $directory->file("pit.yaml");
our $profile_file = undef;
our $verbose      = 1;

sub get {
	my ($name, %opts) = @_;
	my $profile = _load();
	local $YAML::Syck::ImplicitTyping = 1;
	local $YAML::Syck::SingleQuote    = 1;

	if ($opts{require}) {
		unless (all { defined $profile->{$name}->{$_} } keys %{$opts{require}}) {
			# merge
			my %t = (%{$opts{require}}, %{$profile->{$name}});
			$profile->{$name} = set($name, config => \%t);
		}
	}
	return $profile->{$name} || {};
}

sub set {
	my ($name, %opts) = @_;
	my $result = {};
	local $YAML::Syck::ImplicitTyping = 1;
	local $YAML::Syck::SingleQuote    = 1;

	if ($opts{data}) {
		$result = $opts{data};
	} else {
		return {} unless $ENV{EDITOR};
		my $setting = $opts{config} || get($name);
		# system
		my $f = File::Temp->new(SUFFIX => ".yaml");
		print $f YAML::Syck::Dump($setting);
		close $f;
		my $t = file($f->filename)->stat->mtime;
		system $ENV{EDITOR}, $f->filename;
		if ($t == file($f->filename)->stat->mtime) {
			print STDERR "No changes." if $verbose;
			$result = get($name);
		} else {
			$result = set($name, data => YAML::Syck::LoadFile($f->filename));
		}
	}
	my $profile = _load();
	$profile->{$name} = $result;
	YAML::Syck::DumpFile($profile_file, $profile);
	return $result;
}

sub switch {
	my ($name, %opts) = @_;
	local $YAML::Syck::ImplicitTyping = 1;
	local $YAML::Syck::SingleQuote    = 1;

	$name ||= "default";

	$profile_file = File::Spec->catfile($directory, "$name.yaml");

	my $config = _config();
	my $ret = $config->{profile};
	$config->{profile} = $name;
	YAML::Syck::DumpFile($config_file, $config);
	print STDERR "Config::Pit: Profile switch to $name from $ret.\n" if $verbose && ($name ne $ret);
	return $ret;
}

sub pipe {
	local $YAML::Syck::ImplicitTyping = 1;
	local $YAML::Syck::SingleQuote    = 1;

	-t STDOUT ? print STDERR 'do not output to tty.' :  print Dump(get(shift)), "\n"; ## no critic
}

sub _load {
	my $config = _config();
	local $YAML::Syck::ImplicitTyping = 1;
	local $YAML::Syck::SingleQuote    = 1;

	switch($config->{profile});

	unless (-e $profile_file) {
		YAML::Syck::DumpFile($profile_file, {});
	}
	return YAML::Syck::LoadFile($profile_file);
}

sub _config {
	local $YAML::Syck::ImplicitTyping = 1;
	local $YAML::Syck::SingleQuote    = 1;

	(-e $directory) || $directory->mkpath(0, 0700);

	my $config = eval { YAML::Syck::LoadFile($config_file) } || ({
		profile => "default"
	});
	return $config;
}


1;
__END__

=head1 NAME

Config::Pit - Manage settings

=head1 SYNOPSIS

  use Config::Pit;

  my $config = pit_get("example.com", require => {
    "username" => "your username on example",
    "password" => "your password on example"
  });
  # if the fields are not set, open setting by $EDITOR
  # with YAML-dumped default values (specified at C<require>).

  # use $config->{username}, $config->{password}

=head1 DESCRIPTION

Config::Pit is account setting management library.
This library automates editing settings used in scripts.

Original library is written in Ruby and published as pit gem with management command.

You can install it by rubygems:

  $ sudo gem install pit
  $ pit set example.com
  # open setting of example.com with $EDITOR.

And Config::Pit provides ppit command which is pit command written in Perl.

See:

  $ ppit help

=head1 FUNCTIONS

=head2 Config::Pit::get(setting_name, opts)

Get setting named C<setting_name> from current profile.

  my $config = Config::Pit::get("example.com");

This is same as below:

  my $config = pit_get("example.com");

opts:

=over

=item B<require>

Specify fields you want as key and hint (description or default value) of the field as value.

  my $config = pit_get("example.com", require => {
    "username" => "your username on example.com",
    "password" => "your password on example.com"
  });

C<require> specified, module check the required fields all exist in setting.
If not exist, open the setting by $EDITOR with merged setting with current setting.

=back

=head2 Config::Pit::set(setting_name, opts)

Set setting named C<setting_name> to current profile.

  Config::Pit::set("example.com"); #=> will open setting with $EDITOR

opts:

=over

=item B<data>

  Config::Pit::set("example.com", data => {
    username => "foobar",
    password => "barbaz",
  });

When C<data> specified, will not open C<$EDITOR> and set the data directly.

=item B<config>


  Config::Pit::set("example.com", config => {
    username => "config description or default value",
    password => "same as above",
  });

Open C<$EDITOR> with merged setting with specified config.

=back

=head2 Config::Pit::switch(profile_name);

Switch profile to C<profile_name>.

Profile is setting set:

  $ pit get foobar
  # foo bar...

  $ pit switch devel
  Switch profile to devel

  $ pit get foobar
  # bar baz

  $ pit switch
  Switch profile to default

  $ pit get foobar
  # foo bar...

=head1 AUTHOR

cho45 E<lt>cho45@lowreal.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://lowreal.rubyforge.org/pit/> is pit in Ruby.

F<bin/ppit> is pit command in Perl.

=cut
