###############################################################################
package CrawlerCommons::RobotDirective;

# MODULE IMPORTS
########################################
# Pragmas
#------------------#

# CPAN/Core
#------------------#
use Const::Fast;

# Moose Setup
#------------------#

# Moose Pragmas
#------------------#
use Moose;
use MooseX::ClassAttribute;
use namespace::autoclean;

# Custom Modules
#------------------#


# VARIABLES/CONSTANTS
########################################
# Constants
#------------------#
const my $DEBUG                 => $ENV{DEBUG} // 0;
const my $TEST                  => $ENV{TEST} // 1;

const my $CRAWLDELAY_MISSPELLINGS=>["crawl delay"];
const my $DISALLOW_MISSPELLINGS => [qw(desallow dissalow dssalow dsallow)];
const my $DIRECTIVES_LIST       => [
    'USER_AGENT', 'DISALLOW',
    'ALLOW', 'CRAWL_DELAY', 'SITEMAP',
    'HOST',
    'NO_INDEX',
    # Extended standard
    'REQUEST_RATE', 'VISIT_TIME', 'ROBOT_VERSION', 'COMMENT',
    # Treated as sitemap directive
    'HTTP'];
const my $PREFIX_DIRECTIVES     => [qw(ACAP_)];
const my $SPECIAL_DIRECTIVES    => [qw(UNKNOWN MISSING)];
const my $USERAGENT_MISSPELLINGS=> [qw(useragent useg-agent ser-agent)];
const my $VALUES_ENUM_LIST      =>
  [ map {my $v = lc( $_ ); $v =~ s/\_$//; $v;}
    map { @{ $_ } }
    ( $DIRECTIVES_LIST, $PREFIX_DIRECTIVES, $SPECIAL_DIRECTIVES ) ];

# Variables
#------------------#
our $VERSION = '0.03';


# MOOSE ATTRIBUTES
########################################
# Class
#-----------------------------------------------------------------------------#
class_has 'directive_map'       => (
    builder                     => 'load_directives_map',
    handles                     => {
        directive_exists        => 'exists',
        get_directive           => 'get',
    },
    is                          => 'ro',
    isa                         => 'HashRef',
    lazy                        => 1,
    traits                      => ['Hash'],
);
#-----------------------------------------------------------------------------#

# Instance
#-----------------------------------------------------------------------------#
has 'is_prefix'                 => (
    default                     => 0,
    is                          => 'ro',
    isa                         => 'Bool',
);
#-----------------------------------------------------------------------------#
has 'is_special'                => (
    default                     => 0,
    is                          => 'ro',
    isa                         => 'Bool',
);
#-----------------------------------------------------------------------------#
has 'value'                      => (
    enum                        => $VALUES_ENUM_LIST,
    handles                     => 1,
    is                          => 'ro',
    required                    => 1,
    traits                      => ['Enumeration'],
);
#-----------------------------------------------------------------------------#

# METHODS
########################################
# Construction
#------------------#
#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------------#

# Class Methods
#------------------#
#-----------------------------------------------------------------------------#
sub load_directives_map {
    my $pkg = shift;

    my $map = {
        $pkg->_map_directive_list( $DIRECTIVES_LIST, 0, 0),
        $pkg->_map_directive_list( $PREFIX_DIRECTIVES, 1, 0),
        $pkg->_map_directive_list( $SPECIAL_DIRECTIVES, 0, 1),
    };

    # setup common user_agent, disallow and crawl_delya directive misspellings
    $map->{$_} = $map->{'crawl-delay'} for @{ $CRAWLDELAY_MISSPELLINGS };
    $map->{$_} = $map->{disallow} for @{ $DISALLOW_MISSPELLINGS };
    $map->{$_} = $map->{'user-agent'} for @{ $USERAGENT_MISSPELLINGS };

    return $map;
}
#-----------------------------------------------------------------------------#

# Instance Methods
#------------------#
#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------------#

# Private Methods
#------------------#
#-----------------------------------------------------------------------------#
sub _map_directive_list {
    my ($pkg, $directives_list, $is_prefix, $is_special) = @_;
    my %map = ();

    for my $directive_str ( @{ $directives_list } ) {
        (my $prefix = lc($directive_str)) =~ s!_!\-!g;
        (my $value = lc( $directive_str )) =~ s!_$!!g;
        $map{$prefix} = $is_prefix ?
          $pkg->new(value => $value, is_prefix => 1) :
            ($is_special ?
              $pkg->new(value => $value, is_special => 1) :
              $pkg->new(value => $value) );
    }

    return %map;
}
#-----------------------------------------------------------------------------#

###############################################################################

__PACKAGE__->meta->make_immutable;

###############################################################################

1;

__END__