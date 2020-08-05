package Backblaze::B2V2Client;
# API client library for V2 of the API to Backblaze B2 object storage
# Allows for creating/deleting buckets, listing files in buckets, and uploading/downloading files

$Backblaze::B2V2Client::VERSION = '1.3';

# our dependencies:
use Cpanel::JSON::XS;
use Digest::SHA qw(sha1_hex);
use MIME::Base64;
use Path::Tiny;
use URI::Escape;
use WWW::Mechanize;

# I wish I could apply this to my diet.
use strict;

# object constructor; will automatically authorize this session
sub new {
	my $class = shift;

	# required args are the account ID and application_key
	my ($application_key_id, $application_key) = @_;

	# cannot operate without these
	if (!$application_key_id || !$application_key) {
		die "ERROR: Cannot create B2V5Client object without both application_key_id and application_key arguments.\n";
	}

	# initiate class with my keys + WWW::Mechanize object
	my $self = bless {
		'application_key_id' => $application_key_id,
		'application_key' => $application_key,
		'mech' => WWW::Mechanize->new(
			timeout => 60,
			autocheck => 0,
			cookie_jar => {},
			keep_alive => 1,
		),
	}, $class;

	# now start our B2 session via method below
	$self->b2_authorize_account();  # this adds more goodness to $self for use in the other methods

	return $self;
}

# method to start your backblaze session:  authorize the account and get your api URL's
sub b2_authorize_account {
	my $self = shift;

	# prepare our authorization header
	my $encoded_auth_string = encode_base64($self->{application_key_id}.':'.$self->{application_key});

	# add that header in
	$self->{mech}->add_header( 'Authorization' => 'Basic '.$encoded_auth_string );

	# call the b2_talker() method to authenticate our session
	$self->b2_talker('url' => 'https://api.backblazeb2.com/b2api/v2/b2_authorize_account' );

	# if we succeeded, load in our authentication and prepare to proceed
	if ($self->{current_status} eq 'OK') {

		$self->{account_id} = $self->{b2_response}{accountId};
		$self->{api_url} = $self->{b2_response}{apiUrl};
		$self->{account_authorization_token} = $self->{b2_response}{authorizationToken};
		$self->{download_url} = $self->{b2_response}{downloadUrl};
		# for uploading large files
		$self->{recommended_part_size} = $self->{b2_response}{recommendedPartSize} || 104857600;
		# ready!

	# otherwise, not ready!
	} else {
		$self->{b2_login_error} = 1;
	}

}

# method to download a file by ID; probably most commonly used
sub b2_download_file_by_id {
	my $self = shift;

	# required arg is the file ID
	# option arg is a target directory to auto-save the new file into
	my ($file_id, $save_to_location) = @_;

	if (!$file_id) {
		$self->error_tracker('The file_id must be provided for b2_download_file_by_id().');
		return;
	}

	# send the request, as a GET
	$self->b2_talker(
		'url' => $self->{download_url}.'/b2api/v2/b2_download_file_by_id?fileId='.$file_id,
		'authorization' => $self->{account_authorization_token},
	);

	# if the file was found, you will have the relevant headers in %{ $self->{b2_response} }
	# as well as the file's contents in $self->{b2_response}{file_contents}

	# if they provided a save-to location (a directory) and the file was found, let's save it out
	if ($self->{current_status} eq 'OK' && $save_to_location) {
		$self->save_downloaded_file($save_to_location);
	}


}

# method to download a file via the bucket name + file name
sub b2_download_file_by_name {
	my $self = shift;

	# required args are the bucket name and file name
	my ($bucket_name, $file_name, $save_to_location) = @_;

	if (!$bucket_name || !$file_name) {
		$self->error_tracker('The bucket_name and file_name must be provided for b2_download_file_by_name().');
		return;
	}

	# send the request, as a GET
	$self->b2_talker(
		'url' => $self->{download_url}.'/file/'.uri_escape($bucket_name).'/'.uri_escape($file_name),
		'authorization' => $self->{account_authorization_token},
	);


	# if the file was found, you will have the relevant headers in %{ $self->{b2_response} }
	# as well as the file's contents in $self->{b2_response}{file_contents}

	# if they provided a save-to location (a directory) and the file was found, let's save it out
	if ($self->{current_status} eq 'OK' && $save_to_location) {
		$self->save_downloaded_file($save_to_location);
	}

}

# method to save downloaded files into a target location
# only call after successfully calling b2_download_file_by_id() or b2_download_file_by_name()
sub save_downloaded_file {
	my $self = shift;

	# required arg is a valid directory on this file system
	my ($save_to_location) = @_;

	# error out if that location don't exist
	if (!$save_to_location || !(-d "$save_to_location") ) {
		$self->error_tracker("Can not auto-save file without a valid location. $save_to_location");
		return;
	}

	# make sure they actually downloaded a file
	if ( !$self->{b2_response}{'X-Bz-File-Name'} || !length($self->{b2_response}{file_contents}) ) {
		$self->error_tracker("Can not auto-save without first downloading a file.");
		return;
	}

	# still here?  do the save

	# add the filename
	$save_to_location .= '/'.$self->{b2_response}{'X-Bz-File-Name'};

	# i really love Path::Tiny
	path($save_to_location)->spew_raw( $self->{b2_response}{file_contents} );

}

# method to upload a file into Backblaze B2
sub b2_upload_file {
	my $self = shift;

	my (%args) = @_;
	# this must include valid entries for 'new_file_name' and 'bucket_name'
	# and it has to include either the raw file contents in 'file_contents'
	# or a valid location in 'file_location'
	# also, you can include 'content_type' (which would be the MIME Type'
	# if you do not want B2 to auto-determine the MIME/content-type

	# did they provide a file location or path?
	if ($args{file_location} && -e "$args{file_location}") {
		$args{file_contents} = path( $args{file_location} )->slurp_raw;

		# if they didn't provide a file-name, use the one on this file
		$args{new_file_name} = path( $args{file_location} )->basename;
	}

	# were these file contents either provided or found?
	if (!length($args{file_contents})) {
		$self->error_tracker(qq{You must provide either a valid 'file_location' or 'file_contents' arg for b2_upload_file().});
		return;
	}

	# check the other needed args
	if (!$args{bucket_name} || !$args{new_file_name}) {
		$self->error_tracker(qq{You must provide 'bucket_name' and 'new_file_name' args for b2_upload_file().});
		return;
	}

	# default content-type
	$args{content_type} ||= 'b2/x-auto';

	# OK, let's continue:  get the upload URL and authorization token for this bucket
	$self->b2_get_upload_url( $args{bucket_name} );

	# send the special request
	$self->b2_talker(
		'url' => $self->{bucket_info}{ $args{bucket_name} }{upload_url},
		'authorization' => $self->{bucket_info}{ $args{bucket_name} }{authorization_token},
		'file_contents' => $args{file_contents},
		'special_headers' => {
			'X-Bz-File-Name' => uri_escape( $args{new_file_name} ),
			'X-Bz-Content-Sha1' => sha1_hex( $args{file_contents} ),
			'Content-Type' => $args{content_type},
		},
	);

	# b2_talker will handle the rest

}

# method to get the information needed to upload into a specific B2 bucket
sub b2_get_upload_url {
	my $self = shift;

	# the bucket name is required
	my ($bucket_name) = @_;

	# bucket_name is required
	if (!$bucket_name) {
		$self->error_tracker('The bucket_name must be provided for b2_get_upload_url().');
		return;
	}

	# no need to proceed if we already have done for this bucket this during this session
	# return if $self->{bucket_info}{$bucket_name}{upload_url};
	# COMMENTED OUT:  It seems like B2 wants a new upload_url endpoint for each upload,
	# and we may want to upload multiple files into each bucket...so this won't work

	# if we don't have the info for the bucket name, retrieve the bucket's ID
	if (ref($self->{buckets}{$bucket_name}) ne 'HASH') {
		$self->b2_list_buckets($bucket_name);
	}

	# send the request
	$self->b2_talker(
		'url' => $self->{api_url}.'/b2api/v2/b2_get_upload_url',
		'authorization' => $self->{account_authorization_token},
		'post_params' => {
			'bucketId' => $self->{buckets}{$bucket_name}{bucket_id},
		},
	);

	# if we succeeded, get the info for this bucket
	if ($self->{current_status} eq 'OK') {

		$self->{bucket_info}{$bucket_name} = {
			'upload_url' => $self->{b2_response}{uploadUrl},
			'authorization_token' => $self->{b2_response}{authorizationToken},
		};

	}

}

# method to get information on one bucket or all buckets
# specify the bucket-name to search by name
sub b2_list_buckets {
	my $self = shift;

	# optional first arg is a target bucket name
	# optional second arg tells us to auto-create a bucket, if the name is provided but it was not found
	my ($bucket_name, $auto_create_bucket) = @_;

	# send the request
	$self->b2_talker(
		'url' => $self->{api_url}.'/b2api/v2/b2_list_buckets',
		'authorization' => $self->{account_authorization_token},
		'post_params' => {
			'accountId' => $self->{account_id},
			'bucketName' => $bucket_name,
		},
	);

	# if we succeeded, load in all the found buckets to $self->{buckets}
	# that will be a hash of info, keyed by name

	if ($self->{current_status} eq 'OK') {
		foreach my $bucket_info (@{ $self->{b2_response}{buckets} }) {
			$bucket_name = $$bucket_info{bucketName};

			$self->{buckets}{$bucket_name} = {
				'bucket_id' => $$bucket_info{bucketId},
				'bucket_type' => $$bucket_info{bucketType},
			};
		}
	}

	# if that bucket was not found, maybe they want to go ahead and create it?
	if ($bucket_name && !$self->{buckets}{$bucket_name} && $auto_create_bucket) {
		$self->b2_bucket_maker($bucket_name);
		# this will call back to me and get the info
	}

}

# method to retrieve file names / info from a bucket
# this client library is bucket-name-centric, so it looks for the bucket name as a arg
# if there are more than 1000 files, then call this repeatedly
sub b2_list_file_names {
	my $self = shift;

	my ($bucket_name) = @_;

	# bucket_name is required
	if (!$bucket_name) {
		$self->error_tracker('The bucket_name must be provided for b2_list_file_names().');
		return;
	}

	# we need the bucket ID
	# if we don't have the info for the bucket name, retrieve the bucket's ID
	if (ref($self->{buckets}{$bucket_name}) ne 'HASH') {
		$self->b2_list_buckets($bucket_name);
	}

	# retrieve the files
	$self->b2_talker(
		'url' => $self->{api_url}.'/b2api/v2/b2_list_file_names',
		'authorization' => $self->{account_authorization_token},
		'post_params' => {
			'accountId' => $self->{account_id},
			'bucketId' => $self->{buckets}{$bucket_name}{bucket_id},
			'startFileName' => $self->{buckets}{$bucket_name}{next_file_name},
		},
	);

	# if we succeeded, read in the files
	if ($self->{current_status} eq 'OK') {
		$self->{buckets}{$bucket_name}{next_file_name} = $self->{b2_response}{nextFileName};

		# i am not going to waste the CPU cycles de-camelizing these sub-keys
		# add to our possibly-started array of file info for this bucket
		push(
			@{ $self->{buckets}{$bucket_name}{files} },
			@{ $self->{b2_response}{files} }
		);
	}


}

# method to get info for a specific file
# I assume you have the File ID for the file
sub b2_get_file_info {
	my $self = shift;

	# required arg is the file ID
	my ($file_id) = @_;

	if (!$file_id) {
		$self->error_tracker('The file_id must be provided for b2_get_file_info().');
		return;
	}

	# kick out if we already have it
	return if ref($self->{file_info}{$file_id}) eq 'HASH';

	# retrieve the file information
	$self->b2_talker(
		'url' => $self->{api_url}.'/b2api/v2/b2_get_file_info',
		'authorization' => $self->{account_authorization_token},
		'post_params' => {
			'fileId' => $file_id,
		},
	);

	# if we succeeded, read in the information
	if ($self->{current_status} eq 'OK') {
		# i am not going to waste the CPU cycles de-camelizing these sub-keys
		$self->{file_info}{$file_id} = $self->{b2_response};
	}

}

# combo method to create a bucket
sub b2_bucket_maker {
	my $self = shift;

	my ($bucket_name) = @_;

	# can't proceed without the bucket_name
	if (!$bucket_name) {
		$self->error_tracker('The bucket_name must be provided for b2_bucket_maker().');
		return;
	}

	# create the bucket...
	$self->b2_talker(
		'url' => $self->{api_url}.'/b2api/v2/b2_create_bucket',
		'authorization' => $self->{account_authorization_token},
		'post_params' => {
			'accountId' => $self->{account_id},
			'bucketName' => $bucket_name,
			'bucketType' => 'allPrivate',
		},
	);

	if ($self->{current_status} eq 'OK') { # if successful...

		# stash our new bucket into $self->{buckets}
		$self->{buckets}{$bucket_name} = {
			'bucket_id' => $self->{b2_response}{bucketId},
			'bucket_type' => 'allPrivate',
		};

	}

}

# method to delete a bucket -- please don't use ;)
sub b2_delete_bucket {
	my $self = shift;

	my ($bucket_name) = @_;

	# bucket_id is required
	if (!$bucket_name) {
		$self->error_tracker('The bucket_name must be provided for b2_delete_bucket().');
		return;
	}

	# resolve that bucket_name to a bucket_id
	$self->b2_list_buckets($bucket_name);

	# send the request
	$self->b2_talker(
		'url' => $self->{api_url}.'/b2api/v2/b2_delete_bucket',
		'authorization' => $self->{account_authorization_token},
		'post_params' => {
			'accountId' => $self->{account_id},
			'bucketId' => $self->{buckets}{$bucket_name}{bucket_id},
		},
	);

}

# method to delete a stored file object.  B2 thinks of these as 'versions,'
# but if you use unique names, one version = one file
sub b2_delete_file_version {
	my $self = shift;

	# required arguments are the file_name and file_id for the target file
	my ($file_name, $file_id) = @_;

	# bucket_id is required
	if (!$file_name || !$file_id) {
		$self->error_tracker('The file_name and file_id args must be provided for b2_delete_file_version().');
		return;
	}

	# send the request
	$self->b2_talker(
		'url' => $self->{api_url}.'/b2api/v2/b2_delete_file_version',
		'authorization' => $self->{account_authorization_token},
		'post_params' => {
			'fileName' => $file_name,
			'fileId' => $file_id,
		},
	);


}

# method to upload a large file (>100MB)
sub b2_upload_large_file {
	my $self = shift;
	my (%args) = @_;
	# this must include valid entries for 'new_file_name' and 'bucket_name'
	# and it has to a valid location in 'file_location' (Do not load in file contents)
	# also, you can include 'content_type' (which would be the MIME Type'
	# if you do not want B2 to auto-determine the MIME/content-type

	# did they provide a file location or path?
	if ($args{file_location} && -e "$args{file_location}") {
		# if they didn't provide a file-name, use the one on this file
		$args{new_file_name} = path( $args{file_location} )->basename;
	} else {
		$self->error_tracker(qq{You must provide a valid 'file_location' arg for b2_upload_large_file().});
		return;
	}

	# protect my sanity...
	my ($bucket_name, $file_contents_part, $file_location, $large_file_id, $part_number, $remaining_file_size, $sha1_array, $size_sent, $stat);
	$file_location = $args{file_location};
	$bucket_name = $args{bucket_name};

	# must be 100MB or bigger
	$stat = path($file_location)->stat;
	if ($stat->size < $self->{recommended_part_size} ) {
		$self->error_tracker(qq{Please use b2_upload_large_file() for files larger than $self->{recommended_part_size} .});
		return;
	}

	# need a bucket name
	if (!$bucket_name) {
		$self->error_tracker(qq{You must provide a valid 'bucket_name' arg for b2_upload_large_file().});
		return;
	}

	# default content-type
	$args{content_type} ||= 'b2/x-auto';

	# get the bucket ID
	$self->b2_list_buckets($bucket_name);

	# kick off the upload in the API
	$self->b2_talker(
		'url' => $self->{api_url}.'/b2api/v2/b2_start_large_file',
		'authorization' => $self->{account_authorization_token},
		'post_params' => {
			'bucketId' => $self->{buckets}{$bucket_name}{bucket_id},
			'fileName' => $args{new_file_name},
			'contentType' => $args{content_type},
		},
	);

	# these are all needed for each b2_upload_part web call
	$large_file_id = $self->{b2_response}{fileId};
	return if !$large_file_id; # there was an error in the request

	# open the large file
	open(FH, $file_location);

	$remaining_file_size = $stat->size;

	$part_number = 1;

	# cycle thru each chunk of the file
	while ($remaining_file_size >= 0) {
		# how much to send?
		if ($remaining_file_size < $self->{recommended_part_size} ) {
			$size_sent = $remaining_file_size;
		} else {
			$size_sent = $self->{recommended_part_size} ;
		}

		# get the next upload url for this part
		$self->b2_talker(
			'url' => $self->{api_url}.'/b2api/v2/b2_get_upload_part_url',
			'authorization' => $self->{account_authorization_token},
			'post_params' => {
				'fileId' => $large_file_id,
			},
		);

		# read in that section of the file and prep the SHA
		sysread FH, $file_contents_part, $size_sent;
		push(@$sha1_array,sha1_hex( $file_contents_part ));

		# upload that part
		$self->b2_talker(
			'url' => $self->{b2_response}{uploadUrl},
			'authorization' => $self->{b2_response}{authorizationToken},
			'special_headers' => {
				'X-Bz-Content-Sha1' => $$sha1_array[-1],
				'X-Bz-Part-Number' => $part_number,
				'Content-Length' => $size_sent,
			},
			'file_contents' => $file_contents_part,
		);

		# advance
		$part_number++;
		$remaining_file_size -= $self->{recommended_part_size} ;
	}

	# close the file
	close FH;

	# and tell B2
	$self->b2_talker(
		'url' => $self->{api_url}.'/b2api/v2/b2_finish_large_file',
		'authorization' => $self->{account_authorization_token},
		'post_params' => {
			'fileId' => $large_file_id,
			'partSha1Array' => $sha1_array,
		},
	);

	# phew, i'm tired...
}


# generic method to handle communication to B2
sub b2_talker {
	my $self = shift;

	# args hash must include 'url' for the target API endpoint URL
	# most other requests will also include a 'post_params' hashref, and 'authorization' value for the header
	# for the b2_upload_file function, there will be several other headers + a file_contents arg
	my (%args) = @_;

	if (!$args{url}) {
		$self->error_tracker('Can not use b2_talker() without an endpoint URL.');
	}

	# if they sent an Authorization header, set that value
	if ($args{authorization}) {
		$self->{mech}->delete_header( 'Authorization' );
		$self->{mech}->add_header( 'Authorization' => $args{authorization} );
	}

	my ($response, $response_code, $error_message, $header, @header_keys);

	# short-circuit if we had difficulty logging in previously
	if ($self->{b2_login_error}) {

		# track the error / set current state
		$self->error_tracker("Problem logging into Backblaze.  Please check the 'errors' array in this object.", $args{url});

		return;
	}

	# are we uploading a file?
	if ($args{url} =~ /b2_upload_file|b2_upload_part/) {

		# add the special headers
		@header_keys = keys %{ $args{special_headers} };
		foreach $header (@header_keys) {
			$self->{mech}->delete_header( $header );
			$self->{mech}->add_header( $header => $args{special_headers}{$header} );
		}

		# now upload the file
		eval {
			$response = $self->{mech}->post( $args{url}, content => $args{file_contents} );

			# we want this to be 200
			$response_code = $response->{_rc};

			$self->{b2_response} = decode_json( $self->{mech}->content() );

		};

		# remove those special headers, cleaned-up for next time
		foreach $header (@header_keys) {
			$self->{mech}->delete_header( $header );
		}

	# if not uploading and they sent POST params, we are doing a POST
	} elsif (ref($args{post_params}) eq 'HASH') {
		eval {
			# send the POST
			$response = $self->{mech}->post( $args{url}, content => encode_json($args{post_params}) );

			# we want this to be 200
			$response_code = $response->code;

			# decode results
			$self->{b2_response} = decode_json( $self->{mech}->content() );
		};

	# otherwise, we are doing a GET
	} else {

		# attempt the GET
		eval {
			$response = $self->{mech}->get( $args{url} );

			# we want this to be 200
			$response_code = $response->code;

			# did we download a file?
			if ($response->header( 'X-Bz-File-Name' )) {

				# grab those needed headers
				foreach $header ('Content-Length','Content-Type','X-Bz-File-Id','X-Bz-File-Name','X-Bz-Content-Sha1') {
					$self->{b2_response}{$header} = $response->header( $header );
				}

				# and the file itself
				$self->{b2_response}{file_contents} = $self->{mech}->content();

			} elsif ($response_code eq '200') { # no, regular JSON, decode results
				$self->{b2_response} = decode_json( $self->{mech}->content() );
			}
		};
	}

	# there is a problem if there is a problem
	if ($@ || $response_code ne '200') {
		if ($self->{b2_response}{message}) {
			$error_message = 'API Message: '.$self->{b2_response}{message};
		} else {
			$error_message = 'Error: '.$@;
		}

		# track the error / set current state
		$self->error_tracker($error_message, $args{url}, $response_code);

	# otherwise, we are in pretty good shape
	} else {

		$self->{current_status} = 'OK';
	}

}

# for tracking errors into $self->{errrors}[];
sub error_tracker {
	my $self = shift;

	my ($error_message, $url, $response_code) = @_;
	# required is the error message; optional is the URL we were trying to call,
	# and the HTTP status code returned in that API call

	return if !$error_message;

	# defaults
	$url ||= 'N/A';
	$response_code ||= 'N/A';

	# we must currently be in an error state
	$self->{current_status} = 'Error';

	# track the error
	push(@{ $self->{errors} }, {
		'error_message' => $error_message,
		'url' => $url,
		'response_code' => $response_code,
	});

}

# please tell me the lastest error message
sub latest_error {
	my $self = shift;

	# don't fall for the old "Modification of non-creatable array value attempted" trick
	return 'No error message found' if !$self->{errors}[0];

	my $error = $self->{errors}[-1];
	return $$error{error_message}.' ('.$$error{response_code}.')';

}

1;

__END__

=head1 NAME

Backblaze::B2V2Client - Client library for the Backblaze B2 Cloud Storage Service V2 API.

=head1 VERSION

1.0 - Initial working version.

=head1 SYNOPSIS

	use Backblaze::B2V2Client;

	# create an API client object

	$b2client = Backblaze::B2V2Client->new(
		$application_key_id, $application_key
	);

	# please encrypt/protect those keys when not in use!

	# let's say we have a B2 bucket called 'GingerAnna' and a JPG called 'ginger_was_perfect.jpg'.

	# upload a file from your file system
	$b2client->b2_upload_file(
		'bucket_name' => 'GingerAnna',
		'file_location' => '/path/to/ginger_was_perfect.jpg'
	);

	# upload a file you have in a scalar
	$b2client->b2_upload_file(
		'bucket_name' => 'GingerAnna',
		'new_file_name' => 'ginger_was_perfect.jpg',
		'file_contents' => $file_contents
	);
	# B2 file ID (fGUID) is now in $b2client->{b2_response}{fileId}
	# Best to load $file_contents via Path::Tiny's slurp_raw() method

	# download that file to /opt/majestica/tmp
	$b2client->b2_download_file_by_name('GingerAnna','ginger_was_perfect.jpg','/opt/majestica/tmp');

	# if you would rather download with the 84-character GUID
	$b2client->b2_download_file_by_id('X-Bz-File-Id GUID from above','/opt/majestica/tmp');

	# you can leave off the directory to just have the file contents into
	# $b2client->{b2_response}{file_contents}

	# check the status of the last operation
	use Data::Dumper; # hello old friend
	if ($b2client->{current_status} eq 'OK') {

		# all is well -- what did we get?
		print Dumper($b2client->{b2_response});

	} elsif ($b2client->{current_status} eq 'Error') {

		# what info do we have on this disaster?
		print Dumper($b2client->{errors}[-1]);

	}

=head1 DESCRIPTION / SET UP

This module should help you create buckets and store/retrieve files in the
Backblaze B2 cloud storage service using V2 of their API.

Backblaze makes it easy to sign up for B2 from here:

	https://www.backblaze.com/b2/sign-up.html

Then enable the B2 service as per these instructions:

	https://www.backblaze.com/b2/docs/quick_account.html

Next, visit the 'App Keys' section of the 'My Account' area, and look for
the 'Add a New Application Key' button to create an application key.  You
will need a key with Read and Write access.  Be sure to note the Application Key
ID  as well as the Application Key itself. They do not show you that Application
Key again, so copy it immediately.

Please store the Application Key pair in a secure way, preferably encrypted
when not in use by your software.

=head2 BackBlaze B2 also has a S3-compatible API

Backblaze has added an S3-compatible API, which you can read about here:

	https://www.backblaze.com/b2/docs/s3_compatible_api.html

They are continuing to support their native B2 API, so I will continue
to use and support this module.  I have not tested the S3 modules with
Backblaze, but if you already have an S3 integration, it is worth
checking out how Paws::S3 or Awes::S3 works with Backblaze.

=head2 Testing Your Credentials

During install, this module will attempt to connect to B2 and download
a 16KB file into memory. To test using your B2 account
credentials, set these environmental varables prior to attempting
to install:

	B2_APP_KEY_ID - The application key ID for the key you wish to test.
	B2_APP_KEY - The application key -- is never displayed in the B2 UI.
	B2_ACCT_ID - Your account ID; will be the ID of your master key
	B2_TEST_FILE_ID: The long (75+ char) GUID for your target file.

The GUID for a file is displayed when you click on that file's name
in the 'Browse Files' section of the B2 UI.

=head1 METHODS

=head2 new

Creates the B2 client object and initiates an API session with B2.

Requires two arguments: the Application Key ID and Application Key
obtained from Backblaze.

=head2 b2_download_file_by_id

Retrieves a file plus metadata given the GUID of that file.  The first
argument is required and will be the file's GUID.  If you would like
to auto-save the file, provide a path to an existing directory as the
second argument.

Regardless of auto-save, the file's raw contents will be placed in to
$b2client->{b2_response}{file_contents} and the following keys
will be populated under $b2client->{b2_response}:

	Content-Length
	Content-Type
	X-Bz-File-Id
	X-Bz-File-Name
	X-Bz-Content-Sha1

See https://www.backblaze.com/b2/docs/b2_download_file_by_id.html

=head2 b2_download_file_by_name

Works like b2_download_file_by_id() except that it expects the bucket name
and file name as arguments.  The optional third argument is an existing
directory path for auto-saving the file.

See https://www.backblaze.com/b2/docs/b2_download_file_by_name.html

=head2 b2_upload_file

Uploads a new file into B2.  Accepts a hash of arguments.  The name
of the destination bucket must be provided in 'bucket_name'.
If you would like to upload a file already saved on disk, specify
the complete file path in 'file_location'.  Alternatively, if the file
is loaded up into a scalar, provide the new file name in 'new_file_name'
and assign the loaded scalar into 'file_contents'.

Example 1: Uploading from a file on disk:

	$b2client->b2_upload_file(
		'bucket_name' => 'GingerAnna',
		'file_location' => '/opt/majestica/tmp/ginger_was_perfect.jpg',
	);

Example 2: Uploading when the file is loaded into a scalar:

	$b2client->b2_upload_file(
		'bucket_name' => 'GingerAnna',
		'new_file_name' => 'ginger_was_perfect.jpg',
		'file_contents' => $file_contents
	);

NOTE: If you are going to use the 'file_contents' method, it's best
to load the scalar using the 'slurp_raw' method in Path::Tiny.
(I believe 'read_file' in File::Slurp will work, but have yet to test.)

You can also pass a 'content-type' key with the MIME type for the new
file.  The default is 'b2/auto'.

Upon a successful upload, the new GUID for the file will be available
in $b2client->{b2_response}{fileId} .

See: https://www.backblaze.com/b2/docs/b2_upload_file.html

=head2 b2_upload_large_file

Uploads a large file into B2.  Recommended for uploading files larger
than 100MB. Accepts a hash of arguments, which
must include the name of the destination bucket in 'bucket_name'
and the complete file path of the file in 'file_location'.

Example:

	$b2client->b2_upload_large_file(
		'bucket_name' => 'GingerAnna',
		'file_location' => '/opt/majestica/tmp/gingers_whole_life_story.mp4',
	);

=head2 b2_list_file_names

Retrieves an array of file information hashes for a given bucket name.
That array is added to @{ $b2client->{buckets}{$bucket_name}{files} }.

See https://www.backblaze.com/b2/docs/b2_list_file_names.html ,
especially the section for 'Response' to see what is included for those
file info hashes.

Note that B2 limits this response to 1000 entries, so if you have a very
large bucket, you can call this method several times and check the
value in $b2client->{buckets}{$bucket_name}{next_file_name} after each call.

Example:

	$b2client->b2_list_file_names('MyBucketName');

=head2 b2_get_file_info

Given a GUID for a file, will retrieve its info hash and load into
$b2client->{file_info}{$file_id}.

See https://www.backblaze.com/b2/docs/b2_get_file_info.html ,
particularly the section for 'Response' to see what is provided.

Example:

	$b2client->b2_get_file_info('AN84_CHAR_GUID_FROM_B2');

=head2 b2_bucket_maker

Creates a new bucket in your B2 account, given the name for the new
bucket.  The bucket type will be set to 'allPrivate'.

Will retrieve the new bucket's ID into:

	$b2client->{buckets}{$bucket_name}{bucket_id}

See: https://www.backblaze.com/b2/docs/b2_create_bucket.html

Example:

	$b2client->b2_bucket_maker('NewBucketName');

=head2 b2_delete_bucket

Deletes a bucket from your B2 account, provided that it is empty.
Requires the target bucket's name as the argument.

See: https://www.backblaze.com/b2/docs/b2_delete_bucket.html

Example:

	$b2client->b2_delete_bucket('DeletingBucketName');

=head2 b2_delete_file_version

Deletes a version of a file, AKA a stored object.  If you use unique
file names for each file you upload, then one version equals one file.
If you upload multiple files with the same name under a single bucket,
you will create multiple versions of a particular file in B2.

The required arguments are the file name and the file ID.

Example:

	$b2client->b2_delete_file_version('SomeFileName.ext','AN84_CHAR_GUID_FROM_B2');

=head2 b2_talker / b2_get_upload_url  / b2_list_buckets

b2_talker() handles all the communications with B2.
You should be able to use this to make calls not explicitly
provided by this library.

If b2_talker() gets a 200 HTTP status from B2, then the call went
great, the JSON response will be loaded into $b2client->{b2_response},
and $b2client->{current_status} will be set to 'OK'.

If a 200 is not received from B2, $b2client->{current_status} will be
set to 'Error' and a hash error details will be added to
@{ $b2client->{errors} }.  That hash usually includes the
called URL, the returned status code, and the error message.

Note that the base URL for this API session will be stored
under $b2client->{api_url} so that you build a URL like so:

$list_buckets_url = $b2client->{api_url}.'/b2api/v2/b2_list_buckets';

Example of a GET API request:

	$b2client->b2_talker(
		'url' => 'https://SomeB2.API.URL?with=GETparams',
		'authorization' => $b2client->{account_authorization_token},
	);

Example of a POST API request:

	$b2client->b2_talker(
		'url' => 'https://SomeB2.API.URL',
		'authorization' => $b2client->{account_authorization_token},
		'post_params' => {
			'param1_name' => 'param1_value',
			'param2_name' => 'param2_value',
			'param3_name' => 'param3_value',
		},
	);

Almost all the API calls use the Account Authorization Token for the
authorization header, but the file uploader calls require a bucket-specific
token and upload URL.  You can retrieve these via b2_get_upload_url()
with the bucket name as an argument.

Example:

	$b2client->b2_get_upload_url('MyBucketName');

This populates:

	$b2client->{bucket_info}{'MyBucketName'} = {
		'upload_url' => $b2client->{b2_response}{uploadUrl},
		'authorization_token' => $b2client->{b2_response}{authorizationToken},
	};

Note: You have to call b2_get_upload_url on a bucket for each file
upload operation.  My b2_upload_file method does that for you, so that's
just FYI if you roll your own.

See: https://www.backblaze.com/b2/docs/b2_get_upload_url.html

If you need the ID for one or more buckets, you can use b2_list_buckets.  If
a bucket name is provided, only that bucket's ID will be retrieved.  If no
argument is provided, all the ID's will be retrieved for all buckets in your
account.

Example:

	$b2client->b2_list_buckets('MyBucketName');

You now have $b2client->{buckets}{'MyBucketName'}{bucket_id}

See: https://www.backblaze.com/b2/docs/b2_list_buckets.html

=head1 DEPENDENCIES

This module requires:

	Cpanel::JSON::XS
	Digest::SHA
	MIME::Base64
	Path::Tiny
	URI::Escape
	WWW::Mechanize
	LWP::Protocol::https

In order to get this to work properly on Ubuntu 18.04, I installed these
system packages:

	build-essential
	zlib1g-dev
	libssl-dev
	cpanminus
	perl-doc

=head1 SEE ALSO

B2 API Docs:  https://www.backblaze.com/b2/docs/

Backblaze::B2 - V1 API Client for B2

Paws::S3 - If using Backblaze's S3-compatible API.

=head1 AUTHOR / BUGS

Eric Chernoff <eric@weaverstreet.net>

Please send me a note with any bugs or suggestions.

Thanks to ESTRABD for submitting a bugfix when using the 'file_contents' option in the b2_upload_file() method.

=head1 LICENSE

MIT License

Copyright (c) 2020 Eric Chernoff

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
