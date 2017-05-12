package Catalyst::Model::S3;

use strict;
use warnings;

use base qw/ Catalyst::Model /;

use Carp qw( croak );
use Catalyst::Utils ();
use Class::C3 ();
use Net::Amazon::S3 ();

our $VERSION = '0.03';


=head1 NAME

Catalyst::Model::S3 - Catalyst model for Amazon's S3 web service


=head1 SYNOPSIS

    # Use the helper to add an S3 model to your application...
    script/myapp_create.pl create model S3 S3
    
    
    # lib/MyApp/Model/S3.pm
    
    package MyApp::Model::S3;
    
    use base qw/ Catalyst::Model::S3 /;
    
    __PACKAGE__->config(
        aws_access_key_id     => 'your_access_key_id',
        aws_secret_access_key => 'your_secret_access_key',
        secure                => 0,  # optional: default 0  (false)
        timeout               => 30, # optional: default 30 (seconds)
    );
    
    1;
    
    
    # In a controller...
    my $s3 = $c->model('S3');
    print ref($s3);  # Net::Amazon::S3


=head1 DESCRIPTION

This is a L<Catalyst> model class that interfaces with Amazon's Simple Storage
Service. See the L<Net::Amazon::S3> documentation for a description of the
methods available. For more on S3 visit: L<http://aws.amazon.com/s3>


=head1 METHODS

=head2 ->new()

Instantiate a new L<Net::Amazon::S3> Model. See
L<Net::Amazon::S3's new method|Net::Amazon::S3/new> for the options available.

=cut

sub new {
    my $self  = shift->next::method(@_);
    my $class = ref($self);
    
    my ( $c, $arg_ref ) = @_;
    
    # Ensure that the required configuration is available...
    croak "->config->{aws_access_key_id} must be set for $class\n"
        unless $self->{aws_access_key_id};
    croak "->config->{aws_secret_access_key} must be set for $class\n"
        unless $self->{aws_secret_access_key};
    
    # Instantiate a new S3 object...
    $self->{'.s3'} = Net::Amazon::S3->new(
        Catalyst::Utils::merge_hashes( $arg_ref, $self->config )
    );
    
    return $self;
}


=head2 ACCEPT_CONTEXT

Return the L<Net::Amazon::S3> object. Called automatically via
C<$c-E<gt>model('S3');>

=cut

sub ACCEPT_CONTEXT {
    return shift->{'.s3'};
}


1; # End of the module code; everything from here is documentation...
__END__

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Helper::Model::S3>, L<Net::Amazon::S3>


=head1 DEPENDENCIES

=over

=item

L<Carp>

=item

L<Catalyst::Model>

=item

L<Catalyst::Utils>

=item

L<Class::C3>

=item

L<Net::Amazon::Simple>

=back


=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-model-s3 at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Model-S3>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Model::S3

You may also look for information at:

=over 4

=item * Catalyst::Model::S3

L<http://perlprogrammer.co.uk/modules/Catalyst::Model::S3/>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Model-S3/>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Model-S3>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Model-S3/>

=back


=head1 AUTHOR

Dave Cardwell <dcardwell@cpan.org>


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Dave Cardwell. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.


=cut
