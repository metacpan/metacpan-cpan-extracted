#
#  This file is part of Cloudflare::API.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#
package Cloudflare::API::Workers;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw(@ISA $VERSION);
use warnings;


#  Cloudflare::API modules and inheritance
#
use Cloudflare::API::Resource;
@ISA=qw(Cloudflare::API::Resource);


#  External modules
#
use JSON::PP qw(encode_json);
use MIME::Base64 qw(encode_base64);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(basename);
use File::Find qw(find);
use File::Spec;


#  Version information
#
$VERSION='1.010';


#  All done. Positive return
#
1;


#============================================================================


sub list_scripts {


    #  Keep account-level pagination metadata available on request
    #
    my ($self, %query)=@_;
    my $full_response=delete($query{'full_response'});
    return $self->api()->request('GET', $self->api()->account_path('workers', 'scripts'),
        query => \%query, full_response => $full_response);

}


sub search_scripts {


    #  Search uses Cloudflare's paginated script discovery endpoint
    #
    my ($self, %query)=@_;
    my $full_response=delete($query{'full_response'});
    return $self->api()->request('GET',
        $self->api()->account_path('workers', 'scripts-search'),
        query => \%query, full_response => $full_response);

}


sub get_settings {

    my ($self, $name, %opt)=@_;
    return $self->api()->request('GET',
        $self->api()->account_path('workers', 'scripts', $name, 'settings'), %opt);

}


sub get_script_settings {

    my ($self, $name, %opt)=@_;
    return $self->api()->request('GET',
        $self->api()->account_path('workers', 'scripts', $name, 'script-settings'), %opt);

}


sub inspect_script {


    #  Resolve one script summary before retrieving both kinds of settings
    #
    my $self=shift();
    die "inspect_script selectors must be name/value pairs\n" if @_ % 2;
    my %selector=@_;
    my $full_response=delete($selector{'full_response'});
    die "full_response is unavailable for inspect_script\n" if $full_response;
    die "inspect_script requires exactly one of name, tag, or etag\n"
        unless keys(%selector)==1;
    my ($selector)=keys(%selector);
    die "unknown inspect selector: $selector\n"
        unless $selector=~/\A(?:name|tag|etag)\z/;
    my $value=$selector{$selector};
    die "$selector must be a non-empty scalar\n"
        unless defined($value)&&!ref($value)&&length($value);

    my $script_ar=$self->list_scripts();
    die "Worker script list must be an array reference\n"
        unless ref($script_ar) eq 'ARRAY';
    my $field=$selector eq 'name' ? 'id' : $selector;
    my @match=grep {
        ref($_) eq 'HASH'&&defined($_->{$field})&&$_->{$field} eq $value
    } @$script_ar;
    die "no Worker script matches $selector '$value'\n" unless @match;
    die "multiple Worker scripts match $selector '$value'\n" if @match>1;

    my $name=$match[0]{'id'};
    die "matched Worker script has no name\n"
        unless defined($name)&&!ref($name)&&length($name);
    return {
        script          => $match[0],
        settings        => $self->get_settings($name),
        script_settings => $self->get_script_settings($name)
    };

}


sub download_script {

    my ($self, $name)=@_;
    return $self->api()->raw_request('GET',
        $self->api()->account_path('workers', 'scripts', $name));

}


sub upload_script {


    #  Accept prepared modules; building or bundling belongs to the caller
    #
    my ($self, $name, %opt)=@_;
    my $metadata_hr=delete($opt{'metadata'});
    my $files_ar=delete($opt{'files'});
    my $full_response=delete($opt{'full_response'});
    die "unknown upload option: $_\n" foreach sort(keys(%opt));
    my ($body, $content_type)=$self->_multipart_body($metadata_hr, $files_ar);



    #  Uploading immediately publishes the prepared Worker
    #
    return $self->api()->request('PUT',
        $self->api()->account_path('workers', 'scripts', $name),
        content => $body, headers => { 'Content-Type' => $content_type },
        full_response => $full_response);

}


sub upload_version {


    #  A version upload does not change the active deployment
    #
    my ($self, $name, %opt)=@_;
    my $metadata_hr=delete($opt{'metadata'});
    my $files_ar=delete($opt{'files'});
    my $full_response=delete($opt{'full_response'});
    my $bindings_inherit=delete($opt{'bindings_inherit'});
    die "unknown upload option: $_\n" foreach sort(keys(%opt));
    die "bindings_inherit must be strict\n"
        if defined($bindings_inherit)&&$bindings_inherit ne 'strict';
    my ($body, $content_type)=$self->_multipart_body($metadata_hr, $files_ar);
    my %request_opt=(content => $body,
        headers => { 'Content-Type' => $content_type },
        full_response => $full_response);
    $request_opt{'query'}={ bindings_inherit => $bindings_inherit }
        if defined($bindings_inherit);
    return $self->api()->request('POST',
        $self->api()->account_path('workers', 'scripts', $name, 'versions'),
        %request_opt);

}


sub list_versions {

    my ($self, $name, %query)=@_;
    my $full_response=delete($query{'full_response'});
    return $self->api()->request('GET',
        $self->api()->account_path('workers', 'scripts', $name, 'versions'),
        query => \%query, full_response => $full_response);

}


sub get_version {

    my ($self, $name, $version_id, %opt)=@_;
    return $self->api()->request('GET',
        $self->api()->account_path('workers', 'scripts', $name, 'versions', $version_id),
        %opt);

}


sub upload_assets {


    #  Resolve file-backed inputs to URL paths before opening any files
    #
    my ($self, $name, $source, %opt)=@_;
    delete($opt{'full_response'});
    my $prefix=delete($opt{'prefix'});
    die "unknown asset upload option: $_\n" foreach sort(keys(%opt));
    $prefix='' unless defined($prefix);
    die "invalid asset prefix\n" if ref($prefix);
    $prefix='/'.$prefix if length($prefix)&&$prefix!~m{\A/};
    $prefix=~s{/\z}{} if $prefix ne '/';
    $prefix='' if $prefix eq '/';
    die "invalid asset prefix\n"
        if length($prefix)&&($prefix!~m{\A/[A-Za-z0-9._/-]+\z}||
            $prefix=~m{(?:\A|/)\.\.? (?:/|\z)}x);

    my %assets;
    if (ref($source) eq 'HASH') {
        die "invalid asset path\n"
            if grep { !m{\A/[A-Za-z0-9._/-]+\z}||m{(?:\A|/)\.\.?(?:/|\z)} } keys(%$source);
        %assets=%$source;
    }
    elsif (ref($source) eq 'ARRAY') {
        foreach my $entry (@$source) {
            my $item=ref($entry) eq 'HASH' ? $entry : { path => $entry };
            die "asset file path is required\n"
                unless ref($item) eq 'HASH'&&defined($item->{'path'})&&
                    !ref($item->{'path'})&&length($item->{'path'});
            die "asset file must not be a symlink\n" if -l $item->{'path'};
            die "asset file is required\n" unless -f $item->{'path'};
            my $url=exists($item->{'name'}) ? $item->{'name'} : basename($item->{'path'});
            die "invalid asset name\n"
                unless defined($url)&&!ref($url)&&
                    $url=~m{\A[A-Za-z0-9._/-]+\z}&&
                    $url!~m{(?:\A|/)\.\.?(?:/|\z)};
            my $path='/'.$url;
            die "duplicate asset path: $path\n" if exists($assets{$path});
            $assets{$path}=$item;
        }
    }
    elsif (defined($source)&&!ref($source)) {
        die "asset directory must not be a symlink\n" if -l $source;
        die "asset directory is required\n" unless -d $source;
        my $root=File::Spec->rel2abs($source);
        find({ no_chdir => 1, wanted => sub {
            my $file=$File::Find::name;
            die "asset directory contains a symlink: $file\n" if -l $file;
            return if -d $file;
            die "asset directory contains a non-file: $file\n" unless -f $file;
            my $relative=File::Spec->abs2rel($file, $root);
            my $path='/'.$relative;
            die "duplicate asset path: $path\n" if exists($assets{$path});
            $assets{$path}={ path => $file };
        } }, $root);
    }
    else {
        die "assets must be a directory, array reference, or hash reference\n";
    }
    die "assets must not be empty\n" unless keys(%assets);

    #  Register a prepared asset set and upload only hashes Cloudflare needs
    #
    my (%manifest, %content, %content_type);
    foreach my $name (sort(keys(%assets))) {
        my $path=$prefix.$name;
        die "invalid asset path\n"
            unless $path=~m{\A/[A-Za-z0-9._/-]+\z}&&
                $path!~m{(?:\A|/)\.\.?(?:/|\z)};
        my $item=$assets{$name};
        my $bytes;
        my $type;
        if (ref($item) eq 'HASH') {
            $type=$item->{'content_type'};
            die "asset path is required\n" unless defined($item->{'path'})&&!ref($item->{'path'});
            open(my $asset_fh, '<', $item->{'path'}) || die "unable to open asset: $!\n";
            binmode($asset_fh) || die "unable to set binary mode on asset: $!\n";
            local $/;
            $bytes=<$asset_fh>;
            close($asset_fh) || die "unable to close asset: $!\n";
        }
        else {
            die "asset content must be a scalar\n" unless defined($item)&&!ref($item);
            $bytes="$item";
            utf8::encode($bytes) if utf8::is_utf8($bytes);
        }
        my ($extension)=$path=~/\.([^.\/]*)\z/;
        $extension='' unless defined($extension);
        $extension=lc($extension);
        $type=$self->asset_content_type($extension) unless defined($type);
        die "invalid asset content type\n"
            unless defined($type)&&!ref($type)&&
                $type=~m{\A[A-Za-z0-9!#\$&^_.+-]+/[A-Za-z0-9!#\$&^_.+-]+\z};
        my $hash=substr(sha256_hex(encode_base64($bytes, '').$extension), 0, 32);
        $manifest{$path}={ hash => $hash, size => length($bytes) };
        $content{$hash}=encode_base64($bytes, '');
        $content_type{$hash}=$type;
    }

    my $session_hr=$self->api()->request('POST',
        $self->api()->account_path('workers', 'scripts', $name, 'assets-upload-session'),
        json => { manifest => \%manifest });
    die "asset upload session is incomplete\n"
        unless ref($session_hr) eq 'HASH'&&ref($session_hr->{'buckets'}) eq 'ARRAY'&&
            defined($session_hr->{'jwt'})&&!ref($session_hr->{'jwt'});
    my $completion_jwt=$session_hr->{'jwt'};
    $completion_jwt=undef if @{$session_hr->{'buckets'}};

    foreach my $bucket_ar (@{$session_hr->{'buckets'}}) {
        die "invalid asset upload bucket\n" unless ref($bucket_ar) eq 'ARRAY'&&@$bucket_ar;
        my $boundary=sprintf('cloudflare-api-%x-%x-%x', time(), $$, int(rand(0x7fffffff)));
        my $body='';
        foreach my $hash (@$bucket_ar) {
            die "unknown asset hash in upload session\n" unless exists($content{$hash});
            $body.='--'.$boundary."\r\n".
                'Content-Disposition: form-data; name="'.$hash.'"'."\r\n".
                'Content-Type: '.$content_type{$hash}."\r\n\r\n".
                $content{$hash}."\r\n";
        }
        $body.='--'.$boundary."--\r\n";
        my $result_hr=$self->api()->request('POST',
            $self->api()->account_path('workers', 'assets', 'upload'),
            query => { base64 => 'true' }, content => $body,
            headers => { Authorization => 'Bearer '.$session_hr->{'jwt'},
                'Content-Type' => 'multipart/form-data; boundary='.$boundary });
        $completion_jwt=$result_hr->{'jwt'} if defined($result_hr->{'jwt'});
    }
    die "asset upload did not return a completion token\n" unless defined($completion_jwt);
    return { jwt => $completion_jwt, manifest => \%manifest };

}


sub asset_content_type {


    #  Cloudflare serves the MIME type supplied with each asset part
    #
    my ($self, $extension)=@_;
    my %type=(
        html => 'text/html', htm => 'text/html', css => 'text/css',
        js => 'text/javascript', mjs => 'text/javascript',
        json => 'application/json', webmanifest => 'application/manifest+json',
        txt => 'text/plain', xml => 'application/xml',
        svg => 'image/svg+xml', png => 'image/png',
        jpg => 'image/jpeg', jpeg => 'image/jpeg',
        gif => 'image/gif', webp => 'image/webp',
        avif => 'image/avif', ico => 'image/x-icon',
        woff => 'font/woff', woff2 => 'font/woff2',
        pdf => 'application/pdf', wasm => 'application/wasm'
    );
    return $type{$extension} || 'application/octet-stream';

}


sub _multipart_body {

    my ($self, $metadata_hr, $files_ar)=@_;
    die "metadata must be a hash reference\n" unless ref($metadata_hr) eq 'HASH';
    die "files must be a non-empty array reference\n"
        unless ref($files_ar) eq 'ARRAY'&&@$files_ar;



    #  Cloudflare requires the entry point to match an uploaded file name
    #
    my $main_module=$metadata_hr->{'main_module'};
    die "metadata main_module is required\n"
        unless defined($main_module)&&!ref($main_module)&&length($main_module);



    #  Validate each multipart file and read any file-backed content
    #
    my @part;
    my %name;
    foreach my $file_hr (@$files_ar) {
        die "each file must be a hash reference\n" unless ref($file_hr) eq 'HASH';
        my $part_name=$file_hr->{'name'};
        die "invalid file name\n"
            unless defined($part_name)&&!ref($part_name)&&
                $part_name=~/\A[A-Za-z0-9._\/-]+\z/&&
                $part_name!~m{\A/|(?:\A|/)\.\.(?:/|\z)};
        die "duplicate file name: $part_name\n" if $name{$part_name}++;

        my $content;
        if (exists($file_hr->{'path'})) {
            die "file content and path are mutually exclusive\n"
                if exists($file_hr->{'content'});
            my $path_fn=$file_hr->{'path'};
            die "file path must be a non-empty scalar\n"
                unless defined($path_fn)&&!ref($path_fn)&&length($path_fn);
            open(my $file_fh, '<', $path_fn) || die "unable to open $path_fn: $!\n";
            binmode($file_fh) || die "unable to set binary mode on $path_fn: $!\n";
            local $/;
            $content=<$file_fh>;
            close($file_fh) || die "unable to close $path_fn: $!\n";
        }
        else {
            $content=$file_hr->{'content'};
        }
        die "file content must be a scalar\n" unless defined($content)&&!ref($content);
        utf8::encode($content) if utf8::is_utf8($content);

        my $content_type=$file_hr->{'content_type'} || 'application/javascript+module';
        die "invalid content type\n"
            unless $content_type=~m{\A[A-Za-z0-9.+-]+/[A-Za-z0-9.+-]+\z};
        push(@part, [$part_name, $content_type, $content]);
    }
    die "main_module must match an uploaded file name\n" unless $name{$main_module};



    #  Choose a boundary absent from the metadata and all module content
    #
    my $metadata=encode_json($metadata_hr);
    my $boundary;
    do {
        $boundary=sprintf('cloudflare-api-%x-%x-%x', time(), $$, int(rand(0x7fffffff)));
    } while index($metadata, $boundary)>=0 ||
        grep { index($_->[2], $boundary)>=0 } @part;



    #  Assemble the multipart body exactly as the upload endpoint expects
    #
    my $body='--'.$boundary."\r\n".
        "Content-Disposition: form-data; name=\"metadata\"\r\n".
        "Content-Type: application/json\r\n\r\n".$metadata."\r\n";
    foreach my $part_ar (@part) {
        $body.='--'.$boundary."\r\n".
            'Content-Disposition: form-data; name="'.$part_ar->[0].'"; filename="'.$part_ar->[0]."\"\r\n".
            'Content-Type: '.$part_ar->[1]."\r\n\r\n".$part_ar->[2]."\r\n";
    }
    $body.='--'.$boundary."--\r\n";



    return ($body, 'multipart/form-data; boundary='.$boundary);

}


sub delete_script {

    my ($self, $name, %opt)=@_;
    return $self->api()->request('DELETE',
        $self->api()->account_path('workers', 'scripts', $name), %opt);

}


sub list_deployments {

    my ($self, $name, %query)=@_;
    my $full_response=delete($query{'full_response'});
    return $self->api()->request('GET',
        $self->api()->account_path('workers', 'scripts', $name, 'deployments'),
        query => \%query, full_response => $full_response);

}


sub create_deployment {

    my ($self, $name, $body_hr, %opt)=@_;
    die "deployment body must be a hash reference\n" unless ref($body_hr) eq 'HASH';
    return $self->api()->request('POST',
        $self->api()->account_path('workers', 'scripts', $name, 'deployments'),
        json => $body_hr, %opt);

}


sub get_deployment {

    my ($self, $name, $deployment_id, %opt)=@_;
    return $self->api()->request('GET',
        $self->api()->account_path('workers', 'scripts', $name, 'deployments', $deployment_id),
        %opt);

}


sub list_secrets {

    my ($self, $name, %opt)=@_;
    return $self->api()->request('GET',
        $self->api()->account_path('workers', 'scripts', $name, 'secrets'), %opt);

}


sub add_secret {

    my ($self, $name, $body_hr, %opt)=@_;
    die "secret body must be a hash reference\n" unless ref($body_hr) eq 'HASH';
    return $self->api()->request('PUT',
        $self->api()->account_path('workers', 'scripts', $name, 'secrets'),
        json => $body_hr, %opt);

}


sub delete_secret {

    my ($self, $name, $secret_name, %opt)=@_;
    return $self->api()->request('DELETE',
        $self->api()->account_path('workers', 'scripts', $name, 'secrets', $secret_name),
        %opt);

}


sub get_subdomain {

    my ($self, $name, %opt)=@_;
    return $self->api()->request('GET',
        $self->api()->account_path('workers', 'scripts', $name, 'subdomain'), %opt);

}


sub set_subdomain {

    my ($self, $name, $body_hr, %opt)=@_;
    die "subdomain body must be a hash reference\n" unless ref($body_hr) eq 'HASH';
    return $self->api()->request('POST',
        $self->api()->account_path('workers', 'scripts', $name, 'subdomain'),
        json => $body_hr, %opt);

}


sub list_routes {


    #  Worker routes are zone-scoped, unlike the account-scoped script calls
    #
    my ($self, $zone_id, %query)=@_;
    my $full_response=delete($query{'full_response'});
    return $self->api()->request('GET',
        '/zones/'.$self->api()->segment($zone_id).'/workers/routes',
        query => \%query, full_response => $full_response);

}


sub create_route {

    my ($self, $zone_id, $body_hr, %opt)=@_;
    die "route body must be a hash reference\n" unless ref($body_hr) eq 'HASH';
    return $self->api()->request('POST',
        '/zones/'.$self->api()->segment($zone_id).'/workers/routes',
        json => $body_hr, %opt);

}


sub update_route {

    my ($self, $zone_id, $route_id, $body_hr, %opt)=@_;
    die "route body must be a hash reference\n" unless ref($body_hr) eq 'HASH';
    return $self->api()->request('PUT',
        '/zones/'.$self->api()->segment($zone_id).'/workers/routes/'.
        $self->api()->segment($route_id), json => $body_hr, %opt);

}


sub delete_route {

    my ($self, $zone_id, $route_id, %opt)=@_;
    return $self->api()->request('DELETE',
        '/zones/'.$self->api()->segment($zone_id).'/workers/routes/'.
        $self->api()->segment($route_id), %opt);

}
__END__

=encoding utf8

=begin markdown

# Cloudflare::API::Workers #

# NAME #

Cloudflare::API::Workers - manage Worker scripts, versions, assets, and routes

# SYNOPSIS #

```perl
my $workers=$api->workers();
my $version=$workers->upload_version('my-app',
    metadata => {
        main_module        => 'worker.mjs',
        compatibility_date => '2026-09-22'
    },
    files => [{ name => 'worker.mjs', path => 'dist/worker.mjs' }]
);
$workers->create_deployment('my-app', {
    strategy => 'percentage',
    versions => [{ version_id => $version->{'id'}, percentage => 100 }]
});
```

# DESCRIPTION #

Most Worker methods use the account ID configured on `Cloudflare::API`. Route methods instead take a zone ID explicitly. The module sends prepared modules and Cloudflare metadata; it does not build scripts, invoke npm or Wrangler, generate a Worker entry point, or create routes automatically.

Cloudflare's Worker identifiers have distinct purposes. The `id` returned by `list_scripts()` is the script name used in API paths, `tag` is the immutable Worker ID, `tags` contains user-assigned labels, and `etag` identifies the current script content. The search API calls the immutable `tag` value `id`. `inspect_script()` uses the unambiguous selector names `name`, `tag`, and `etag`.

JSON methods return Cloudflare's decoded `result` by default. Except where noted, pass `full_response => 1` to return the complete parsed envelope. List methods take named Cloudflare query parameters alongside `full_response`; this retains pagination information such as `result_info`. Script names, version IDs, secret names, and route IDs are percent-encoded in URLs.

# METHODS #

* **list_scripts(%query)** — List account Worker scripts. Returns `result`; `full_response => 1` retains pagination information.
* **search_scripts(%query)** — Search scripts through Cloudflare's discovery endpoint. `name` accepts exact or partial names; `id` is an exact immutable Worker ID (called `tag` in list results). Ordering and pagination parameters pass through. Returns `result`; `full_response => 1` retains pagination information.
* **get_settings($name, %options)** — Return the named Worker's combined script and current-version settings, including bindings, compatibility configuration, annotations, placement, and runtime limits.
* **get_script_settings($name, %options)** — Return Worker-level settings such as user-assigned tags, Logpush, observability, and tail consumers.
* **inspect_script(name => $name | tag => $tag | etag => $etag)** — Resolve exactly one Worker from the account inventory and return `{ script => ..., settings => ..., script_settings => ... }`. Exactly one non-empty selector is required. `name` matches the script name exactly; `tag` matches the immutable Worker ID; `etag` matches the current content hash. Zero or multiple matches cause an exception. This convenience method makes three read requests, has no `full_response` mode, and does not include source, versions, or deployments.
* **download_script($name)** — Return an `HTTP::API::Core::Response` object. Read its `content()` for Worker source or multipart content; this response is not JSON-decoded and has no `full_response` option.
* **upload_script($name, metadata => \%metadata, files => \@files)** — PUT a prepared module upload to the script endpoint, **deploying it immediately**. Returns `result`, or the envelope with `full_response => 1`. See **Module uploads** below for required metadata and file entries.
* **upload_version($name, metadata => \%metadata, files => \@files, %options)** — POST a prepared module upload as a version without activating it. Returns the version `result`, or the envelope with `full_response => 1`. Optional `bindings_inherit => 'strict'` asks Cloudflare to reject unresolved inherited bindings; no other value is accepted.
* **list_versions($name, %query)** — List versions for a script. Returns `result`; `full_response => 1` retains pagination information.
* **get_version($name, $version_id, %options)** — Retrieve a version and return its `result`.
* **upload_assets($name, $source, %options)** — Register and upload a static asset set. Returns `{ jwt => $completion_token, manifest => \%manifest }`, not a normal Cloudflare response envelope. `prefix` chooses a URL prefix; `full_response` is accepted but has no effect. See **Static assets** below.
* **delete_script($name, %options)** — DELETE a script and return the endpoint's `result`, possibly `undef` for an empty body.
* **list_deployments($name, %query)** — List deployments of a script. Returns `result`; `full_response => 1` retains pagination information.
* **get_deployment($name, $deployment_id, %options)** — Retrieve a deployment and return its `result`.
* **create_deployment($name, \%body, %options)** — POST a deployment definition, such as a `strategy` and `versions` array. This activates the specified version mix and returns `result`.
* **list_secrets($name, %options)** — List a Worker's secret bindings and return `result`.
* **add_secret($name, \%body, %options)** — PUT a secret binding and return `result`. Keep secret values out of logs and source control.
* **delete_secret($name, $secret_name, %options)** — DELETE a secret binding and return the endpoint's `result`.
* **get_subdomain($name, %options)** — Retrieve a Worker's workers.dev subdomain setting and return `result`.
* **set_subdomain($name, \%body, %options)** — POST a subdomain setting, including `enabled` when changing reachability, and return `result`.
* **list_routes($zone_id, %query)** — List routes in a zone. Returns `result`; `full_response => 1` retains pagination information.
* **create_route($zone_id, \%body, %options)** — POST a zone route and return `result`.
* **update_route($zone_id, $route_id, \%body, %options)** — PUT a replacement route and return `result`.
* **delete_route($zone_id, $route_id, %options)** — DELETE a route and return the endpoint's `result`.
* **asset_content_type($extension)** — Return the built-in MIME type for a lowercase extension, or `application/octet-stream` when unknown. `upload_assets()` calls this for entries without an explicit `content_type`.

Write bodies must be hash references. Missing account context, invalid identifiers, selectors or body shapes, ambiguous inspection matches, and unknown upload options cause exceptions before or during the request. The `Cloudflare::API` man page describes HTTP, transport, and Cloudflare envelope failures.

# MODULE UPLOADS #

`upload_script()` and `upload_version()` require metadata with a non-empty `main_module` that matches the name of one uploaded file. Supply Cloudflare fields such as `compatibility_date` and `bindings` in the metadata. `files` must be a non-empty array of entries with a `name` and exactly one of `path` or `content`; each entry may also set `content_type` (default `application/javascript+module`). Names may contain letters, numbers, dots, dashes, underscores, and slashes for nested modules. Duplicate names are rejected. Module content and the multipart request are assembled in memory, so large uploads need enough process memory.

Use `upload_script()` when immediate deployment is intended. To stage a version, use `upload_version()`, inspect it with `get_version()` if needed, then call `create_deployment()` to make it active. Version upload alone does not change traffic.

# STATIC ASSETS #

`upload_assets($name, $source, %options)` accepts a directory path, an array reference of filenames or `{ path => $file, name => 'nested/page.html', content_type => 'image/jxl' }` entries, or a hash reference mapping absolute URL paths to content scalars or `{ path => $file }` entries. Directory uploads recurse and preserve paths relative to the directory. Array filenames use their basenames unless `name` is supplied. Duplicate URL paths are rejected; directory and file-list uploads reject symlinks. The source must not be empty. `prefix => '/docs'` places every URL path under `/docs`.

The method hashes the content, registers a manifest, uploads the buckets Cloudflare requests, and returns a manifest plus a short-lived completion `jwt`. Uploads are assembled in memory. Common HTML, CSS, JavaScript, JSON, text, font, PDF, WASM, and image extensions receive a MIME type; unknown extensions use `application/octet-stream`. An entry may override the MIME type with `content_type`.

Asset upload does not deploy a Worker. Put the returned token into a version's metadata, along with an assets binding, then deploy that version:

```perl
my $assets=$workers->upload_assets('my-app', 'dist', prefix => '/docs');
my $version=$workers->upload_version('my-app',
    metadata => {
        main_module        => 'worker.mjs',
        compatibility_date => '2026-09-22',
        assets             => { jwt => $assets->{'jwt'} },
        bindings           => [{ type => 'assets', name => 'ASSETS' }]
    },
    files => [{ name => 'worker.mjs', path => 'dist/worker.mjs' }]
);
```

The prepared Worker must route requests to its asset binding, for example with `env.ASSETS.fetch(request)`. Treat the JWT as a credential and keep it out of logs. See `cloudflare-api --man` for command-line asset source options.

# SEE ALSO #

[Cloudflare::API](../API.pm.md), [Cloudflare::API::Zones](Zones.pm.md), [Cloudflare::API::SecretsStore](SecretsStore.pm.md)

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of Cloudflare::API.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 NAME

Cloudflare::API::Workers - manage Worker scripts, versions, assets, and routes


=head1 SYNOPSIS


 my $workers=$api->workers();
 my $version=$workers->upload_version('my-app',
     metadata => {
         main_module        => 'worker.mjs',
         compatibility_date => '2026-09-22'
     },
     files => [{ name => 'worker.mjs', path => 'dist/worker.mjs' }]
 );
 $workers->create_deployment('my-app', {
     strategy => 'percentage',
     versions => [{ version_id => $version->{'id'}, percentage => 100 }]
 });

=head1 DESCRIPTION

Most Worker methods use the account ID configured on C<Cloudflare::API>. Route methods instead take a zone ID explicitly. The module sends prepared modules and Cloudflare metadata; it does not build scripts, invoke npm or Wrangler, generate a Worker entry point, or create routes automatically.

Cloudflare's Worker identifiers have distinct purposes. The C<id> returned by C<list_scripts()> is the script name used in API paths, C<tag> is the immutable Worker ID, C<tags> contains user-assigned labels, and C<etag> identifies the current script content. The search API calls the immutable C<tag> value C<id>. C<inspect_script()> uses the unambiguous selector names C<name>, C<tag>, and C<etag>.

JSON methods return Cloudflare's decoded C<result> by default. Except where noted, pass C<<< full_response => 1 >>> to return the complete parsed envelope. List methods take named Cloudflare query parameters alongside C<full_response>; this retains pagination information such as C<result_info>. Script names, version IDs, secret names, and route IDs are percent-encoded in URLs.


=head1 METHODS

=over

=item *

B<list_scripts(%query)> — List account Worker scripts. Returns C<result>; C<<< full_response => 1 >>> retains pagination information.


=item *

B<search_scripts(%query)> — Search scripts through Cloudflare's discovery endpoint. C<name> accepts exact or partial names; C<id> is an exact immutable Worker ID (called C<tag> in list results). Ordering and pagination parameters pass through. Returns C<result>; C<<< full_response => 1 >>> retains pagination information.


=item *

B<get_settings($name, %options)> — Return the named Worker's combined script and current-version settings, including bindings, compatibility configuration, annotations, placement, and runtime limits.


=item *

B<get_script_settings($name, %options)> — Return Worker-level settings such as user-assigned tags, Logpush, observability, and tail consumers.


=item *

B<< inspect_script(name => $name | tag => $tag | etag => $etag) >> — Resolve exactly one Worker from the account inventory and return C<<< { script => ..., settings => ..., script_settings => ... } >>>. Exactly one non-empty selector is required. C<name> matches the script name exactly; C<tag> matches the immutable Worker ID; C<etag> matches the current content hash. Zero or multiple matches cause an exception. This convenience method makes three read requests, has no C<full_response> mode, and does not include source, versions, or deployments.


=item *

B<download_script($name)> — Return an C<HTTP::API::Core::Response> object. Read its C<content()> for Worker source or multipart content; this response is not JSON-decoded and has no C<full_response> option.


=item *

B<< upload_script($name, metadata => \%metadata, files => \@files) >> — PUT a prepared module upload to the script endpoint, B<deploying it immediately>. Returns C<result>, or the envelope with C<<< full_response => 1 >>>. See B<Module uploads> below for required metadata and file entries.


=item *

B<< upload_version($name, metadata => \%metadata, files => \@files, %options) >> — POST a prepared module upload as a version without activating it. Returns the version C<result>, or the envelope with C<<< full_response => 1 >>>. Optional C<<< bindings_inherit => 'strict' >>> asks Cloudflare to reject unresolved inherited bindings; no other value is accepted.


=item *

B<list_versions($name, %query)> — List versions for a script. Returns C<result>; C<<< full_response => 1 >>> retains pagination information.


=item *

B<get_version($name, $version_id, %options)> — Retrieve a version and return its C<result>.


=item *

B<upload_assets($name, $source, %options)> — Register and upload a static asset set. Returns C<<< { jwt => $completion_token, manifest => \%manifest } >>>, not a normal Cloudflare response envelope. C<prefix> chooses a URL prefix; C<full_response> is accepted but has no effect. See B<Static assets> below.


=item *

B<delete_script($name, %options)> — DELETE a script and return the endpoint's C<result>, possibly C<undef> for an empty body.


=item *

B<list_deployments($name, %query)> — List deployments of a script. Returns C<result>; C<<< full_response => 1 >>> retains pagination information.


=item *

B<get_deployment($name, $deployment_id, %options)> — Retrieve a deployment and return its C<result>.


=item *

B<create_deployment($name, \%body, %options)> — POST a deployment definition, such as a C<strategy> and C<versions> array. This activates the specified version mix and returns C<result>.


=item *

B<list_secrets($name, %options)> — List a Worker's secret bindings and return C<result>.


=item *

B<add_secret($name, \%body, %options)> — PUT a secret binding and return C<result>. Keep secret values out of logs and source control.


=item *

B<delete_secret($name, $secret_name, %options)> — DELETE a secret binding and return the endpoint's C<result>.


=item *

B<get_subdomain($name, %options)> — Retrieve a Worker's workers.dev subdomain setting and return C<result>.


=item *

B<set_subdomain($name, \%body, %options)> — POST a subdomain setting, including C<enabled> when changing reachability, and return C<result>.


=item *

B<list_routes($zone_id, %query)> — List routes in a zone. Returns C<result>; C<<< full_response => 1 >>> retains pagination information.


=item *

B<create_route($zone_id, \%body, %options)> — POST a zone route and return C<result>.


=item *

B<update_route($zone_id, $route_id, \%body, %options)> — PUT a replacement route and return C<result>.


=item *

B<delete_route($zone_id, $route_id, %options)> — DELETE a route and return the endpoint's C<result>.


=item *

B<asset_content_type($extension)> — Return the built-in MIME type for a lowercase extension, or C<application/octet-stream> when unknown. C<upload_assets()> calls this for entries without an explicit C<content_type>.


=back

Write bodies must be hash references. Missing account context, invalid identifiers, selectors or body shapes, ambiguous inspection matches, and unknown upload options cause exceptions before or during the request. The C<Cloudflare::API> man page describes HTTP, transport, and Cloudflare envelope failures.


=head1 MODULE UPLOADS

C<upload_script()> and C<upload_version()> require metadata with a non-empty C<main_module> that matches the name of one uploaded file. Supply Cloudflare fields such as C<compatibility_date> and C<bindings> in the metadata. C<files> must be a non-empty array of entries with a C<name> and exactly one of C<path> or C<content>; each entry may also set C<content_type> (default C<application/javascript+module>). Names may contain letters, numbers, dots, dashes, underscores, and slashes for nested modules. Duplicate names are rejected. Module content and the multipart request are assembled in memory, so large uploads need enough process memory.

Use C<upload_script()> when immediate deployment is intended. To stage a version, use C<upload_version()>, inspect it with C<get_version()> if needed, then call C<create_deployment()> to make it active. Version upload alone does not change traffic.


=head1 STATIC ASSETS

C<upload_assets($name, $source, %options)> accepts a directory path, an array reference of filenames or C<<< { path => $file, name => 'nested/page.html', content_type => 'image/jxl' } >>> entries, or a hash reference mapping absolute URL paths to content scalars or C<<< { path => $file } >>> entries. Directory uploads recurse and preserve paths relative to the directory. Array filenames use their basenames unless C<name> is supplied. Duplicate URL paths are rejected; directory and file-list uploads reject symlinks. The source must not be empty. C<<< prefix => '/docs' >>> places every URL path under C</docs>.

The method hashes the content, registers a manifest, uploads the buckets Cloudflare requests, and returns a manifest plus a short-lived completion C<jwt>. Uploads are assembled in memory. Common HTML, CSS, JavaScript, JSON, text, font, PDF, WASM, and image extensions receive a MIME type; unknown extensions use C<application/octet-stream>. An entry may override the MIME type with C<content_type>.

Asset upload does not deploy a Worker. Put the returned token into a version's metadata, along with an assets binding, then deploy that version:


 my $assets=$workers->upload_assets('my-app', 'dist', prefix => '/docs');
 my $version=$workers->upload_version('my-app',
     metadata => {
         main_module        => 'worker.mjs',
         compatibility_date => '2026-09-22',
         assets             => { jwt => $assets->{'jwt'} },
         bindings           => [{ type => 'assets', name => 'ASSETS' }]
     },
     files => [{ name => 'worker.mjs', path => 'dist/worker.mjs' }]
 );
The prepared Worker must route requests to its asset binding, for example with C<env.ASSETS.fetch(request)>. Treat the JWT as a credential and keep it out of logs. See C<cloudflare-api --man> for command-line asset source options.


=head1 SEE ALSO

L<Cloudflare::API|Cloudflare::API>, L<Cloudflare::API::Zones|Cloudflare::API::Zones>, L<Cloudflare::API::SecretsStore|Cloudflare::API::SecretsStore>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.

=cut
