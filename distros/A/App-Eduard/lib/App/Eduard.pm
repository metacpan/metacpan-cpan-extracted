package App::Eduard;

use 5.014000;
use strict;
use warnings;
use parent qw/Exporter/;
our $VERSION = '0.001002';
our @EXPORT_OK = qw/import_pubkeys process_message/;

use Email::Sender::Simple qw/sendmail/;
use File::Share qw/dist_file/;
use File::Slurp qw/read_file/;
use File::Spec::Functions qw/rel2abs/;
use IO::Handle;
use Getopt::Long;
use MIME::Entity;
use MIME::Parser;
use Mail::GnuPG;
use PerlX::Maybe;
use Template;
use Try::Tiny;

sub debug { say STDERR @_ if $ENV{EDUARD_DEBUG} }
sub stringify ($) { join '', map {; '>', $_ } @{$_[0]} }
sub mg {
	Mail::GnuPG->new(
		key                => $ENV{EDUARD_KEY},
		maybe always_trust => $ENV{EDUARD_ALWAYS_TRUST},
		maybe keydir       => $ENV{EDUARD_KEYDIR},
		maybe passphrase   => $ENV{EDUARD_PASSPHRASE},
		maybe use_agent    => $ENV{EDUARD_USE_AGENT},
		@_);
}

sub mp {
	my $parser = MIME::Parser->new;
	$parser->decode_bodies($_[0] // 0);
	$parser->output_to_core(1);
	$parser
}

sub first_part{
	my ($ent) = @_;
	return first_part ($ent->parts(0)) if $ent->parts;
	stringify [$ent->bodyhandle->as_lines]
}

sub import_pubkeys {
	my ($ent, $mg) = @_;
	my @keys;
	if ($ent->mime_type eq 'application/pgp-keys') {
		$ent = mp(1)->parse_data($ent->stringify);
		my $gpg = GnuPG::Interface->new;
		$mg->_set_options($gpg);
		$gpg->options->quiet(1);
		my ($input, $status) = (IO::Handle->new, IO::Handle->new);
		my $pid = $gpg->import_keys(handles => GnuPG::Handles->new(stdin => $input, status => $status));
		my $read = Mail::GnuPG::_communicate([$status], [$input], {$input => $ent->bodyhandle->as_string});
		push @keys, map { /IMPORT_OK \d+ (\w+)/ } $read->{$status};
		waitpid $pid, 0
	}
	push @keys, import_pubkeys ($_, $mg) for $ent->parts;
	@keys
}

sub find_pgp_part {
	my ($ent, $mg) = @_;
	do {
		my $part = find_pgp_part ($_, $mg);
		return $part if $part
	} for $ent->parts;
	return $ent if $ent->bodyhandle && ($mg->is_signed($ent) || $mg->is_encrypted($ent));
	return
}

sub process_message {
	my ($in) = @_;
	my $msg;
	my $parser = mp;

	$msg =                      $in   if     ref $in eq 'MIME::Entity';
	$msg = $parser->parse      ($in)  if     ref $in eq 'IO';
	$msg = $parser->parse_data ($in)  if     ref $in eq 'SCALAR';
	$msg = $parser->parse_open ($in)  unless ref $in;
	die "Don't know how to parse $in" unless $msg;

	if ($msg->mime_type ne 'multipart/signed' && $msg->mime_type ne 'multipart/encrypted') {
		# PGP/Inline requires decoding
		$parser->decode_bodies(1);
		$msg = $parser->parse_data($msg->stringify)
	}

	my $gpg = mg;
	if ($msg->effective_type ne 'multipart/signed' && $msg->effective_type ne 'multipart/encrypted' && !$msg->bodyhandle) {
		debug 'This is (probably) a PGP/Inline mail with attachments. Working around...';
		$msg = find_pgp_part $msg, $gpg
	}

	if ($gpg->is_signed($msg)) {
		debug 'This mail looks signed';
		my ($code, $keyid, $email) = $gpg->verify($msg);
		return sign_error => (
			message => stringify $gpg->{last_message}) if $code;
		return sign => (
			keyid   => $keyid,
			email   => $email,
			message => stringify $gpg->{last_message});
	}

	if ($gpg->is_encrypted($msg)) {
		debug 'This mail looks encrypted';
		my ($code, $keyid, $email) = $gpg->decrypt($msg);
		return encrypt_error => (
			message   => stringify $gpg->{last_message}) if $code;
		return encrypt => (
			plaintext => stringify $gpg->{plaintext},
			decrypted => $gpg->{decrypted},
			message   => stringify $gpg->{last_message}) unless defined $keyid;
		return signencrypt => (
			keyid     => $keyid,
			email     => $email,
			plaintext => stringify $gpg->{plaintext},
			decrypted => $gpg->{decrypted},
			message   => stringify $gpg->{last_message});
	}

	debug 'This mail doesn\'t seem to be signed or encrypted';
	return 'plain', message => ''
}

sub run {
	GetOptions(
		'always-trust!' => \$ENV{EDUARD_ALWAYS_TRUST},
		'debug!'        => \$ENV{EDUARD_DEBUG},
		'from=s'        => \$ENV{EDUARD_FROM},
		'key=s'         => \$ENV{EDUARD_KEY},
		'keydir=s'      => \$ENV{EDUARD_KEYDIR},
		'logfile=s'     => \$ENV{EDUARD_LOGFILE},
		'passphrase=s'  => \$ENV{EDUARD_PASSPHRASE},
		'tmpl-path=s'   => \$ENV{EDUARD_TMPL_PATH},
		'use-agent!'    => \$ENV{EDUARD_USE_AGENT},
	);
	my $tmpl_path = $ENV{EDUARD_TMPL_PATH} // 'en';
	open STDERR, '>>', $ENV{EDUARD_LOGFILE} if $ENV{EDUARD_LOGFILE};

	my $in = mp->parse(\*STDIN);
	debug 'Received mail from ', $in->get('From');
	my @keys = import_pubkeys $in, mg;
	say 'Found keys: ', join ' ', @keys if @keys;

	my ($tmpl, %params);
	try {
		($tmpl, %params) = process_message $in
	} catch {
		($tmpl, %params) = (error => message => $_)
	};
	debug "Result is $tmpl, GnuPG said:\n", $params{message};

	$params{plaintext} = first_part $params{decrypted} if $params{decrypted};

	my $tt = Template->new(INCLUDE_PATH => rel2abs $tmpl_path, dist_file 'App-Eduard', 'tmpl');
	my ($keys, $result) = ('', '');
	$tt->process('keys', {keys => \@keys}, \$keys) if @keys;
	$tt->process($tmpl, \%params, \$result);
	my $email = MIME::Entity->build(
		From    => $ENV{EDUARD_FROM},
		To      => $in->get('From'),
		Type    => 'text/plain; charset=UTF-8',
		Encoding=> '-SUGGEST',
		Subject => 'Re: ' . $in->get('Subject'),
		Data    => $keys.$result);

	my $email_unencrypted = $email->dup;
	my $mg = mg always_trust => 1;
	my $encrypt_failed = $mg->mime_signencrypt($email, $in->get('From') =~ /<(.*)>/);
	debug 'Could not encrypt message, sending unencrypted. GnuPG said:', "\n", stringify $mg->{last_message} if $encrypt_failed;
	sendmail $encrypt_failed ? $email_unencrypted : $email
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Eduard - GnuPG email sign/encrypt testing bot

=head1 SYNOPSIS

  use App::Eduard;
  my ($status, %params) = process_message '/path/to/message';
  if ($status eq 'signencrypt') {
    say 'This message is encrypted and signed with key ', $params{keyid}, ' from ', $params{email};
    say 'Its contents are: ', $params{plaintext};
  } elsif ($status eq 'encrypt') {
    say 'This message is encrypted but not signed';
    say 'Its contents are: ', $params{plaintext};
  } elsif ($status eq 'encrypt_error') {
    say 'This message is encrypted but I was unable to decrypt it. GnuPG output: ', $params{message};
  } elsif ($status eq 'sign') {
    say 'This message is signed with key ', $params{keyid}, ' from ', $params{email};
  } elsif ($status eq 'sign_error') {
    say 'This message is signed but I was unable to verify the signature. GnuPG output: ', $params{message};
  } elsif ($status eq 'plain') {
    say 'This message is neither signed nor encrypted';
  } elsif ($status eq 'error') {
    say 'There was an error processing the message: ', $params{message};
  }

=head1 DESCRIPTION

Eduard is Ceata's reimplementation of the Edward reply bot referenced in L<https://emailselfdefense.fsf.org/>.

=head1 EXPORTS

None by default.

=head2 B<import_keys>(I<$entity>, I<$gpg>)

Scan a message for PGP public keys, and import them. I<$entity> is a L<MIME::Entity> to scan, I<$gpg> is a L<Mail::GnuPG> instance.

Returns a list of fingerprints of keys found.

=head2 B<process_message>(I<$message>)

Analyze a message, looking for PGP signatures and encryption. I<$message> can be:

=over

=item A filehandle reference, e.g. C<\*STDIN>.

=item A reference to a scalar which holds the message contents.

=item A scalar which represents a path to a message.

=item A L<MIME::Entity> object created with decode_bodies(0)

=back

The function returns a status followed by a hash. Possible results:

=over

=item plain

The message is neither signed nor encrypted.

=item sign_error, message => $message

The message is signed but the signature could not be verified. GnuPG output is $message.

=item sign, keyid => $keyid, email => $email, message => $message

The message is signed with key $keyid from $email. GnuPG output is $message.

=item encrypt_error, message => $message

The message is encrypted and unable to be decrypted. GnuPG output is $message.

=item encrypt, plaintext => $plaintext, decrypted => $decrypted, message => $message

The message is encrypted and unsigned. $plaintext is the decrypted message as plain text, while $decrypted is a MIME::Entity representing the decrypted message. GnuPG output is $message.

=item signencrypt, plaintext => $plaintext, decrypted => $decrypted, keyid => $keyid, email => $email, message => $message

The message is encrypted and signed with key $keyid from $email. $plaintext is the decrypted message as plain text, while $decrypted is a MIME::Entity representing the decrypted message. GnuPG output is $message.

=item error, message => $message

There was an error while processing the message. The error can be found in $message.

=back

=head1 ENVIRONMENT

This module is configured via the %ENV hash. See the L<eduard(1)> manpage for more information.

=head1 SEE ALSO

L<eduard(1)>, L<http://ceata.org/proiecte/eduard>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ceata.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Fundația Ceata

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
