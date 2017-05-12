package Catalyst::Helper::Model::Filemaker;

use strict;
use warnings;

use Carp qw( croak );

our $VERSION = '0.01';

=head1 NAME

Catalyst::Helper::Model::Filemaker - Helper for Filemaker Catalyst models


=head1 SYNOPSIS

    script/myapp_create.pl model ModelName Filemaker host=myhost user=myuser \
    pass=mypass db=mydb


=head1 DESCRIPTION

Use this module to set up a new L<Catalyst::Model::Filemaker> model for your 
Catalyst application.

=head2 Arguments

    ModelName is the short name for the Model class being generated 
    (eg. "Filemaker")

=head1 METHODS

=head2 mk_compclass

This method takes the given arguments and generates a 
Catalyst::Model::Filemaker model for your application.

=cut

sub mk_compclass {
	my ( $self, $helper, @options ) = @_;

	# Extract the arguments...
	foreach (@options) {
		if (/^host=(.+)$/x) {
			$helper->{host} = $1;
		}
		elsif (/^user=(.+)$/x) {
			$helper->{user} = $1;
		}
		elsif (/^pass=(.+)$/x) {
			$helper->{pass} = $1;
		}
		elsif (/^pass=(.+)$/x) {
			$helper->{db} = $1;
		}
	}

	$helper->{config_encountered} =
	  (      exists $helper->{host}
		  || exists $helper->{user}
		  || exists $helper->{pass}
		  || exists $helper->{db} );

	$helper->render_file( 'filemakerclass', $helper->{file} );
	return;
}

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Helper>, L<Catalyst::Model::Filemaker>


=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-model-filemaker at rt.cpan.org>, or through the web interface 
at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Model-Filemaker>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Helper::Model::Filemaker

You may also look for information at:

=over 4

=item * Catalyst::Model::Filemaker

L<https://github.com/micheleo/Catalyst--Model--Filemaker/>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Model-Filemaker/>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Model-Filemaker>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Model-Filemaker/>

=back


=head1 AUTHOR

Michele Ongaro <micheleo@cpan.org>


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011 Michele Ongaro. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

=cut

1;
__DATA__

=begin pod_to_ignore

__filemakerclass__
package [% class %];

use strict;
use warnings;

use base qw/ Catalyst::Model::Filemaker /;

[%- IF config_encountered %]
__PACKAGE__->config(
    [% "host     => '" _ host    _ "',\n" IF host    -%]
    [% "user => '" _ user _ "',\n" IF user -%]
    [% "pass     => '" _ pass    _ "',\n" IF pass    -%]
    [% "db     => '" _ db    _ "',\n" IF db    -%]    
);
[%- END %]


=head1 NAME

[% class %] - Filemaker Model Class


=head1 SYNOPSIS

See L<[% app %]>.


=head1 DESCRIPTION

Filemaker Model Class.


=head1 AUTHOR

[% author %]


=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

=cut


1;
