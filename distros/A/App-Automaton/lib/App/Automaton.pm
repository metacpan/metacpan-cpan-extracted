package App::Automaton;

# ABSTRACT: Execute various tasks based on input from various sources

use strict;
use warnings;

use Moo;
use YAML::Tiny;
use Module::Load;

use Data::Dumper;

has conf => ( is => 'rw' );
has yaml_conf => ( is => 'rw' );
has conf_file => ( is => 'rw' );
has found_bits => ( is => 'rw' );
has debug => ( is => 'rw');

sub BUILD {
    my $self = shift;
    $self->load_conf();
    return 1;
}

sub load_conf {
    my $self = shift;
    
    if ( $self->{yaml_conf} ) {
	$self->{conf} = YAML::Tiny::Load($self->{yaml_conf});
    } elsif ( $self->{conf_file} ) {
	$self->{conf} = YAML::Tiny::LoadFile($self->{conf_file}) or die;
    }
    
    $self->logger('Loaded config');
    return $self->{conf};
}

sub check_sources {
    my $self = shift;
    
    my $sources = $self->{conf}->{sources};
    foreach my $name (keys %$sources) {
		my $source = $sources->{$name};
		next if $source->{bypass};
		$source->{debug} = $self->{debug};
		$self->logger("checking source: $name");
		my $mod = 'App::Automaton::Plugin::Source::' . $source->{type};
		load $mod;
		my $s = eval {$mod->new()};
		die $! unless $s;
		die $! unless $s->can('go');
		push(@{$self->{found_bits}}, $s->go($source));
    }

    return $1;
}

sub apply_filters {
	my $self = shift;
	
	my $filters = $self->{conf}{filters};
	foreach my $name (keys %{$filters}) {
		my $filter = $filters->{$name};
		next if $filter->{bypass};
		$filter->{debug} = $self->{debug};
		$self->logger("Applying filter: $name");
		my $mod = 'App::Automaton::Plugin::Filter::' . $filter->{type};
		load $mod;
		my $a = eval {$mod->new()};
		die $! unless $a;
		die $! unless $a->can('go');
		$a->go($filter, $self->{found_bits});
	}
	
	return 1;
}

sub do_actions {
    my $self = shift;
    # process each action for each buffer

	my $actions = $self->{conf}{actions};
	foreach my $name (keys %$actions) {
		my $action = $actions->{$name};
		next if $action->{bypass};
		$action->{debug} = $self->{debug};
		$self->logger("Executing action: $name");
		my $mod = 'App::Automaton::Plugin::Action::' . $action->{type};
		load $mod;
		my $a = eval {$mod->new()};
		die $! unless $a;
		die $! unless $a->can('go');
		my $r = $a->go($action, $self->found_bits());
		$self->logger("Unsuccessful return from action: $name") unless $r;
	}
	
    return 1;
}

sub dedupe {
	my $self = shift;
	my %hash;
	$self->logger("Removing duplicates");
	@hash{@{$self->{found_bits}}} = ();
	@{$self->{found_bits}} = keys %hash;
	return 1;
}

sub logger {
	my $self = shift;
	my $message = shift;
	if ($self->{debug}) {
		print STDERR "$message\n";
	}
	return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Automaton - Execute various tasks based on input from various sources

=head1 VERSION

version 0.150912

=head1 SYNOPSIS

	my $a = App::Automaton->new(conf_file => $conf_file);
	$a->check_sources();
	$a->apply_filters();
	$a->dedupe();
	$a->do_actions();

or just use the shell utility:

	automaton

=head1 DESCRIPTION

This project is an attempt to realize the tiniest bit of my desire to have my computer automatically execute tasks for me.
The not so ambitious first step is to receive URLs from various sources and download them for me.

The core concepts are as follows:

Automaton is designed to run periodically from Cron or something similar. Although, there is no reason you couldn't just run it manually.
It will gather input from it's input plugins, pass it through any specified filter plugins, and pass it on to it's action plugins.
The action plugins will parse each line of the input and execute any appropriate actions. The input will then be passed on to the next action plugin.

The following plugins are available now with the initial release:

  * Input
    * File: Reads all lines from a file and adds them to it's queue to be processed
    * IMAP: Reads all messages from an IMAP email account and adds the content of each message to the queue
  * Filter
    * Unshorten: Looks for URLs from several known URL shortener services and expands them to full URLs
  * Action
    * YouTube: Downloads the video from a YouTube.com url
    * TedTalks: Downloads the video from a TedTalks.com url
    * NZB: Downloads the NZB file specified in the url

As you can see, these are all geared towards downloading videos. It's the first real world use case that I felt I could really do well.
The plugins can be appear multiple times in a config file, or left out completely. This allows you to download YouTube videos to multiple locations, for instance.

In the future, I picture giving it input that could tell it to do more interesting things. However, as long as commands are coming in over email, I'll leave the security implications minimal.
Obviously, you don't have to use that plugin. If you do, I certainly suggest not using your primary email since the password must be in the config file.

=head1 INSTALLATION

If you are working directly from source, this module can be installed using the Dist::Zilla tools:

    sudo dzil install

=head1 CONFIGURATION

Once installed, you will have to create a configuration file for Automaton to operate on. Here is a sample config file that uses all of the currently available plugins.

	sources:
	  automaton email:
		bypass: 1
		type: IMAP
		server: imap.gmail.com
		port: 993
		account: notyourprimary@emailaccount.com
		password: 123456
		ssl: yes
		delete: 0
	  file1:
		type: File
		path: ../input.txt
		delete: 0
		empty: 1
	filters:
	  unshorten:
		type: Unshorten
	actions:
	  YouTube1:
		bypass: 0
		type: YouTube
		target: ../down
	  NZB1:
		bypass: 0
		type: NZB
		target: ../down
	  Ted1:
		bypass: 0
		type: TedTalks
		target: ../down

You'll see there that the plugin configs are divided into sections for "input", "filters", and "actions".
Within those sections are named references to the plugin. These names allow you to have the same plugin appear multiple times, but have no other significance. They can whatever you want, but must be unique within their section.
The config that appears within the named section is passed on to that plugin during execution and allows you to specify any settings that it understands.

Here is a commented example of an IMAP plugin:

  automaton email: # name, can be anything unique within it's section
    bypass: 1 # OPTIONAL; if true, this plugin will be skipped, defaults to false
    type: IMAP # plguin type: This is how it finds the plugin code, case sensitive
    delete: 0 # OPTIONAL; if true, messages will be deleted after reading, defaults to false
    # These are passed on to the plugin and have obvious purposes
    server: imap.gmail.com 
    port: 993
    account: notyourprimary@emailaccount.com
    password: 123456
    ssl: yes

The plugins work in generally the same way. They should all respect the bypass flag and, if applicable, the delete flag.
Action plugins will usually have a "target" flag to specify where the downloaded files should be put.
In my personal config, I have my NZB files dropped into my news reader's "watch" folder which will execute that download.
I have my video files targets set to drop right into a folder on my Plex media server, so they are waiting for me at home.

=head1 PLUGINS

Feel free to create additional plugins. I'm currently re-evaluating this, but they must meet the following criteria:

  * Must be a valid Perl object (I suggest Moo)
  * Must have a method named "go" that accepts an array ref of strings to operate on

=head1 EXECUTION

Once it's installed and you have a config file, you can run it using the "automaton" wrapper script.
By default, it will look for a config file named '.automaton' in your home directory. You can also specify a config file using the -c filename parameter. You can also get some verbose output with -v, but there isn't much there yet.

=head1 TODO

This is the first release and the project is in it's very early stages. Here's what I'd like to add:

  * Determine if I've overcomplicated the plugin architecture. It's possible that I don't need to instantiate the objects...or that they don't even have to be objects.
  * Determine if filters need to be named. I can't quite come up with a use case for re-using the same filter, but I also can't predict the future.
  * Add some additional plugin types, such as a directory action that operates on all the files within a directory (probably by calling the file plugin for each)
  * Evaluate security concerns on an action plugin that executes more generic commands. Perhaps limit it to certain input types or require a key in the input string.
  * Figure out some better tests. It's awkward to download real files during testing. Also, how to test the IMAP plugin?
  * Package it up and put it on CPAN (after PrePan probably)

=head1 METHODS

=over 4

=item load_conf

Loads a YAML configuration from object variables. Checks in the following order:
1) conf : Just accepts it, since it was passed in as a hash
2) yaml_conf : parses a YAML string into conf hash
3) conf_file : reads and parses the supplied file into conf hash

=item check_sources

Iterates through configured sources to populate queue

=item apply_filters

Iterates through filters and applies changes to queue

=item dedupe

Removes duplicate entries from the queue

=item do_actions

Iterates through the configured action plugins, executing each one on the entire queue

=item logger

Output messages if debug level is sufficient. Currently only a boolean check on this value.
Expects input: numeric debug level, string message

=back

=for Pod::Coverage BUILD conf conf_file debug found_bits yaml_conf

=head1 AUTHOR

Michael LaGrasta <michael@lagrasta.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Michael LaGrasta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
