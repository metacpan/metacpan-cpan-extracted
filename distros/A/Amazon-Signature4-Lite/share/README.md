<a id="table-of-contents" class="anchor" aria-label="Permalink: Table of Contents" href="#table-of-contents"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">Table of Contents</h1>
<ul>
<li><a href="#name">NAME</a></li>
<li><a href="#synopsis">SYNOPSIS</a></li>
<li><a href="#description">DESCRIPTION</a></li>
<li>
<a href="#methods">METHODS</a>
<ul>
<li><a href="#new%args">new(%args)</a></li>
<li><a href="#sign%args">sign(%args)</a></li>
<li><a href="#parse%5Cservice%5Curl%args">parse_service_url(%args)</a></li>
</ul>
</li>
<li><a href="#dependencies">DEPENDENCIES</a></li>
<li><a href="#see-also">SEE ALSO</a></li>
</ul>
<a id="name" class="anchor" aria-label="Permalink: NAME" href="#name"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">NAME</h1>
<p>Amazon::Signature4::Lite - Lightweight AWS Signature Version 4 signing</p>
<a id="synopsis" class="anchor" aria-label="Permalink: SYNOPSIS" href="#synopsis"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">SYNOPSIS</h1>
<pre><code>use Amazon::Signature4::Lite;

my $signer = Amazon::Signature4::Lite-&gt;new(
  access_key    =&gt; $access_key_id,
  secret_key    =&gt; $secret_access_key,
  session_token =&gt; $session_token,   # optional, for STS/IAM roles
  region        =&gt; 'us-east-1',
  service       =&gt; 's3',             # default
);

my $signed = $signer-&gt;sign(
  method  =&gt; 'PUT',
  url     =&gt; 'https://s3.amazonaws.com/my-bucket/my-key',
  headers =&gt; { 'Content-Type' =&gt; 'application/gzip' },
  payload =&gt; $content,
);

# $signed is a hashref of headers ready for HTTP::Tiny:
# Authorization, x-amz-date, x-amz-content-sha256,
# x-amz-security-token (if session_token provided), host
</code></pre>
<a id="description" class="anchor" aria-label="Permalink: DESCRIPTION" href="#description"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">DESCRIPTION</h1>
<p>A minimal, dependency-free AWS Signature Version 4 implementation for
signing S3 and other AWS API requests. Unlike <a href="https://metacpan.org/pod/AWS%3A%3ASignature4" rel="nofollow">AWS::Signature4</a>, this
module does not depend on <a href="https://metacpan.org/pod/LWP" rel="nofollow">LWP</a> or <a href="https://metacpan.org/pod/HTTP%3A%3ARequest" rel="nofollow">HTTP::Request</a> - it works
directly with the plain scalars and hashrefs that <a href="https://metacpan.org/pod/HTTP%3A%3ATiny" rel="nofollow">HTTP::Tiny</a> uses.</p>
<a id="methods" class="anchor" aria-label="Permalink: METHODS" href="#methods"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">METHODS</h1>
<a id="newargs" class="anchor" aria-label="Permalink: new(%args)" href="#newargs"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">new(%args)</h2>
<pre><code>my $signer = Amazon::Signature4::Lite-&gt;new(
  access_key =&gt; $key,
  secret_key =&gt; $secret,
  region     =&gt; 'us-east-1',
);
</code></pre>
<p>Required: <code>access_key</code>, <code>secret_key</code>, <code>region</code>.
Optional: <code>session_token</code> (for temporary credentials), <code>service</code>
(defaults to <code>s3</code>).</p>
<a id="signargs" class="anchor" aria-label="Permalink: sign(%args)" href="#signargs"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">sign(%args)</h2>
<pre><code>my $headers = $signer-&gt;sign(
  method  =&gt; 'GET',
  url     =&gt; $url,
  headers =&gt; \%extra_headers,
  payload =&gt; $body,
);
</code></pre>
<p>Returns a hashref of HTTP headers including <code>Authorization</code>,
<code>x-amz-date</code>, <code>x-amz-content-sha256</code>, and <code>host</code>. Merge these
into your <a href="https://metacpan.org/pod/HTTP%3A%3ATiny" rel="nofollow">HTTP::Tiny</a> request headers.</p>
<a id="parse_service_urlargs" class="anchor" aria-label="Permalink: parse_service_url(%args)" href="#parse_service_urlargs"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">parse_service_url(%args)</h2>
<pre><code>my ($host, $service, $region) = Amazon::Signature4::Lite-&gt;parse_service_url(
  host           =&gt; 's3.us-east-2.amazonaws.com',
  default_region =&gt; 'us-east-1',
);
</code></pre>
<p>Extracts service name and region from an AWS endpoint URL. Can be
called as a class or instance method.</p>
<p><em>Note: The patterns used for parsing are S3/AWS endpoint focused, not
a general URL parser.</em></p>
<a id="dependencies" class="anchor" aria-label="Permalink: DEPENDENCIES" href="#dependencies"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">DEPENDENCIES</h1>
<p>All dependencies are Perl core modules (since 5.10) or already
required by distributions in the Amazon::* toolchain:</p>
<ul>
<li>
<a href="https://metacpan.org/pod/Digest%3A%3ASHA" rel="nofollow">Digest::SHA</a> (core since 5.10)</li>
<li>
<a href="https://metacpan.org/pod/MIME%3A%3ABase64" rel="nofollow">MIME::Base64</a> (core)</li>
<li>
<a href="https://metacpan.org/pod/POSIX" rel="nofollow">POSIX</a> (core)</li>
<li><a href="https://metacpan.org/pod/URI%3A%3AEscape" rel="nofollow">URI::Escape</a></li>
</ul>
<a id="see-also" class="anchor" aria-label="Permalink: SEE ALSO" href="#see-also"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">SEE ALSO</h1>
<p><a href="https://metacpan.org/pod/AWS%3A%3ASignature4" rel="nofollow">AWS::Signature4</a>, <a href="https://metacpan.org/pod/Signer%3A%3AAWSv4" rel="nofollow">Signer::AWSv4</a>, <a href="https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ALite" rel="nofollow">Amazon::S3::Lite</a></p>
