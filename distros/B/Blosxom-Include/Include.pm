package Blosxom::Include;

use strict;
use Filter::Simple;
use FileHandle;

use vars qw($VERSION);

$VERSION = 0.002000;

my $include_pattern = qr/^#?\s*(?:IncludeConfig|__END_CONFIG__).*$/m;

FILTER {
  my ($self, $plugin_name) = @_;
  return unless m/$include_pattern/;

  # Try and figure out $config_dir in the same way as blosxom itself
  my $config_dir = '';
  if ($ENV{BLOSXOM_CONFIG_FILE}) {
    ($config_dir = $ENV{BLOSXOM_CONFIG_FILE}) =~ s! / [^/]* $ !!x;
  }
  unless (-d $config_dir) {
    for my $blosxom_config_dir ($ENV{BLOSXOM_CONFIG_DIR}, '/etc/blosxom', '/etc') {
      if (-d $blosxom_config_dir) {
        $config_dir = $blosxom_config_dir;
        last;
      }
    }
  }

  # Load plugin config data
  if ($config_dir  && -d $config_dir && 
      $plugin_name && -f "$config_dir/$plugin_name" && 
                      -r "$config_dir/$plugin_name") {
    if (my $fh = FileHandle->new( "$config_dir/$plugin_name", 'r' )) {
      local $/ = undef;
      my $plugin_config = <$fh>;
      if (defined $plugin_config) {
        my ($before, $after) = split $include_pattern;

        # Munge the line count to include $plugin_config
        my $line_count = ($before =~ tr/\n//);
        $line_count += ($plugin_config =~ tr/\n//);
        $line_count++;

        # Insert config and revised line count
        $_ = $before . $plugin_config . "# line $line_count\n" . $after;
      }
      close $fh;
    }
  }
};


1;

__END__

=head1 NAME

Blosxom::Include - a perl source filter to allow external configuration 
settings to be included within blosxom plugins with minimal code

=head1 SYNOPSIS

    # In a random blosxom plugin ...

    # Add as the first code statement in your plugin (before the package stmt)
    use Blosxom::Include qw(my_plugin_name);

    # Add a commented-out include directive after last plugin config item:
    # IncludeConfig();
    

    # Then create your external configuration file in your $blosxom::config_dir
    # directory with the name you used in the 'use' statement above - typically
    # the name of your plugin. Usually you can just copy the entire 
    # configuration section, which is typically the bits between the:

    # --- Configuration variables ----- 

    # --------------------------------- 

    # sections. 


=head1 DESCRIPTION

Blosxom::Include is a perl source filter to allow external configuration 
settings to be included within blosxom plugins with a minimum of fuss.

It works by injecting an external configuration file directly into the 
plugin at the point of the IncludeConfig() directive, which is typically
immediately after the configuration section. This allows you to override 
and redefine any configuration item you choose, including lexical variables
(my $foo = 'bar'), which you can't modify externally any other way.

To use, you add the following to the very top of your plugin (before the 
package statement):

    use Blosxom::Include qw(my_plugin_name);

e.g. for atomfeed, you would use:

    use Blosxom::Include qw(atomfeed);

Then immediately after the configuration section, add an include marker in 
a comment:

    # IncludeConfig();

This gets replaced by the external config when the source filter runs, before
the script is passed to the interpreter.

If you are distributing your plugin, I suggest you also comment out the use 
directive, since not everyone will have this module installed. It's reasonably 
straightforward to uncomment it for an installed set of plugins after 
installation e.g.

    perl -i -pe 's/^# *(use Blosxom::Include)/$1/' file1 file2 ...


=head2 ALTERNATIVES

I tried initially to do this within blosxom.cgi itself by just doing a simple 
require on the external config file after the initial plugin itself had been
loaded (into the same package namespace, of course). This works great for
package-scoped (global) configuration variables, but doesn't work with lexical
variables (my $config_item), which are inherently file-scoped.


=head1 AUTHOR

Gavin Carr <gavin@openfusion.com.au>


=head1 LICENCE

Copyright 2007 Gavin Carr.

This program is free software; you can redistribute and/or modify it under the 
same terms as perl itself.

=cut

