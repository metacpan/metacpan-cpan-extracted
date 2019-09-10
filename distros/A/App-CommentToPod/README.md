# Comment2pod

A util for generating pod documentation from comments.

This package contains:

 - `comment2pod` (commandline util)
 - `App::CommentToPod` - module containing utils for converting text to pod
 - `Dist::Zilla::Plugin::CommentToPod` - distzilla plugin which enables
   comment2pod during builds.

## test/build/install

```bash
# expect distzilla to be installed
PERL5LIB=lib dzil test
PERL5LIB=lib dzil build
cpanm comment2pod-0.00*.tar.gz
```

## Example

Concider the following file
```perl
# Hello::Printer provide some utils
# foo
package Hello::Printer;

use strict;
use warnings;

# hello() prints hello
sub hello {
	...
}

# wow() prints wow
sub wow {
	...
}

1;
```
The following command:

    $ cat Printer.pm | ./bin/comment2pod 

Will generate the following (to stdout)

```perl
=pod

=encoding utf8

=head1 NAME

Hello::Printer

=head1 SYNOPSIS

     Hello::Printer provide some utils
     foo


=cut

=head2 Methods

=cut

# Hello::Printer provide some utils
# foo

package Hello::Printer;

use strict;
use warnings;

=over 12

=item C<hello>

hello() prints hello

=back

=cut

sub hello {
	...
}

=over 12

=item C<wow>

wow() prints wow

=back

=cut

sub wow {
	...
}

1;
```
