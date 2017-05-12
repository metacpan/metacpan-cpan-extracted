package Crypt::OTR;

use 5.010000;
use strict;
use warnings;
use Carp qw/croak/;
use Crypt::OTR::PublicKey;
use AutoLoader;

our $VERSION = '0.08';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Crypt::OTR::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Crypt::OTR', $VERSION);

#########################

=head1 NAME

Crypt::OTR - Off-The-Record encryption library for secure instant
messaging applications

=head1 SYNOPSIS

    use Crypt::OTR;
    
    # call near the beginning of your program
    Crypt::OTR->init;

    # create OTR object, set up callbacks
    my $otr = new Crypt::OTR(
        account_name     => "alice",            # name of account associated with this keypair
        protocol_name    => "my_protocol_name", # e.g. 'AIM'
        max_message_size => 1024,               # how much to fragment
    );
    $otr->set_callback('inject' => \&otr_inject);
    $otr->set_callback('otr_message' => \&otr_system_message);
    $otr->set_callback('verified' => \&otr_verified);
    $otr->set_callback('unverified' => \&otr_unverified);

    # create a context for user "bob"
    $otr->establish("bob");  # calls otr_inject($account_name, $protocol, $dest_account, $message)

    # send a message to bob
    my $plaintext = "hello, bob! this is a message from alice";
    if (my $ciphertext = $otr->encrypt("bob", $plaintext)) {
        $my_app->send_message_to_user("bob", $ciphertext);
    } else {
        warn "Your message was not sent - no encrypted conversation is established\n";
    }

    # called from bob's end
    if (my $plaintext = $otr->decrypt("alice", $ciphertext)) {
        print "alice: $plaintext\n";
    } else {
        warn "We received an encrypted message from alice but were unable to decrypt it\n";
    }

    # done with chats
    $otr->finish("bob");
    
    # CALLBACKS 

    # called when OTR is ready to send a message after massaging it.
    # this method should actually transmit $message to $dest_account
    sub otr_inject {
        my ($self, $account_name, $protocol, $dest_account, $message) = @_;
        $my_app->send_message_to_user($dest_account, $message);
    }

    # called to display an OTR control message for a particular user or protocol
    sub otr_system_message {
        my ($self, $account_name, $protocol, $other_user, $otr_message) = @_;
        warn "OTR says: $otr_message\n";
        return 1;
    }

    # called when a verified conversation is established with $from_account
    sub verified {
        my ($self, $from_account) = @_;
        print "Started verified conversation with $from_account\n";
    }

    # called when an unverified conversation is established with $from_account
    sub unverified {
        my ($self, $from_account) = @_;
        print "Started unverified conversation with $from_account\n";
    }


=head1 DESCRIPTION

Perl wrapper around libotr - see
http://www.cypherpunks.ca/otr/README-libotr-3.2.0.txt

This module is experimental and unfinished, not yet recommended for
production or important systems.

=head1 EXPORT

No namespace pollution will be tolerated.

=head1 METHODS

=over 4


=item init(%opts)

This method sets up OTR and should be called early at the start of
your application, before using any OTR facilities. It is probably
unwise to call this more than once.

=cut

sub init {
    crypt_otr_init();
}


=item new(%opts)

This method sets up an OTR context for an account on a protocol (e.g. "lindenstacker" on OSCAR (AIM))

Options:

 'account_name'     => name of the account in your application

 'protocol'         => string identifying your application

 'max_message_size' => how many bytes messages should be fragmented into

 'config_dir'       => where to store keys and fingerprints, defaults to $ENV{HOME}/.otr

=cut

sub new {
    my ($class, %opts) = @_;

    my $account_name     = delete $opts{account_name}     || 'crypt_otr_user';
    my $protocol         = delete $opts{protocol}         || 'crypt_otr';
    my $max_message_size = delete $opts{max_message_size} || 0;
    my $config_dir       = delete $opts{config_dir}       || "$ENV{HOME}/.otr";

    croak "Unknown opts: " . join(', ', keys %opts) if keys %opts;

    $account_name = lc $account_name;
    $protocol     = lc $protocol;

    croak "$config_dir is not writable"
        if -e $config_dir && ! -w $config_dir;

    mkdir $config_dir unless -e $config_dir;
    croak "unable to create $config_dir"
        unless -e $config_dir;

    my $state = crypt_otr_create_user($config_dir, $account_name, $protocol);

    my $self = {
        account_name     => $account_name,
        protocol         => $protocol,
        max_message_size => $max_message_size,
        config_dir       => $config_dir,

        state => $state,        
    };

    return bless $self, $class;
}


=item set_callback($event, \&callback)

Set a callback to be called when various events happen:

  inject: Called when establishing a connection, or sending a
  fragmented message. This should send your message over whatever
  communication channel your application is using.

  otr_message: Called when OTR wants to display a notification to the
  user. Return 1 if the message has been displayed, return 0 if you
  want OTR to display the message inline.

  verified: A conncetion has been established and the other party's
  key fingerprint has been verified

  unverified: A connection has been established but the key
  fingerprint has not been verified

  disconnect: Connection has been disconnected

  system_message: OTR has a system message to display to the user

  error: Error message to display

  warning: Warning message to display

  info: Informative message to display

  new_fingerprint: Received a new fingerprint for a user

  smp_request: Identity verification challenge request

=cut

sub set_callback {
    my ($self, $action, $cb) = @_;


    # wrap in method call
    my $wrapped_cb = sub {
        $cb->($self, @_);
    };

    my $callback_map = {
        'inject'          => \&crypt_otr_set_inject_cb,
        'otr_message'     => \&crypt_otr_set_system_message_cb,
        'verified'        => \&crypt_otr_set_connected_cb,
        'unverified'      => \&crypt_otr_set_unverified_cb,
        'disconnect'      => \&crypt_otr_set_disconnected_cb,
        'system_message'  => \&crypt_otr_set_system_message_cb,
        'still_connected' => \&crypt_otr_set_stillconnected_cb,
        'error'           => \&crypt_otr_set_error_cb,
        'warning'         => \&crypt_otr_set_warning_cb,
        'info'            => \&crypt_otr_set_info_cb,
        'new_fingerprint' => \&crypt_otr_set_new_fpr_cb,
        'smp_request'     => \&crypt_otr_set_smp_request_cb,
    };

    my $cb_method = $callback_map->{$action}
    or croak "unknown callback $action";
	
    $cb_method->($self->_us, $wrapped_cb);
}


=item establish($user_name)

Attemps to begin an OTR-encrypted conversation with $user_name. This
will call the inject callback with a message containing an OTR
connection attempt.

=cut

sub establish {
    my ($self, $user_name) = @_;

    croak "No user_name specified to establish()" unless $user_name;
    return crypt_otr_establish($self->_args, $user_name);
}


=item encrypt($user_name, $plaintext)

Encrypts $plaintext for $user_name. Returns undef unless an encrypted
message has been generated, in which case it returns that.

=cut

sub encrypt {
    my ($self, $user_name, $plaintext) = @_;

    return undef unless $plaintext;
    return crypt_otr_process_sending($self->_args, $user_name, $plaintext);
}


=item decrypt($user_name, $ciphertext)

Decrypt a message from $user_name, returns plaintext if successful, otherwise undef

In list context, returns ($plaintext, $should_discard). If
$should_discard is set, you should ignore the message entirely as it
is an internal OTR protocol message or message fragment.

=cut

sub decrypt {
    my ($self, $user_name, $ciphertext) = @_;

    return undef unless $ciphertext;
    my ($plain, $should_discard) = crypt_otr_process_receiving($self->_args, $user_name, $ciphertext);
    return wantarray ? ($plain, $should_discard) : $plain;
}

=item start_smp($user_name, $secret, $question)

Start the Socialist Millionaires' Protocol over the current
connection, using the given initial secret, and optionally a question
to pass to the buddy (not supported).

=cut

sub start_smp {
	my($self, $user_name, $secret, $question) = @_;
	
	return undef unless $secret;
	
	if( $question ){
		crypt_otr_start_smp_q($self->_args, $user_name, $secret, $question);
	} else {
		crypt_otr_start_smp($self->_args, $user_name, $secret );
	}

}

=item continue_smp($user_name, $secret)

Continue the Socialist Millionaires' Protocol over the current
connection, using the given initial secret

=cut

sub continue_smp {
	my($self, $user_name, $secret) = @_;

	return undef unless $secret;
	crypt_otr_continue_smp($self->_args, $user_name, $secret);
}

=item abort_smp($user_name)

Abort the SMP protocol.  Used when malformed or unexpected messages are received.

=cut

sub abort_smp {
	my($self, $user_name) = @_;
	
	crypt_otr_abort_smp($self->_args, $user_name);
}

# takes a digest of a message to sign (not the message itself)
sub sign {
    my ($self, $message_digest) = @_;
    my $sig = crypt_otr_sign($self->_args, $message_digest);
}

# same as above
sub verify {
    my ($self, $message_digest, $sig, $pubkey) = @_;
    my $ok = crypt_otr_verify($message_digest, $sig, $pubkey->data, $pubkey->size, $pubkey->type);
}



=item finish($user_name)

Ends an encrypted conversation, no new messages from $user_name will
be able to be decrypted

=cut

sub finish {
    my ($self, $user_name) = @_;

    return crypt_otr_disconnect($self->_args, $user_name);
}

sub DESTROY {
    my $self = shift;

    crypt_otr_cleanup($self->_us);
}


##############




### UTILITY METHODS

# get userstate
sub _us { $_[0]->{state} }

sub account_name { $_[0]->{account_name} }
sub protocol { $_[0]->{protocol} }
sub config_dir { $_[0]->{config_dir} }
sub max_message_size { $_[0]->{max_message_size} }

# contextual information passed to xsubs
sub _args {
    my $self = shift;
    ($self->_us, $self->account_name, $self->protocol, $self->max_message_size);
}

# key filename
sub keyfile {
    my $self = shift;
    return crypt_otr_get_keyfile($self->_us);
}

# fingerprints filename
sub fprfile {
    my $self = shift;
    return crypt_otr_get_fprfile($self->_us);
}

# attempt to load or generate a private key, may block for a long time
sub load_privkey {
    my $self = shift;

    crypt_otr_load_privkey($self->_args);
}

sub pubkey_data {
    my $self = shift;
    return crypt_otr_get_pubkey_str($self->_args);
}

sub fingerprint_data {
	my $self = shift;
	return crypt_otr_get_privkey_fingerprint($self->_args);
}

sub fingerprint_data_raw {
	my $self = shift;
	return crypt_otr_get_privkey_fingerprint_raw($self->_args);
}


# opaque public key structure
sub pubkey {
    my $self = shift;

    return $self->{_pubkey} if $self->{_pubkey};

    # make sure we have a key
    $self->load_privkey;

    my $pk = Crypt::OTR::PublicKey->new(
        data => crypt_otr_get_pubkey_data($self->_args),
        type => crypt_otr_get_pubkey_type($self->_args),
        size => crypt_otr_get_pubkey_size($self->_args),
    );

    $self->{_pubkey} = $pk;

    return $pk;
}



# read a stored fingerprint file from disk
sub read_fprfile {
	my ($self, $fpr_filepath) = @_;
	return crypt_otr_read_fingerprints($self->_args, $fpr_filepath);
}

# Write the fingerprint unique to your userstate to disk
sub write_fprfile{
	my ($self, $fpr_filepath) = @_;
	return crypt_otr_write_fingerprints($self->_args, $fpr_filepath);
}

# Forget all private keys for your user state
sub forget_all{
	my $self = shift;
	
	crypt_otr_forget_all($self->_args);
}






#########

=back

=head1 SEE ALSO

http://www.cypherpunks.ca/otr

=head1 TODO

- More documentation (always)

- More tests (always)

- Find leaking scalars

=head1 AUTHOR

Patrick Tierney, E<lt>patrick.l.tierney@gmail.comE<gt>
Mischa Spiegelmock, E<lt>mspiegelmock@gmail.comE<gt>

This module is unfinished, not very tested, and incomplete. Would you
like to help make it better? Send an email to one of the authors, we'd
love to get more people involved

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2010 by Patrick Tierney, Mischa Spiegelmock

    This program is free software: you can redistribute it and/or
    modify it under the terms of the GNU General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see
    <http://www.gnu.org/licenses/>.

=cut


1;
__END__
