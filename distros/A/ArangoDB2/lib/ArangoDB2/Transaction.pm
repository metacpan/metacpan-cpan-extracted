package ArangoDB2::Transaction;

use strict;
use warnings;

use base qw(
    ArangoDB2::Base
);

use Data::Dumper;
use JSON::XS;

my $JSON = JSON::XS->new->utf8;



# action
#
# get/set action
sub action { shift->_get_set('action', @_) }

# collections
#
# get/set collections
sub collections { shift->_get_set('collections', @_) }

sub execute
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, [qw(
        action collections lockTimeout params waitForSync
    )]);

    return $self->arango->http->post(
        $self->api_path('transaction'),
        undef,
        $JSON->encode($args),
    );
}

# lockTimeout
#
# get/set lockTimeout
sub lockTimeout { shift->_get_set('lockTimeout', @_) }

# params
#
# get/set params
sub params { shift->_get_set('params', @_) }

# waitForSync
#
# get/set waitForSync value
sub waitForSync { shift->_get_set_bool('waitForSync', @_) }

1;

__END__

=head1 NAME

ArangoDB2::Transaction - ArangoDB transaction API methods

=head1 METHODS

=over 4

=item new

=item action

=item collections

=item execute

=item lockTimeout

=item params

=item waitForSync

=back

=head1 AUTHOR

Ersun Warncke, C<< <ersun.warncke at outlook.com> >>

http://ersun.warnckes.com

=head1 COPYRIGHT

Copyright (C) 2014 Ersun Warncke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
