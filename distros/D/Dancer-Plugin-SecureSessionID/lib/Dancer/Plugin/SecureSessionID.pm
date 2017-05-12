package Dancer::Plugin::SecureSessionID;

use Modern::Perl;

use Carp 'croak';
use Dancer ':syntax';
use Dancer::Plugin;
use Dancer::Session::Abstract ();
use Crypt::OpenSSL::Random ();
use MIME::Base64 ();

=head1 NAME

Dancer::Plugin::SecureSessionID - A secure replacement of Dancer's built-in session id generator

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Dancer::Plugin::SecureSessionID;

    use_secure_session_id;

=head1 DESCRIPTION

This plugin overrides the C<build_id()> method in L<Dancer::Session::Abstract|Dancer::Session::Abstract> and make use of L<Crypt::OpenSSL::Random|Crypt::OpenSSL::Random> to get really secure random session ids.

=head1 METHODS

=head2 C<< use_secure_session_id([ %options ]) >>

In a previous version of the module, the options ware passed into C<Crypt::Random::makerandom_octet(...)>. For compatibility reasons, the option-keys Strength, Length and Skip are still valid. B<Other option-keys are no longer supported>.

The defaults are Strength=1 and Length=16. These options can be set with plugin settings, too.

	use_secure_session_id(Length => 20, Uniform => 1, Skip => 512);

same as:

	plugins:
	  SecureSessionID:
	    Length: 20
	    Uniform: 1
	    Skip: 512

The result is encoded with C<base64url()>. A length of 16 random bytes results in 22 characters.

=cut

register use_secure_session_id => sub {
	my %options = (
		Length => 16,
		Strength => 1,
		%{ plugin_setting || {} },
		@_
	);
	warn "option 'Uniform' is deprecated" if $options{Uniform};
	no strict 'refs';
	no warnings 'redefine';
	*{'Dancer::Session::Abstract::build_id'} = sub {
		my $r;
		$options{Skip} ||= 0;
		if ($options{Strength}) {
			$r = Crypt::OpenSSL::Random::random_bytes($options{Length} + $options{Skip});
		} else {
			$r = Crypt::OpenSSL::Random::random_pseudo_bytes($options{Length} + $options{Skip});
		}
		use bytes;
		$r = substr($r, $options{Skip});
		return MIME::Base64::encode_base64url($r,'');
	};
};

=head1 SECURITY WARNING

Any session module which does not override C<build_id()> make profit from this plugin. This behaviour may change in future. Don't rely on it without auditing the source code of the affected session modules. By now, both the Simple and YAML session engines (shipped with the Dancer package) do not override C<build_id> so this plugin works as expected.

Addtionally, mind the blocking behaviour when C<Strength=1> is requested. If your application blocks, you can set the C<Strength> option to 0. This may be a lack of security but it helps to improve performance. Since your application cause network traffic, the entropy pool will be recharged often enough to never get stalled. See also L<the manpage of your random device|random(4)>.

=head1 AUTHOR

David Zurborg, C<< <zurborg@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests trough my project management tool
at L<http://development.david-zurb.org/projects/libdancer-plugin-securesessionid/issues/new>.  I
will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::SecureSessionID

You can also look for information at:

=over 4

=item * Redmine: Homepage of this module

L<http://development.david-zurb.org/projects/libdancer-plugin-securesessionid>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-SecureSessionID>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-SecureSessionID>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-SecureSessionID>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-SecureSessionID/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2014 David Zurborg, all rights reserved.

This program is released under the following license: open-source

=cut

register_plugin;
1;
