#!/usr/bin/perl

# Example Blosxom plugin. This uses subclassing to render the blog content
# as BBCode. Note the use of next::method to get Blog::Blosxom to do most
# of the hard work. And that is how simple it is to use.

use strict;
use warnings;
use FindBin;
use File::Spec;

my $blog = My::Blosxom->new(
    datadir => File::Spec->catdir($FindBin::Bin, "blog"),
    blog_title => "My Blog",
    blog_description => "A blog for blogging with",
);

my $path = "";
my $flavour = "html";

print $blog->run($path, $flavour);

#==========================================#
package My::Blosxom;

use base qw(Blog::Blosxom);

use Parse::BBCode;
use Class::C3;

sub entry_data {
    my ($self, $entry) = @_;
    my $parse = Parse::BBCode->new();

    my $entry_data = $self->next::method($entry);

    $entry_data->{body} = $parse->render($entry_data->{body});

    return $entry_data;
}

__END__

This script is licenced under the same licence as the version of Blog::Blosxom
with which it was shipped, or the latest version if it becomes orphaned.
