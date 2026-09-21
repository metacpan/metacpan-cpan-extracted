# Examples

Small, self-contained programs showing typical usage. Beside the modules
of the distribution (Moo, Ouch and namespace::clean, see `cpanfile`; with
Carton, run them as `carton exec ./eg/...`) they only need Perl core
modules (`HTTP::Tiny` needs `IO::Socket::SSL` for HTTPS), plus CryptX for
the X.509 ones. Run them from a checkout (they load `../lib`).

Set `DRY_RUN=1` to see the signed request instead of sending it. This is
handy to try them out without any AWS access, e.g. with dummy credentials:

```shell
export AWS_ACCESS_KEY_ID=AKIDEXAMPLE AWS_SECRET_ACCESS_KEY=secret DRY_RUN=1
```

Credentials come from `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and
optionally `AWS_SESSION_TOKEN`; the region from `AWS_REGION` where it
makes sense (default `us-east-1`).

`HTTP::Tiny` is used only because it is in the core: the module does not
depend on it, and any other user agent can be used the same way. Mind that
`HTTP::Tiny` wants to set the `Host` header itself, so the examples remove
it from the headers they pass (it is still part of the signature). They
also ask it to verify TLS certificates explicitly (`verify_SSL => 1`),
because versions of `HTTP::Tiny` before 0.083, bundled with older Perls,
do not do it by default: without it, anybody in the middle could read the
signed requests and, in example 07, the temporary credentials.


## 01-sts-get-caller-identity.pl

The simplest case: a signed POST with credentials taken from the
environment. It asks STS who the caller is, so it is also a quick way to
check that the credentials work: it prints the answer either way, and
exits non-zero when the request fails.

```shell
./eg/01-sts-get-caller-identity.pl
DRY_RUN=1 ./eg/01-sts-get-caller-identity.pl
```


## 02-s3-get-object.pl

Download an S3 object, printing it on the standard output or saving it in
a file. S3 is special (paths are neither normalized nor double-encoded,
the payload hash goes in a header) but the module knows it from the
service name.

```shell
./eg/02-s3-get-object.pl my-bucket path/to/key.txt
AWS_REGION=eu-west-1 ./eg/02-s3-get-object.pl my-bucket photo%20one.jpg photo.jpg
```

Like 03, 04 and 05, this example puts the key in the URL as it is
written, so the key must be given as it appears there: ASCII,
percent-encoded (a space is `%20`, a percent sign `%25`, and so on).
Handing over a raw space makes `HTTP::Tiny` write an invalid request
line, and a raw `%`, `?` or `#` truncates the key or breaks the
signature.

These four examples also use the virtual-hosted URL, where the bucket is
part of the host name. That host does not match the
`*.s3.REGION.amazonaws.com` certificate when the bucket name contains a
dot, and the answer is not to turn TLS verification off: use the
path-style URL `https://s3.REGION.amazonaws.com/BUCKET/KEY` for those
buckets.

Because the bucket and `AWS_REGION` end up in the host name, they are
checked before use, as in 10: a `/` in either would move the host
somewhere else altogether (a bucket of `evil.example.com/x` gives
`https://evil.example.com/x.s3...`) and the request would be signed and
sent there, session token and all. The key needs no such check, since it
lands in the path: `sign` already refuses control characters in the URL,
and the rest is the encoding caveat above.


## 03-s3-put-object-from-file.pl

Upload a file to S3 without loading it in memory: the payload hash is
computed from a filehandle (`body_fh`, which is left where it was), and
`HTTP::Tiny` then reads the same file a piece at a time when sending.

```shell
./eg/03-s3-put-object-from-file.pl backup.tar.gz my-bucket backups/backup.tar.gz
DRY_RUN=1 ./eg/03-s3-put-object-from-file.pl big.iso my-bucket isos/big.iso
```


## 04-s3-presigned-urls.pl

Presigned URLs: the signature travels in the query string, so anyone
holding the URL can use it until it expires, with any client at all. It
prints one URL to read the object and one to write it.

```shell
./eg/04-s3-presigned-urls.pl my-bucket path/to/key.txt
./eg/04-s3-presigned-urls.pl my-bucket path/to/key.txt 600    # valid for 10 minutes
```

The output suggests how to use them with `curl`.


## 05-s3-chunked-upload.pl

Streaming upload to S3 (`aws-chunked`): the body is sent in signed
chunks, so the whole payload does not need to be hashed in advance nor
held in memory. The total size must be known, because the `Content-Length`
of the encoded body is computed with `encoded_length` and the chunker
checks that the data matches. In dry-run mode it also encodes the file and
reports how many bytes the body has, compared with the announced length.

To try a trailing checksum, set the `@checksum` variable in the script to
`(checksum => 'crc32c')`: it is passed to both `encoded_length` and
`sign`, because the announced length has to count the trailer too.

```shell
./eg/05-s3-chunked-upload.pl data.bin my-bucket uploads/data.bin
DRY_RUN=1 ./eg/05-s3-chunked-upload.pl data.bin my-bucket uploads/data.bin
```


## 06-dynamodb-json-api.pl

A JSON API, where the operation is chosen by a header
(`X-Amz-Target`), signed like all the others. It lists the DynamoDB tables
of a region.

```shell
./eg/06-dynamodb-json-api.pl
./eg/06-dynamodb-json-api.pl eu-west-1
```


## 07-rolesanywhere-x509.pl

The X.509 variant: instead of a secret key, the request is signed with
the private key of a certificate, as IAM Roles Anywhere wants, to get
temporary credentials. `KEY_TYPE` is `RSA` (default) or `ECDSA`;
`CHAIN_FILE` (a PEM bundle of intermediate CAs) and `KEY_PASSWORD` (for
encrypted keys) are optional. `TRUST_ANCHOR_ARN`, `PROFILE_ARN` and
`ROLE_ARN` are required, except with `DRY_RUN=1`, where placeholders
stand in just to show the shape of the request. Beside the
`Authorization` header, the request carries the certificate in
`X-Amz-X509` and the chain, if any, in `X-Amz-X509-Chain`.

```shell
CERT_FILE=cert.pem KEY_FILE=key.pem \
   TRUST_ANCHOR_ARN=arn:aws:rolesanywhere:... PROFILE_ARN=arn:aws:rolesanywhere:... \
   ROLE_ARN=arn:aws:iam::... ./eg/07-rolesanywhere-x509.pl

DRY_RUN=1 KEY_TYPE=ECDSA CERT_FILE=cert.pem KEY_FILE=key.enc.pem \
   KEY_PASSWORD=secret CHAIN_FILE=ca-bundle.pem ./eg/07-rolesanywhere-x509.pl
```

The session JSON is the only thing on the standard output — the
algorithm, the status line, any error body and the `DRY_RUN=1` dump of
the request all go to the standard error — so the program can be used as
`> session.json` or piped into `jq`. A dry run obtains no session and so
writes nothing there either. A failed request prints nothing at all on
the standard output, rather than
an error body where a session was expected: `HTTP::Tiny` reports a
request that never reached AWS as status 599 with the reason, as plain
text, in the body, and that saved under the name of a session would be a
failure kept as if it were credentials. The exit status is non-zero
either way. Mind that what does get saved holds temporary credentials,
so the file deserves the same care as a private key.

`AWS_REGION` is checked here too, for the same reason as in 02 to 05 and
10: it lands in the host name, and a `/` would send the certificate and
its signature somewhere else, with whatever answered read back as a
session.

Check the shape of the `CreateSession` request (path and body) against
the current IAM Roles Anywhere API reference before relying on it: it was
written from memory and has not been tried against AWS.


## 08-x509-custom-signer.pl

With the X.509 variant the private key does not have to be given to the
module: a `signer` function receives the bytes to sign and returns the
signature. That is how to use keys that cannot leave an HSM or a KMS. Here
the function just uses CryptX by itself and logs what it does, to show
where the hook is.

```shell
CERT_FILE=cert.pem KEY_FILE=key.pem ./eg/08-x509-custom-signer.pl
```


## 09-inspect-a-signature.pl

No network, no secrets: it reproduces the example of the AWS documentation
and prints all the intermediate values (canonical request, string to sign,
authorization header), which is what helps when AWS answers
`SignatureDoesNotMatch`. The time is fixed, so the output is always the
same, and the program tells whether the signature matches the one in the
documentation.

```shell
./eg/09-inspect-a-signature.pl
```


## 10-s3-content-encoding-probe.pl

Not a usage example but a diagnostic probe, kept here because it is built
out of the same pieces as 05. With `streaming`, `sign` adds `aws-chunked`
to whatever `Content-Encoding` the caller already set, and the authorities
disagree on the order: this uploads a gzipped object and reports whether
S3 takes the one the module sends (see the note in `TODO.md`).

It writes two objects to the bucket it is given, a control without any
`Content-Encoding` and the real case with gzip, so that a rejection can
be told apart from a wrong bucket, region or set of credentials. It reads
both back, checks the bytes round-trip, and deletes them again unless
`KEEP=1`. The key prefix defaults to `aws-sigv4-probe/`.

Because it deletes what it uploads, it first checks that both keys hold
nothing and refuses to run otherwise, treating anything but a clear "not
there" as occupied. That check needs `s3:ListBucket` on the bucket:
without it S3 answers a HEAD on a key that does not exist with 403
rather than 404, a free key cannot be told from a forbidden one, and the
program stops and says so. The bucket, the region and the key prefix are also
checked before use: they are pasted into the URL, and a `/` in the bucket
or the region would move the host elsewhere and send the signed request,
session token included, to whatever is there.

```shell
./eg/10-s3-content-encoding-probe.pl my-bucket
AWS_REGION=eu-west-1 ./eg/10-s3-content-encoding-probe.pl my-bucket scratch/probe-
KEEP=1 ./eg/10-s3-content-encoding-probe.pl my-bucket
DRY_RUN=1 ./eg/10-s3-content-encoding-probe.pl my-bucket
```

A verdict is only reached when the run earns it. "Accepted" needs more
than a 200: S3 must also have stored the object as `Content-Encoding:
gzip`, having taken the `aws-chunked` token off, and have given the bytes
back unchanged. "Rejected", which tells you to change the order in the
signing code, needs S3 itself to have turned the upload down — a 4xx
carrying an S3 error code, and not one of the 401 and 403 that talk
about the credentials rather than the header. Everything else, a 503, a
dropped connection, a key that expired halfway through, is reported as
inconclusive, because the control having gone through says nothing about
the upload after it. It exits non-zero when the probe reaches no verdict,
or when the order is refused, and then says which line to change. The
report it prints is meant
to be pasted into a bug report or a chat: it is built from a fixed list of
fields, so it holds no credentials, no `Authorization` header, no session
token, and neither the bucket name nor the key.
