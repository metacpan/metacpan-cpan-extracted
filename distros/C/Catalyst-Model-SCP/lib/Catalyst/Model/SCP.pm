package Catalyst::Model::SCP;

use 5.006;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';

use MooseX::Types::Moose qw/ Str Bool HashRef /;
use File::Temp qw/tempfile/;
use Net::SCP::Expect;
use Moose::Util::TypeConstraints;

subtype 'IdentityFile'
  => as 'Str'
  => where { -f $_ }
  => message { 'Invalid identity_file specified.' };

=head1 NAME

Catalyst::Model::SCP - SCP model class for Catalyst

=head1 DESCRIPTION

This module is really only a layer between Catalyst::Model and Net::SCP::Expect. Which help catalyst application to upload files using SCP.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    package TestApp;

    use strict;
    use warnings;

    use Catalyst;

    __PACKAGE__->config( 'Model::MYSCP' => {
            host => '1.2.3.4',
            user => 'user',
            identity_file => '/home/user/.ssh/id_rsa',
            net_scp_options => {
                # Net::SCP::Expect options
            }
       }
    );

    1;

Create your model class

    package TestApp::Model::MYSCP;

    use 5.006;
    use strict;
    use warnings;

    use parent 'Catalyst::Model::SCP';

    1;

In your catalyst application

    my $scp_client = $c->model('MYSCP');

    my $success = $scp_client->is_connection_success;
    warn 'SCP connection is good.' if $success;

    my $success = $scp_client->put_file('local_file.txt','destination.txt');
    warn 'File uploaded successfully' if $success;

    my $success = $scp_client->download_file('destination.txt','local_file.txt');
    warn 'File downloaded successfully' if $success;

=cut

has host => (
    isa => 'Str',
    is => 'ro',
    required => 1,
);

has user => (
    isa => 'Str',
    is => 'ro',
    required => 1,
);

has identity_file => (
    isa => 'IdentityFile',
    is => 'ro',
    required => 1,
);

has net_scp_options => (
    isa => 'HashRef',
    is => 'ro',
    default => sub {
        return {};
    }
);

has net_scp => (
    isa => 'Net::SCP::Expect',
    is => 'ro',
    lazy_build => 1,
);
sub _build_net_scp {
    my $self = shift;
    my $other_options = $self->net_scp_options;
    my %default_options = (
        'host' => $self->host,
        'user' => $self->user,
        'identity_file' => $self->identity_file,
        'auto_yes' => 1
    );
    my %options = (%{$other_options}, %default_options);
    return Net::SCP::Expect->new(%options);
}

=head1 SUBROUTINES/METHODS

=head2 is_connection_success

C<is_connection_success()> - Returns true when it able to make connection using specified credentials.

=cut

has is_connection_success => (
    isa => 'Bool',
    is => 'ro',
    lazy_build => 1
);
sub _build_is_connection_success {
    my $self = shift;
    my ($fh, $filename) = tempfile();
    my $status = $self->put_file( $filename, '/home/'.$self->user.'/scp_connection_test' );
    return $status;
}

=head2 put_file

C<put_file(LOCALFILE, REMOTEPATH)> - Transfer local file to the remote path.
                 Local file should have absolute path.
                 Remote file is the location on the remote server, no need to specify username, like normal scp.

=cut

sub put_file {
    my( $self, $file, $destination ) = @_;
    if ( not -f $file ){
        warn "$file does not exist";
        return 0;
    }
    my $scp_client = $self->net_scp;
    my $status = 0;
    eval {
        $status = $scp_client->scp($file,$destination);
    };
    if ($@) {
        warn $@;
    }
    return $status;
}

=head2 download_file

C<download_file(REMOTEFILE, LOCALPATH)> - Download remote file to local path.
                 Local file should have absolute path.
                 Remote file is the location on the remote server, no need to specify username, like normal scp.

=cut

sub download_file {
    my( $self, $destination, $file ) = @_;
    if ( not -e $file ){
        warn "$file does not exist";
        return 0;
    }
    my $scp_client = $self->net_scp;
    my $status = 0;
    eval {
        my $destination_string = $self->user . '@' . $self->host .':'. $destination;
        $status = $scp_client->scp($destination_string,$file);
    };
    if ($@) {
        warn $@;
    }
    return $status;
}

=head1 AUTHOR

Rakesh Kumar Shardiwal, C<< <rakesh.shardiwal at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-model-scp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Model-SCP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Model::SCP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Model-SCP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Model-SCP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Model-SCP>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Model-SCP/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Rakesh Kumar Shardiwal.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Catalyst::Model::SCP
