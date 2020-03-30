package DBIx::Class::Helper::Schema::QuoteNames;
$DBIx::Class::Helper::Schema::QuoteNames::VERSION = '2.036000';
# ABSTRACT: force C<quote_names> on

use strict;
use warnings;

use parent 'DBIx::Class::Schema';

use DBIx::Class::Helpers::Util 'normalize_connect_info';

sub connection {
   my $self = shift;

   my $args = normalize_connect_info(@_);
   $args->{quote_names} = 1;

   $self->next::method($args)
}

1;

__END__

=pod

=head1 NAME

DBIx::Class::Helper::Schema::QuoteNames - force C<quote_names> on

=head1 SYNOPSIS

 package MyApp::Schema;

 __PACKAGE__->load_components('Helper::Schema::QuoteNames');

=head1 DESCRIPTION

This helper merely forces C<quote_names> on, no matter how your settings are
configured.  You should use it.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
