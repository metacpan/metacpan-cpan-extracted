package Apache2::Controller::Test::Mockr;

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use Carp qw( cluck confess );

use Apache2::Controller::Test::UnitConf;

use Log::Log4perl qw(:easy);
Log::Log4perl->init(\$L4P_UNIT_CONF);

use YAML::Syck;

our $AUTOLOAD;

sub new { 
    my $class = shift; 
    my $self = { @_ };
    bless $self, $class;
    DEBUG(Dump($self));
    DEBUG($L4P_UNIT_CONF);
    return $self;
}

sub AUTOLOAD { 
    my ($self, $value) = @_;
    my $pkg = __PACKAGE__;
    my $key = substr $AUTOLOAD, length($pkg) + 2;
    return if $key eq 'DESTROY';
    DEBUG("$AUTOLOAD => '$key'");
    if (defined $value) {
        DEBUG("setting value '$value'");
        $self->{$key} = $value;
    }
    DEBUG("mockr->{$key} = ".($self->{$key} || '[none]'));
    return $self->{$key}; 
}

sub notes {
    my ($self) = @_;
    $self->{notes}  ||= { };
    return $self->{notes};
}

sub pnotes {
    my ($self) = @_;
    $self->{pnotes} ||= { };
    return $self->{pnotes};
}

1;

