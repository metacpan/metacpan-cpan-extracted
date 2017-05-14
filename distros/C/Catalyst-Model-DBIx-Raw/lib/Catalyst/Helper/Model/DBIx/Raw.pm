package Catalyst::Helper::Model::DBIx::Raw;
use strict;
 
#ABSTRACT: Helper for DBIx::Raw Model


sub mk_compclass {
  my ($self, $helper) = @_;
  my $file = $helper->{file};
  $helper->render_file('compclass', $file);
}
 
 
1;

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Helper::Model::DBIx::Raw - Helper for DBIx::Raw Model

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  script/myapp_create.pl model Raw DBIx::Raw

=head1 DESCRIPTION

Helper for DBIx::Raw model

=head1 METHODS

=head2 mk_compclass

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>, L<Catalyst::Model::DBIx::Raw>

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
=begin pod_to_ignore
 
__compclass__
package [% class %];
 
use strict;
use warnings;
 
use base qw/Catalyst::Model::DBIx::Raw/;
 
# 3-token (Signature) authentication
__PACKAGE__->config(
	dsn => 'dsn',
	user => 'user',
	password => 'password',
	conf => '/path/to/conf.pl',
	dbix_class_model => 'DB',
);
 
=head1 NAME
 
[% class %] - Catalyst DBIx::Raw Model for [% app %]
 
=head1 SYNOPSIS
 
See L<[% app %]>
 
=head1 DESCRIPTION
 
Catalyst DBIx::Raw Model for [% app %]
 
=head1 AUTHOR
 
[% author %]
 
=head1 LICENSE
 
This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.
 
=cut
 
1;
