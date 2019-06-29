package App::TeleGramma::Constants;
$App::TeleGramma::Constants::VERSION = '0.14';
# ABSTRACT: Constants for TeleGramma

use strict;
use warnings;

use Exporter qw/import/;

use constant {
  PLUGIN_NO_RESPONSE      => 'NO_RESPONSE',
  PLUGIN_NO_RESPONSE_LAST => 'NO_RESPONSE_LAST',
  PLUGIN_RESPONDED        => 'RESPONDED',
  PLUGIN_RESPONDED_LAST   => 'RESPONDED_LAST',
  PLUGIN_DECLINED         => 'PLUGIN_DECLINED',
};

our @EXPORT_OK = qw/
  PLUGIN_NO_RESPONSE
  PLUGIN_NO_RESPONSE_LAST
  PLUGIN_RESPONDED
  PLUGIN_RESPONDED_LAST
  PLUGIN_DECLINED
/;
our %EXPORT_TAGS = (const => \@EXPORT_OK);

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TeleGramma::Constants - Constants for TeleGramma

=head1 VERSION

version 0.14

=head1 AUTHOR

Justin Hawkins <justin@hawkins.id.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Justin Hawkins <justin@eatmorecode.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
