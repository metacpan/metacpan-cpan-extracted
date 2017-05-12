package App::Colorist;
$App::Colorist::VERSION = '0.150460';
use Moose;

with 'MooseX::Getopt';

use App::Colorist::Colorizer;

use IPC::Open3;

# ABSTRACT: Add color to your plain old outputs


has configuration => (
    is          => 'ro',
    isa         => 'Str',
    traits      => [ 'Getopt' ],
    cmd_aliases => [ qw(c) ],
    lazy_build  => 1,
);

sub _build_configuration {
    my $self = shift;

    return $self->extra_argv->[0] if $self->execute;
    return;
}

has ruleset => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    traits      => [ 'Getopt' ],
    cmd_aliases => [ qw(R) ],
    default     => 'rules',
);

has colorset => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    traits      => [ 'Getopt' ],
    cmd_aliases => [ qw(C) ],
    default     => 'colors',
);

has include => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    traits      => [ 'Getopt' ],
    cmd_aliases => [ qw(I) ],
    default     => sub { [] },
);

has debug => (
    is          => 'ro',
    isa         => 'Bool',
    required    => 1,
    default     => 0,
);

has execute => (
    is          => 'ro',
    isa         => 'Bool',
    traits      => [ 'Getopt' ],
    cmd_aliases => [ qw(e) ],
    lazy_build  => 1,
);

sub _build_execute {
    my $self = shift;
    return $self->stderr ? 1 : 0;
}

has stderr => (
    is          => 'ro',
    isa         => 'Bool',
    required    => 1,
    traits      => [ 'Getopt' ],
    cmd_aliases => [ qw(E) ],
    default     => 0,
);

# I would like to have this someday...
# has follow => (
#     is          => 'ro',
#     isa         => 'Bool',
#     required    => 1,
#     default     => 0,
# );

has _colorizer => (
    reader      => 'colorizer',
    isa         => 'App::Colorist::Colorizer',
    lazy_build  => 1,
    handles     => [ 'run' ],
);

sub _build__colorizer {
    my $self = shift;

    my @args = @{ $self->extra_argv };

    my %params;

    # The command-line contains the command to run and arguments to it
    if ($self->execute) {

        # They have asked us to capture STDERR too
        if ($self->stderr) {
            open3('<&STDIN', my $outfh, my $errfh, @args);
            $params{inputs} = [ $outfh, $errfh ];
        }

        # They have asked us to capture just STDOUT
        else {
            open my $fh, '-|', @args or die "cannot execute ", join(' ', @args), ": ", $!;
            $params{inputs} = [ $fh ];
        }
    }

    # Otherwise, we use the default input reading from ARGV

    return App::Colorist::Colorizer->new(
        configuration => $self->configuration,
        ruleset       => $self->ruleset,
        colorset      => $self->colorset,
        include       => $self->include,
        debug         => $self->debug,
        %params,
    );
}

sub BUILD {
    my $self = shift;

    # This makes sure that <ARGV> works
    @ARGV = @{ $self->extra_argv };
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Colorist - Add color to your plain old outputs

=head1 VERSION

version 0.150460

=head1 DESCRIPTION

This documentation is primarily concerned with the installation of the application and giving an in-depth description  of the configuration of colorist rulesets and colorsets. For more information about the command-line options, see L<colorist>.

B<Installer Beware.> This application is still early in development, so please be aware that any upgrade might drastically change the way the application works.

=head2 SYNOPSIS

  # See the manual for colorist for command-line info
  alias cpanm="colorist -E cpanm"
  cpanm App::Colorist

  # OOOH! Look at the pretty colors!

=head1 QUICK START

If you just want to start using this with some canned configurations, here's the quick way to get started.

  # install colorist
  cpanm App::Colorist

  # clone the shared configuration from github
  git clone git://github.com/zostay/dot-colorist.git ~/.colorist

  # update your bashrc to setup the aliases you need
  echo 'source $HOME/.colorist/bashrc' > ~/.bashrc

After you are done you can logout and log back in or run:

  source ~/.colorist/bashrc

After that, you can update your configuration to the latest just by pulling the latest configuration from github:

  # make sure colorist is up-to-date first
  cpanm App::Colorist

  # update your configuration
  cd ~/.colorist
  git pull

For more details on writing your own colorist configurations or customizing existing ones, you may read on.

=head1 CONFIGURATION

The configuration of colorist happens from a number of sources. First, the options passed to the command determine which configuration to use and where to find it, there's an environment variable to help with that as well, then a set of at least 2 configuration files is read to determine how to break up the input for adding color and what colors to add.

To help understand these, you may want to visit L<https://github.com/zostay/dot-colorist> and look through the files there to get a sense of what some of the configuraiton files look like as you read this documentation.

=head2 Finding Configuration

The first step in configuring colorist is to locate the configuration files. Without any special files or handling, colorist will normally look first in the current users's F<~/.colorist> directory for configuration and then into the F</etc/colorist> directory for the system.

The search order can be modified in two ways. First, you can put additional search paths into the C<COLORIST_CONFIG> environment variable, like this:

  # assuming bash or something bash-ish
  export COLORIST_CONFIG=/opt/etc/colorist:/var/app/common/config/colorist

The C<COLORIST_CONFIG> variable is a colon-separated list of paths to search.

The other way to modify the search order is using the C<--include> (or C<-I>) option on the command-line. For example, the following options are roughly equivalent to the environment variable shown above:

  --I /opt/etc/colorist --I /var/app/common/config/colorist

The search paths are parent configuration I<directories>, which may each contain zero or more named configurations.

It is important to note that a ruleset might be loaded from a different directory than the colorset. This allows a user to define a set of colors in their own F<~/.colorist> directory that has been altered to match their preferences, while the ruleset is loaded from F</etc/colorist> or somewhere else.

B<N.B.> The search order of directories is currently experimental and could change. Currently, the search order is to prefer (from most prefered to list) configuration in this order: (1) paths added using the C<--include> option on the command-line, (2) paths set in the C<COLORIST_CONFIG> environment variable, (3) F<~/.colorist>, and (4) F</etc/colorist>.

=head2 Named Configuration Directory

Inside the colorist configuration directory are zero or more other directories. Each such directory is generally named for the command output or file type that will be colorized. These directories contain two types of files:

=over

=item 1.

B<Rulesets.> These are Perl scripts whose sole purpose is to define a rule set used to parse some input and give sections of hte input names that may be colored.

=item 2.

B<Colorsets.> These are YAML files which map the named sections of the parsed input different color names.

=back

A given named configuration may have multiple rulesets and colorsets, but should define at least one of each, with F<rules.pl> being the default ruleset and F<colors.yml> being the default colorset.

=head2 Rulesets

The rulesets are defined using Perl code. The easiest way to do this is to use the special syntax defined in L<App::Colorist::Ruleset> to define your rules. However, rulesets files just need to return a reference to an array where the even indexed elements are regular expressions and the odd indexed elements are arrays containing the names to assign each grouping.

Here's a short sample ruleset:

  ruleset {
      rule qr{Starting (\S+)\.\.\.}, qw( message program );
      rule qr{Finished processing (http://([\w.]+)/) \.\.\.}, qw( 
          message url hostname
      );
  }

This ruleset contains two rules. The first rule matches a line containing text like:

  Starting Hello_World...

It will assign the entire line the color name "message" and the "Hello_World" part gets assigned the color name "program".

The second rule matches a line like:

  Finished processing http://example.com/ ...

Here the whole line is marked as being the color name "message", the "http://example.com/" part gets named "url" and the "example.com" bit gets "hostname".

Some things to note:

=over

=item 1.

The first part of a rule is always a regular expression that is used to match the line.

=item 2.

The remaining items are the names to assign each group in the regular expression match. The first name is the name assigned to the whole line. The rest match each parenthetical.

=item 3.

Matches can be nested arbitrarily deep and the colors will work with each set of parenthesis marking the start/end of a color name assigned to the matched text.

=item 4.

The color names are mapped to actual colors in the colorset configuration.

=item 5.

Every ruleset contains an implicit match anything rule, which assigns those lines the color name to "DEFAULT".

=back

If you have complex rules or need something more complicated, the important thing about these files to know is that the very last line of the file must return an array reference containing alternating regular expressions and names. For example, the following code is identical to the ruleset defined using the C<ruleset> and C<rule> syntax above:

  [
      qr{Starting (\S+)\.\.\.}, [ qw( message program ) ],
      qr{Finished processing (http://([\w.]+)/) \.\.\.}, [ qw( 
          message url hostname
      ) ],
  ]

For more information about the rule syntax. You may read the documentation at L<App::Colorist::Ruleset> for details.

A named configuration may contain more than one ruleset. This might be used to parse different variations of the command (such as colorizing git output for various sub-commands) or just provide alternate ways of parsing the command in case you need to colorize the output in different ways on different occassions or just because some people in your organization like to do it one way and others their own way.

=head2 Colorsets

The colorset configuration gives each color named in the ruleset an actual color. It is defined using YAML (which is a superset of JSON, so you may use JSON if you prefer). The file should be built as a single section that contains a hash at the root. Each key in the hash is the name given in the ruleset. Each value is a color declaration, defining how to color that group.

There is also a special color, named "DEFAULT". You can use this to assign a color to any unmatched line. (If default is set to the "No color" option described below then it will be set to whatever color uncolored text is given in the user's terminal.)

Here is an example colorset file to go with the ruleset example defined in the L</Ruleset> section:

  ---
  message: ~
  program: white
  url: { fg: blue, bg: gray }
  hostname: [ 2, 2, 0 ]
  DEFAULT: [ 10 ]

Each color declaration may be defined in one of the following ways:

=over

=item *

B<No color.> To use no color for a section, you may either omit the color name entirely from the colorset or set it to C<null> (which can be written as C<~> in YAML). This does not necessarily mean the section will be uncolored, but that it will get the color of whatever the surrounding match was (or "DEFAULT" if it is the line color.)

=item *

B<Named color.> As of this writing the following color names are permitted (with the ANSI color code in parenthesis):

  black  (0)    gray    (8)
  maroon (1)    red     (9)
  green  (2)    lime    (10)
  olive  (3)    yellow  (11)
  navy   (4)    blue    (12)
  purple (5)    fuschia (13)
  teal   (6)    aqua    (14)
  silver (7)    white   (15)

These are the most common ways to color text. If just a single name is given this way, it is the color of the foreground or text itself.

=item *

B<Numeric color.> Another option is to assign each a color. For most terminals, this can be any integer in the 0-15 range with the colors usually being like those named above. If you use a terminal that supports it, you may use numbers in the 0-255 range, which includes an additional 216 color mapped into an RGB color cube and 24 shades of gray.

=item *

B<Color pair.> If you would like to set the background color, you may do so by setting the color to a hash (or object, if you prefer). The keys in the hash are "fg" for setting the foreground color and "bg" for setting the background. The color itself for each can be any of the other color values described here (except this one, of course).

=item *

B<Gray scale.> For terminals supporting 256 colors, you may use the gray scale by setting the color name to a 1-tuple (single element array) containing the numeric index of the shade of gray you want to use. In these scheme, C<[0]> is black and C<[23]> is white, and all the numbers in between are shades of gray with lower numbers being darker and higher numbers being brighter.

=item *

B<RGB color.> The final option is to use a 3-tuple (an array with 3 elements) to use one of the 216 colors available on 256 color terminals. As with most representations of the sort, the first index is red, the second is green, and the third is blue. The colors may each be assigned a number in a range from 0 to 5 with 0 representing none of that color and 5 representing the most of the that color. So, C<[0,0,0]> is black and C<[5,5,5]> is white, C<[5,0,0]> is red, C<[5,5,0]> is yellow, C<0,5,0> is lime, C<[0,5,5]> is aqua, C<[0,0,5]> is blue, C<[5,0,5]> is fuschia, etc.

=back

There can be multiple colorsets for each named configuration. This allows for different themes to be used for different circumstances or different preferences.

=for Pod::Coverage     BUILD

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
