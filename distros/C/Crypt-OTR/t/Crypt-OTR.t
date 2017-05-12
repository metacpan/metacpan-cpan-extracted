use threads;
use threads::shared;use Digest::SHA1  qw(sha1);

use Test::More tests => 18;
BEGIN { use_ok('Crypt::OTR') };

use strict;
use warnings;
use Carp qw/confess/;

my $finished : shared = 0;
my %e;
my $established : shared;
$established = share(%e);
my $test_init : shared;

my @test_alice:shared;
my $test_alice_buf = \@test_alice;

my $alice_buf = [];
my $bob_buf = [];
my $charles_buf = [];

share( @$alice_buf );
share( @$bob_buf );
share( @$charles_buf );

my $bob_info_buf = [];

share( @$bob_info_buf );

my $u1 = "alice";
my $u2 = "bob";
my $u3 = "charles";

my $m1 = "Hello $u1, this is $u2";
my $m2 = "Hello $u2, this is $u1";

# socialist millionaires protocol (shared secret verification)
my $secret = "Rosebud";
my $question = "Which movie";

my %connected :shared = (
	$u1 => 0,
	$u2 => 0,
);

my %disconnected :shared = (
	$u1 => 0,
	$u2 => 0,
);

my %secured :shared = (
	$u1 => 0,
	$u2 => 0,
);

my %smp_request :shared = (
	$u1 => 0,
	$u2 => 0,
);

my %new_fingerprint :shared = (
	$u1 => 0,
	$u2 => 0,
);

my $multithread_done :shared = 0;
my $sign_thread_done :shared = 0;

Crypt::OTR->init;

ok(test_multithreading(), "multithreading");
#$multithread_done = 2;
#ok(test_signing(), "signing");
#ok(test_fingerprint_read_write(), "fingerprint read/write");


# TODO:
# This test is not complete, verify does not return 0

# Creates two new users and a message
# Alice hashes the message and signs the digest
# Bob checks the digest using  Alices's public key

sub test_signing {
	# These tests shouldn't start until the multithreading test is over
	flush_shared();

	sleep 1;

	my $sign_thread = async {
		# wait until both alice and bob pass multithreading
		until($multithread_done > 1){
			print STDERR "Sleeping";
			sleep 1;
		}

		my $msg = q/TEST MESSAGE FOR SIGNING/ x 100;

		my $alice = test_init($u1, $bob_buf);
		$alice->load_privkey;
		$alice->establish($u2);

		ok($alice, "Set up $u1");

		my $bob = test_init($u2, $test_alice_buf);
		$bob->load_privkey;
		$bob->establish($u1);

		ok($bob, "Set up $u2");
		
		# alice creates a digest and signs it
		my $digest = sha1($msg);
		my $sig = $alice->sign($digest);
		
		# This is actually meaningless, though at the moment I can't seem to find
		# a good way to check pass errors from OTR.  They are printed though
		ok($sig, "Successfully signed message");
		
		# technically bob should generate his own digest of the message
		ok( $bob->verify($digest, $sig, $alice->pubkey), "Verifying signature");
	};
	
	$sign_thread->join;

	$sign_thread_done = 1;
	
	return 1;
}

# Used to reset all values so another conversation-based test can start
sub flush_shared {

    # Flush the buffers, in case any remained from the previous test
    @$alice_buf = ();
    @$bob_buf = ();

    $connected{ $u1 } = 0; 
    $connected{ $u2 } = 0; 
    $disconnected{ $u1 } = 0;
    $disconnected{ $u2 } = 0;
    $secured{ $u1 } = 0;
    $secured{ $u2 } = 0;
    $smp_request{ $u1 } = 0;
    $smp_request{ $u2 } = 0;
    $new_fingerprint{ $u1 } = 0;
    $new_fingerprint{ $u2 } = 0;
}

# TODO:
# This test is not complete, the OTR function to print fingerprints segfaults
# 

# Create a new user, generate a fingerprint, write the fingerprint to disk
# Dumps all fingerprints, load the fingerprint from disk
# Check to make sure the fingerprints are equal

sub test_fingerprint_read_write {

	my $alice_fingerprint_path;
	my $alice_fingerprint;
	my $alice_new_fpr_path;
	
	flush_shared();

	sleep 1;

	my $alice_fpr_thread = async {	
		until( $sign_thread_done){
			sleep 1;
		}

		my $alice = test_init($u1, $bob_buf);
		$alice->load_privkey;
        $alice->establish($u2);

        my $con = 0;

        while( $con == 0 ){
            sleep 1;

            my $msg;
            {
                lock( @$alice_buf );
                $msg = shift @$alice_buf;
            }

            if( $msg ){
                my $resp = $alice->decrypt($u2, $msg);
            }
            {
                lock( %connected );
                $con = $connected{ $u2 }
            }
        }

		my $new_fpr = 0;
		
		while( $new_fpr == 0 ){
			sleep 1;
			
			{
				lock( %new_fingerprint );
				$new_fpr = $new_fingerprint{ $u1 };
			}
		}
		
		# At this point a fingerprint file should have been generated
		$alice_fingerprint_path = $alice->fprfile;
		
		print STDERR "Alice fingerprint path:\n$alice_fingerprint_path\n";
		
		# write the fingerprint to disk
		
		$alice_new_fpr_path = $alice_fingerprint_path . "-fingerprint_read_write";

		warn "About to write fprfile";
		
		$alice->write_fprfile( $alice_new_fpr_path);

		warn "About to get fingerprint data";

		# this function segfaults at the moment,
        # specifically whet the otrl_privkey_fingerprint function is called
		#$alice_fingerprint = $alice->fingerprint_data;		
		$alice_fingerprint = $alice->fingerprint_data_raw;

		print STDERR "Alice fingerprint:\n$alice_fingerprint\n";

	};


	# The bob thread simply establishes a connection so a new fingerprint is generated
	my $bob_fpr_thread = async {
		until( $sign_thread_done){
			sleep 1;
		}

		my $bob   = test_init($u2, $alice_buf);

        {
			$bob->load_privkey;
            $bob->establish($u1);

            select undef, undef, undef, 1.2;

            my $con = 0;

            while( $con == 0 ){
                sleep 1;

                my $msg;
                {
                    lock( @$bob_buf );
                    $msg = shift @$bob_buf;
                }

                if( $msg ){
                    my $resp = $bob->decrypt($u1, $msg);
                }

                {
                    lock( %connected );
                    $con = $connected{ $u1 };
                }

            }

            ok($established->{$u1}, "Connection with $u1 established");
		}		
			
	};

    $_->join foreach ($alice_fpr_thread, $bob_fpr_thread);

	return 1;
}



# Main test thread:
# - Loading / generating private keys
# - Establishing a conversation
# - Establishing a secure conversation with SMP
# - Disconnecting

sub test_multithreading {
    # don't run these at the same time

    my $alice_thread = async {
        my $alice = test_init($u1, $bob_buf);

		ok($alice, "Generated / loaded private key for $u1...");

        $alice->establish($u2);

        my $con = 0;

        while( $con == 0 ){
            sleep 1;

            my $msg;
            {
                lock( @$alice_buf );
                $msg = shift @$alice_buf;
            }

            if( $msg ){
                my $resp = $alice->decrypt($u2, $msg);
            }
            {
                lock( %connected );
                $con = $connected{ $u2 }
            }
        }

        ok($established->{$u2}, "Connection with $u2 established");
        
        # Encrypt a message and send it to Bob
        {
            my $enc_msg = $alice->encrypt($u2, $m1);
            lock( @$bob_buf );
            push @$bob_buf, $enc_msg;
        }
        
        # Decrypt messages from Bob
        {
            my $rec_msg;
            my $dec_msg;

            until( $dec_msg )
            {
                {
                    lock( @$alice_buf );
                    $rec_msg = shift @$alice_buf;
                    $dec_msg = $alice->decrypt($u2, $rec_msg);
                }
                sleep 1;
            }

            ok( $dec_msg eq $m2, "Send: $m2 = Decrypted: $dec_msg");
        }

        sleep 2;

        # Secure the connection using SMP
        {
            my $sec_con;
            $alice->start_smp($u2, $secret);

            until( $sec_con )
            {
                my $msg;
                {
                    lock( @$alice_buf );
                    $msg = shift @$alice_buf;
                }

                if( $msg ){
                    my $resp = $alice->decrypt($u2, $msg);
                    if ($resp){
                        print "resp: $resp\n";
                    }
                }

                {
                    lock( %secured );
                    $sec_con = $secured{ $u2 };
                }

                sleep 1;
            }
			pass("Secured connection with SMP");
        }

        # Disconnect
        sleep 2;				
        {
            $alice->finish($u2);

            my $dis;
            until( $dis )
            {
                {
                    lock( %disconnected );
                    $dis = $disconnected{ $u2 };
                }
            }

            ok( $dis, "Disconnected from $u2" );
			
			$multithread_done++;
        }

    };

    my $bob_thread = async {
        my $bob   = test_init($u2, $alice_buf);

        # establish
        {
			ok($bob, "Generated / loaded private key for $u2...");

            $bob->establish($u1);

            select undef, undef, undef, 1.2;

            my $con = 0;

            while( $con == 0 ){
                sleep 1;

                my $msg;
                {
                    lock( @$bob_buf );
                    $msg = shift @$bob_buf;
                }

                if( $msg ){
                    my $resp = $bob->decrypt($u1, $msg);
                }

                {
                    lock( %connected );
                    $con = $connected{ $u1 };
                }

            }

            ok($established->{$u1}, "Connection with $u1 established");
        }
        
        # Encrypt a message and send it to Alice
        {
            my $enc_msg = $bob->encrypt($u1, $m2);
            lock( @$alice_buf );
            push @$alice_buf, $enc_msg;
        }

        # Decrypt messages from Alice
        {
            my $rec_msg;
            my $dec_msg;

            until( $dec_msg )
            {
                {
                    lock( @$bob_buf );
                    $rec_msg = shift @$bob_buf;
                    $dec_msg = $bob->decrypt($u1, $rec_msg);
                }
                sleep 1;
            }

            ok( $dec_msg eq $m1, "Send: $m1 = Decrypted: $dec_msg");
        }

        sleep 2;
        
        # Monitor for SMP until the conversation is secure
        {
            my $sec_con;
            
            until( $sec_con )
            {
                my $msg;
                {
                    lock( @$bob_buf );
                    $msg = shift @$bob_buf;
                }
                
                if( $msg )
                {
                    my ($resp, $is_status) = $bob->decrypt($u1, $msg);
                    if($resp){
                        print "resp $resp\n";
                    }
                }

                my $smp_req;
                {
                    lock( %smp_request );
                    $smp_req = $smp_request{ $u1 };
                }

                # takes a few steps to finish SMP
                if( $smp_req )
                {
                    $bob->continue_smp($u1, $secret);
                    lock( %smp_request );
                    $smp_request{ $u1 } = 0;
                }
                
                {
                    lock( %secured );
                    $sec_con = $secured{ $u1 };
                }

                sleep 1;
            }
        }

        # Disconnect
        sleep 2;
        {
            $bob->finish($u1);

            my $dis;
            until( $dis )
            {
                {
                    lock( %disconnected );
                    $dis = $disconnected{ $u1 };
                }
            }

            ok( $dis, "Disconnected from $u1" );

			$multithread_done++;
        }

    };

    $_->join foreach ($alice_thread, $bob_thread);

    return 1;
}

sub test_init {
    my ($user, $dest) = @_;

    lock( $test_init );

    my $otr = new Crypt::OTR(
        account_name     => $user,
        protocol         => "crypt-otr-test",
        max_message_size => 2000, 
    );

    # callback to inject an encrypted message (add to recipient's buffer)
    my $inject = sub {
        my ( $ptr, $account_name, $protocol, $dest_account, $message) = @_;
        die "no message passed to inject" unless $message;
        lock( @$dest );
        push @$dest, $message;
    };

    # got a message from the OTR system (e.g. "Heartbeat received from alice")
    my $send_system_message = sub {
        my( $ptr, $account_name, $protocol, $dest_account, $message) = @_;
        
        if( $dest_account eq $u2 ){
            lock( @$bob_buf );
            push @$bob_buf, $message;
        }

        if( $dest_account eq $u1 ){
            lock( @$alice_buf );
            push @$alice_buf, $message;
        }
    };

    # created an unverified connection
    my $unverified_cb = sub {
        my($ptr, $username) = @_;

        pass("Unverified connection started with $username");
        lock( %connected );
        $connected{ $username } = 1;
        $established->{$username} = 1;
    };

    # created a verified connection, not tested yet
    # TODO: add tests for fingerprint verification
    my $verified_cb = sub {
        my($ptr, $username) = @_;
        
        pass("Secure connection established with $username");
        lock(%secured);
        $secured{ $username } = 1;
    };
    

    #### self-explanatory OTR callbacks below
    my $disconnected_cb = sub {
        my( $ptr, $username ) = @_;

        #print "Disconnected\n";

        lock( %disconnected );
        $disconnected{ $username } = 1;
    };
    my $error_cb = sub {
        my($ptr, $accountname, $protocol, $username, $title, $primary, $secondary) = @_;
        
        print "Error! -- $accountname -- $protocol -- $username -- $title -- $primary -- $secondary\n";
    };
    my $warning_cb = sub {
        my($ptr, $accountname, $protocol, $username, $title, $primary, $secondary) = @_;
        
        print "Warning! -- $accountname -- $protocol -- $username -- $title -- $primary -- $secondary\n";
    };
    my $info_cb = sub {
        my($ptr, $accountname, $protocol, $username, $title, $primary, $secondary) = @_;
        
        #print "Info -- $accountname -- $protocol -- $username -- $title -- $primary -- $secondary\n";

        if( $accountname eq $u2 ){
            lock( @$bob_info_buf );
            push @$bob_info_buf, $primary;
        }
    };
    
    my $new_fingerprint_cb = sub {
        my( $ptr, $accountname, $protocol, $username, $fingerprint) = @_;

		lock( %new_fingerprint );
		$new_fingerprint{ $username } = 1;
        
        pass("New fingerprint for $username = $fingerprint");
    };

    my $still_connected_cb = sub {
        my( $ptr, $username ) = @_;
        
        #print "Still connected with $username\n";
    };

    # socialist millionares protocol, where one party creates a shared
    # secret and the other party must generate the same secret
	my $smp_request_cb = sub {
		my( $ptr, $protocol, $username, $question ) = @_;
		
		if( $question ){
                    # this is never reached?
                    print "Question asked: $question\n";
		}
		
		pass("$username requesting SMP shared secret");

		lock( %smp_request );
		$smp_request{ $username } = 1;
	};

    # install callbacks
    $otr->set_callback('inject' => $inject);
    $otr->set_callback('otr_message' => $send_system_message);

    $otr->set_callback('verified' => $verified_cb);
    $otr->set_callback('unverified' => $unverified_cb);
    $otr->set_callback('disconnect' => $disconnected_cb);
    $otr->set_callback('still_connected' => $still_connected_cb);

    $otr->set_callback('error' => $error_cb);
    $otr->set_callback('warning' => $warning_cb);
    $otr->set_callback('info' => $info_cb);
    $otr->set_callback('smp_request' => $smp_request_cb);

    $otr->set_callback('new_fingerprint' => $new_fingerprint_cb);

    $otr->load_privkey;

    return $otr;
}

