package BabelObjects::Util::Dvlpt::Log;

use Carp;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
);
$VERSION = '1.00';

my %fields = (
    file => 'STDERR',
    debug => 1
);

sub new {
    my $proto = shift;
    my $args = shift;

    my $class = ref($proto) || $proto;

    my $self  = {
        _permitted => \%fields,
        %fields,
    };

    bless ($self, $class);

    if ($args) {
        my %parameters = %$args;
        foreach (keys %parameters) {
            # the following lines are useful to verify argument values
            #print STDERR "$_ = ", $parameters{$_}, "\n";
            #print STDERR "$_ = ", $self->$_, "\n";
            $self->$_($parameters{$_});
        }
    }

    return $self;
}

sub log {
    my $self = shift;
    my $msg = shift;

    if ($self->debug == 1) {
        print STDERR $msg."\n";
    } 
}

sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self) or croak "$self is not an object";

    my $name = $AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion

    unless (exists $self->{_permitted}->{$name} ) {
        croak "Can't access `$name' field in class $type";
    }

    if (@_) {
        return $self->{$name} = shift;
    } else {
        return $self->{$name};
    }
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

BabelObjects::Util::Dvlpt::Log - logs events events in a very simple way.

=head1 SYNOPSIS

  use BabelObjects::Util::Dvlpt::Log;

  $aLog = new BabelObjects::Util::Dvlpt::Log();
  $aLog->log($msg);

  DON'T USE THIS PACKAGE ANYMORE. Use any Perl logger instead.

=head1 DESCRIPTION

  This package is very simple. DON'T USE THIS PACKAGE ANYMORE.
  Use any specialized Perl logger instead.

=head1 AUTHOR

Jean-Christophe Kermagoret, jck@BabelObjects.Org (http://www.BabelObjects.Org)

=head1 SEE ALSO

perl(1).

=cut
