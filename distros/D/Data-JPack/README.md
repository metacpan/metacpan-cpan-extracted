# NAME

Data::JPack - Offline/Online Web Application Packer

# SYNOPISIS

```perl
use Data::JPack;

my $packer=Data::JPack->new();
$packer->encode ($data);
```

# DESCRIPTION

Provides a platform to package application content suitable for web clients,
templating, via [Template::Plexsite](https://metacpan.org/pod/Template%3A%3APlexsite) and a foundation for a client side worker
pool for CPU intensive javavscript tasks.

Application code (javascript), textual and binary data can be packaged and
loaded without the requirement of a server (ie local files) and avoiding
samesite / origin security issues.

The client side javascript is installed and accessable via [Data::JPack::App](https://metacpan.org/pod/Data%3A%3AJPack%3A%3AApp).

# API (Server side)

## Construction 

### new

```
Data::JPack->new(OPTIONS)
```

Create a new packer object, configured with OPTIONS, which are key value pairs.
The options supported are:

- html\_container

    ```perl
    html_container=> Path_to_html_file
    ```

    This is a path to a html which will be considered the root or container for the
    data. If a path to a html is given, the dirname is extracted and is used as the
    the actual container path.  If a directory path is provided, this is used
    directly.

- jpack\_type

    ```perl
    html_container=> "data"; 
    ```

    Currently the only supported value for this option is `"data"`;

- jpack\_compression

    ```perl
    jpack_compression=>COMPRESSION
    ```

    Configures if compression of packed files should be enabled. The only
    compression option supported is `'deflate'`. Any other value will disable
    compression.

- embedded 

    ```perl
    embedded => FLAG
    ```

    If FLAG is true, the data encoded will be configured for inline/embedded usage
    in a html file. Otherwise the encoded data will be configured for loading from
    a external file.

    The default is `false`.

## Single Shot Encoding

With an existing `Data::JPack` object, these methods these methods will
process a single data chunk, with required header and footer.

### encode

```
$packer->encode($data);
```

Single call that wraps and encodes data suitable for storing in a standalone
file, or embeded if the `$packer` object is conifigured.

Returns the encoded data.

### decode

```
$packer->decode($data);
```

Decodes `$data` expected in [Data::JPack](https://metacpan.org/pod/Data%3A%3AJPack) format.  Returns the decoded data.

### encode\_file

```
$packer->encode_file($path);
```

Single call the encodes the data from a file located and `$path`. Calls
`encode` internally. 

Returns the encoded data.

## Streaming Encoding

To encoding a data a chunk at a time, first encode the header, then 0 or more data, then the footer:

```
$packer->encode_header;       # Must be first
$packer->encode_data($data);  # 0 or more times
$packer->encode_footer;       # Must be last
```

### encode\_header

```
$packer->encode_header;
```

Serializes the header information required. The actual header created depends
on the `embedded` flag of the `$packer` object. The Output of this sub must
before any data chunk encoded.

### encode\_data

```
$packer->encode_data;
```

Encodes the provided data and returns it. Note no filtering of the `$data` is
performed.  It must be done manaully before hand.

Returns the encoded data.

### encode\_footer

```
$packer->encode_footer;
```

Serializes the end of the encoded file. The output of this sub must be after
all data chunks to be encoded.

## Container Management and Inspection

The container contains multiple files.

### next\_set\_name

### next\_file\_name

### html\_root

### current\_set

### current\_file

### set\_prefix

### flush
