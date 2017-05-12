package Config::PropertiesSequence;

=pod

=head1 NAME

Config::PropertiesSequence -  provides access to sequential properties loaded from properties file.

=head1 USAGE


my $props = Config::PropertiesSequence->new();

$props->load( *FH );

my @multipleSettings = $props->getPropertySequence( $prefix, @names );

returns settings prefixed by $prefix, numbered consecutively and suffixed with values
from @names.

eg when

my $prefix = "test.settings.multi";

my @names = qw(setting1 setting2);

then getPropertySequence will return

(
    {   setting1 => "abc", 
        setting2 => "def"   },
    {   setting1 => "ghi",
        setting2 => "jkl"   }
)

from a properties file containing

test.settings.multi.1.setting1=abc
test.settings.multi.1.setting2=def
test.settings.multi.2.setting1=ghi
test.settings.multi.2.setting2=jkl

=head1 NOTES

see L<Config::Properties>.

=head1 VERSION

$Id: PropertiesSequence.pm,v 1.2 2004/01/31 12:09:35 mark Exp $

=cut



use strict;
use warnings;

use base qw(Config::Properties);

use Carp qw(cluck);
use Carp::Assert;
use Data::Dumper;
use FileHandle;
use Config::Properties;

use constant DEFAULTMAXSEQUENCENUMBER => 100;

our $VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)/g;


BEGIN {
    my $MAXSEQUENCENUMBER = DEFAULTMAXSEQUENCENUMBER;
    sub setMaxSequenceNumber($){
        my $newMaxSequenceNumber = shift;
        $MAXSEQUENCENUMBER = $newMaxSequenceNumber;
    };
    sub getMaxSequenceNumber(){
        return $MAXSEQUENCENUMBER;
    }
};


sub getPropertySequence ($$@) {
    my __PACKAGE__ $self  = shift;
    my $prefix  = shift;
    my @searchFor = @_;

    my @props = ();
    my $ii;
    my $MAXSEQUENCENUMBER = getMaxSequenceNumber();

    for($ii = 1 ; $ii <= $MAXSEQUENCENUMBER ; $ii++ ){
        my %sequence = ();
        foreach my $searchFor(@searchFor){
            my $prop = $self->getProperty( "$prefix.$ii.$searchFor" );
            $sequence{$searchFor} = $prop if defined $prop;
        }
        last unless keys %sequence;
        push @props, \%sequence;
    }
    if($ii == $MAXSEQUENCENUMBER){
        cluck "maximum sequence number ".$MAXSEQUENCENUMBER." reached";
    }
    return @props;
    
}

1;

