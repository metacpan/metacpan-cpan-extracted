package Catalyst::Model::MogileFS::Client;

use strict;
use warnings;

use base qw/Catalyst::Model/;

use Carp qw/croak/;
use Catalyst::Exception;
use NEXT;
use Scalar::Util qw/reftype/;
use MogileFS::Client;

__PACKAGE__->mk_accessors(qw/client/);

{
    no strict 'refs';

    my @delegate_methods = qw(
        last_tracker
        errstr
        errcode
        readonly
        set_pref_ip
        new_file
        store_file
        store_content
        get_paths
        get_file_data
        delete
        sleep
        rename
        list_keys
        foreach_keys
    );

    foreach my $method (@delegate_methods) {
        *{ "Catalyst::Model::MogileFS::Client::" . ${method} } = sub {
            my ( $proto, @args ) = @_;

            return eval { $proto->client->$method(@args); };
            if ( my $error = $@ ) {
                Catalyst::Exception->throw($error);
            }
        };
    }
}

=head1 NAME

Catalyst::Model::MogileFS::Client - Model class of MogileFS::Client on Catalyst

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';
our $AUTOLOAD;

=head1 SYNOPSIS

in MyApp.pm

  package MyApp;
    MyApp->config(
      'Model::Storage::MyImage' => {
        domain => 'myimage.art-code.org',
        readonly => 1
    }
  );

=head1 INSTALL

At first, you must run mogilefsd and mogstored.
For example,

  $ sudo mogstored 
  $ sudo -u mogile mogilefsd

Next, execute Makefile.PL.

=head1 METHODS

=head2 new([$config])

Constructor. $config must be hash ref.
See below for available parameter.
More detail in L<MogileFS::Client>.

=over 2

=item root

For nfs setup.

=item domain

MogileFS domain

=item backend

MogileFS::Backend object

=item readonly

readonly flag 1 or 0

=item hosts

trackers hosts as array ref

=item timeout

timeout sec

=back

=cut

sub new {
    my $class     = shift;
    my $arguments = pop;
    my $c         = shift;

    $class->config($arguments);

    my $self = $class->NEXT::new( $c, $class->config );

    eval {
        $self->client(
            MogileFS::Client->new(
                $class->_regulize_config( $class->config )
            )
        );
    };
    if ( my $error = $@ ) {
        Catalyst::Exception->throw($error);
    }

    return $self;
}

=head2 reload($config)

Reload MogileFS::Client setting
More detail, see 'new' method.

=cut

sub reload {
    my $self = shift;

    return eval { $self->client->reload( $self->_regulize_config(@_) ); };

    if ( my $error = $@ ) {
        Catalyst::Exception->throw($error);
    }
}

=head2 client

Getter for MogileFS::Client original instance

=head2 last_tracker

Return last using tracker.
See L<MogileFS::Client>, L<MogileFS::Backend>

=head2 errstr

Return error message if exists errors.
See L<MogileFS::Client>, L<MogileFS::Backend>

=head2 errcode

Return error code if exists errors.
See L<MogileFS::Client>, L<MogileFS::Backend>

=head2 readonly

Readonly flag accessor.
See L<MogileFS::Client>, L<MogileFS::Backend>

=head2 set_pref_ip($arg)

$arg must be hash ref as {"standard-ip" => "prefferred-ip"}.
See L<MogileFS::Client>, L<MogileFS::Backend>

=head2 new_file($key, $class[, $bytes, $opts])

Return MogileFS::NewHTTPFile object or undef if no device.

=over 2

=item $key

Specified file key name.

=item $class

Specified class name include files.

=item $bytes [optional]

The length of the file.

=item $opt [optional]

It must be hash ref.
Now supported option is "fid".

"fid" option is unique file id to use 
instead of just picking one in the database.

=back

See L<MogileFS::Client>, L<MogileFS::Backend>

=head2 store_file($key, $class, $file[, $opt])

=over 2

=item $file

File name.

=back

See also new_method about other arguments.
See L<MogileFS::Client>, L<MogileFS::Backend>

=head2 store_content($key, $class, $content[, $opts])

=over 2

=item $content

File content.

=back

See also new_method about other arguments.
See L<MogileFS::Client>, L<MogileFS::Backend>

=head2 get_paths($key[, $opts])

=over 2

=item $key

Specified file key name.

=item $opts [optional]

Available two option. see below.

=over 2

=item noverify

No verify. 0 or 1.

=item zone

Specified zone value.

=back

=back

See L<MogileFS::Client>, L<MogileFS::Backend>

=head2 get_file_data($key[, $timeout])

=over 2

=item $key

Specified file key name.

=item $timeout

Timeout seconds. default 10 sec.

=back

See L<MogileFS::Client>, L<MogileFS::Backend>

=head2 delete($key)

Delete file with $key.

See L<MogileFS::Client>, L<MogileFS::Backend>

=head2 sleep($duration)

Sleep thread $duration seconds.
See L<MogileFS::Client>, L<MogileFS::Backend>

=head2 rename($from_key, $to_key)

Rename file key name $from_key to $to_key.
See L<MogileFS::Client>, L<MogileFS::Backend>

=head2 list_keys($prefix, $after, $limit)

Search key list by $prefix, $after.

=over 2

=item $prefix

key's prefix.

=item $after

key's postfix.

=item $limit

Limitation of result list count.

=back

See L<MogileFS::Client>, L<MogileFS::Backend>

=head2 foreach_keys($opts, $callback)

Apply callback easch list keys.

=over 2

=item $opts

Hash ref.
Available option is only prefix.
See list_keys method.

=item $callback

Code ref with 1 argument.

=back

See L<MogileFS::Client>, L<MogileFS::Backend>

=head2 AUTOLOAD

used to support plugins that have modified the server, 
this builds things into an argument list and passes them back to the server

See L<MogileFS::Client>, L<MogileFS::Backend>

=cut

sub AUTOLOAD {
    my $self = shift;

    my $method = $AUTOLOAD;
    $method =~ s/^.*://;

    return if ( $method eq 'DESTROY' );

    return eval {
        return $self->$method(@_)         if ( $self->can($method) );
        return $self->client->$method(@_) if ( $self->can() );
    };

    croak($@);
}

sub _regulize_config {
    my $proto = shift;

    my %params = ();

    if ( reftype $_[0] eq 'HASH' ) {
        %params = %{ $_[0] };
    }
    else {
        %params = @_;
    }

    my %options;
    $options{$_} = 1 foreach (qw/root domain backend readonly hosts timeout/);

    return map { ( $_, $params{$_} ) }
        grep { exists $options{$_} }
        keys %params;
}

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou at cpan.org> >>

=head1 SEE ALSO

=over 2

=item L<MogileFS::Client>

=item L<Catalyst::Model>

=item L<Catalyst>

=item L<NEXT>

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-model-mogilefs-client at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Model-MogileFS-Client>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Model::MogileFS::Client

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Model-MogileFS-Client>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Model-MogileFS-Client>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Model-MogileFS-Client>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Model-MogileFS-Client>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Toru Yamaguchi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Catalyst::Model::MogileFS::Client
