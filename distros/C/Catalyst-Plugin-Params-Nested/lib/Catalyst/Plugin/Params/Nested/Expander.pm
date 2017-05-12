package Catalyst::Plugin::Params::Nested::Expander;
use base qw/CGI::Expand/;

use strict;
use warnings;

sub split_name {
    my ( $class, $name ) = @_;

    if ( $name =~ /^ .*? \[ \S+ \]/x ) {
        return grep { defined } ( $name =~ /
          ^  (\w+)      # root param
          | \[ (\w+) \] # nested
        /gx );
    } else {
        return $class->SUPER::split_name( $name );
    }
}


__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Params::Nested::Expander - CGI::Expand subclass with rails
like tokenization.

=cut

