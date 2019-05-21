package CTK::Plugin::Net;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::Plugin::Net - Net plugin

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use CTK;
    my $ctk = new CTK(
            plugins => "net",
        );

    $ctk->fetch(
        -url     => 'ftp://anonymous:anonymous@192.168.200.8/mbutiny/rsp?Debug=1&Passive=1',
        -command => "copy", # copy / copyuniq / move / moveuniq
        -dirdst  => "/path/to/destination/dir", # Destination directory
        -regexp   => qr/tmp$/,
    );

    $ctk->store(
        -url     => 'ftp://anonymous:anonymous@192.168.200.8/mbutiny/rsp?Debug=1&Passive=1',
        -command => "copy", # copy / copyuniq / move / moveuniq
        -dirsrc => "/path/to/source/dir", # Source directory
        -regexp   => qr/tmp$/,
    )

=head1 DESCRIPTION

Net plugin

=head1 METHODS

=over 8

=item B<fetch>

    $ctk->fetch(
        -url     => 'ftp://anonymous:anonymous@192.168.200.8/mbutiny/rsp?Debug=1&Passive=1',
        -command => "copy", # copy / copyuniq / move / moveuniq
        -dirdst  => "/path/to/destination/dir", # Destination directory
        -files   => ['foo.tgz', 'bar.tgz', 'baz.tgz'],
    );

Download specified files from resource

    $ctk->fetch(
        -url     => 'ftp://anonymous:anonymous@192.168.200.8/mbutiny/rsp?Debug=1&Passive=1',
        -command => "copy", # copy / copyuniq / move / moveuniq
        -dirdst  => "/path/to/destination/dir", # Destination directory
        -regexp   => qr/tmp$/,
    );

Download files from remote resource by regexp mask

=over 8

=item B<-url>

URL of resource.

For example:

    ftp://anonymous:anonymous@192.168.200.8/mbutiny/rsp?Debug=1&Passive=1

Debug=1&Passive=1 -- Net::FTP atrtributes. See L<Net::FTP>

=item B<-dirout>, B<-out>, B<-output>, B<-dirdst>, , B<-dst>

Specifies desination directory

Default: current directory

=item B<-list>, B<-mask>, B<-file>, B<-files>, B<-regexp>

    -list => [qw/ file1.txt file2.txt file3.* /]

List of files

    -file => "file1.txt"

Name of file

    -regexp => qr/\.(cgi|pl)$/i

Regexp

Default: undef (all files)

=item B<-cmd>, B<-command>, B<-action>

Command name. Allowed: copy, copyuniq, move, moveuniq

Default: copy

=back

=item B<store>

    $ctk->store(
        -url     => 'ftp://anonymous:anonymous@192.168.200.8/mbutiny/rsp?Debug=1&Passive=1',
        -command => "copy", # copy / copyuniq / move / moveuniq
        -dirsrc => "/path/to/source/dir", # Source directory
        -regexp   => qr/tmp$/,
    )

Upload files from local directory to remote resource by regexp mask

=over 8

=item B<-url>

URL of resource.

For example:

    ftp://anonymous:anonymous@192.168.200.8/mbutiny/rsp?Debug=1&Passive=1

Debug=1&Passive=1 -- Net::FTP atrtributes. See L<Net::FTP>

=item B<-dirin>, B<-in>, B<-input>, B<-dirsrc>, , B<-src>

Specifies source directory

Default: current directory

=item B<-list>, B<-mask>, B<-glob>, B<-file>, B<-files>, B<-regexp>

    -list => [qw/ file1.zip file2.zip foo*.zip /]

List of files or globs

    -glob => "*.zip"

Glob pattern

    -file => "file1.zip"

Name of file

    -regexp => qr/\.(zip|zip2)$/i

Regexp

Default: undef (all files)

=item B<-cmd>, B<-command>, B<-action>

Command name. Allowed: copy, copyuniq, move, moveuniq

Default: copy

=back

=back

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<CTK>, L<CTK::Plugin>

=head1 TO DO

* Use SSH (SFTP)

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK>, L<CTK::Plugin>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses>

=cut

use vars qw/ $VERSION /;
$VERSION = '1.00';

use base qw/CTK::Plugin/;

use CTK::Util qw(:API :FORMAT :ATOM :FILE);
use URI;
use Carp;
use File::Spec;
use File::Find;
use Cwd qw/getcwd/;

__PACKAGE__->register_method(
    method    => "fetch",
    callback  => sub {
    my $self = shift;
    my ($url, $cmd, $dirout, $listmsk) =
            read_attributes([
                ['URL','URI'],
                ['CMD','COMMAND','ACTION'],
                ['DIROUT','OUT','OUTPUT','DIRDST','DST'],
                ['LISTMSK','LIST','MASK','GLOB','GLOBS','FILE','FILES','REGEXP'],
            ],@_) if defined $_[0];
    my $count = 0;
    unless ($url) {
        $self->error("Incorrect URL!");
        return 0;
    }
    my $uri = new URI($url);
    $cmd ||= 'copy'; # copy / copyuniq / move / moveuniq
    $dirout //= getcwd();
    $dirout = File::Spec->catdir(getcwd(), $dirout) unless File::Spec->file_name_is_absolute($dirout);
    unless (-e $dirout) {
        $self->error(sprintf("Destination directory not found \"%s\"", $dirout));
        return 0;
    }
    $listmsk //= '';
    my (@list, $cond);
    if (ref($listmsk) eq 'ARRAY') { @list = @$listmsk } # array of globs
    elsif (ref($listmsk) eq 'Regexp') { $cond = $listmsk } # Regexp
    else { @list = ($listmsk) } # glob

    # Get connect data
    my %attr = $uri->query_form; $uri->query_form({});
    my %ftpct = (
        ftphost     => $uri->host,
        ftpuser     => $uri->user,
        ftppassword => $uri->password,
        ftpdir      => $uri->path,
        (%attr) ? (ftpattr => {%attr}) : (), # See Net::FTP
    );

    # Get list of files
    my $ftplist = ftpgetlist({%ftpct}, $cond) || {};
    my %tmp;
    foreach my $f (@list, @$ftplist) {
        exists($tmp{$f}) ? ($tmp{$f}++) : ($tmp{$f} = 0);
    }
    if (@list) {
        @list = grep { $tmp{$_} } keys %tmp;
    } else {
        @list = grep {$_!~/^\.+$/} @$ftplist;
    }

    # Get connect handler
    my $ftph = ftp({%ftpct}, 'connect');

    foreach my $fn (@list) {$count++;
        my $fs = $ftph->size($fn) || 0;
        my $fndst = File::Spec->catfile($dirout,$fn);
        $ftph->binary;

        my $statget = 0;
        if (($cmd =~ /uniq/) && (-e $fndst) && (-s $fndst) == $fs) {
            $statget = 1;
        } else {
            $statget = $ftph->get($fn, $fndst);
        }

        my $fsdst = $statget && -e $fndst ? (-s $fndst) : 0; # Size of file
        if ($statget && $fsdst >= $fs) { # OK
            if ($cmd =~ /move/) {
                $ftph->delete($fn) or
                   $self->error(sprintf("Can't delete file \"%s\": %s", $fn, $ftph->message));
            }
        } else { # Error
            if ($statget) {
                $self->error(sprintf("Can't get file \"%s\": %s", $fn, $ftph->message));
            } else {
                $self->error(sprintf("Can't get file \"%s\". Size mismatch: Got: %d; Expected: %d", $fn, $fs, $fsdst));
            }
            $count--;
        }
    }

    $ftph->quit();

    return $count;
});

__PACKAGE__->register_method(
    method    => "store",
    callback  => sub {
    my $self = shift;
    my ($url, $cmd, $dirin, $listmsk) =
            read_attributes([
                ['URL','URI'],
                ['CMD','COMMAND','ACTION'],
                ['DIRIN','IN','INPUT','DIRSRC','SRC'],
                ['LISTMSK','LIST','MASK','GLOB','GLOBS','FILE','FILES','REGEXP'],
            ],@_) if defined $_[0];
    my $count = 0;
    unless ($url) {
        $self->error("Incorrect URL!");
        return 0;
    }
    my $uri = new URI($url);
    $cmd ||= 'copy'; # copy / copyuniq / move / moveuniq
    $dirin //= getcwd();
    $dirin = File::Spec->catdir(getcwd(), $dirin) unless File::Spec->file_name_is_absolute($dirin);
    unless (-e $dirin) {
        $self->error(sprintf("Source directory not found \"%s\"", $dirin));
        return 0;
    }
    $listmsk //= '';
    my (@list, $cond);
    if (ref($listmsk) eq 'ARRAY') { @list = @$listmsk } # array of globs
    elsif (ref($listmsk) eq 'Regexp') { $cond = $listmsk } # Regexp
    else { @list = ($listmsk) } # glob

    # Get connect data
    my %attr = $uri->query_form; $uri->query_form({});
    my %ftpct = (
        ftphost     => $uri->host,
        ftpuser     => $uri->user,
        ftppassword => $uri->password,
        ftpdir      => $uri->path,
        (%attr) ? (ftpattr => {%attr}) : (), # See Net::FTP
    );

    # Get connect handler
    my $ftph = ftp({%ftpct}, 'connect');
    $ftph->binary;

    my $top = length($dirin) ? $dirin : getcwd();
    my @inlist;
    find({ wanted => sub {
        return if -d;
        my $name = $_;
        my $file = $File::Find::name;
        my $dir = $File::Find::dir;
        return if $dir ne $top;
        @inlist = _expand_wildcards(@list) unless @inlist;
        if ($cond) {
            return unless $name =~ $cond;
        } elsif(@inlist) {
            return unless grep {$_ eq $name} @inlist;
        }

        # Start!
        #printf "#%d Dir: %s; Name: %s; File: %s\n", $count, $dir, $name, $file;
        my $fs = -e $name ? (-s $name) : 0;
        my $fsdsta = $ftph->size($name) || 0;

        my $statput = 0;
        if (($cmd =~ /uniq/) && (-e $name) && $fsdsta == $fs) {
            $statput = 1;
        } else {
            $statput = $ftph->put($name,$name);
        }
        my $fsdst = $ftph->size($name) || 0;
        if ($statput && $fsdst >= $fs) { # Ok
            if ($cmd eq 'move') {
                unlink($name) or
                    $self->error(sprintf("Can't delete file \"%s\": %s", $name, $!));
            }
            $count++;
        } else { # Error
            if ($statput) {
                $self->error(sprintf("Can't put file \"%s\": %s", $name, $ftph->message));
            } else {
                $self->error(sprintf("Can't put file \"%s\". Size mismatch: Got: %d; Expected: %d", $name, $fsdst, $fs));
                $count--;
            }
        }
    }}, $top);

    $ftph->quit();

    return $count;
});

sub _expand_wildcards {
    my @wildcards = grep {defined && length} @_;
    return () unless @wildcards;
    my @g = map(/[*?]/o ? (glob($_)) : ($_), @wildcards);
    return () unless @g;
    return @g;
}

1;

__END__
