
# Compress::Bzip2

### DESCRIPTION

This module provides a Compress::Zlib like Perl interface to the bzip2
library.  It uses the low level interface to the bzip2 algorithm, and
reimplements all high level routines.

### What is Bzip2 ?

bzip2 is a portable lossless data compression library written in ANSI C.
It offers pretty fast compression and fast decompression.
bzip2 has very good results, if you want to compress ASCII Documents.

bzip2 is probably not great for streaming compression.  It fills it's
internal buffer, which depending of parameters is between 100k and 900k
in size, before it outputs ANY compressed data.  It works best compressing
an entire document.

Streaming decompression on the other hand, gives a steady torrent of bytes.

### What is Compress::Bzip2 ?

Compress::Bzip2 provided early bzip2 bindings for Perl5 compatible to
the old Compress::Zlib library. See Compress::Raw::Bzip2 for the new API
compatible with IO::Compress.

It's my intent to make this package like the Compress::Zlib package, so
that code that uses one can fairly easily use the other.  The perlxs stuff
that's visible to perl has methods that have the same names as their
Compress::Zlib counterparts, except that the "g" is changed to a "b".

Most code that uses Compress::Zlib should be able to use this package.
Simply change
```

   $gz = Compress::Zlib::gzopen( "filename", "w" );
   
```

to
```

   $gz = Compress::Bzip2::gzopen( "filename", "w" );
  ```

I made aliases of all the Compress::Zlib functions.  Some of them don't
return anything useful, like crc32 or adler32, cause bzip2 doesn't
do that sort of thing.  Take a look at t/070-gzcomp.t and t/071-gzuncomp.t.

Bug fixes and other feedback are welcome.

### Copyright

bzip2

**Julian Seward**, j s e w a r d   a t   a c m . o r g

Compress-Bzip2 prior to 2.0 is distributed under the terms of the
GNU General Public License (GPL).  See the file COPYING.

Since version 2.0 Compress-Bzip2 is dual-licensed.
You can redistribute it and/or modify it under the same terms as Perl
itself, either Perl version 5.8.3 or, at your option, any later
version of Perl 5 you may have available.


### Many Thanks to:


**Author of bzip2**

Julian Seward, j s e w a r d   a t   a c m . o r g

Cambridge, UK

http://sources.redhat.com/bzip2

**Author of Compress::Zlib**

Paul Marquess, p m q s   a t   c p a n . o r g

http://www.cpan.org

**Author of 1.x Compress::Bzip2 (1999)**

Gawdi Azem <azemgi@rupert.informatik.uni-stuttgart.de>

(last known email, no longer valid)

**Helped out with win32 compatibility**

Sisyphus, s i s y p h u s 1   a t   o p t u s n e t . c o m . a u

**Author of Compress::Bzip2 1.03**

Marco "Kiko" Carnut,
 
k i k o   a t   t e m p e s t . c o m . b r

