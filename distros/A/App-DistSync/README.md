[//]: # ( README.md Fri 05 Dec 2025 16:41:07 MSK )

# App::DistSync

**App::DistSync** is a ready-to-use solution for synchronizing two or more web resources containing static data. The project has proven itself in scenarios involving distribution mirrors, software repositories, and collections of photos, videos, audio files, and other multimedia content.

## FEATURES

- Directory and file replication between multiple resources
- Simple file addition workflow — just copy files into the resource directory
- No complex configuration required: behavior is controlled through command-line options and descriptor files
- Dynamic addition of new resources (mirrors)
- Installation via `RPM`, `APT`, `CPAN`, or manually with `make install`

## REQUIREMENTS

Before installation, ensure the following packages are present on the system where App::DistSync will run:

- GCC (recent version)
- Perl v5.20 or later (recommended: 5.20+)
- libwww (perl-libwww-perl / p5-libwww / libwww-perl / perl-libwww / LWP)
- libnet
- A web server such as Apache2, nginx, lighttpd, etc.

## INSTALLATION

You can install App::DistSync automatically or manually.

### Automatic installation

For **RHEL-based** systems:
```bash
sudo dnf install perl-libwww-perl
```

For **Debian-based** systems:
```bash
sudo apt install perl-libwww-perl
```

From **CPAN**:
```bash
cpan install App::DistSync
```

For **ActivePerl** (Windows):
```bash
ppm install App-DistSync
```

### Manual installation

1. Download the distribution from [CPAN](https://metacpan.org/pod/App::DistSync) or the official release from [SourceForge](https://sourceforge.net/projects/app-distsync/).
2. Extract the archive and switch into the project directory.
3. Run:

```bash
perl Makefile.PL
make
make test
sudo make install
```

Or using `cpanminus`:

```bash
cpanm App::DistSync
```

Missing modules will be installed automatically.

## INITIAL SETUP

Before first use, initialize the directory that will act as the mirror root. Initialization creates a basic directory structure and several system files. These files are described in the next section.

To initialize, run:

```bash
distsync -D /var/www/foo.localhost init
```

The `-D` option specifies the resource directory where required system files will be created.

Next, configure your web server to serve this directory. Example Apache2 configuration:

```apache
<VirtualHost *:80>
    ServerName foo.localhost
    DocumentRoot /var/www/foo.localhost
    <Directory /var/www/foo.localhost>
        DirectoryIndex index.html
        Options +Indexes +FollowSymLinks -Includes -MultiViews
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

> Note: the `-Includes` option must be disabled. SSI and similar post-processing filters interfere with App::DistSync, which relies on correct `Last-Modified` headers for all files. Disable any filters that modify response bodies.

Once the server is running, the resource is ready. Add its own URL to the `MIRRORS` descriptor file, e.g.:
```
http://foo.localhost
```

If your mirror should reside in a subdirectory (e.g. `/dist`), initialize it there:

```bash
mkdir -p /var/www/foo.localhost/dist
distsync -D /var/www/foo.localhost/dist init
```

And provide this specific URL to other mirrors:
```
http://foo.localhost/dist
```

## RESOURCE DIRECTORY STRUCTURE

The resource directory is the root of the mirror and contains all files and descriptors. A single server may host multiple resources with different URLs.

Some descriptor files **must not** be edited manually — they are marked accordingly.

### META

*NOT EDITABLE.* A YAML file containing metadata about the resource, including the last synchronization time. Also provides system information required by other mirrors.

### MANIFEST

*NOT EDITABLE.* Generated automatically on each run. Describes the current directory structure. After sync completion, it is regenerated and the `mtime` field in `META` is updated.

Format:
```
DIRNAME/FILENAME   MTIME   SIZE   MTIME_AS_STRING
```

Paths are relative, with `/` used as the separator regardless of OS.

### MANIFEST.SKIP

Editable descriptor defining which files must be excluded from `MANIFEST`. Supports Perl-compatible regular expressions in YAML format.

The following files are always ignored:
```
META
MANIFEST
MANIFEST.DEL
MANIFEST.SKIP
MANIFEST.LOCK
README
```

Format:
```
DIRNAME/FILENAME   COMMENT
```

### MANIFEST.DEL

Editable descriptor listing files that must be deleted after a specified offset (`DTIME`). `DTIME` is relative to the modification time of `MANIFEST.DEL` itself (default: `+3d`).

The file is **not synchronized**, but remote mirrors download it and delete the listed files locally. After processing, the file is cleared and recreated.

Format:
```
DIRNAME/FILENAME   DTIME
```

### MIRRORS

Editable descriptor listing the URLs of all mirrors. The current resource **must** be included in this list.

Format:
```
URL   COMMENT
```

### MANIFEST.LOCK

*NOT EDITABLE.* Contains the PID of the process performing synchronization. Prevents concurrent `distsync` runs across mirrors.

### MANIFEST.TEMP

*NOT EDITABLE.* Temporary file holding downloaded data. May persist between runs.

### README

Optional, local-only informational file. Not synchronized. If you need it to sync, use `README.md` instead.

## GETTING STARTED

After initialization, edit the `MIRRORS` file and add the new mirror’s URL. Then upload the updated file to any existing mirror so others can discover the new resource.

Run the first synchronization:

```bash
distsync -D /var/www/foo.localhost sync -d
```

`-d` enables progress output; `-dv` adds more verbose diagnostics.

### Important option

`-D DATADIR` — Specifies the local resource directory where synchronized files are stored.

Help:
```bash
distsync --help
man distsync
```

## PRODUCTION USE

Once mirrors can reach the newly created resource, it may be scheduled for automatic, periodic synchronization. The most common method is cron.

Example crontab entry:
```cron
37 * * * * /usr/bin/distsync -D /var/www/foo.localhost >/var/log/distsync.log 2>&1
```

All logs and errors are written to `/var/log/distsync.log`.

### Adding files
Copy files into the resource directory. They will be synchronized automatically.

### Deleting files
Add filenames to `MANIFEST.DEL`. The system will handle deletion. You may remove files from disk manually afterwards.

### Updating files
Replace the file with a newer version. Synchronization will propagate the change.

⚠ **Do NOT rename or move files or directories.**
Missing items will be recreated during synchronization, leading to divergence or duplication across mirrors.

