use strict;
use warnings;
package AI::PredictionClient::Predict;
$AI::PredictionClient::Predict::VERSION = '0.01';

# ABSTRACT: The Predict service client

use Moo;
with 'AI::PredictionClient::Roles::PredictionRole',
  'AI::PredictionClient::Roles::PredictRole';
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::PredictionClient::Predict - The Predict service client

=head1 VERSION

version 0.01

=head1 AUTHOR

Tom Stall <stall@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Tom Stall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
