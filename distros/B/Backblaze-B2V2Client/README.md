# NAME

Backblaze::B2V2Client - Client library for the Backblaze B2 Cloud Storage Service V2 API.

# SYNOPSIS

        use Backblaze::B2V2Client;

        # create an API client object

        my $b2client = Backblaze::B2V2Client->new(
                $application_key_id, $application_key
        );

        # please encrypt/protect those keys when not in use!

        # let's say we have a B2 bucket called 'GingerAnna' and a JPG called 'ginger_was_perfect.jpg'.

        # upload a file from your file system
        my $operation_status = $b2client->b2_upload_file(
                'bucket_name' => 'GingerAnna',
                'file_location' => '/path/to/ginger_was_perfect.jpg'
        );

        # upload a file you have in a scalar
        my $operation_status = $b2client->b2_upload_file(
                'bucket_name' => 'GingerAnna',
                'new_file_name' => 'ginger_was_perfect.jpg',
                'file_contents' => $file_contents
        );
        # B2 file ID (fGUID) is now in $b2client->{b2_response}{fileId}
        # Best to load $file_contents via Path::Tiny's slurp_raw() method

        # download that file to /opt/majestica/tmp
        my $operation_status = $b2client->b2_download_file_by_name('GingerAnna','ginger_was_perfect.jpg','/opt/majestica/tmp');

        # if you would rather download with the 84-character GUID
        my $operation_status = $b2client->b2_download_file_by_id('X-Bz-File-Id GUID from above','/opt/majestica/tmp');

        # you can leave off the directory to just have the file contents into
        # $b2client->{b2_response}{file_contents}

        # $operation_status is now 'OK' or 'Error', and is
        # also stashed in $b2client->{current_status}

        # check the status of the last operation
        use Data::Dumper; # hello old friend
        if ($b2client->{current_status} eq 'OK') {

                # all is well -- what did we get?
                print Dumper($b2client->{b2_response});

        } elsif ($b2client->{current_status} eq 'Error') {

                # what info do we have on this disaster?
                print Dumper($b2client->{errors}[-1]);

        }

# DESCRIPTION / SET UP

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

## b2\_client Command Line Utility

Backblaze::B2V2Client includes the 'b2\_client' command line utility to
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

For all the below, when they return $operation\_status, that will
be 'OK' or 'Error'.  If you get 'Error,' check out $b2client->{errors}\[-1\] .

## new

Creates the B2 client object and initiates an API session with B2.

Requires two arguments: the Application Key ID and Application Key
obtained from Backblaze.

## b2\_download\_file\_by\_id

Retrieves a file plus metadata given the GUID of that file.  The first
argument is required and will be the file's GUID.  If you would like
to auto-save the file, provide a path to an existing directory as the
second argument.

Regardless of auto-save, the file's raw contents will be placed in to
$b2client->{b2\_response}{file\_contents} and the following keys
will be populated under $b2client->{b2\_response}:

        Content-Length
        Content-Type
        X-Bz-File-Id
        X-Bz-File-Name
        X-Bz-Content-Sha1

See https://www.backblaze.com/b2/docs/b2\_download\_file\_by\_id.html

## b2\_download\_file\_by\_name

Works like b2\_download\_file\_by\_id() except that it expects the bucket name
and file name as arguments.  The optional third argument is an existing
directory path for auto-saving the file.

See https://www.backblaze.com/b2/docs/b2\_download\_file\_by\_name.html

## b2\_upload\_file

Uploads a new file into B2.  Accepts a hash of arguments.  The name
of the destination bucket must be provided in 'bucket\_name'.
If you would like to upload a file already saved on disk, specify
the complete file path in 'file\_location'.  Alternatively, if the file
is loaded up into a scalar, provide the new file name in 'new\_file\_name'
and assign the loaded scalar into 'file\_contents'.

Example 1: Uploading from a file on disk:

        my $operation_status = $b2client->b2_upload_file(
                'bucket_name' => 'GingerAnna',
                'file_location' => '/opt/majestica/tmp/ginger_was_perfect.jpg',
        );

Example 2: Uploading when the file is loaded into a scalar:

        my $operation_status = $b2client->b2_upload_file(
                'bucket_name' => 'GingerAnna',
                'new_file_name' => 'ginger_was_perfect.jpg',
                'file_contents' => $file_contents
        );

NOTE: If you are going to use the 'file\_contents' method, it's best
to load the scalar using the 'slurp\_raw' method in Path::Tiny.
(I believe 'read\_file' in File::Slurp will work, but have yet to test.)

You can also pass a 'content-type' key with the MIME type for the new
file.  The default is 'b2/auto'.

Upon a successful upload, the new GUID for the file will be available
in $b2client->{b2\_response}{fileId} .

See: https://www.backblaze.com/b2/docs/b2\_upload\_file.html

## b2\_upload\_large\_file

Uploads a large file into B2.  Recommended for uploading files larger
than 100MB. Accepts a hash of arguments, which
must include the name of the destination bucket in 'bucket\_name'
and the complete file path of the file in 'file\_location'.

Example:

        my $operation_status = $b2client->b2_upload_large_file(
                'bucket_name' => 'GingerAnna',
                'file_location' => '/opt/majestica/tmp/gingers_whole_life_story.mp4',
        );

## b2\_list\_file\_names

Required input is `$bucket_name` as the first parameter (required) and
an optional key-value hash of parameters.  These parameters can include:

- `prefix`

    Allows one to specify a filename prefix or directory path, useful for buckets
    with a large number of files or many subdirectories. Default is undefined.

- `delimiter`

    Allows one to specify what is considered the delimiter for the file `path` in
    the bucket. Default is undefined.

- `startFileName`

    Allows one to select where in the file list to start the results, since the max
    results for each call is 1000 files. This allows one to define the `start` for
    emulating pagination of the results.

- `maxFileCount`

    The default is 1000, the ultimate maximum per the specification. The module
    default may be accessed via the package variable, `$B2_MAX_FILE_COUNT`.

Retrieves an array of file information hashes for a given bucket name.
That array is added to @{ $b2client->{buckets}{$bucket\_name}{files} } and
returned as an array reference to the list of file objects.

See https://www.backblaze.com/b2/docs/b2\_list\_file\_names.html ,
especially the section for 'Response' to see what is included for those
file info hashes.

Note that B2 limits this response to 1000 entries, so if you have a very
large bucket, you can call this method several times and check the
value in $b2client->{buckets}{$bucket\_name}{next\_file\_name} after each call.

Example 1: Basic call:

        my $files_ref = $b2client->b2_list_file_names('MyBucketName');

Example 2: Basic call and capturing file list:

        my $files_ref = $b2client->b2_list_file_names('MyBucketName');

Example 3: Avoid initial API call to get `bucket_id`:

        # In order to avoid the initial API call to determine the BucketId, which is
        # actually what B2 wants, one may set this directly if known ahead of time:

        $b2client->{buckets}{q/MyBucketName/}->{bucket_id} = q{b9d516ba733afb62719c4};
        my $files_ref = $b2client->b2_list_file_names('MyBucketName');

Example 4: Using optional parameters to control results (Note: only `$bucket_name` is required):

        my $bucket_name = q{MyBucketName};
        my %args = (
                'prefix' => q{path/to/sub/directory/},
                'delimter' => undef,
                'startFileName' => undef,
                'maxFileCount' => $b2client::B2_MAX_FILE_COUNT
        );

        # $bucket_id look up hack
        $b2client->{buckets}{$bucket_name}->{bucket_id} = q{b9d516ba733afb62719c4};

        # actual call - parameter order matters
        my $files_ref = $b2client->b2_list_file_names($bucket_name, %args);

## b2\_get\_file\_info

Given a GUID for a file, will retrieve its info hash and load into
$b2client->{file\_info}{$file\_id}.

See https://www.backblaze.com/b2/docs/b2\_get\_file\_info.html ,
particularly the section for 'Response' to see what is provided.

Example:

        my $operation_status = $b2client->b2_get_file_info('AN84_CHAR_GUID_FROM_B2');

## b2\_bucket\_maker

Creates a new bucket in your B2 account, given the name for the new
bucket.  The bucket type will be set to 'allPrivate',

Will place the new bucket's ID into:

        my $operation_status = $b2client->{buckets}{$bucket_name}{bucket_id}

See: https://www.backblaze.com/b2/docs/b2\_create\_bucket.html

Example:

        my $operation_status = $b2client->b2_bucket_maker('NewBucketName');

By default the new bucket will be set to use the 'Server-Side 
Encryption with Backblaze-Managed Keys (SSE-B2)' option 
described here: https://www.backblaze.com/b2/docs/server\_side\_encryption.html
You can send a second param to disable that (not recommended):

        my $operation_status = $b2client->b2_bucket_maker('UnEncryptedBucketName', 1);
        

Also, if your app key does not have the 'writeBucketEncryption' then 
encryption will be disabled.

## b2\_delete\_bucket

Deletes a bucket from your B2 account, provided that it is empty.
Requires the target bucket's name as the argument.

See: https://www.backblaze.com/b2/docs/b2\_delete\_bucket.html

Example:

        my $operation_status = $b2client->b2_delete_bucket('DeletingBucketName');

## b2\_delete\_file\_version

Deletes a version of a file, AKA a stored object.  If you use unique
file names for each file you upload, then one version equals one file.
If you upload multiple files with the same name under a single bucket,
you will create multiple versions of a particular file in B2.

The required arguments are the file name and the file ID.

Example:

        my $operation_status = $b2client->b2_delete_file_version('SomeFileName.ext','AN84_CHAR_GUID_FROM_B2');

## b2\_talker / b2\_get\_upload\_url  / b2\_list\_buckets

b2\_talker() handles all the communications with B2.
You should be able to use this to make calls not explicitly
provided by this library.

If b2\_talker() gets a 200 HTTP status from B2, then the call went
great, the JSON response will be loaded into $b2client->{b2\_response},
and $b2client->{current\_status} will be set to 'OK'.

If a 200 is not received from B2, $b2client->{current\_status} will be
set to 'Error' and a hash error details will be added to
@{ $b2client->{errors} }.  That hash usually includes the
called URL, the returned status code, and the error message.

Note that the base URL for this API session will be stored
under $b2client->{api\_url} so that you build a URL like so:

$list\_buckets\_url = $b2client->{api\_url}.'/b2api/v2/b2\_list\_buckets';

Example of a GET API request:

        my $operation_status = $b2client->b2_talker(
                'url' => 'https://SomeB2.API.URL?with=GETparams',
                'authorization' => $b2client->{account_authorization_token},
        );

Example of a POST API request:

        my $operation_status = $b2client->b2_talker(
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
token and upload URL.  You can retrieve these via b2\_get\_upload\_url()
with the bucket name as an argument.

Example:

        my $operation_status = $b2client->b2_get_upload_url('MyBucketName');

This populates:

        my $operation_status = $b2client->{bucket_info}{'MyBucketName'} = {
                'upload_url' => $b2client->{b2_response}{uploadUrl},
                'authorization_token' => $b2client->{b2_response}{authorizationToken},
        };

Note: You have to call b2\_get\_upload\_url on a bucket for each file
upload operation.  My b2\_upload\_file method does that for you, so that's
just FYI if you roll your own.

See: https://www.backblaze.com/b2/docs/b2\_get\_upload\_url.html

If you need the ID for one or more buckets, you can use b2\_list\_buckets.  If
a bucket name is provided, only that bucket's ID will be retrieved.  If no
argument is provided, all the ID's will be retrieved for all buckets in your
account.

Example:

        my $operation_status = $b2client->b2_list_buckets('MyBucketName');

You now have $b2client->{buckets}{'MyBucketName'}{bucket\_id}

See: https://www.backblaze.com/b2/docs/b2\_list\_buckets.html

# DEPENDENCIES

This module requires:

        Cpanel::JSON::XS
        Digest::SHA
        MIME::Base64
        Path::Tiny
        URI::Escape
        WWW::Mechanize
        LWP::Protocol::https

In order to get this to work properly on Ubuntu 18.04 and 20.04, I installed these
system packages:

        build-essential
        zlib1g-dev
        libssl-dev
        cpanminus
        perl-doc

# SEE ALSO

B2 API Docs:  https://www.backblaze.com/b2/docs/

Backblaze::B2 - V1 API Client for B2

Paws::S3 - If using Backblaze's S3-compatible API.

# AUTHOR / BUGS

Eric Chernoff <ericschernoff@gmail.com> - Please send me a note with any bugs or suggestions.

ESTRABD <estrabd@cpan.org> - Enhanced b2\_list\_file\_names() to fully use options and a great bugfix 
when using the 'file\_contents' option in the b2\_upload\_file() method.

# LICENSE

MIT License

Copyright (c) 2021 Eric Chernoff

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
