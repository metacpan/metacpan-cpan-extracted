=head1 NAME

CrawlerCommons::RobotRules - the result of a parsed robots.txt

=head1 SYNOPSIS

 use CrawlerCommons::RobotRules;
 use CrawlerCommons::RobotRulesParser;

 my $rules_parser = CrawlerCommons::RobotRulesParser->new;
 
 my $content = "User-agent: *\r\nDisallow: *images";
 my $content_type = "text/plain";
 my $robot_names = "any-old-robot";
 my $url = "http://domain.com/";

 my $robot_rules =
   $rules_parser->parse_content($url, $content, $content_type, $robot_names);

 # obtain the 'mode' of the robot rules object
 say "Anything Goes!!!!" if $robot_rules->is_allow_all;
 say "Nothing to see here!" if $robot_rules->is_allow_none;
 say "Default robot rules mode..." if $robot_rules->is_allow_some;

 # are we allowed to crawl a URL (returns 1 if so, 0 if not)
 say "We're allowed to crawl the index :)"
  if $robot_rules->is_allowed( "https://www.domain.com/index.html");

 say "Not allowed to crawl: $_" unless $robot_rules->is_allowed( $_ )
   for ("http://www.domain.com/images/some_file.png",
        "http://www.domain.com/images/another_file.png");

=head1 DESCRIPTION

This object is the result of parsing a single robots.txt file

=cut

###############################################################################
package CrawlerCommons::RobotRules;

# MODULE IMPORTS
########################################
# Pragmas
#------------------#
use 5.10.1;
use strict;
use utf8;
use warnings;

# CPAN/Core
#------------------#
use Const::Fast;
use Try::Tiny;
use URI;
use URI::Escape;

# Moose Setup
#------------------#
use Moose;
use namespace::autoclean;

# Moose Pragmas
#------------------#
with 'MooseX::Log::Log4perl';

# Custom Modules
#------------------#


# VARIABLES/CONSTANTS
########################################
# Debug Constants
#------------------#
const my $DEBUG                 => $ENV{DEBUG} // 0;
const my $TEST                  => $ENV{TEST} // 1;

const our $ALLOW_ALL            => 'allow_all';
const our $ALLOW_NONE           => 'allow_none';
const our $ALLOW_SOME           => 'allow_some';
const my $ROBOT_RULES_MODES     =>
  ["$ALLOW_ALL", "$ALLOW_NONE", "$ALLOW_SOME"];
const our $UNSET_CRAWL_DELAY    => 0xffffffff * -1;

# Constants
#------------------#

# Variables
#------------------#
=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

# setup logging, if not present
BEGIN {
    require Log::Log4perl;
    Log::Log4perl->easy_init($Log::Log4perl::ERROR)
      unless $Log::Log4perl::Logger::INITIALIZED;
}


# ATTRIBUTES
########################################
# Class
#------------------#
#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------------#

# Instance
#------------------#
#-----------------------------------------------------------------------------#
has 'crawl_delay'               => (
    default                     => $UNSET_CRAWL_DELAY,
    is                          => 'rw',
    isa                         => 'Int',
    writer                      => 'set_crawl_delay',
);
#-----------------------------------------------------------------------------#
has '_defer_visits'             => (
    default                     => 0,
    is                          => 'rw',
    isa                         => 'Bool',
    traits                      => ['Bool'],
);
#-----------------------------------------------------------------------------#
has '_mode'                     => (
    enum                        => $ROBOT_RULES_MODES,
    handles                     => 1,
    is                          => 'ro',
    required                    => 1,
    traits                      => ['Enumeration'],
);
#-----------------------------------------------------------------------------#
has '_rules'                    => (
    default                     => sub {[]},
    handles                     => {
        '_add_rule'             => 'push',
        'clear_rules'           => 'clear',
        '_get_rules'            => 'elements',
    },
    is                          => 'ro',
    isa                         => 'ArrayRef[CrawlerCommons::RobotRule]',
    traits                      => ['Array'],
    writer                      => '_set_rules',
);
#-----------------------------------------------------------------------------#
has '_sitemaps'                 => (
    default                     => sub {[]},
    handles                     => {
        _add_sitemap            => 'push',
        get_sitemap             => 'get',
        get_sitemaps            => 'elements',
        sitemaps_size           => 'count',
    },
    is                          => 'ro',
    isa                         => 'ArrayRef[Str]',
    traits                      => ['Array'],
);
#-----------------------------------------------------------------------------#

=head1 METHODS

=cut

# METHODS
########################################
# Constructor
#------------------#
#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------------#

# Class Methods
#------------------#
#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------------#

# Instance Methods
#------------------#
#-----------------------------------------------------------------------------#
sub add_rule {
    my ($self, $prefix, $allow) = @_;
    $allow = 1 if !$allow && length($prefix) == 0;
    $self->_add_rule(
      CrawlerCommons::RobotRule->new(  _prefix => $prefix, _allow => $allow )
    );
}
#-----------------------------------------------------------------------------#
sub add_sitemap {
    my ($self, $sitemap) = @_;
    $self->_add_sitemap( $sitemap );
}
#-----------------------------------------------------------------------------#
=head2 C<< my $true_or_false = $robot_rules->is_allowed( $url ) >>

Returns 1 if we're allowed to crawl the URL represented by C<$url> and 0
otherwise.  Will return 1 if the method C<is_allow_all()> returns true,
otherwise, if C<is_allow_none> is false, returns 1 if there is an allow rule or
no disallow rule for this URL.

=over

=item * C<$url>

The URL whose path is used to search for a matching rule within the object for
evaluation.

=back

=cut

sub is_allowed {
    my ($self, $url) = @_;
    return 0 if $self->is_allow_none;
    return 1 if $self->is_allow_all;
    my $path_with_query = $self->_get_path( $url, 1);

    # always allow robots.txt
    return 1 if $path_with_query eq '/robots.txt';

    for my $rule ($self->_get_rules) {
        return $rule->_allow
          if $self->_rule_matches( $path_with_query, $rule->_prefix );
    }

    return 1;
}
#-----------------------------------------------------------------------------#
sub sort_rules {
    my $self = shift;

    $self->_set_rules(
        [ sort {length( $b->_prefix ) <=> length( $a->_prefix ) ||
                $b->_allow <=> $a->_allow} @{ $self->_rules }
        ]
    );

}
#-----------------------------------------------------------------------------#

# Private Methods
#------------------#
#-----------------------------------------------------------------------------#
sub _get_path() {
    my ($self, $url, $with_query) = @_;

    try {
        my $uri = URI->new( $url );
        my $path = $uri->path();
        my $path_query = $uri->path_query() // '';

        $path = $path_query if ($with_query && $path_query ne ''); 

        if (not(defined($path)) || $path eq '') {
            return '/';
        }
        else {
            $path = uri_unescape( $path );
            utf8::encode( $path );
            return $path;
        }
    }
    catch {
        return '/';
    };
}
#-----------------------------------------------------------------------------#
sub _rule_matches {
    my ($self, $text, $pattern) = @_;
    my $pattern_pos = my $text_pos = 0;
    my $pattern_end = length( $pattern );
    my $text_end = length( $text );

    my $contains_end_char = $pattern =~ m!\$! ? 1 : 0;
    $pattern_end -= 1 if $contains_end_char;

    while ( ( $pattern_pos < $pattern_end ) && ( $text_pos < $text_end ) ) {
        my $wildcard_pos = index( $pattern, '*', $pattern_pos );
        $wildcard_pos = $pattern_end if $wildcard_pos == -1;

        $self->log->trace( <<"DUMP" );
# _rule_matches wildcard...
############################
pattern         $pattern
pattern_end     $pattern_end
wildcard_pos    $wildcard_pos
DUMP

        if ( $wildcard_pos == $pattern_pos ) {
            $pattern_pos += 1;
            return 1 if $pattern_pos >= $pattern_end;

            my $pattern_piece_end = index( $pattern, '*', $pattern_pos);
            $pattern_piece_end = $pattern_end if $pattern_piece_end == -1;

            my $matched = 0;
            my $pattern_piece_len = $pattern_piece_end - $pattern_pos;
            while ( ( $text_pos + $pattern_piece_len <=  $text_end )
                    && !$matched ) {

                $matched = 1;

                for ( my $i = 0; $i < $pattern_piece_len && $matched; $i++ ) {
                    $matched = 0
                      if substr( $text, $text_pos + $i, 1 ) ne
                        substr( $pattern, $pattern_pos + $i, 1 );
                }

                $text_pos += 1 unless $matched;
            }

            return 0 unless $matched;
        }

        else {
            while ( ( $pattern_pos < $wildcard_pos ) &&
                    ( $text_pos < $text_end ) ) {

                $self->log->trace( <<"DUMP" );
# _rule_matches dump
#####################
text        $text
text_pos    $text_pos
pattern     $pattern
pattern_pos $pattern_pos
DUMP
                return 0 if substr( $text, $text_pos++, 1) ne
                  substr( $pattern, $pattern_pos++, 1);
            }
        }
    }

    while ( ( $pattern_pos < $pattern_end ) &&
            ( substr( $pattern, $pattern_pos, 1 ) eq '*' ) ) {
        $pattern_pos++;
    }

    return ( $pattern_pos == $pattern_end ) &&
        ( ( $text_pos == $text_end ) || !$contains_end_char ) ? 1 : 0;
}
#-----------------------------------------------------------------------------#
###############################################################################

__PACKAGE__->meta->make_immutable;

###############################################################################

=pod


=cut

###############################################################################
package CrawlerCommons::RobotRule;

# MODULE IMPORTS
########################################
# Pragmas
#------------------#
use 5.10.1;
use strict;
use utf8;
use warnings;

# CPAN/Core
#------------------#
use Const::Fast;
use Try::Tiny;

# Moose Setup
#------------------#
use Moose;
use namespace::autoclean;

# Moose Pragmas
#------------------#

# Custom Modules
#------------------#



# VARIABLES/CONSTANTS
########################################
# Debug Constants
#------------------#

# Constants
#------------------#

# Variables
#------------------#

# ATTRIBUTES
########################################
# Class
#------------------#
#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------------#

# Instance
#------------------#
#-----------------------------------------------------------------------------#
has '_allow'                    => (
    is                          => 'ro',
    isa                         => 'Bool',
    required                    => 1,
);
#-----------------------------------------------------------------------------#
has '_prefix'                   => (
    is                          => 'ro',
    isa                         => 'Str',
);
#-----------------------------------------------------------------------------#

# METHODS
########################################
# Constructor
#------------------#
#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------------#

# Class Methods
#------------------#
#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------------#

# Instance Methods
#------------------#
#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------------#

# Private Methods
#------------------#
#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------------#
###############################################################################

__PACKAGE__->meta->make_immutable;

###############################################################################

=head1 AUTHOR

Adam Robinson <akrobinson74@gmail.com>

=cut

1;

__END__