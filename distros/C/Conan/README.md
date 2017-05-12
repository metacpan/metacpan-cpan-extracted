# Conan The Deployer

This Perl module is designed to facilitate the promotion and configuration of Xen virtual images.  For more documentation, please see the POD at the end of each perl module.


### Deploy

The *Conan::Deploy* module has configuration option that are set via *'/etc/conan.cfg* and *~/.conanrc*, which override the default parameters used an object instantiation.

#### Deploy Config Format

The config file looks for the format
```Perl
/^(\S+)=(\S+)/
```

And will allows comments that start with a hash.  The parameters used are:

* srcimagebase
* targetimagebase

Allowing you to configure the software at a site, or user level for different default source and target paths.

#### Deploying an image

Example deployment:

```Perl
use Conan::Deploy;
my $d = Conan::Deploy->new(
        srcimagebase => '/tmp/base/qa',
        targetimagebase => '/tmp/base/prod',
);

$d->promote_image( 'image-ver' );
```

This will look for *image-ver* within the *srcimagebase* and rsync it to *targetimagebase* and subsequently run an md5 file checksum against all files in both locations, ensuring that the copy was complete.

