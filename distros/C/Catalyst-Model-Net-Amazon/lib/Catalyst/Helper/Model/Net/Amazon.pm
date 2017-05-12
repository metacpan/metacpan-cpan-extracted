package Catalyst::Helper::Model::Net::Amazon;

use strict;
use warnings;

use Carp qw/ croak /;

our $VERSION = '0.01001';

sub mk_compclass {
    my ( $self, $helper, $token ) = @_;
    
    $helper->{token} = $token;
    
    $helper->render_file( 'net_amazon_class', $helper->{file} );
}

1;

=head1 NAME

Catalyst::Helper::Model::Net::Amazon - Helper for Net::Amazon Catalyst models


=head1 SYNOPSIS

    script/myapp_create.pl model ModelName Net::Amazon amazon_secret_token

=head1 DESCRIPTION

Use this module to set up a new L<Catalyst::Model::Net::Amazon> model for 
your Catalyst application.

=head2 Arguments

C<ModelName> is the short name for the Model class being generated (eg. 
C<Net::Amazon>)

C<token> is your Amazon Web Services account's Access Key. For more 
information see: L<http://aws.amazon.com/s3>

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Helper>, L<Catalyst::Model::Net::Amazon>

=head1 BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Model-Net-Amazon>.

=head1 AUTHOR

Carl Franks, C<cfranks@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Carl Franks

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

__DATA__
=begin pod_to_ignore

__net_amazon_class__
package [% class %];

use strict;
use warnings;

use base qw/ Catalyst::Model::Net::Amazon /;
[% IF token %]
__PACKAGE__->config(
    token => '[% token %]',
);
[% END %]
=head1 NAME

[% class %] - S3 Model Class


=head1 SYNOPSIS

See L<[% app %]>.

=head1 DESCRIPTION

Net::Amazon Model Class.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

=cut

1;
