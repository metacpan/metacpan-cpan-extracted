package AI::Evolve::Befunge::Util::Config;

use strict;
use warnings;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors( qw(hash host gen physics) );


=head1 NAME

    AI::Evolve::Befunge::Util::Config - config database object


=head2 SYNOPSIS

    use AI::Evolve::Befunge::Util;
    my $config = custom_config(host => 'test', physics => 'ttt', gen => 1024);
    my $value = $config->config('value', 'default');


=head2 DESCRIPTION

This is a config object.  The config file allows overrides based on
hostname, physics engine in use, and AI generation.  Thus, the config
file data needs to be re-assessed every time one of these (usually
just the generation) is changed.  The result of this is a Config
object, which is what this module implements.


=head1 CONSTRUCTOR

=head2 custom_config

This module does not actually implement the constructor - please see
custom_config() in L<AI::Evolve::Befunge::Util> for the details.


=head1 METHODS

=head2 config

    my $value = global_config('name');
    my $value = global_config('name', 'default');
    my @list  = global_config('name', 'default');
    my @list  = global_config('name', ['default1', 'default2']);

Fetch some data from the config object.

=cut

sub config {
    my ($self, $keyword, $value) = @_;
    $value = $$self{hash}{$keyword}
        if exists $$self{hash}{$keyword};

    if(wantarray()) {
        return @$value if ref($value) eq 'ARRAY';
        if(!defined($value)) {
            return () if scalar @_ == 2;
            return (undef);
        }
    }
    return $value;
}

1;
