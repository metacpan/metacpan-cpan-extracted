package Catalyst::Plugin::Session::Store::Couchbase;
use Moose;
use MRO::Compat;
extends 'Catalyst::Plugin::Session::Store';
with 'Catalyst::ClassData';
use Catalyst::Exception;
use Couchbase::Client 1.00;
use namespace::clean -except => 'meta'; # The last bit cargo culted.
use Storable qw(nfreeze thaw);

our $VERSION = '0.94';

__PACKAGE__->mk_classdata('_session_couchbase_handle');
__PACKAGE__->mk_classdata('_session_couchbase_prefix');

=head1 NAME

Catalyst::Plugin::Session::Store::Couchbase

=head1 SYNOPSIS

  use Catalyst qw{Session Session::Store::Couchbase Session::State::Cookie};
  MyApp->config(
    'Plugin::Session' => {
      expires => 7200,
    },
    Couchbase => {
      server => 'couchbase01.domain',
      username => 'Administrator',
      password => 'password',
      bucket => 'default',
    }
  );

=cut

sub setup_session {
    my $c = shift;
    $c->maybe::next::method(@_);

    $c->log->debug("Setting up Couchbase session store") if $c->debug;

    my $cfg = $c->config->{'Couchbase'};

    my $appname = "$c";
    $c->_session_couchbase_prefix($appname . "sess:");

    my $cb = Couchbase::Client->new({
        server => $cfg->{server},
        username => $cfg->{username},
        password => $cfg->{password},
        bucket => $cfg->{bucket},
        compress_threshold => 25_000,
        timeout => 6.0,
    });
    Catalyst::Exception->throw("Couchbase client undefined!")
        unless defined $cb;

    if (my @errs = @{$cb->get_errors}) {
        Catalyst::Exception->throw(
            "Couchbase client errors:\n"
             . join("\n", map { $_->[1] } @errs)
         );
    }
    $c->_session_couchbase_handle($cb);
    1;
}

sub get_session_data {
    my ($c, $key) = @_;
    croak("No cache key specified") unless length($key);
    $key = $c->_session_couchbase_prefix . $key;
    my $r = $c->_session_couchbase_handle->get($key);
    if (defined $r and defined $r->value) {
        return $r->value;
    }
    elsif (defined $r) {
        my $err = $r->errstr;
        Catalyst::Exception->throw(
            "Failed to fetch Couchbase item: $err. Key was: $key"
        ) unless $err =~ /No such key/;
    }
    return;
}

sub store_session_data {
    my ($c, $key, $data) = @_;
    croak("No cache key specified") unless length($key);
    $key = $c->_session_couchbase_prefix . $key;
    my $expiry = $c->session_expires ? $c->session_expires - time() : 0;
    if (not $expiry) {
        $c->log->warn("No expiry set for sessions! Defaulting to one hour..");
        $expiry = 3600;
    }
    my $r = $c->_session_couchbase_handle->set(
        $key => $data,
        int($expiry) # required due to outstanding bug in XS client code
    );
    unless (defined $r and $r->is_ok) {
        Catalyst::Exception->throw(
            "Couldn't save $key / $data in couchbase storage: " . $r->errstr
        );
    }
    return 1;
}

sub delete_session_data {
    my ($c, $key) = @_;
    $c->log->debug("Couchbase session store: delete_session_data($key)") if $c->debug;
    croak("No cache key specified") unless length($key);
    $key = $c->_session_couchbase_prefix . $key;
    $c->_session_couchbase_handle->remove($key);
    # Couchbase::Client API doesn't current specify what return codes apply to
    # this operation, so ignore 'em..
    return;
}

# Not required as Couchbase expires things itself.
sub delete_expired_sessions { }

=head1 AUTHOR

Toby Corkindale, C<< <tjc at wintrmute.net> >>

=head1 BUGS

Please report any bugs to the Github repo for this module:

https://github.com/TJC/Catalyst-Plugin-Session-Store-Couchbase

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::Session::Store::Couchbase


You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-Session-Store-Couchbase>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-Session-Store-Couchbase>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-Session-Store-Couchbase/>

=back


=head1 ACKNOWLEDGEMENTS

This module was supported by Strategic Data. The module was originally
written for their internal use, and the company has allowed me to produce
an open-source version.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Toby Corkindale.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

__PACKAGE__->meta->make_immutable;
1;
