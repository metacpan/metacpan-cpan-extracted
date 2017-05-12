package App::Goto::Amazon;

use strict;
use warnings;
use v5.10;
our $VERSION = '0.01';

use Moo;
use App::Goto;
use Data::Dumper;
use Config::Tiny;
use Net::Amazon::EC2;

has ec2 => ( is => 'rw' );
has name => ( is => 'ro' );
has domain => ( is => 'rw', default => '' );
has instances => ( is => 'rw', default => sub { [] } );

sub BUILD {
    my $self = shift;

    # Connect to EC2
    $self->ec2( Net::Amazon::EC2->new($self->ec2_params) );

    # Get all instances
    my $reservations = $self->ec2->describe_instances;
    foreach my $reservation (@$reservations) {
       foreach my $instance ($reservation->instances_set) {
           # Ensure only running instances
           next unless $instance->instance_state->name eq 'running';
           push @{ $self->instances }, $instance->name;
           }
        }

    # Exit with a list of hosts if no name specified
    my $name = $self->name;
    unless ($name) {
        say join "\n", sort @{$self->instances};
        exit;
        }
    # We have all we need. Let's goto!
    my $goto = App::Goto->new({ args => [qr/$name/], config => $self->config });
    my $cmd = $goto->cmd;
    $cmd =~ s/\s+$//;
    exec ( $cmd . $self->domain ) if $goto->cmd;
    print "No valid host found for given arguments\n";
    }

sub config {
    my $self = shift;
    my %hosts;
    map { $hosts{$_} = $_ } @{ $self->instances };
    my $hosts = { hosts => \%hosts };
    return $hosts;
    }

sub ec2_params {
    my $self = shift;
    my $cfg = Config::Tiny->read($ENV{HOME}.'/.ssa');

    $self->domain( $cfg->{_}->{domain} ) if  $cfg->{_}->{domain};
    map { $_ => $cfg->{_}->{$_} } qw/AWSAccessKeyId SecretAccessKey region/;
}


1;
__END__

=encoding utf-8

=head1 NAME

App::Goto::Amazon - Shorthand way of ssh'ing to AWS EC2 servers

=head1 SYNOPSIS

  use App::Goto::Amazon;

=head1 DESCRIPTION

App::Goto::Amazon is called by the included 'ssa' script. If no arguments are supplied,
ssa will simply print a list of running EC2 instances. If arguments are supplied, then
the script will look for an instance whose name matches all supplied arguments (in order)
and, if it finds one, will ssh to it. If the arguments are ambiguous, the first match will
be used

Requires your Amazon keys in a ~/.ssa file - see ssa.example file for template

=head1 AUTHOR

Dominic Humphries E<lt>dominic@oneandoneis2.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Dominic Humphries

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
