
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

package CGI::FormBuilder::Test;

=head1 NAME

CGI::FormBuilder::Test - Test harness for FormBuilder

=head1 SYNOPSIS

    use CGI::FormBuilder::Test;

    my $test = 1;
    for (@tests) {
        my $outfile = outfile($test++);

    }

=cut

use strict;
use warnings;
no  warnings 'uninitialized';

use CGI::FormBuilder::Util;


our $VERSION = '3.10';
our $DEBUG = 0;

use Exporter;
use base 'Exporter';
our @EXPORT = qw(outfile);

use File::Basename 'fileparse';
use File::Spec::Functions;

sub outfile ($) {
    my($file, $dir) = fileparse($0);
    $file =~ s/-.*//;   # just save "1a-", "3d-", etc
    my $out = catfile($dir, sprintf("$file-test%2.2d.html", $_[0]));
    open(O, $out) || warn "Can't open $out: $!\n";
    return join '', <O>;
}

1;

=head1 DESCRIPTION

=head1 REVISION

$Id: Test.pm 100 2007-03-02 18:13:13Z nwiger $

=head1 AUTHOR

Copyright (c) L<Nate Wiger|http://nateware.com>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut
