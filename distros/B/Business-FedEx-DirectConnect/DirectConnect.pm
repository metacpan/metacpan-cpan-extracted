# FedEx::DirectConnect
# $Id: DirectConnect.pm,v 1.27 2004/08/09 16:07:20 jay.powers Exp $
# Copyright (c) 2004 Jay Powers
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself

package Business::FedEx::DirectConnect; #must be in Business/FedEx

require 5.006_000;

use Business::FedEx::Constants qw(
    %FE_RE %FE_SE %FE_TT %FE_RQ
    field_name_to_tag
    field_tag_to_name
);

use Carp qw(confess croak);
use LWP::UserAgent;

our $VERSION = '1.01';

use strict;


#Please register with FedEx to receive the addresses to their DirectConnect API.
use constant FEDEX_API_URI => '';

# Use Tie::IxHash so that fields are output in the order they're set,
# which makes reading the list of fields easier if you set them in a
# useful order.
#
# XXX only use IxHash when a debug flag is set?

{ my $have_ix_hash;
sub _init_ix_hash {
    my ($rhash, $rdata) = @_;

    $have_ix_hash = !!eval { local $SIG{__DIE__}; require Tie::IxHash }
    if !defined $have_ix_hash;

    if ($have_ix_hash) {
    tie %$rhash, 'Tie::IxHash', @$rdata;
    }
    else {
        %$rhash = @$rdata;
    }
} }

sub new {
    my $name = shift;
    my $class = ref($name) || $name;
    my $self  = {
                 uri=>FEDEX_API_URI
                ,acc => ''
                ,meter => ''
                ,referer => ''
                ,Debug=>0
                ,sdata => {}
                ,@_ };
    $self->{UA} = LWP::UserAgent->new(
                          exists $self->{timeout}
                              ? (timeout => $self->{timeout})
                              : ()
                    );
    $self->{REQ} = HTTP::Request->new(POST => $self->{uri}); # Create a request
    bless ($self, $class);
}

sub get_data {
    my $self = shift;
    my @key = @_;

    if (!@key) {
        return $self->{sdata};
    }

    if (@key > 1 && !wantarray) {
        croak "scalar context but asked for ", 0+@key, " items";
    }

    my $r = $self->{sdata};
    my @ret;
    for my $key (@key) {
        # This sucks, but the key might be present as either a number
        # or a name (or both, there's nothing which prevents that
        # currently).
        #
        # Check first as they passed it (in case it's there both ways):

        #print "key=$key\n";
        if (exists $r->{$key}) {
            push @ret, $r->{$key};
            next;
        }

        # Then as a number:

        my $tag = field_name_to_tag $key;
        #print "tag=$tag\n";
        if (exists $r->{$tag}) {
            push @ret, $r->{$tag};
            next;
        }        

        # Then as a name:

        my $name = field_tag_to_name $key;
        #print "name=$name\n";
        if (exists $r->{$name}) {
            push @ret, $r->{$name};
            next;
        }        

        # It isn't there.

        print "undef\n";
        push @ret, undef;
    }

    return wantarray ? @ret : $ret[0];
}

sub set_data {
    my $self = shift;
    $self->{UTI} = shift;
    $self->{sdata} = {};
    _init_ix_hash $self->{sdata}, \@_;
    if (!$self->{UTI}) {
        $self->set_err("Error: You must provide a valid UTI.");
        return 0;
    }
    $self->{sbuf} = '0,"' . $FE_TT{$self->{UTI}}[0] . '"';

    # Supply default values where appropriate.

    for ([3025 => $FE_TT{$self->{UTI}}[1]]
            , [10 => $self->{acc}]
            , $self->{UTI} == 3003 ? () : [498 => $self->{meter}]
            ) {
        my ($key, $val) = @$_;
        $self->{sdata}->{$key} = $val
            unless exists $self->{sdata}->{$key};
    }
        
    while (my ($key, $val) = each %{$self->{sdata}}) {
        $key = field_name_to_tag $key;

        # Empty value should not be sent (except for 99).

        next if !defined $val;
        next if $val !~ /\S/;

        # Alphanumeric fields should not contain leading or
        # trailing blanks.

        $val =~ s/^\s+//;
        $val =~ s/\s+\z//;

        # %-escape as necessary

        $val =~ s/([%"\x00])/sprintf '%%%02X', ord $1/eg;

        # XXX The TT guide says the data needs to be ASCII only (though
        # it didn't choke on Latin 1 chars I tried sending it), but
        # there's no way for me to do the translation here since I don't
        # know what char set you're using.  Croak if there are non-ASCII
        # data?

        $self->{sbuf} .= qq($key,"$val");
    }
    $self->{sbuf} .= '99,""';
    return $self->{sbuf};
}

# Send a call to FedEx
sub transaction {
    my $self = shift;
    if (@_) {
        $self->{sbuf} = shift;
    }
    if (!$self->{sbuf}) {
        $self->set_err("Error: You must provide data to send to FedEx.");
        return 0;
    }

    if ($self->_send())    { # send POST to FedEx
        $self->{rbuf} =~ s/[\x00\s]+$//g; # get rid of the extra spaces/nulls
        $self->{rstring} = "Total bytes returned ". length($self->{rbuf}) if ($self->{Debug});
        print $self->{rstring} . "\n" if ($self->{Debug});
        $self->{rHash} = $self->_split_data()
            or return 0;
        # Check for Errors from FedEx
        if (exists $self->{rHash}->{2}) {
            $self->set_err("FedEx Transaction Error: " . $self->{rHash}->{2} . " " . $self->{rHash}->{3},
                            $self->{rHash}->{2});
            return 0;
        }
        return 1;
    } else {
        return 0;
    }
}


# Send POST request to FedEx API
sub _send {
    my $self = shift;      
    print "Sending ". $self->{sbuf} . "\n" if ($self->{Debug}); 
    $self->{REQ}->header(()
    ,'Referer' => $self->{referer}
    ,'User-Agent' => 'Business-FedEx-DirectConnect-'.$VERSION
    ,'Accept' => "image/gif,image/jpeg,image/pjpeg,text/plain,text/html,*/*"
    ,'Content-Type' => "image/gif"
    ,'Content-Length' => length($self->{sbuf}));
    $self->{sbuf} .= '99,""' unless ($self->{sbuf} =~ /99,\"\"$/);
    $self->{REQ}->content($self->{sbuf});
    print $self->{REQ}->as_string() if ($self->{Debug});
    # Pass request to the user agent and get a response back
    my $res = $self->{UA}->request($self->{REQ});
    # Check the outcome of the response
    if ($res->is_success) {
        $self->{rbuf} = $res->content;
        return 1;
    } else {
        $self->set_err("Request Error: " . $res->status_line);
        return 0;
    }
}

# here are some functions to deal with data from FedEx
sub _split_data {
    my $self = shift;
    my $sdata = shift || $self->{rbuf};
    my $count = 0;
    my (%hash, @key);

    if (!defined $sdata) {
        $self->set_err("No data received from FedEx server");
        return;
    }

    # There ought to be a way to signal less serious errors without
    # choking completely, or a way for the user to tell you to notice
    # them.

    my $warn = 0;

    while ($sdata ne '') {
        if ($sdata !~ s/^(0|[1-9]\d*(?:-\d*)*),"([^"]*)"//) {
            $self->set_err("Invalid FedEx transaction data at `$sdata'");
            return;
        }
        my ($key, $val) = ($1, $2);

        if (exists $hash{$key}) {
            $self->set_err("Duplicate key $key in FedEx transaction");
            return;
        }

        if ($warn && $val eq '' && $key ne '99') {
            $self->set_err("Empty value for key $key in FedEx transaction");
            return;
        }

        push @key, $key;
        $hash{$key} = $val;
    }

    if ($warn && $key[0] ne '0') {
        $self->set_err("first element of FedEx transaction data isn't 0");
        return;
    }

    if ($warn && $key[-1] ne '99') {
        $self->set_err("last element of FedEx transaction data isn't 99");
        return;
    }

    if ($warn && $hash{99} ne '') {
        $self->set_err("non-empty value for last element of FedEx transaction data");
        return;
    }

    # XXX validate \d+-\d+ type fields

    return \%hash;
}


# array of all the required fields
sub required {
    my $self = shift;
    my $uti = shift;
    my @req;
    foreach (@{$FE_RQ{$uti}}) {
        push (@req, $FE_RE{$_});
    }
    return @req;
}

#check against required fields
# XXX Why are you passing in the UTI instead of using $self->{UTI}?
sub has_required {
    my $self = shift;
    my $uti = shift;
    my @keys = keys %{$self->{sdata}};
    my (%seen, @diff);
    @seen{@keys} = ();
    # XXX 0 is in %FE_RQ but not in sdata
    $seen{0} = undef;
    foreach (@{$FE_RQ{$uti}}) {
        push(@diff, $_) unless exists $seen{$_};
    }
    return @diff
}
# print or create a label
sub label {
    my $self = shift;
    my $file = shift;
    my $image_key = shift || 188;
    $self->{rbinary} = $self->{rHash}->{$image_key};
    $self->{rbinary} =~ s/\%([0-9A-F][0-9A-F])/chr(hex("0x$1"))/eg if ($self->{rbinary});
    if ($file) {
        open(FILE, ">$file") or die "Could not open $file:\n$!";
        binmode(FILE);
        print FILE $self->{rbinary};
        close(FILE);
        return 1;
    } else {
        return $self->{rbinary};
    }
}
#look up a value
sub lookup {
    my $self = shift;
    my $code = field_name_to_tag shift;
    print "Looking for " . $code . "\n" if ($self->{Debug});
    return $self->{rHash}->{$code};
}
# All the data from FedEx
sub rbuf {
    my $self = shift;
    $self->{rbuf} = shift if @_;
    return $self->{rbuf};
}
# Build a hash from the return data from FedEx
sub hash_ret {
    my $self = shift;
    return $self->{rHash};
}

sub errstr {
    my $self = shift;
    $self->{errstr} = shift if @_;
    return $self->{errstr};
}

sub errcode {
    my $self = shift;
    $self->{errcode} = shift if @_;
    return $self->{errcode};
}

sub set_err {
    my $self = shift;
    my $errstr = @_ ? shift : "Unknown error";
    my $errcode = @_ ? shift : -1;
    @_ and confess;

    $self->errstr($errstr);
    $self->errcode($errcode);
}

sub user_data {
    @_ == 1 || @_ == 2
        or croak "->user_data expected 0 or 1 args, got ", 0+@_;
    my $self = shift;
    my $old = $self->{user_data};
    $self->{user_data} = shift if @_;
    return $old;
}

1;
__END__

=head1 NAME

Business::FedEx::DirectConnect - FedEx Ship Manager Direct Connect

=head1 SYNOPSIS

        use Business::FedEx::DirectConnect;

        my $t = Business::FedEx::DirectConnect->new(uri=>''
                                        ,acc => '' #FedEx Account Number
                                        ,meter => '' #FedEx Meter Number (This is given after you subscribe to FedEx)
                                        ,referer => 'Vermonster' # Name or Company
                                        ,Debug => 1
                                        );

        # 2016 is the UTI for FedEx.  If you don't know what this is
        # you need to read the FedEx Documentation.
        # http://www.fedex.com/globaldeveloper/shipapi/
        # The hash values are case insensitive.
        $t->set_data(2016,
            'sender_company' => 'Vermonster LLC',
            'sender_address_line_1' => '312 stuart st',
            'sender_city' => 'Boston',
            'sender_state' => 'MA',
            'sender_postal_code' => '02134',
            'recipient_contact_name' => 'Jay Powers',
            'recipient_address_line_1' => '44 Main street',
            'recipient_city' => 'Boston',
            'recipient_state' => 'Ma',
            'recipient_postal_code' => '02116',
            'recipient_phone_number' => '6173335555',
            'weight_units' => 'LBS',
            'sender_country_code' => 'US',
            'recipient_country' => 'US',
            'sender_phone_Number' => '6175556985',
            'packaging_type' => '01',
            'service_type' => '03',
            'total_package_weight' => '1.0',
            'label_type' => '1',
            'label_printer_type' => '1',
            'label_media_type' => '6',
            'drop_off_type' => '1'
        ) or die $t->errstr;

        $t->transaction() or die $t->errstr;

        print "Tracking# ". $t->lookup('tracking_number');

        $t->label("myLabel.png");


=head1 DESCRIPTION

This module provides the necessary means to send transactions to FedEx's
Ship Manager Direct API.  Precautions have been taken to enforce FedEx's API guidelines
to allow for all transaction types.

This module is an alternative to using the FedEx Ship Manager API ATOM product.
Business::FedEx::DirectConnect will provide the same communication using LWP and
Crypt::SSLeay.

The main advantage is you will no longer need to install the JRE dependant API
provided by FedEx.  Instead, data is POST(ed) directly to the FedEx transaction servers.

When using this module please keep in mind FedEx will occasionally change some of the
transaction codes for their API.  This should not break existing code, but it is a good idea
to check out changes when possible.  I document all the changes in a "Changes" log.

=head1 REQUIREMENTS

To submit a transaction to FedEx's Gateway server you must have a valid
FedEx Account Number and a FedEx Meter Number (except for tracking transactions).  To gain access
and receive a Meter Number you must send a Subscribe() #3003 request to FedEx containing your FedEx
account number and contact information.  There is an example of this request below.
FedEx has two API servers, one for live transactions and a beta server for testing.
Per requests from FedEx I can no longer include the URIs to their test and
beta servers.  It is very important that you contact FedEx to register first before you use their APIs.
FedEx will provide you with the information you need to get up and running.
Also, Vermonster LLC provides a service to help you get setup, registered and certified with FedEx.
Please contact us at http://vermonster.com/contact/ if you need more information.

You will need to subscribe to each server you intend to use.  FedEx will also require you
to send a batch of defined data to their live server in order to become certified for live
label creation.

This module uses LWP to POST request information so it is a requirement to have LWP installed.
Also, you will need SSL encryption to access https URIs.  I recommend installing Crypt::SSLeay
Please refer to the FedEx documentation at http://www.fedex.com/globaldeveloper/shipapi/
Here you will find more information about using the FedEx API.  You will need to know
what UTI is needed to send your request.

Here is a sample Subscription Transaction

    $t->set_data(3003,
        1 => 'unique12345',
        4003 => 'John Doe',
        4008 => '123 Main St',
        4011 => 'Boston',
        4012 => 'MA',
        4013 => '02116',
        4014 => 'US',
        4015 => '6175551111',
    ) or die $t->errstr;


This call will return a FedEx Meter number so you can use the FedEx API.  The meter number
will be referenced in field 498.  $t->lookup(498);

=head1 FedEx UTI

Sited from FedEx Documentation.  See http://www.fedex.com/globaldeveloper/shipapi
for more information.

"The Universal Transaction Identifier (UTI) is a unique integral code that 
has been assigned to a given transaction type. For example, the UTI of the tagged 
Transaction Type "021" (FedEx Express global Ship a Package Request) is 2016.
UTIs are unique not just within the tagged transaction set, but across all transaction 
sets that have been or will be approved for transmission via the API.

The UTI accompanying a transaction indicates where it should be routed within the FedEx 
systems. The FedEx server recognizes the UTI passed and will direct the request
to the correct business server."

Valid UTIs are listed below:

uti  = request / reply Carrier Description 

    1002 = 007 / 107 FDXG End-of-day close
    1005 = 023 / 123 FDXE FedEx Express Delete-A-Package
    2016 = 021 / 121 FDXE FedEx Express Ship-A-Package
    2017 = 022 / 122 FDXE Global Rate-A-Package
    2018 = 019 / 119 FDXE Service Availability
    2024 = 025 / 125 ALL Rate Available Services
    3000 = 021 / 121 FDXE FedEx Ground Ship-A-Package
    3001 = 023 / 123 FDXG FedEx Ground Delete-A-Package
    3003 = 211 / 311 ALL Subscription
    3004 = 022 / 122 FDXG Global Rate-A-Package
    5000 = 402 / 502 ALL Track By Number, Destination, Ship Date, and Reference
    5001 = 405 / 505 ALL Signature Proof of Delivery

=head1 COMMON METHODS

The methods described in this section are available for all C<FedEx::DirectConnect> objects.

=over 4

=item new(%hash)

The new method is the constructor.  The input hash can inlude the following:

    uri     / URI to the FedEx Transaction Server
    acc     / The nine-digit FedEx account
    meter   / The FedEx meter login number (obtain after running a subscribe request)
    referer / Used to identify yourself to FedEx
    Debug   / 0 or 1, print out debug information
    timeout / Set a timeout for the LWP user agent (could also access the UA directly.
              see below)

The LWP UserAgent object is accessable and can be modified if nessessary:

    my $t = new Business::FedEx::DirectConnect(
         uri=>''
        ,acc=>'123456789'
        ,meter=>'1234567');

    $t->{UA}->proxy(http=>'https://172.0.0.1');

=item $t->set_data(UTI, %hash)

This method will accept a valid FedEx UTI number and a hash of values.  The first
arg must be a valid UTI. Using these values set_data will construct and return a
valid FedEx request string.

Assuming you pass a valid FedEx UTI this method will find the correct
Transaction Number for you.  You need not pass this in.  Also no need to pass in your
FedEx Account Number or Meter Number.  You should pass these when creating a new
Business::FedEx::DirectConnect object.

This method will allow you to use either the number field provided in the FedEx
documentation or the hash (case insensitive) %FE_RE found in Business::FedEx::Constants.
If the hash key you pass is not present in Business::FedEx::Constants you will
be warned.

Here is a tracking example where 29 is the "tracking number" field FedEx has
provided.

    $t->set_data(5000, 'tracking_number'=>'836603877972') or die $t->errstr;

is the same as

    $t->set_data(5000, 29 =>'836603877972') or die $t->errstr;

=item $t->get_data($field_name_or_tag...)

This method returns data set with C<$t-E<gt>set_data>.  With no args it
returns a reference to the underlying hash, otherwise it returns the
corresponding values.

=item $t->has_required(UTI)

Check the required fields and return an array of missing fields if any.  Currently, this
function only does a simple check on most common fields.  There are conditional fields that will
be added later.  For example, if the ship_date > today you will be required to pass
a future_day_shipment flag.  This function does not have this level of functionality yet.

=item $t->required(UTI)

Method to return the required fields for a given FedEx UTI.

=item $t->transaction()

Send transaction to FedEx. Optionally you can pass the full request string if you choose not to use
the set_data method.  Returns the full reply from FedEx.

=item $t->label('someLabel.png')

This method will decode the binary image data from FedEx and save it to a file.  
If nothing is passed the binary data string will be returned.  You can also pass an image
key if binary data is stored in a different field.  The default is 188 for FedEx labels.
For example, if you wanted to access a COD buffer stream you would pass a 411.
$t->label('COD.png', 411);

=item $t->lookup('tracking_number')

This method will return the value for an item returned from FedEx.  Refer to
the C<Business::FedEx::Constants> %FE_RE hash to see all possible values.

=item $t->rbuf()

Returns the decoded string portion of the FedEx reply.

=item $t->hash_ret()

Returns a hash of the FedEx reply values

    my $stuff= $t->hash_ret;

    foreach (keys %{$stuff}) {
        print $_. ' => ' . $stuff->{$_} . "\n";
    }

=item $t->errstr()

Returns an error code and message

    $t->transaction() || die 'Error: '.$t->errstr();

=item $t->errcode()

Returns just an error code, useful for programatic handling of errors.  Note that
the return code is alphanumeric (and not just a number).
    
    if (!$t->transaction())
    {
        if ($t->errcode() eq '0038') # 0038 is an invalid tracking number
        {
            [..code relating to an invalid tracking number..]
        }
    }

=item $t->user_data(I<new_data>)

The object provides a place for you to store a scalar.  This method
optionally sets it to the value you specify, and returns the old value.

=back

=head1 ERRORS/BUGS

=over 4

=item Request Error: 501 Protocol scheme 'https' is not supported

This will occur if your LWP does not support SSL (i.e. https).  I suggest
installing the L<Crypt::SSLeay> module.

=back

=head1 IDEAS/TODO

Build methods for each type of transaction so you don't need to
know UTIs and other FedEx codes. FedEx Express Ship-A-Package UTI 2016 
would be called via $object->FDXE_ship();

Build for multiple request.  FedEx currently can only accept
one transaction per request. I might try something with LWP::Parallel::UserAgent.

Better parsing for the FedEx return data.

=head1 AUTHOR

Jay Powers, <F<jpowers@cpan.org>>

L<http://www.vermonster.com>

Copyright (c) 2004 Jay Powers

Many thanks to Roderick from IBC for his help improving this module.

All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself

If you have any questions, comments or suggestions please feel free 
to contact me.

=head1 SEE ALSO

L<Crypt::SSLeay>, L<LWP::UserAgent>, L<Business::FedEx::Constants>

=cut
