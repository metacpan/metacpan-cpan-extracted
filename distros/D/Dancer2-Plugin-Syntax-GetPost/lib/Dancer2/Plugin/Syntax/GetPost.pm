use 5.008001;
use strict;
use warnings;

package Dancer2::Plugin::Syntax::GetPost;
# ABSTRACT: Syntactic sugar for GET+POST handlers
our $VERSION = '0.002'; # VERSION

use Dancer2::Plugin;

register get_post => sub {
  my ( $dsl, @args ) = @_;
  $dsl->any( [qw/get post/] => @args );
};

register_plugin for_versions => [ 2 ];

1;


# vim: ts=2 sts=2 sw=2 et:

__END__

=pod

=head1 NAME

Dancer2::Plugin::Syntax::GetPost - Syntactic sugar for GET+POST handlers

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Dancer2::Plugin::Syntax::GetPost;

  get_post '/myform' => sub { ... };

=head1 DESCRIPTION

This module provides very simple syntactic sugar to define a handler for GET and
POST requests.  Instead of writing this:

  any [qw/get post/] => '/form' => sub { ... };

You can write just this:

  get_post '/form' => sub { ... };

=for Pod::Coverage method_names_here

=head1 SEE ALSO

=over 4

=item *

L<Dancer2>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/dancer2-plugin-syntax-getpost/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/dancer2-plugin-syntax-getpost>

  git clone git://github.com/dagolden/dancer2-plugin-syntax-getpost.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
