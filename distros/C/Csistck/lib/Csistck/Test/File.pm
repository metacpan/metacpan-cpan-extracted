package Csistck::Test::File;

use 5.010;
use strict;
use warnings;

use base 'Csistck::Test::FileBase';
use Csistck::Oper qw/debug/;
use Csistck::Util qw/hash_file hash_string/;

our @EXPORT_OK = qw/file/;

use Digest::MD5;
use File::Basename;
use File::Copy;
use FindBin;
use File::stat;
use Template;
use Sys::Hostname::Long qw//;
use Text::Diff ();

sub file { Csistck::Test::File->new(@_); };

sub desc { sprintf("File check on %s", shift->dest); }

sub file_check {
    my $self = shift;
    my ($dest, $src) = ($self->dest, $self->src);
    file_compare($src, $dest);
}

sub file_repair {
    my $self = shift;
    my ($dest, $src) = ($self->dest, $self->src);
    debug("Copying file: <src=$src> <dest=$dest>");
    copy($src, $dest);
}
    
sub file_diff {
    my $self = shift;
    my ($dest, $src) = ($self->dest, $self->src);
    say(Text::Diff::diff($dest, $src));
}

# Compare hashes between two files
sub file_compare {
    my @files = @_;
    return 0 unless (scalar @files == 2);
    
    # Get hashes and return compare
    my ($hasha, $hashb) = map hash_file($_), @files;
    debug(sprintf "File compare result: <hash=%s> <hash=%s>", $hasha, $hashb);
    return ($hasha eq $hashb);
}

1;
__END__

=head1 NAME

Csistck::Test::File - Csistck file check

=head1 DESCRIPTION

=head1 METHODS

=head2 file($target, :$src, :$mode, :$uid, :$gid, :\&on_repair)

Copy file C<$src> to C<$target>, setting additional options with named
arguments such as mode and uid.

    role 'test' => file(
        '/etc/lighttpd/lighttpd.conf',
        src => 'lighttpd/lighttpd.conf',
        mode => '0644'
    );

This method takes the following named parameters:

=over

=item B<src>

Source file for copying

=item B<mode>

Change target file mode. This should be a string representation of the octal
mode of the target file -- eg. '0644'

=item B<uid>

Change target UID to the specified integer value.

=item B<gid>

Change target GID to the specified integer value.

=item B<on_repair>

If a repair operation is run, this coderef is called by the process method.

=back

=head1 AUTHOR

Anthony Johnson, E<lt>anthony@ohess.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2012 Anthony Johnson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
