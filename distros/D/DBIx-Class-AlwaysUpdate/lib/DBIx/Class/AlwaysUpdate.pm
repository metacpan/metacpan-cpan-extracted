package DBIx::Class::AlwaysUpdate;
BEGIN {
  $DBIx::Class::AlwaysUpdate::AUTHORITY = 'cpan:GETTY';
}
BEGIN {
  $DBIx::Class::AlwaysUpdate::VERSION = '0.001';
}
# ABSTRACT: Always update the result on ->update, independent of changes
use strict;
use warnings;
use base 'DBIx::Class::Core';

sub is_changed { 1 };
sub is_column_changed { 1 };
sub get_dirty_columns { shift->get_columns }

1;


__END__
=pod

=head1 NAME

DBIx::Class::AlwaysUpdate - Always update the result on ->update, independent of changes

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  package MyApp::Schema::Result::CD;
  
  __PACKAGE__->load_components( qw( AlwaysUpdate ) );

=head1 DESCRIPTION

This little helper will bring your result to always update all of its row, regardless of the change state or if its dirty or not. Its a very simple hack that overloads all functions which are required to identify if the data has changed. Be aware that this also means that you are unable to detect for yourself, if there was made a change.

=head1 SUPPORT

IRC

  Join #dbix-class on irc.perl.org and ask for Getty.

Repository

  http://github.com/Getty/p5-dbix-class-alwaysupdate
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-dbix-class-alwaysupdate/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us> L<http://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Raudssus Social Software.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

