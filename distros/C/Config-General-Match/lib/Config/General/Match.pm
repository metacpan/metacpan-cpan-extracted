
package Config::General::Match;

use warnings;
use strict;

use Carp;

use Config::General;
use Hash::Merge qw();

our @ISA = qw(Config::General);

=head1 NAME

Config::General::Match - Add C<< <Location> >> and C<< <LocationMatch> >> style matching to Config::General

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 NOTE

This module is obsolete and has now been superceded by
L<Config::Context>.

=head1 SYNOPSIS

    use Config::General::Match;

    my $config_text = '

        <Location /users>
            title = "User Area"
        </Location>

        <LocationMatch \.*(jpg|gif|png)$>
            image_file = 1
        </Location>

    ';


    my $conf = Config::General::Match->new(
        -String => $config_text,
        -MatchSections => [
            {
                -Name          => 'Location',
                -MatchType     => 'path',
            },
            {
                -Name          => 'LocationMatch',
                -MatchType     => 'regex',
            },
        ],
    );

    my %config = $conf->getall_matching('/users/~mary/index.html');
    use Data::Dumper;
    print Dumper(\%config);
    $VAR1 = {
        'title'         => 'User Area',
        'image_file'    => undef,
    };

    my %config = $conf->getall_matching('/users/~biff/images/flaming_logo.gif');
    print Dumper(\%config);
    $VAR1 = {
        'title'         => 'User Area',
        'image_file'    => 1,
    };


=head1 DESCRIPTION

=head2 Introduction

This module extends C<Config::General> by providing support for
configuration sections that match only for a particular file or path or
URL.

Typically you would use this to support the Apache-style conditional
blocks, for instance:

    <FilesMatch .jpg$>
        # ... some configuration ...
    </FilesMatch>

    <Location /users>
        # ... some configuration ...
    </Location>

    <LocationMatch .html$>
        # ... some configuration ...
    </LocationMatch>

To read the configuration use C<< $conf->getall_matching >> instead of
C<< $conf->getall >>:

    my $conf         = Config::General::Match->new(...);
    my %config       = $conf->getall_matching('/users/joe/index.html');
    my %other_config = $conf->getall_matching('/images/banner.jpg');

=head2 Matching things other than paths

The Match feature is general enough that you can use it to match other
things besides paths and URLs.  For instance you could specify a
C<-PathSeparator> of C<::> and use the feature to match against Perl
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

    my $conf = Config::General::Match->new(
        -String => $config_text,
        -MatchSections => [
            {
                -Name          => 'Module',
                -PathSeparator => '::',
                -MatchType     => 'path',
            },
        ],
    );

    my %config = $conf->getall_matching('Net::FTP');
    use Data::Dumper;
    print Dumper(\%config);
    $VAR1 = {
        'is_core_module' => 1,
        'author'         => 'Nathan Torkington',
    };

=head2 Merging

=head3 Merging with the implied 'Default' section

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
    my %config = $conf->getall_matching('/admin/index.html');
    use Data::Dumper;
    print Dumper(\%config);
    $VAR1 = {
        'private_area' => 1,
        'client_area' => 0,
    };

    # Client Area URL
    my %config = $conf->getall_matching('/clients/index.html');
    print Dumper(\%config);
    $VAR1 = {
        'private_area' => 0,
        'client_area'  => 1,
    };

    # Neither Client nor Admin
    my %config = $conf->getall_matching('/public/index.html');
    print Dumper(\%config);
    $VAR1 = {
        'private_area' => 0,
        'client_area'  => 0,
    };

=head3 Multiple Level Merging

Sections and subsections are merged along with single values.  For instance:

    private_area = 0
    client_area  = 0
    <page_settings>
        title       = "The Widget Emporium"
        logo        = logo.gif
        advanced_ui = 0
    </page_settings>

    <Location /admin>
        private_area = 1
        <page_settings>
            title       = "The Widget Emporium - Admin Area"
            logo        = admin_logo.gif
            advanced_ui = 1
        </page_settings>
    </Location>

    <Location /clients>
        client_area  = 1
        <page_settings>
            title = "The Widget Emporium - Wholesalers"
            logo  = client_logo.gif
        </page_settings>
    </Location>

    # Admin Area URL
    my %config = $conf->getall_matching('/admin/index.html');
    use Data::Dumper;
    print Dumper(\%config);
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
    my %config = $conf->getall_matching('/clients/index.html');
    print Dumper(\%config);
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
    my %config = $conf->getall_matching('/public/index.html');
    print Dumper(\%config);
    $VAR1 = {

        'page_settings' => {
                            'advanced_ui' => '0',
                            'title' => 'The Widget Emporium',
                            'logo' => 'logo.gif'
                           },
        'client_area' => '0',
        'private_area' => '0'

    };


=head3 Merging Multiple Matching Sections

Often more than one section will match the target string.  When this
happens, the matching sections are merged together using the
C<Hash::Merge> module.  Typically this means that sections that are
merged later override the values set in earlier sections.  (But you can
change this behaviour.  See L<Changing Hash::Merge behaviour> below.)

The order of merging matters.  The sections are merged first according
to each section's C<-MergePriority> value (lowest values are merged
first), and second by the length of the substring that matched (shortest
matches are merged first).  If you don't specify C<-MergePriority> for
any section, they all default to a priority of C<0> which means all
sections are treated equally and matches are prioritized based soley on
the length of the matching strings.

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

    my $conf         = Config::General::Match->new(
        -MatchSections => [
            { -Name    => 'Directory',  -MatchType => 'path' -MergePriority => 1 },
            { -Name    => 'Dir',        -MatchType => 'path' -MergePriority => 1 },
            { -Name    => 'Path',       -MatchType => 'path' -MergePriority => 2 },
        ],
    );

...then the target string '/foo/bar/baz/bam/boom' would match all sections
the order of 1, 3, 4, 2.



=head1 CONSTRUCTOR

=head2 new(...)

Creates and returns a new C<Config::General::Match> object.

    my $conf = Config::General::Match->new(
        -MatchSections => [
           {  -Name  => 'Directory',  -MatchType => 'path' },
        ],
        -ConfigFile => 'somefile.conf',
    );

The arguments to C<new()> are the same as you would provide to
C<Config::General>, with the addition of C<-MatchSections>.  (But see
see the C<BUGS> section for limitations on compatibility with
C<Config::General>.)

The C<-MatchSections> parameter takes a list of specification hashrefs.
Each specification has the following fields:

=over 4

=item B<-Name>

The name of the section.  For a name of 'Location', the section would look like:

    <Location /somepath>
    </Location>

This parameter is affected by the C<Config::General> option
C<-LowerCaseNames>.  If C<-LowerCaseNames> is true, then the following
would all be valid 'Location' sections.

    <Location /somepath>
    </Location>

    <loCATtion /somepath>
    </Location>

    <lOcAtion /somepath>
    </LOCATION>

=item B<-MatchType>

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


    my $conf = Config::General::Match->new(
        -MatchSections => [
            {
                -Name      => 'Site',
                -MatchType => 'exact',
            },
        ],
        -ConfigFile => 'somefile.conf',
    );

In this case, only the string C<mysite> would match the section.

=item substring

The config section string is tested to see if it is a substring of the
target string.  For instance:

    # somefile.conf
    <Location foo>
        ...
    </Location>

    ...


    my $conf = Config::General::Match->new(
        -MatchSections => [
            {
                -Name      => 'LocationMatch',
                -MatchType => 'substring',
            },
        ],
        -ConfigFile => 'somefile.conf',
    );

In this case, the following target strings would all match:

    /foo
    big_foo.html
    /hotfood

Do not quote the match string; it will not work if you do so.

=item regex

The config section string is treated as a regular expression against
which the target string is matched.  For instance:

    # somefile.conf
    <LocationMatch (\.jpg)|(\.gif)(\.png)$>
        Image = 1
    </LocationMatch>

    ...

    my $conf = Config::General::Match->new(
        -MatchSections => [
            {
                -Name      => 'LocationMatch',
                -MatchType => 'regex',
            },
        ],
        -ConfigFile => 'somefile.conf',
    );

    my %config = $conf->getall_matching('banner.jpg');

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

Do not quote a regex; it will not work if you do so.

=item path

This method is useful for matching paths, URLs, Perl Modules and other
hierarchical strings.

The config section string is tested against the the target string
according to the following rules:

=over 4

=item *

The section string is a substring of the target string

=item *

The section string starts at the first character of the target string

=item *

In the target string, the section string is followed immediately by
C<-PathSeparator> or the end-of-string.

=back

For instance:

    # somefile.conf
    <Location /foo>
    </Location>

    ...

    my $conf = Config::General::Match->new(
        -MatchSections => [
            {
                -Name      => 'LocationMatch',
                -MatchType => 'path',
            },
        ],
        -ConfigFile => 'somefile.conf',
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

Do not quote the path; it will not work if you do so.

=item hierarchical

A synonym for 'path'.

=back

=item B<-PathSeparator>

The path separator when matching hierarchical strings (paths, URLs,
Module names, etc.).  It defaults to '/'.

This parameter is ignored unless the C<-MatchType> is 'path' or
'hierarchical'.

=item B<-SectionType>

Allows you to only process certain sections for certain types of
strings.  For instance, you could match some sections against a given
filesystem path and some sections against a Perl module name, using the
same config file.

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

    my $conf = Config::General::Match->new(
        -MatchSections => [
            {
                -Name        => 'FileMatch',
                -MatchType   => 'regex',
                -SectionType => 'file',
            },
            {
                -Name        => 'File',
                -MatchType   => 'path',
                -SectionType => 'file',
            },
            {
                -Name        => 'Module',
                -MatchType   => 'path',
                -Separator   => '::',
                -SectionType => 'module',
            },
        ],
        -ConfigFile => 'somefile.conf',

        # need to turn off C-style comment parsing because of the
        # */ in the name of section 3
        -CComments => 0,
    );

    my %config = $conf->getall_matching(
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
    $VAR1 = {
        'Perl_Module'      => 1,
        'Core_Module'      => 0,
        'FTP_Module'       => 1,
        'Installed_Module' => 1,
    };

Another example:

    my %config = $conf->getall_matching(
        file   => '/var/www/cgi-lib/FTP/FTPServer.pm',
        module => 'NET::FTPServer',
    );

This tests C</var/www/cgi-lib/NET/FTPServer.pm> against sections 1, 2
and 3, and matches only against section 1.  Then it matches
'NET::FTPServer' against section 4 (which does not match).  The
result is:

    use Data::Dumper;
    print Dumper(\%config);
    $VAR1 = {
        'Perl_Module'      => 1,
        'Core_Module'      => 0,
        'FTP_Module'       => 0,
        'Installed_Module' => 0,
    };


If a C<-SectionType> is not specified in a C<-MatchSections> block, then
target strings of a named type will not match it.

Matching by C<-SectionType> is used in
C<CGI::Application::Plugin::Config::General> to generate configurations
based both on the URL of the request and of the name of the Perl Module
and runmode handling the request.

=item B<-TrimSectionNames>

By default, section names are trimmed of leading and trailing whitespace
before they are used to match.  This is to allow for sections like:

    <Path /foo/bar/ >
    </Path>

The whitespace at the end of the section name is necessary to prevent
Config::General's parser from thinking that the first tag is an empty
C<< <Path /> >> block.

    <Path /foo/bar/>  # Config::General parses this as <Path />
    </Path>           # Config::General now considers this to be spurious

If leading and trailing whitespace is significant to your matches, you
can disable trimming by setting -TrimSectionNames to C<0> or C<undef>.

=item B<-MergePriority>

Sections with a lower C<-MergePriority> are merged before sections with
a higher C<-MergePriority>.  If two or more sections have the same
C<-MergePriority> they are weighted the same and they are merged
according to the "best match" against the target string (i.e. the
longest matching substring).

See the description above under L<Merging Multiple Matching Sections>.

=back

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my %args           = @_;
    my $match_sections = [];

    if (exists $args{'-MatchSections'} and ref $args{'-MatchSections'} eq 'ARRAY') {
        $match_sections = delete $args{'-MatchSections'};
    }

    my $self = $class->SUPER::new(%args);

    $self->{__PACKAGE__ . '::MatchSections'} = $match_sections;

    bless $self, $class;
    return $self;
}

=head1 METHODS

C<Config::General::Match> is a subclass of C<Config::General>, so you
can use of C<Config::General>'s methods.  In particular, you can use
C<getall()> to get the entire configuration without concern for any
section matching.

=head2 getall_matching( $target_string )

Returns the merged configuration of all sections matching
C<$target_string>, according to the rules set up in the
C<-MatchSections> in C<new()>.  All C<-MatchSections> are included,
regardless of their C<-SectionType>.

=head2 getall_matching( $type => $target_string )

Returns the merged configuration matching C<$target_string>, based only
the C<-MatchSection>s that have a C<-SectionType> of C<$type>.

=head2 getall_matching( $type1 => $target_string1, $type2 => $target_string2 )

Returns the merged configuration of all sections of C<-SectionType>
C<$type1> matching C<$target_string1> and all sections of
C<-SectionType> C<$type2> matching C<$target_string2>.

The order of the parameters to C<getall_matching()> is retained, so
C<$type1> sections will be matched first, followed by C<$type2>
sections.

If you call C<getall_matching> in a scalar context, you will receive a
reference to the config hash:

    my $config = $conf->getall_matching($target_string);
    my $value = $config->{'somekey'};

=cut

sub getall_matching {
    my $self = shift;
    my %config = $self->getall();

    return $self->_getall_matching_in_config(\%config, @_);
}

=head2 getall_matching_nested( $level, ... )

Behaves the same as C<getall_matching>, except that it can match nested
structures.

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


    my $conf = Config::General::Match->new(
        -MatchSections => [
            {
                -Name        => 'Story',
                -MatchType   => 'substring',
                -SectionType => 'story',
            },
            {
                -Name        => 'Location',
                -MatchType   => 'path',
                -SectionType => 'path',
            },
        ],
        -ConfigFile => 'stories.conf',
    );

    my $depth = 2;
    $config = $conf->getall_matching_nested(
        $depth,
        story => 'Wolf in Sheep\'s Clothing',
        path  => '/aesop/wolf-in-sheeps-clothing',
    );

    use Data::Dumper;
    print Dumper($config);
    $VAR1 = {
        'antagonist' => 'Big Bad Wolf',
        'moral'      => 'appearances are deceptive'
    };


=cut

sub getall_matching_nested {
    my $self   = shift;
    my $depth  = shift;

    my $config = { $self->getall() };

    for (1..$depth) {
        $config  = $self->_getall_matching_in_config($config, @_);
    }
    return %$config if wantarray;
    return $config;
}

# _getall_matching_in_config($config, ... )
# Behaves the same as C<getall_matching>, except that you must explicitly
# provide a reference to a hash of config values as the first argument.
# This allows you to match against a specific configuration
# without the overhead of creating a new object:

sub _getall_matching_in_config {
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

sub _get_matching_sections {
    my $self   = shift;
    my $config = shift;

    my ($target_string, $target_section_type) = @_;

    my $match_sections = $self->{__PACKAGE__ . '::MatchSections'};

    # validation of -MatchSections
    unless ($match_sections and ref $match_sections eq 'ARRAY' and @$match_sections) {
        croak "Can't run getall_matching when no -MatchSections provided";
    }

    my %allowed_spec_keys = map { $_ => 1 } qw(
        -Name
        -MatchType
        -PathSeparator
        -SectionType
        -MergePriority
        -TrimSectionNames
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
        my $name               = $spec->{'-Name'}          or croak "Spec #$count has no -Name";
        my $match_type         = $spec->{'-MatchType'}     or croak "Spec #$count has no -MatchType";
        my $path_sep           = $spec->{'-PathSeparator'} || '/';
        my $section_priority   = $spec->{'-MergePriority'} || 0;
        my $this_section_type  = $spec->{'-SectionType'};

        my $trim_section_names = exists $spec->{'-TrimSectionNames'} ? $spec->{'-TrimSectionNames'} : 1;

        if ($self->{'LowerCaseNames'}) {
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
                croak "Bad -MatchType: $match_type";
            }
        }
    }
    return @matches;
}

=head1 Changing Hash::Merge behaviour

Matching sections are merged together using the C<Hash::Merge> module.
If you want to change how this module does its work you can call
subroutines in the C<Hash::Merge> package directly.  For instance, to
change the merge strategy so that earlier sections have precidence over
later sections, you could call:

    # Note American Spelling :)
    Hash::Merge::set_behavior('RIGHT_PRECEDENT')

You should do this before you call C<getall_matching()>.

For more information on how to change merge options, see the
C<Hash::Merge> docs.

=head1 AUTHOR

Michael Graham, C<< <mag-perl@occamstoothbrush.com> >>

=head1 BUGS

=over 4

=item *

This module does not support the functional interface to
C<Config::General> (e.g. C<ParseConfig()>).

=item *

This module only supports the following constructor form:

    my $self = Config::General::Match->new( %options );

It does not support the other two C<Config::General> constructor styles:

    # NOT supported
    my $self = Config::General->new( "rcfile" );
    my $self = Config::General->new( \%some_hash );

=back

Please report any bugs or feature requests to
C<bug-config-general-match@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 SEE ALSO

    Config::General
    CGI::Application::Plugin::Config::General
    Hash::Merge

=head1 ACKNOWLEDGEMENTS

This module would not be possible without Thomas Linden's excellent
C<Config::General> module.

=head1 COPYRIGHT & LICENSE

Copyright 2004-2005 Michael Graham, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;


