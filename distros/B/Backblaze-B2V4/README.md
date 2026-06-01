[![Actions Status](https://github.com/ericschernoff/backblaze-b2v4/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/ericschernoff/backblaze-b2v4/actions?workflow=test)
# NAME

Backblaze::B2V4 - Client library for the Backblaze B2 Cloud Storage Service V4 API.

# SYNOPSIS

        use Backblaze::B2V4;

        # create an API client object

        my $b2 = Backblaze::B2V4->new(
                application_key => $application_key,
                application_key_id => $application_key_id,
        );

        # please encrypt/protect those keys when not in use!

        # let's say we have a B2 bucket called 'GingerAnna' and a JPG called 'ginger_was_perfect.jpg'.

        # upload a file from your file system
        my $response = $b2->b2_upload_file(
                bucket_name => 'GingerAnna',
                file_location => '/path/to/ginger_was_perfect.jpg'
        );

        # upload a file you have in a scalar
        my $response = $b2->b2_upload_file(
                bucket_name => 'GingerAnna',
                new_file_name => 'ginger_was_perfect.jpg',
                file_contents => $file_contents
        );
        # B2 file ID (fGUID) is now in $response->{fileId}
        # Best to load $file_contents via Path::Tiny's slurp_raw() method

        # download that file to /opt/majestica/tmp
        my $response = $b2->b2_download_file_by_name(
                bucket_name => 'GingerAnna', 
                file_name => 'ginger_was_perfect.jpg', 
                save_to_location => '/opt/majestica/tmp'
        );

        # if you would rather download with the 84-character GUID
        my $response = $b2->b2_download_file_by_id(
                file_id => 'X-Bz-File-Id GUID from above',
                save_to_location => '/opt/majestica/tmp'
        );
        
        # For all of these $response is the output from the B2 V4 API
        
        # to confirm all is well
        my $all_is_well = $b2->current_status_is_not_ok != 1;
        
        # to get the latest error
        print $b2->latest_error();
        # if none, will be 'No error message found'

# DESCRIPTION / SET UP

This module should help you create buckets and store/retrieve files in the
Backblaze B2 cloud storage service using V4 of their API.

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

## b2\_client Command Line Utility

Backblaze::B2V4 includes the 'b2\_client' command line utility to
easily download or upload files from B2.  Please execute 'b2\_client help'
for more details, and here are a few examples:

        # download a file to current directory
        b2_client get MyPictures FamilyPhoto.jpg
        
        # download a file to a target directory
        b2_client get MyPictures FamilyPhoto.jpg /home/ginger/photos
        
        # upload a file to B2
        b2_client put MyPictures /home/ginger/photos/AnotherFamilyPhoto.jpg

There is also an official command line utility from Backblaze that does a
whole lot more: 

        https://www.backblaze.com/b2/docs/quick_command_line.html

## BackBlaze B2 also has a S3-compatible API

Backblaze has added an S3-compatible API, which you can read about here:

        https://www.backblaze.com/b2/docs/s3_compatible_api.html

They are continuing to support their native B2 API, so I will continue
to use and support this module.  I have not tested the S3 modules with
Backblaze, but if you already have an S3 integration, it is worth
checking out how Paws::S3 or Awes::S3 works with Backblaze.

## Testing Your Credentials

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

# METHODS

## new

Creates the B2 client object and initiates an API session with B2.

Requires two arguments: 
	application\_key => the Application Key from Backblaze,
	application\_key\_id => the Application Key ID from Backblze,

Returns your B2 client object.

## b2\_download\_file\_by\_id

Retrieves a file plus metadata given the GUID of that file.  
The 'file\_id' argument is required and will be the file's GUID.  
If you would like to auto-save the file, provide a path to an 
existing directory via the 'save\_to\_location' argument.

On success, will return the $response hashref with these keys:

        file_contents
        content-length
        content-type
        x-bz-file-id
        x-bz-file-name
        x-bz-content-sha1

See https://www.backblaze.com/b2/docs/b2\_download\_file\_by\_id.html

## b2\_download\_file\_by\_name

Works like b2\_download\_file\_by\_id() except that it expects 'bucket\_name'
and 'file\_name' named arguments arguments.  
If you would like to auto-save the file, provide a path to an 
existing directory via the 'save\_to\_location' argument.

See https://www.backblaze.com/b2/docs/b2\_download\_file\_by\_name.html

## b2\_upload\_file

Uploads a new file into B2. Accepts these named arguments:

        bucket_name => required, name of destination bucket,
        content_type => optional mime type; defaults to b2/x-auto,
        file_location => optional, full path of file to upload incl name
        new_file_name => optional, filename for file on B2
        file_contents => optional scalar with file contents

If you do not provide 'file\_location', then you need to provide
'new\_file\_name' and 'file\_contents' (or vice versa).
If you are going to use the 'file\_contents' method, it's best
to load the scalar using the 'slurp\_raw' method in Path::Tiny.
(I believe 'read\_file' in File::Slurp will work, but have yet to test.)

If successful, returns the GUID for the new file (aka the fileId); otherwise
returns 0.
See: https://www.backblaze.com/b2/docs/b2\_upload\_file.html

Example 1: Uploading from a file on disk:

        my $file_id = $b2->b2_upload_file(
                'bucket_name' => 'GingerAnna',
                'file_location' => '/opt/majestica/tmp/ginger_was_perfect.jpg',
        );

Example 2: Uploading when the file is loaded into a scalar:

        my $file_id = $b2->b2_upload_file(
                'bucket_name' => 'GingerAnna',
                'new_file_name' => 'ginger_was_perfect.jpg',
                'file_contents' => $file_contents
        );

## b2\_upload\_large\_file

Uploads a large file into B2.  Recommended for uploading files larger
than 100MB. 

Example:

        my $file_id = $b2->b2_upload_large_file(
                'bucket_name' => 'GingerAnna',
                'file_location' => '/opt/majestica/tmp/gingers_whole_life_story.mp4',
        );

## b2\_list\_file\_info

Retrieves an arrayref hashrefs with file infomrmation for a bucket. 
Backblaze calls if 'b2\_list\_file\_names' but it really is for file info.
Limited to 10,000 file results per call, so you will may need to 
call repeatedly to retrieve all names.  

NOTE: You are billed per 1,000 results returned.

Accepts these named arguments

        bucket_name => required, the name of the target bucket,
        prefix => optional, if seeking files that start with a given string,
        start_file_name => optional, the file name to start listing 10,000 files from
        delimiter => optional (default '/') used if you have folders within your bucket,

See https://www.backblaze.com/b2/docs/b2\_list\_file\_names.html ,
especially the section for 'Response' to see what is included for those
file info hashes.

Basic call:

        my $files_ref = $b2->b2_list_file_names(
                bucket_name => 'MyBucketName'
        );

## b2\_get\_file\_info

Given a GUID for a file, will retrieve its info a $response hash
See https://www.backblaze.com/b2/docs/b2\_get\_file\_info.html 

        my $response = $b2->b2_get_file_info(
                file_id => 'AN84_CHAR_GUID_FROM_B2'
        );

## b2\_bucket\_maker

Creates a new bucket in your B2 account, given the name for the new
bucket.  The bucket type will be set to 'allPrivate'

Returns 1 (success) or 0 (failure)

Accepts named args:

        bucket_name => required, the name of the new bucket
        disable_encryption => optional, 1 or 0 and defaults to 0 --> have the encryption

See: https://www.backblaze.com/b2/docs/b2\_create\_bucket.html

Note that B2 bucket namess must be unique system-wide, not just your account. 
Select a name that willbe unique globally.

Example:

        my $success = $b2->b2_bucket_maker(
                bucket_name => 'NewBucketName'
        );

By default the new bucket will be set to use the 'Server-Side 
Encryption with Backblaze-Managed Keys (SSE-B2)' option 
described here: https://www.backblaze.com/b2/docs/server\_side\_encryption.html
You can send a second param to disable that (not recommended):

        my $success = $b2->b2_bucket_maker(
                bucket_name => 'UnEncryptedBucketName', 
                disable_encryption => 1
        );
        

Also, if your app key does not have the 'writeBucketEncryption' then 
encryption will be disabled.

## b2\_delete\_bucket

Deletes a bucket from your B2 account, provided that it is empty.

Requires the target bucket's name as the 'bucket\_name' argument.

Returns 1 (success) or 0 (failure)

See: https://www.backblaze.com/b2/docs/b2\_delete\_bucket.html

Example:

        my $success = $b2->b2_delete_bucket(
                bucket_name => 'DeletingBucketName'
        );

## b2\_delete\_file\_version

Deletes a version of a file, AKA a stored object.  If you use unique
file names for each file you upload, then one version equals one file.
If you upload multiple files with the same name under a single bucket,
you will create multiple versions of a particular file in B2.

Required named args

        file_name => the name of the file
        file_id => the Backblaze GUID for the file

Returns 1 (success) or 0 (failure)

        my $success = $b2->b2_delete_file_version(
                file_name => 'SomeFileName.ext',
                file_id => 'AN84_CHAR_GUID_FROM_B2'
        );

## send\_request / b2\_get\_upload\_info  / b2\_list\_buckets

send\_request() handles all the communications with B2.
You should be able to use this to make calls not explicitly
provided by this library.

If send\_request() gets a 200 HTTP status from B2, then the call went
great, $b2->current\_status\_is\_not\_ok will be 0, and 
the JSON response will be returned.

If a 200 is not received from B2, $b2->current\_status\_is\_not\_ok
will be 1, and you can find an error in $b2->latest\_error()

Note that the base URL for this API session will be stored
under $b2->api\_info->{api\_url} so that you build a URL like so:

$list\_buckets\_url = $b2->api\_info->{api\_url}.'/b2api/v4/b2\_list\_buckets';

Example of a GET API request:

        my $response = $b2->send_request(
                'url' => 'https://SomeB2.API.URL?with=GETparams',
        );

Example of a POST API request:

        my $response = $b2->send_request(
                'url' => 'https://SomeB2.API.URL',
                'post_params' => {
                        'param1_name' => 'param1_value',
                        'param2_name' => 'param2_value',
                        'param3_name' => 'param3_value',
                },
        );

Almost all the API calls use the Account Authorization Token for the
authorization header, but the file uploader calls require a bucket-specific
token and upload URL.  You can retrieve these via b2\_get\_upload\_info()
with the bucket name as an argument.

Example:

        my $results = $b2->b2_get_upload_info(
                bucket_name => 'MyBucketName'
        );

The %$results hash now has 'upload\_url' and 'authorization\_token'

Note: You have to call b2\_get\_upload\_info on a bucket for each file
upload operation.  My b2\_upload\_file method does that for you, so that's
just FYI if you roll your own.

See: https://www.backblaze.com/b2/docs/b2\_get\_upload\_info.html

If you need the ID for one or more buckets, you can use b2\_list\_buckets.  If
a bucket name is provided, only that bucket's ID will be retrieved.  If no
argument is provided, all the ID's will be retrieved for all buckets in your
account.

Example:

        my $bucket_id = $b2->b2_list_buckets(
                'bucket_name' => 'MyBucketName'
        );

See: https://www.backblaze.com/b2/docs/b2\_list\_buckets.html

# DEPENDENCIES

This module requires:

        Cpanel::JSON::XS
        Digest::SHA
        HTTP::Request
        LWP::Protocol::https
        LWP::UserAgent
        Marlin
        MIME::Base64
        Path::Tiny
        URI::Escape

# SEE ALSO

B2 API V4 Docs: https://www.backblaze.com/apidocs/b2-authorize-account

Paws::S3 - If using Backblaze's S3-compatible API.

# AUTHOR / BUGS

Eric Chernoff <eric@weaverstreet.net> - Please send me a note with any bugs or suggestions.

ESTRABD <estrabd@cpan.org> - Enhanced b2\_list\_file\_names() to fully use options and a great bugfix 
when using the 'file\_contents' option in the b2\_upload\_file() method.

# LICENSE

MIT License

Copyright (c) 2026 Eric Chernoff

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
