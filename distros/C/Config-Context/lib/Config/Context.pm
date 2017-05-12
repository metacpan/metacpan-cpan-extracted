package Config::Context;

use warnings;
use strict;

use Carp;
use Hash::Merge ();
use Clone ();
use Cwd;

=head1 NAME

Config::Context - Add C<< <Location> >> and C<< <LocationMatch> >> style context matching to hierarchical configfile formats such as Config::General, XML::Simple and Config::Scoped

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

=head2 Apache-style configs (via Config::General)

    use Config::Context;

    my $config_text = '

        <Location /users>
            title = "User Area"
        </Location>

        <LocationMatch \.*(jpg|gif|png)$>
            image_file = 1
        </LocationMatch>

    ';

    my $conf = Config::Context->new(
        string        => $config_text,
        driver        => 'ConfigGeneral',
        match_sections => [
            {
                name          => 'Location',
                match_type    => 'path',
            },
            {
                name          => 'LocationMatch',
                match_type    => 'regex',
            },
        ],
    );

    my %config = $conf->context('/users/~mary/index.html');

    use Data::Dumper;
    print Dumper(\%config);
    --------
    $VAR1 = {
        'title'         => 'User Area',
        'image_file'    => undef,
    };

    my %config = $conf->context('/users/~biff/images/flaming_logo.gif');
    print Dumper(\%config);
    --------
    $VAR1 = {
        'title'         => 'User Area',
        'image_file'    => 1,
    };

=head2 XML configs (via XML::Simple)

    use Config::Context;

    my $config_text = '
        <opt>

          <Location name="/users">
            <title>User Area</title>
          </Location>

          <LocationMatch name="\.*(jpg|gif|png)$">
            <image_file>1</image_file>
          </LocationMatch>

        </opt>
    ';

    my $conf = Config::Context->new(
        string        => $config_text,
        driver        => 'XMLSimple',
        match_sections => [
            {
                name          => 'Location',
                match_type    => 'path',
            },
            {
                name          => 'LocationMatch',
                match_type    => 'regex',
            },
        ],
    );

    my %config = $conf->context('/users/~mary/index.html');

    use Data::Dumper;
    print Dumper(\%config);
    --------
    $VAR1 = {
        'title'         => 'User Area',
        'image_file'    => undef,
    };

    my %config = $conf->context('/users/~biff/images/flaming_logo.gif');
    print Dumper(\%config);
    --------
    $VAR1 = {
        'title'         => 'User Area',
        'image_file'    => 1,
    };

=head2 Config::Scoped style configs

    use Config::Context;

    my $config_text = '
        Location /users {
            user_area = 1
        }

        LocationMatch '\.*(jpg|gif|png)$' {
            image_file = 1
        }
    ';

    my $conf = Config::Context->new(
        string        => $config_text,
        driver        => 'ConfigScoped',
        match_sections => [
            {
                name          => 'Location',
                match_type    => 'path',
            },
            {
                name          => 'LocationMatch',
                match_type    => 'regex',
            },
        ],
    );

    my %config = $conf->context('/users/~mary/index.html');

    use Data::Dumper;
    print Dumper(\%config);
    --------
    $VAR1 = {
        'title'         => 'User Area',
        'image_file'    => undef,
    };

    my %config = $conf->context('/users/~biff/images/flaming_logo.gif');
    print Dumper(\%config);
    --------
    $VAR1 = {
        'title'         => 'User Area',
        'image_file'    => 1,
    };


=head1 DESCRIPTION

=head2 Introduction

This module provides a consistent interface to many hierarchical
configuration file formats such as L<Config::General>, L<XML::Simple>
and L<Config::Scoped>.

It also provides Apache-style context matching.  You can include blocks
of configuration that match or not based on run-time parameters.

For instance (using L<Config::General> syntax):

    company_name      = ACME
    in_the_users_area = 0

    <Location /users>
        in_the_users_area = 1
    </Location>

At runtime, if C<Location> is within C</users>, then the configuration
within the C<< <Location> >> block is merged into the top level.
Otherwise, the block is ignored.

So if C<Location> is C</users/gary>, the configuration is reduced to:

     {
         company_name      => 'ACME',
         in_the_users_area => 1,
     }

But if C<Location> is outside of the C</users> area (e.g.
C</admin/documents.html>), the configuration is reduced to:

     {
         company_name      => 'ACME',
         in_the_users_area => 0,
     }

The exact mechanics of how C<Location> matches C</users> is extensively
customizable.  You can configure a particular block to match based on
exact string matches, a substring, a path, or a regex.

This kind of context-based matching was inspired by Apache's
context-based configuration files.

L<Config::Context> works with Apache-style config files (via
L<Config::General>), XML documents (via L<XML::Simple>), and
L<Config::Scoped> config files.  You select the type config file with
the L<driver> option to L<new>.

The examples in this document use L<Config::General> (Apache-style)
syntax.  For details on other configuration formats, see the
documentation for the appropriate driver.

For a real world example of L<Config::Context> in action, see
L<CGI::Application::Plugin::Config::Context>, which determines
configurations based on the URL of the request, the name of the Perl
Module, and the virtual host handling the web request.

=head2 The Default Section

Config values that appear outside of any block act like defaults.
Values in matching sections are merged with the default values.  For
instance:

    private_area = 0
    client_area  = 0

    <Location /admin>
        private_area = 1
    </Location>

    <Location /clients>
        client_area  = 1
    </Location>

    # Admin Area URL
    my %config = $conf->context('/admin/index.html');
    use Data::Dumper;
    print Dumper(\%config);
    $VAR1 = {
        'private_area' => 1,
        'client_area' => 0,
    };

    # Client Area URL
    my %config = $conf->context('/clients/index.html');
    print Dumper(\%config);
    $VAR1 = {
        'private_area' => 0,
        'client_area'  => 1,
    };

    # Neither Client nor Admin
    my %config = $conf->context('/public/index.html');
    print Dumper(\%config);
    $VAR1 = {
        'private_area' => 0,
        'client_area'  => 0,
    };

When using the L<Config::Context::ConfigScoped> driver, you must be
careful with the use of the default section, since L<Config::Scoped>
does its own inheritance from the global scope into named sections.  See
the documentation for L<Config::Context::ConfigScoped> for more
information.

=head2 Subsections are preserved

When a block matches, and its configuration is merged into the top level,
any subsections that it contained are preserved along with single
values.  For instance:

    # Default config
    private_area = 0
    client_area  = 0
    <page_settings>
        title       = "The Widget Emporium"
        logo        = logo.gif
        advanced_ui = 0
    </page_settings>

    # Admin config
    <Location /admin>
        private_area = 1
        <page_settings>
            title       = "The Widget Emporium - Admin Area"
            logo        = admin_logo.gif
            advanced_ui = 1
        </page_settings>
    </Location>

    # Client config
    <Location /clients>
        client_area  = 1
        <page_settings>
            title = "The Widget Emporium - Wholesalers"
            logo  = client_logo.gif
        </page_settings>
    </Location>

    # Admin Area URL
    my %config = $conf->context('/admin/index.html');

    use Data::Dumper;
    print Dumper(\%config);
    --------
    $VAR1 = {
        'page_settings' => {
                            'advanced_ui' => '1',
                            'title' => 'The Widget Emporium - Admin Area',
                            'logo' => 'admin_logo.gif'
                           },
        'private_area' => '1',
        'client_area' => '0'
    };

    # Client Area URL
    my %config = $conf->context('/clients/index.html');

    print Dumper(\%config);
    --------
    $VAR1 = {
        'page_settings' => {
                            'advanced_ui' => '0',
                            'title' => 'The Widget Emporium - Wholesalers',
                            'logo' => 'client_logo.gif'
                           },
        'client_area' => '1',
        'private_area' => '0'
    };

    # Neither Client nor Admin
    my %config = $conf->context('/public/index.html');

    print Dumper(\%config);
    --------
    $VAR1 = {

        'page_settings' => {
                            'advanced_ui' => '0',
                            'title' => 'The Widget Emporium',
                            'logo' => 'logo.gif'
                           },
        'client_area' => '0',
        'private_area' => '0'

    };



=head2 Multiple Sections Matching

Often more than one section will match the target string.  When this
happens, the matching sections are merged together using the
L<Hash::Merge> module.  Typically this means that sections that are
merged later override the values set in earlier sections.  (But you can
change this behaviour.  See L<Changing Hash::Merge behaviour> below.)

The order of merging matters.  The sections are merged first according
to each section's L<merge_priority> value (lowest values are merged
first), and second by the length of the substring that matched (shortest
matches are merged first).  If you don't specify L<merge_priority> for
any section, they all default to a priority of C<0> which means all
sections are treated equally and matches are prioritized based soley on
the length of the matching strings.

When two sections have the same priority, the section with the shorter
match is merged first.  The idea is that longer matches are more
specific, and should have precidence.

The order of sections in the config file is ignored.

For instance, if your config file looks like this:

    <Dir /foo/bar/baz>
        # section 1
    </Dir>

    <Path /foo>
        # section 2
    </Path>

    <Dir /foo/bar>
        # section 3
    </Dir>

    <Directory /foo/bar/baz/bam>
        # section 4
    </Directory>

...and you construct your $conf object like this:

    my $conf         = Config::Context->new(
        driver         => 'ConfigGeneral',
        match_sections => [
            { name    => 'Directory',  match_type => 'path' merge_priority => 1 },
            { name    => 'Dir',        match_type => 'path' merge_priority => 1 },
            { name    => 'Path',       match_type => 'path' merge_priority => 2 },
        ],
    );

...then the target string '/foo/bar/baz/bam/boom' would match all sections
the order of 1, 3, 4, 2.

=head2 Matching Context based on More than one String

You have different sections match against different run time values.
For instance, you could match some sections against the day of the week
and other sections against weather:

    my $config = '

    weekend    = 0
    background = ''

    <Day Saturday>
        weekend = 1
    </Day>

    <Weekday Sunday>
        weekend = 1
    </Weekday>

    <Weather sunny>
        sky = blue
    </Weather>

    <Weather cloudy>
        sky = grey
    </Weather>
    ';

    my $conf = Config::Context->new(
        driver         => 'ConfigGeneral',
        match_sections => [
            { name => 'Day',      section_type => 'day',     match_type => 'path' },
            { name => 'Weekday',  section_type => 'day',     match_type => 'path' },
            { name => 'Weather',  section_type => 'weather', match_type => 'regex' },
        ],
    );

    my %config = $conf->context(day => 'Friday', weather => 'sunny');

    print Dumper(\%config);
    --------
    $VAR1 = {
        'weekend' => 0,
        'sky'     => 'blue',
    };

    my %config = $conf->context(day => 'Sunday', weather => 'partially cloudy');

    print Dumper(\%config);
    --------
    $VAR1 = {

        'weekend' => 1,
        'sky'     => 'grey',
    };



=head2 Matching other path-like strings

You can use L<Config::Context> to match other hierarchical strings
besides paths and URLs.  For instance you could specify a
L<path_separator> of C<::> and use the path feature to match against Perl
modules:

    my $config_text = "

        is_core_module 0
        <Module NET::FTP>
            is_core_module 1
            author         Nathan Torkington
        </Module>

        <Module NET::FTPServer>
            author Richard Jone
        </Module>

    ";

    my $conf = Config::Context->new(
        driver         => 'ConfigGeneral',
        string         => $config_text,
        match_sections => [
            {
                name           => 'Module',
                path_separator => '::',
                match_type     => 'path',
            },
        ],
    );

    my %config = $conf->context('Net::FTP');

    use Data::Dumper;
    print Dumper(\%config);
    --------
    $VAR1 = {
        'is_core_module' => 1,
        'author'         => 'Nathan Torkington',
    };




=head2 Nested Matching

You can have matching sections within matching sections:

    <Site bookshop>
        <Location /admin>
            admin_area = 1
        </Location>
    </Site>
    <Site recordshop>
        <Location /admin>
            admin_area = 1
        </Location>
    </Site>

Enable this feature by setting L<nesting_depth> parameter to L<new>,
or by calling C<< $conf->nesting_depth($some_value) >>.

B<Note:> see the documentation of L<Config::Context::ConfigScoped> for
the limitations of nesting with L<Config::Scoped> files.

=head1 CONSTRUCTOR

=head2 new(...)

Creates and returns a new L<Config::Context> object.

The configuration can be read from a file, parsed from a string, or can
be generated from a perl data struture.

To read from a config file:

    my $conf = Config::Context->new(
        file           => 'somefile.conf',
        driver         => 'ConfigGeneral',
        match_sections => [
           {  name  => 'Directory',  match_type => 'path' },
        ],
    );

To parse from a string:

    my $text = '
        in_the_users_area = 0
        <Directory /users>
            in_the_users_area = 1
        </Directory>
    ';

    my $conf = Config::Context->new(
        string         => $text,
        driver         => 'ConfigGeneral',
        match_sections => [
           {  name => 'Directory',    match_type => 'path' },
        ],
    );

To generate from an existing Perl data structure:

    my %config = (
        'in_the_user_area' => '0'
        'Location' => {
            '/users' => {
                'in_the_user_area' => '1'
            },
        },
    );

    my $conf = Config::Context->new(
        config         => \%config,
        driver         => 'ConfigGeneral',
        match_sections => [
           {  name => 'Directory',    match_type => 'path' },
        ],
    );


The parameters to new are described below:

=head3 file

The config file.

=head3 string

A string containing the configuration to be parsed.  If L<string> is
specified then L<file> is ignored.

=head3 config

A Perl multi-level data structure containing the configuration.  If
L<config> is specified, then both L<file> and L<string> are ignored.

=head3 driver

Which L<Config::Context> driver should parse the config.  Currently
supported drivers are:

    driver            module name
    ------            -----------
    ConfigGeneral     Config::Context::ConfigGeneral
    ConfigScoped      Config::Context::ConfigScoped
    XMLSimple         Config::Context::XMLSimple

=head3 driver_options

Options to pass directly on to the driver.  This is a multi-level hash,
where the top level keys are the driver names:

    my $conf = Config::Context->new(
        driver => 'ConfigScoped',
        driver_options => {
           ConfigGeneral => {
               -AutoLaunder => 1,
           },
           ConfigScoped = > {
               warnings => {
                   permissions  => 'off',
               }
           },
        },
    );

In this example the options under C<ConfigScoped> will be passed to the
C<ConfigScoped> driver.  (The options under C<ConfigGeneral> will be
ignored because C<driver> is not set to C<'ConfigGeneral'>.)

=head3 match_sections

The L<match_sections> parameter defines how L<Config::Context> matches
runtime values against configuration sections.

L<match_sections> takes a list of specification hashrefs. Each
specification has the following fields:

=over 4

=item B<name>

The name of the section.  For a name of 'Location', the section would look like:

    <Location /somepath>
    </Location>

=item B<match_type>

Specifies the method by which the section strings should match the
target string.

The valid types of matches are 'exact', 'substring', 'regex', 'path',
and 'hierarchical'

=over 4

=item exact

The config section string matches only if it is equal to the target
string.  For instance:

    # somefile.conf
    <Site mysite>
        ...
    </Site>
    ...

    my $conf = Config::Context->new(
        driver         => 'ConfigGeneral'
        match_sections => [
            {
                name       => 'Site',
                match_type => 'exact',
            },
        ],
        file => 'somefile.conf',
    );

In this case, only the exact string C<mysite> would match the section.

=item substring

The config section string is tested to see if it is a substring of the
target string.  For instance:

    # somefile.conf
    <Location foo>
        ...
    </Location>

    ...

    my $conf = Config::Context->new(
        driver         => 'ConfigGeneral'
        match_sections => [
            {
                name       => 'LocationMatch',
                match_type => 'substring',
            },
        ],
        file => 'somefile.conf',
    );

In this case, the following target strings would all match:

    /foo
    big_foo.html
    /hotfood

=item regex

The config section string is treated as a regular expression against
which the target string is matched.  For instance:

    # somefile.conf
    <LocationMatch (\.jpg)|(\.gif)(\.png)$>
        Image = 1
    </LocationMatch>

    ...

    my $conf = Config::Context->new(
        driver         => 'ConfigGeneral'
        match_sections => [
            {
                name       => 'LocationMatch',
                match_type => 'regex',
            },
        ],
        file        => 'somefile.conf',
    );

    my %config = $conf->context('banner.jpg');

The regex can contain any valid Perl regular expression.  So to match
case-insensitively you can use the C<(?i:)> syntax:

    <LocationMatch (?i:/UsErS)>
        UserDir = 1
    </LocationMatch>

Also note that the regex is not tied to the beginning of the target
string by default.  So for regexes involving paths you will probably
want to do so explicitly:

    <LocationMatch ^/users>
        UserDir = 1
    </LocationMatch>

=item path

This method is useful for matching paths, URLs, Perl Modules and other
hierarchical strings.

The config section string is tested against the the target string.
It matches if the following are all true:

=over 4

=item *

The section string is a substring of the target string

=item *

The section string starts at the first character of the target string

=item *

In the target string, the section string is followed immediately by
L<path_separator> or the end-of-string.

=back

For instance:

    # somefile.conf
    <Location /foo>
    </Location>

    ...

    my $conf = Config::Context->new(
        driver         => 'ConfigGeneral'
        match_sections => [
            {
                name       => 'LocationMatch',
                match_Type => 'path',
            },
        ],
        file        => 'somefile.conf',
    );

In this case, the following target strings would all match:

    /foo
    /foo/
    /foo/bar
    /foo/bar.txt

But the following strings would B<not> match:

    /foo.txt
    /food
    /food/bar.txt
    foo.txt

=item hierarchical

A synonym for 'path'.

=back

=item B<path_separator>

The path separator when matching hierarchical strings (paths, URLs,
Module names, etc.).  It defaults to '/'.

This parameter is ignored unless the L<match_type> is 'path' or
'hierarchical'.

=item B<section_type>

Allows you to match certain sections against certain run time values.
For instance, you could match some sections against a given filesystem
path and some sections against a Perl module name, using the same config
file.

    # somefile.conf
    # section 1
    <FileMatch \.pm$>
        Perl_Module      = 1
        Core_Module      = 1
        Installed_Module = 0
    </FileMatch>

    # section 2
    <FileMatch ^/.*/lib/perl5/site_perl>
        Core_Module = 0
    </FileMatch>

    # section 3
    # Note the whitespace at the end of the section name, to prevent File from
    # being parsed as a stand-alone block by Config::General
    <File /usr/lib/perl5/ >
        Installed_Module = 1
    </File>

    # section 4
    <Module NET::FTP>
        FTP_Module = 1
    </Module>

    my $conf = Config::Context->new(
        driver         => 'ConfigGeneral'
        match_sections => [
            {
                name         => 'FileMatch',
                match_type   => 'regex',
                section_type => 'file',
            },
            {
                name         => 'File',
                match_type   => 'path',
                section_type => 'file',
            },
            {
                name         => 'Module',
                match_type   => 'path',
                separator    => '::',
                section_type => 'module',
            },
        ],
        file        => 'somefile.conf',

        # need to turn off C-style comment parsing because of the
        # */ in the name of section 2
        driver_options => {
            ConfigGeneral => {
                -CComments => 0,
            }
        },
    );

    my %config = $conf->context(
        file   => '/usr/lib/perl5/site_perl/5.6.1/NET/FTP/Common.pm',
        module => 'NET::FTP::Common',
    );

This tests C</usr/lib/perl5/site_perl/5.6.1/NET/FTP/Common.pm> against
sections 1, 2 and 3 (and merging them in the order of shortest to
longest match, i.e. 1, 3, 2).

Then it tests 'NET::FTP::Common' against section 4 (which also matches).
The resulting configuration is:

    use Data::Dumper;
    print Dumper(\%config);
    --------
    $VAR1 = {
        'Perl_Module'      => 1,
        'Core_Module'      => 0,
        'FTP_Module'       => 1,
        'Installed_Module' => 1,
    };

Another example:

    my %config = $conf->context(
        file   => '/var/www/cgi-lib/FTP/FTPServer.pm',
        module => 'NET::FTPServer',
    );

This tests C</var/www/cgi-lib/NET/FTPServer.pm> against sections 1, 2
and 3, and matches only against section 1.  Then it matches
'NET::FTPServer' against section 4 (which does not match).  The
result is:

    use Data::Dumper;
    print Dumper(\%config);
    --------
    $VAR1 = {
        'Perl_Module'      => 1,
        'Core_Module'      => 0,
        'FTP_Module'       => 0,
        'Installed_Module' => 0,
    };


If a L<section_type> is not specified in a L<match_sections> block, then
target strings of a named type will not match it.

For another example, see L<Matching Context based on More than one String>, above.

Matching by L<section_type> is used in
L<CGI::Application::Plugin::Config::Context> to determine configurations
based both on the URL of the request and of the name of the Perl Module
and runmode handling the request.

=item B<trim_section_names>

By default, section names are trimmed of leading and trailing whitespace
before they are used to match.  This is to allow for sections like:

    <Path /foo/bar/ >
    </Path>

The whitespace at the end of the section name is necessary to prevent
L<Config::General>'s parser from thinking that the first tag is an empty
C<< <Path /> >> block.

    <Path /foo/bar/>  # Config::General parses this as <Path />
    </Path>           # Config::General now considers this to be spurious

If leading and trailing whitespace is significant to your matches, you
can disable trimming by setting trim_section_names to C<0> or C<undef>.

=item B<merge_priority>

Sections with a lower L<merge_priority> are merged before sections with
a higher L<merge_priority>.  If two or more sections have the same
L<merge_priority> they are weighted the same and they are merged
according to the "best match" against the target string (i.e. the
longest matching substring).

See the description above under L<Multiple Sections Matching>.

=back

=head3 nesting_depth

This option alows you to match against nested structures.

    # stories.conf
    <Story Three Little Pigs>
        antagonist = Big Bad Wolf
        moral      = obey the protestant work ethic
    </Story>

    <Location /aesop>
        <Story Wolf in Sheep's Clothing>
            antagonist = Big Bad Wolf
            moral      = appearances are deceptive
        </Story>
    </Location>

    <Story Little Red Riding Hood>
        antagonist = Big Bad Wolf

        <Location /perrault>
            moral      = never talk to strangers
        </Location>

        <Location /grimm>
            moral      = talk to strangers and then chop them up
        </Location>
    </Story>


    my $conf = Config::Context->new(
        match_sections => [
            {
                name         => 'Story',
                match_type   => 'substring',
                section_type => 'story',
            },
            {
                name         => 'Location',
                match_type   => 'path',
                section_type => 'path',
            },
        ],
        file          => 'stories.conf',
        nesting_depth => 2,
    );

    $config = $conf->context(
        story => 'Wolf in Sheep\'s Clothing',
        path  => '/aesop/wolf-in-sheeps-clothing',
    );

    use Data::Dumper;
    print Dumper($config);
    --------
    $VAR1 = {
        'antagonist' => 'Big Bad Wolf',
        'moral'      => 'appearances are deceptive'
    };

You can also change the nesting depth by calling
C<< $self->nesting_depth($depth) >> after you have constructed the
L<Config::Context> object.

=head3 lower_case_names

Attempts to force all section and key names to lower case.  If
L<lower_case_names> is true, then the following sections would
all match 'location':

    <Location /somepath>
    </Location>

    <loCATtion /somepath>
    </Location>

    <lOcAtion /somepath>
    </LOCATION>

B<Note:> the C<XMLSimple> driver does not support this option.

=head3 cache_config_files

Whether or not to cache configuration files.  Enabled, by default.
This option is useful in a persistent environment such as C<mod_perl>.
See L<Config File Caching> under L<ADVANCED USAGE>, below.

=head3 stat_config

If config file caching is enabled, this option controls how often the
config files are checked to see if they have changed.  The default is 60
seconds.  This option is useful in a persistent environment such as
C<mod_perl>.  See L<Config File Caching> under L<ADVANCED USAGE>, below.

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my $self  = {};
    bless $self, $class;

    my %args           = @_;


    my $driver_opts        = delete $args{'driver_options'};
    my $config             = delete $args{'config'};
    my $file               = delete $args{'file'};
    my $string             = delete $args{'string'};
    my $match_sections     = delete $args{'match_sections'}    || [];
    my $nesting_depth      = delete $args{'nesting_depth'}     || 1;
    my $lower_case_names   = delete $args{'lower_case_names'};
    my $cache_config_files = exists $args{'cache_config_files'} ? delete $args{'cache_config_files'} : 1;
    my $stat_config        = exists $args{'stat_config'}        ? delete $args{'stat_config'}        : 60;
    my $driver_name        = delete $args{'driver'};

    if (keys %args) {
        croak __PACKAGE__ . "->new(): unrecognized parameters: ". (join ', ', keys %args);
    }

    my ($raw_config, $files);

    if ($config) {
        $raw_config = $config;
    }
    else {

        if (!$driver_name) {
            croak __PACKAGE__ . "->new(): 'driver' is required for configurations read from file or string";
        }
        $driver_name =~ /^\w+$/ or croak __PACKAGE__ . "->new(): 'driver' must only contain word characters";

        my $driver_package = __PACKAGE__ . '::' . $driver_name;

        eval "require $driver_package;";
        if ($@) {
            croak __PACKAGE__ . "->new(): Could not load config driver $driver_package: $@\n";
        }

        if ($string) {
            my $driver = $driver_package->new(
                string           => $string,
                lower_case_names => $lower_case_names,
                match_sections   => $match_sections,
                nesting_depth    => $nesting_depth,
                options          => $driver_opts,
            );
            $raw_config = $driver->parse;
        }
        elsif($file) {
            # handle caching
            if ($cache_config_files) {
                if ($self->_cache_check_valid($file, $stat_config)) {
                    $raw_config = $self->_cache_retrieve($file);
                }
            }
            if (!$raw_config) {
                my $driver = $driver_package->new(
                    file             => $file,
                    lower_case_names => $lower_case_names,
                    match_sections   => $match_sections,
                    nesting_depth    => $nesting_depth,
                    options          => $driver_opts,
                );
                $raw_config = $driver->parse;
                $files      = $driver->files;

                if ($cache_config_files) {
                    $self->_cache_store($file, $raw_config, $files, time);
                }
            }
        }
        else {
            croak __PACKAGE__ . "->new(): one of 'file', 'string' or 'config' is required";
        }
    }

    $self->{'files'}            = $files;
    $self->{'raw_config'}       = $raw_config;
    $self->{'match_sections'}   = $match_sections    || [];
    $self->{'nesting_depth'}    = $nesting_depth     || 1;
    $self->{'lower_case_names'} = $lower_case_names;

    $self->{'reduced_config'}   = $self->_reduce_nested;

    return $self;
}

=head1 METHODS

=head2 raw()

Returns the raw configuration data structure as read by the driver,
before any context matching is performed.

=cut

sub raw {
    my $self = shift;
    return %{ $self->{'raw_config'} } if wantarray;
    return $self->{'raw_config'};
}

=head2 context( $target_string )

Returns the merged configuration of all sections matching
C<$target_string>, according to the rules set up in
L<match_sections> in L<new()>.  All L<match_sections> are included,
regardless of their L<section_type>.

=head2 context( $type => $target_string )

Returns the merged configuration matching C<$target_string>, based only
the L<match_section>s that have a L<section_type> of C<$type>.

=head2 context( $type1 => $target_string1, $type2 => $target_string2 )

Returns the merged configuration of all sections of L<section_type>
C<$type1> matching C<$target_string1> and all sections of
L<section_type> C<$type2> matching C<$target_string2>.

The order of the parameters to L<context()> is retained, so
C<$type1> sections will be matched first, followed by C<$type2>
sections.

=head2 context( )

If you call L<context> without parameters, it will return the same
configuration that was generated by the last call to L<context>.

If you call L<context> in a scalar context, you will receive a
reference to the config hash:

    my $config = $conf->context($target_string);
    my $value  = $config->{'somekey'};

In a list context, L<context> returns a hash:

    my %config = $conf->context($target_string);
    my $value  = $config{'somekey'};

=cut

sub context {
    my $self = shift;

    if (@_) {
        $self->_reduce_nested(@_);
    }

    return %{ $self->{'reduced_config'} } if wantarray;
    return $self->{'reduced_config'};
}

=head2 files

Returns a list of all the config files read, including any config files
included in the main file.

=cut

sub files {
    my $self = shift;
    my $files = $self->{'files'} || [];
    return @$files if wantarray;
    return $files;
}

# _reduce_nested()
# iteratively calls _reduce_with_context $self->{'nesting_depth'} times
# to reduce a nested config structure.
sub _reduce_nested {
    my $self = shift;

    # make a copy
    $self->{'reduced_config'} = Clone::clone( $self->{'raw_config'} );

    for (1 .. $self->{'nesting_depth'}) {
        $self->{'reduced_config'} = $self->_reduce_with_context($self->{'reduced_config'}, @_);
    }
}

# _reduce_with_context(...)
# matches $config against the runtime values provided as in the pod for context:
# $self->_reduce_with_context($config_hash, $type1 => $target_string1, $type2 => $target_string2);

sub _reduce_with_context {
    my $self          = shift;
    my $merged_config = shift;

    my $target_string;
    my $section_type;

    my @matches;

    while (@_) {
        if (@_ == 1) {
            $target_string = shift;
            $section_type  = undef;
        }
        else {
            $section_type  = shift;
            $target_string = shift;
        }
        push @matches, $self->_get_matching_sections($merged_config, $target_string, $section_type);
    }

    # Now sort the matching sections, first by MergePriority (lowest
    # first), second by length of the matching substring (shortest first)
    #
    # @matches contains a list of array refs whose first element is the
    # section's MergePriority, the second element is the number of
    # characters that matched, and the third element is the config hash
    # of the matching section

    foreach my $match (sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @matches) {

        my $section_hash = $match->[2];

        $merged_config = Hash::Merge::merge($section_hash, $merged_config);

    }

    return %$merged_config if wantarray;
    return $merged_config;
}

# _get_matching_sections()
# a list the sections that match
# the list contains array refs whose first element is the
# section's merge_priority, the second element is the number of
# characters that matched, and the third element is the config hash
# of the matching section

sub _get_matching_sections {
    my $self   = shift;
    my $config = shift;

    my ($target_string, $target_section_type) = @_;

    my $match_sections = $self->{'match_sections'};

    # validation of -MatchSections
    unless ($match_sections and ref $match_sections eq 'ARRAY' and @$match_sections) {
        croak "Can't run context when no match_sections provided";
    }

    my %allowed_spec_keys = map { $_ => 1 } qw(
        name
        match_type
        path_separator
        section_type
        merge_priority
        trim_section_names
    );

    my @matches;

    my $count;
    foreach my $spec (@$match_sections) {
        $count++;

        my @bad_spec_keys = grep { !$allowed_spec_keys{$_} } keys %$spec;
        if (@bad_spec_keys) {
           croak "Unknown spec option(s): ".(join ', ', @bad_spec_keys);
        }

        # Must have name and MatchType
        my $name               = $spec->{'name'}           or croak "Spec #$count has no name";
        my $match_type         = $spec->{'match_type'}     or croak "Spec #$count has no match_type";
        my $path_sep           = $spec->{'path_separator'} || '/';
        my $section_priority   = $spec->{'merge_priority'} || 0;
        my $this_section_type  = $spec->{'section_type'};

        my $trim_section_names = exists $spec->{'trim_section_names'} ? $spec->{'trim_section_names'} : 1;

        if ($self->{'lower_case_names'}) {
            $name              = lc $name;
            $this_section_type = lc $this_section_type;
        }

        # Skip this section if the section's type does not match the type
        # of the target string.  But only do so if the target_string has a type.
        if ($target_section_type) {

            # If the target_string has a type but the section doesn't then skip
            next unless $this_section_type;

            # If the target_string doesn't equal the section string then skip
            if ($target_section_type ne $this_section_type) {
                next;
            }
        }

        next unless exists $config->{$name};

        my $sections = delete $config->{$name};


        foreach my $section_string (keys %$sections) {
            my $section_hash = $sections->{$section_string};

            if ($trim_section_names) {
                $section_string =~ s/^\s*(.*?)\s*$/$1/;
            }

            if ($match_type =~ /^exact$/i) {
                if ($target_string eq $section_string) {
                    # store matches as array ref where first element is
                    # the section's MergePriority, the second element is
                    # the length and the third is the config hash of
                    # matching section

                    push @matches, [
                        $section_priority,
                        length($section_string),
                        $section_hash,
                    ];
                }
            }
            elsif ($match_type =~ /^substring$/i) {
                if ((index $target_string, $section_string) != ($[ - 1)) {
                    # store matches as array ref where first element is
                    # the section's MergePriority, the second element is
                    # the length and the third is the config hash of
                    # matching section

                    push @matches, [
                        $section_priority,
                        length($section_string),
                        $section_hash,
                    ];
                }
            }
            elsif ($match_type =~ /^regex$/i) {
                my $regex = qr/$section_string/;
                if ($target_string =~ qr/($section_string)/) {
                    # store matches as array ref where first element is
                    # the section's MergePriority, the second element is
                    # the length and the third is the config hash of
                    # matching section

                    push @matches, [
                        $section_priority,
                        length($1),
                        $section_hash,
                    ];
                }
            }
            elsif ($match_type =~ /^path$/i or $match_type =~ /^hierarchy$/i) {

                my $regex = quotemeta($section_string);

                # If the section string ends with $path_sep then
                # we have only to match the whole string

                if (($section_string =~ /$path_sep$/ and $target_string =~ qr/^($regex)/)

                # otherwise, we have to find the section_string either at
                # the end of target_string or immediately followed by
                # $path_sep in target string

                or ($target_string =~ qr/^($regex)(?:$path_sep|$)/)) {
                    # store matches as array ref where first element is
                    # the section's MergePriority, the second element is
                    # the length and the third is the config hash of
                    # matching section

                    push @matches, [
                        $section_priority,
                        length($1),
                        $section_hash,
                    ];
                }
            }
            else {
                croak "Bad match_type: $match_type";
            }
        }
    }
    return @matches;
}

=head2 nesting_depth()

Changes the default nesting depth, for matching nested structures.
See the L<nesting_depth> parameter to L<new>.

=cut

sub nesting_depth {
    my $self                 = shift;
    $self->{'nesting_depth'} = shift || 0;
}

our %CC_Cache;

# Cache format:
# %CC_Cache = (
#     $absolute_filename1 => {
#         __CONFIG        => $config_hash,
#         __CREATION_TIME => $creation_time,   # time object was constructed
#
#         __FILES         => [                 # array of fileinfo hashrefs,
#                                              # one per config file included
#                                              # by the primary config file
#             {
#                 __FILENAME  => $filename1,   # name of file
#                 __MTIME     => $mtime1,      # last modified time, in epoch seconds
#                 __SIZE      => $size1,       # size, in bytes
#                 __LASTCHECK => $time1,       # last time we checked this file, in epoch seconds
#             },
#             {
#                 __FILENAME  => $filename2,
#                 __MTIME     => $mtime2,
#                 __SIZE      => $size2,
#                 __LASTCHECK => $time2,
#             },
#         ]
#     }

# _cache_retrieve($filename)       # returns config_hash
sub _cache_retrieve {
    my ($self, $config_file) = @_;

    my $abs_path = Cwd::abs_path($config_file);

    return $CC_Cache{$abs_path}->{'__CONFIG'};
}

# _cache_store($filename, $config, $files, $creation_time) # stores config
sub _cache_store {
    my ($self, $config_file, $config, $files, $creation_time) = @_;

    my $abs_path     = Cwd::abs_path($config_file);

    my @filedata;

    foreach my $file (@$files) {
        my $time = time;
        my ($size, $mtime) = (stat $file)[7,9];
        my %fileinfo = (
            '__FILENAME'  => $file,
            '__LASTCHECK' => $time,
            '__MTIME'     => $mtime,
            '__SIZE'      => $size,
        );
        push @filedata, \%fileinfo;
    }

    $CC_Cache{$abs_path} = {
        '__CONFIG'        => $config,
        '__CREATION_TIME' => $creation_time,
        '__FILES'         => \@filedata,
    };

}

# _cache_check_valid($config_file, $stat_config)
#  - returns true if all config files associated with this file
#    are still valid.
#  - returns false if any of the configuration files have changed
#
# if a file was checked less than stat_seconds ago, then it is not even
# checked, but assumed to be valid.
# Otherwise it is checked again.  If its mtime or size have changed
# then it is assumed to be invalid.
#
# if any file has changed then the configuration is determined to
# be invalid

sub _cache_check_valid {
    my ($self, $config_file, $stat_config) = @_;

    my $abs_path = Cwd::abs_path($config_file);

    return unless exists $CC_Cache{$abs_path};
    return unless ref    $CC_Cache{$abs_path}{'__FILES'} eq 'ARRAY';

    foreach my $fileinfo (@{ $CC_Cache{$abs_path}{'__FILES'} }) {
        my $time = time;

        # Don't stat the file unless our last check was more recent than
        # $stat_config seconds ago

        # but, if $stat_config is zero then always stat the file

        if ($stat_config) {
            next if ($fileinfo->{'__MTIME'} + $stat_config >= $time);
        }

        my ($size, $mtime) = (stat $fileinfo->{'__FILENAME'})[7,9];

        # return false if any differences
        return if $size  != $fileinfo->{'__SIZE'};
        return if $mtime != $fileinfo->{'__MTIME'};

        # no change, so save the new stat info in the cache
        $fileinfo->{'__SIZE'}      = $size;
        $fileinfo->{'__MTIME'}     = $mtime;
        $fileinfo->{'__LASTCHECK'} = $time;

    }
    return 1;
}

=head2 clear_file_cache

Clears the internal file cache.  Class method.

    Config::Context->clear_file_cache;
    $conf->clear_file_cache;

=cut

sub clear_file_cache {
    my $class = shift;
    %CC_Cache = ();
}

# Utility method for drivers to load their prerequsite modules

sub _require_prerequisite_modules {
    my ($class, $driver_class) = @_;

    my @missing_modules;

    foreach my $module ($driver_class->config_modules) {
        eval "require $module";
        if ($@) {
            push @missing_modules, $module;
        }
    }
    if (@missing_modules) {
        foreach my $module (@missing_modules) {
            warn "$driver_class: missing prerequisite module: $module\n";
        }
        die "Can't continue loading: $driver_class\n";
    }
}


=head1 ADVANCED USAGE

=head2 Config File Caching

By default each config file is read only once when the conf object is
first initialized.  Thereafter, on each init, the cached config is used.

This means that in a persistent environment like mod_perl, the config
file is parsed on the first request, but not on subsequent requests.

If enough time has passed (sixty seconds by default) the config file is
checked to see if it has changed.  If it has changed, then the file is
reread.

If the driver supports it, any included files will be checked for
changes along the main file.   If you use L<Config::General>, you must
use version 2.28 or greater for this feature to work correctly.

To disable caching of config files pass a false value to the
L<cache_config_files> parameter to L<new>, e.g:

    my $conf = Config::Context->new(
        cache_config_files => 0,
        # ... other options here ...
    );

To change how often config files are checked for changes, change the
value of the L<stat_config> paramter to L<init>, e.g.:

    my $conf = Config::Context->new(
        stat_config => 1, # check the config file every second
        # ... other options here ...
    );

Internally the configuration cache is implemented by a hash, keyed by
the absolute path of the configuration file.  This means that if you
have two applications running in the same process that both use the same
configuration file, they will use the same cache.

However, matching is performed on the config retrieved from the cache,
so the two applications could each use different matching options
creating different configurations from the same file.

=head2 Changing Hash::Merge behaviour

Matching sections are merged together using the L<Hash::Merge> module.
If you want to change how this module does its work you can call
subroutines in the L<Hash::Merge> package directly.  For instance, to
change the merge strategy so that earlier sections have precidence over
later sections, you could call:

    # Note American Spelling :)
    Hash::Merge::set_behavior('RIGHT_PRECEDENT')

You should do this before you call L<context()>.

For more information on how to change merge options, see the
L<Hash::Merge> docs.

=head1 AUTHOR

Michael Graham, C<< <mag-perl@occamstoothbrush.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-config-context@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Michael Graham, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Config::Context
