package Catalyst::Model::Akismet;

use Carp qw( croak );
use Catalyst::Utils ();
use Net::Akismet::Protocol ();
use MRO::Compat;
use Moose;
extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';
no Moose;

our $VERSION = '0.04';


=head1 NAME

Catalyst::Model::Akismet - Catalyst model for the Akismet anti-spam protocol

=head1 SYNOPSIS

    # Use the helper to add an Akismet model to your application...
    script/myapp_create.pl model Akismet Akismet


    # lib/MyApp/Model/Akismet.pm

    package MyApp::Model::Akismet;

    use base qw/ Catalyst::Model::Akismet /;

    __PACKAGE__->config(
        url => 'http://yourblog.com',
        key => 'SECRET',
        host => 'rest.akismet.com'
      );

    1;


    # In a controller...
    my $akismet = $c->model('Akismet');
    print ref($akismet);  # Net::Amazon::Akismet


=head1 DESCRIPTION

This is a L<Catalyst> model class that interfaces with the Akismet anti-
spam protocol. By default it will connect to typepad's antispam service.

=head1 METHODS

=head2 ->new()

Instantiate a new L<Net::Amazon::Akismet> Model. See
L<Net::Akismet::Protocols's new method|Net::Akismet::Protocol/new> for the options available.


=head2 check

Check if a comment is spam. Sets user_ip, user_agent and referer and proxies to 
L<Net::Akismet::Protocol>'s check method. See that method for more info about parameters.

=cut

sub new {
    my $self  = shift->next::method(@_);
    my $class = ref($self);
    
    my ( $c, $arg_ref ) = @_;
    
    # Ensure that the required configuration is available...
    croak "->config->{key} must be set for $class\n"
        unless $self->{key};
    croak "->config->{url} must be set for $class\n"
        unless $self->{url};
    
    # Instantiate a new Akismet object...
    $self->{'akismet'} = Net::Akismet::Protocol->new(
        Catalyst::Utils::merge_hashes( $arg_ref, $self->config )
    );
    
    return $self;
}


sub check {
    my ($self,%params)=@_;
    return $self->{akismet}->check(
        %params,%{$self->{params}} )
}

sub akismet {
    my $self=shift;
    return $self->{akismet};
}

sub build_per_context_instance {
my ($self, $c) = @_;

   return $self unless ref $c;
   $self->{params}= {
        user_ip 		=> $c->req->address,
		user_agent 		=> $c->req->user_agent,
		referer		=> $c->req->referer,
   };
   
   return $self;
}

1; # End of the module code; everything from here is documentation...
__END__

=head2 build_per_context_instance

=head2 akismet

Access the L<Net::Akismet::Protocol> object directly.

Gets info about user. Called by Catalyst automatically.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Helper::Model::Akismet>, L<Net::Akismet::Protocol>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-model-akismet at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Model-Akismet>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Model::Akismet

You may also look for information at:

=over 4

=item * Catalyst::Model::Akismet

L<http://perlprogrammer.co.uk/modules/Catalyst::Model::S3/>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Model-Akismet/>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Model-Akismet>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Model-Akismet/>

=back


=head1 AUTHOR

Marcus Ramberg <mramberg@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008 Marcus Ramberg.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.


=cut
