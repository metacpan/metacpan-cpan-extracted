package Crypt::GpgME;

use strict;
use warnings;
use IO::Scalar;

our $VERSION = '0.09';
our @ISA;

eval {
    require XSLoader;
    XSLoader::load( __PACKAGE__, $VERSION );
    1;
} or do {
    require DynaLoader;
    push @ISA, 'DynaLoader';
    __PACKAGE__->bootstrap( $VERSION );
};

sub import {
    my ($base, @args) = @_;

    my $do_init = 1;
    my $init_version = undef;

    while (my $arg = shift @args) {
        if ($arg eq '-no-init') {
            $do_init = 0;
        }
        elsif ($arg eq '-init') {
            $do_init = 1;

            if (!@args) {
                require Carp;
                Carp::croak ('-init requires a version number to pass to Crypt::GpgME->check_version');
            }

            $init_version = shift @args;
        }
        else {
            $base->VERSION($arg);
        }
    }

    if ($do_init) {
        $base->check_version( defined $init_version ? $init_version : () );
    }
}

package Crypt::GpgME::Data;

use strict;
use warnings;
use base qw/IO::Scalar/;

1;

__END__
=head1 NAME

Crypt::GpgME - Perl interface to libgpgme

=head1 SYNOPSIS

    use IO::File;
    use Crypt::GpgME;

    my $ctx = Crypt::GpgME->new;

    $ctx->set_passphrase_cb(sub { 'abc' });

    my $signed = $ctx->sign( IO::File->new('some_file', 'r') );

    print while <$signed>;

=head1 FUNCTIONS

=head2 GPGME_VERSION

    my $version = Crypt::GpgME->GPGME_VERSION;
    my $version = $ctx->GPGME_VERSION;

Returns a string containing the libgpgme version number this module has been
compiled against.

=head2 new

    my $ctx = Crypt::GpgME->new;

Returns a new Crypt::GpgME instance. Throws an exception on error.

=head2 card_edit

    my $fh = $ctx->card_edit($key, $coderef);
    my $fh = $ctx->card_edit($key, $coderef, $user_data);

=head2 check_version

    Crypt::GpgME->check_version;
    Crypt::GpgME->check_version($version);

=head2 delete

    $ctx->delete($key);
    $ctx->delete($key, $allow_secret);

=head2 edit

    my $fh = $ctx->edit($key, $coderef);
    my $fh = $ctx->edit($key, $coderef, $user_data);

=head2 engine_check_version

    $ctx->engine_check_version($proto);
    Crypt::GpgME->engine_check_version($proto);

=head2 genkey

    my ($result, $pubkey_fh, $seckey_fh) = $ctx->genkey($parms);

=head2 get_armor

    my $armor = $ctx->get_armor;

=head2 get_engine_info

    my $engine_info = $ctx->get_engine_info;
    my $engine_info = Crypt::GpgME->get_engine_info;

=head2 get_include_certs

    my $include_certs = $ctx->get_include_certs;

=head2 get_key

    my $key = $ctx->get_key($fpr);
    my $key = $ctx->get_key($fpr, $secret);

=head2 get_keylist_mode

    my $keylist_mode = $ctx->get_keylist_mode;

=head2 get_protocol

    my $protocol = $ctx->get_protocol;

=head2 get_textmode

    my $textmode = $ctx->get_protocol;

=head2 keylist

    my @results = $ctx->keylist($pattern);
    my @results = $ctx->keylist($pattern, $secret_only);

=head2 set_armor

    $ctx->set_armor($armor);

=head2 set_engine_info

    $ctx->set_engine_info($proto, $file_name, $home_dir);
    Crypt::GpgME->set_engine_info($proto, $file_name, $home_dir);

=head2 set_include_certs

    $ctx->set_include_certs;
    $ctx->set_include_certs($nr_of_certs);

=head2 set_keylist_mode

    $ctx->set_keylist_mode;
    $ctx->set_keylist_mode($keylist_mode);

=head2 set_locale

    $ctx->set_locale($category, $value);
    Crypt::GpgME->set_locale($category, $value);

=head2 set_passphrase_cb

    $ctx->set_passphrase_cb($coderef);
    $ctx->set_passphrase_cb($coderef, $user_data);

=head2 set_progress_cb

    $ctx->set_progress_cb($coderef);
    $ctx->set_progress_cb($coderef, $user_data);

=head2 set_protocol

    $ctx->set_protocol;
    $ctx->set_protocol($proto);

=head2 set_textmode

    $ctx->set_textmode($textmode);

=head2 sig_notation_add

    $ctx->sig_notation_add($name, $value);
    $ctx->sig_notation_add($name, $value, $flags);

=head2 sig_notation_clear

    $ctx->sig_notation_clear;

=head2 sig_notation_get

    my @notation = $ctx->sig_notation_get;

=head2 sign

    my $fh = $ctx->sign($plain);
    my $fh = $ctx->sign($plain, $mode);

=head2 signers_add

    $ctx->signers_add($key);

=head2 signers_clear

    $ctx->signers_clear;

=head2 signers_enum

    my $key = $ctx->signers_enum($seq);

=head2 trustlist

    my @trustlist = $ctx->trustlist($pattern, $maxlevel);

=head2 verify

    my ($result, $plain) = $ctx->verify($sig);
    my $result = $ctx->verify($sig, $signed_text);

=head1 AUTHOR

Florian Ragwitz, C<< <rafl at debian.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-crypt-gpgme at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-GpgME>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::GpgME

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-GpgME>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-GpgME>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-GpgME>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-GpgME>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007-2009 Florian Ragwitz, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
