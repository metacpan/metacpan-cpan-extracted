AWS-Signature4
==============

This is a Perl module for generating Version 4 signatures for use with
Amazon Web Services. It can be used to add authentication information
to the headers of GET, POST, PUT and DELETE.

The module can be also used to generate "signed" URLs. These are
preauthorized URLs that contain all the authentication and header
information in the URL query parameters. They can be sent to another
user to, for example, grant time-limited access to a private S3
bucket.

Relationship to Other Signature Modules
=======================================

This module has overlapping functionality with
Net::Amazon::Signature::V4, WebService::Amazon::Signature::v4, and
Net::Amazon::SignatureVersion4. None of these modules offers the
option of generating a signed URL, so you will want to use
AWS::Signature4 if you need this functionality. Other than that, the
current module is pretty simple to use and hides all of the details of
generating signed requests while remaining generic.

SYNOPSIS
========

<pre>
 use AWS::Signature4;
 use HTTP::Request::Common;
 use LWP;

 my $signer = AWS::Signature4->new(-access_key => 'AKIDEXAMPLE',
                                   -secret_key => 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY');
 my $ua     = LWP::UserAgent->new();

 # Example GET request on a URI
 my $uri     = URI->new('https://iam.amazonaws.com');
 $uri->query_form(Action=>'ListUsers',
		  Version=>'2010-05-08');

 my $url      = $signer->signed_url($uri); # This gives a signed URL that can be fetched by a browser
 my $response = $ua->get($url);            # Fetch it

 $time_limited_url = $signer->signed_url($uri,60*60); # This gives a signed URL valid for one hour

 # Example POST request
 my $request = POST('https://iam.amazonaws.com',
		    [Action=>'ListUsers',
		     Version=>'2010-05-08']
                    );
 $signer->sign($request);                 # This signs the request
 my $response = $ua->request($request);  #  Fetch it
</pre>

INSTALLATION
============

<pre>
 perl Build.PL
 ./Build test
 sudo ./Build install
</pre>

DEVELOPMENT SITE
================

This source code for this module is hosted at
https://github.com/lstein/AWS-Signature4, where you can also file bug
reports and feature requests.

AUTHOR & LICENSE INFORMATION
============================

Lincoln D. Stein <lincoln.stein@gmail.com>

Copyright (c) 2014 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

