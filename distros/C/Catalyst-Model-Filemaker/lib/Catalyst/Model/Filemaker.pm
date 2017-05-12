package Catalyst::Model::Filemaker;

use strict;
use warnings;

use base qw/ Catalyst::Model /;

use Carp qw( croak );
use Catalyst::Utils ();
use Net::FileMaker::XML::ResultSet;

our $VERSION = '0.01';

=head1 NAME

Catalyst::Model::Filemaker - Catalyst model for Filemaker's XML services


=head1 SYNOPSIS

    # Use the helper to add a L<Net::FileMaker::XML> model to your application
    script/myapp_create.pl create model Filemaker Filemaker host=myhost \ 
    user=myuser pass=mypassword db=mydb 
    
    or
    
    # lib/MyApp/Model/Filemaker.pm
    
    package MyApp::Model::Filemaker;
    
    use base qw/ Catalyst::Model::Filemaker /;
    
    __PACKAGE__->config(
        host    => 'myhostname',
        user    => 'myusername',
        pass    => 'mypassword',
        db      => 'mydb.fpX'
    );
    
    1;
    
    
    # In a controller...
    my $fm = $c->model('Filemaker');
    print ref($fm);  # Net::FileMaker::XML


=head1 DESCRIPTION

This is a L<Catalyst> model that interfaces with Filemaker's XML service. 
See the L<Net::FileMaker::XML> documentation for a description of the
methods available.


=head1 METHODS

=head2 ->new()

Instantiate a new L<Net::FileMaker::XML> Model. See L<Net::FileMaker::XML's 
new method|Net::FileMaker::XML/new> for the options available.

=cut

sub new {
	my $self  = shift->next::method(@_);
	my $class = ref($self);

	my ( $c, $arg_ref ) = @_;

	# check configuration
	croak "->config->{host} must be set for $class\n"
	  unless $self->{host};
	croak "->config->{user} must be set for $class\n"
	  unless $self->{user};
	croak "->config->{pass} must be set for $class\n"
	  unless $self->{pass};
	croak "->config->{db} must be set for $class\n"
	  unless $self->{db};

	my $fms = Net::FileMaker::XML->new( host => $self->{host} );

	my $fmdb = $fms->database(
		db   => $self->{db},
		user => $self->{user},
		pass => $self->{pass}
	);

	# Instantiating a Net::FileMaker::XML obj
	$self->{'fm'} = $fmdb;

	return $self;
}

=head2 ACCEPT_CONTEXT

Return the L<Net::FileMaker::XML> object. Called automatically via
C<$c-E<gt>model('Filemaker');>

=cut

sub ACCEPT_CONTEXT {
	return shift->{'fm'};
}

1;    # End of the module code; everything from here is documentation...
__END__

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Helper::Model::Filemaker>, L<Net::FileMaker::XML>


=head1 DEPENDENCIES

=over

=item

L<Carp>

=item

L<Catalyst::Model>

=item

L<Catalyst::Utils>

=item

L<Net::FileMaker::XML::ResultSet>

=back


=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-model-filemaker at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Model-Filemaker>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Model::Filemaker

You may also look for information at:

=over 4

=item * Catalyst::Model::Filemaker

L<https://github.com/micheleo/Catalyst--Model--Filemaker>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Model-Filemaker/>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Model-Filemaker>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Model-Filemaker/>

=back


=head1 AUTHOR

 <micheleo@cpan.org>


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011 Michele Ongaro. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.


=cut
