package Config::Writer;

=pod #{{{ main documentation section

=head1 NAME

B<Config::Writer> - a module to write configuration files
in an easy and safe way.

=head1 DESCRIPTION

This module is intended to perform the next operations:

=over 4

=item *

safe temporary configuration file creation, ownership and
access mode setting;

=item *

creation of backup file(-s) of the target configuration file;

=item *

automatic cleanup of outdated or surplus backup files.

=back

Now you are able to restore configuration file even if you
forgot to create a backup file before editing it!

=head1 CAVEATS

=over 4

=item *

This module is written using `signatures` feature. As for me,
it makes code clearer. However, it requires perl 5.10+. All
more or less modern OSes has much more newer perl included, so
don't think it will be a problem.

=back

=head1 B<SYNOPSIS>

    my $fh = Config::Writer->new('file.conf', {
        'workdir'     => '/usr/local/etc',
        'owner'       => 'nobody',
        'permissions' => 0640,
        'retain'      => 4
    });
    die "can not open file for writing" if $fh->error;
    $fh->sayf('# Configuration file created with %s', $0);
    $fh->close;

=cut #}}}

use v5.16.0;
use strict;
use warnings 'FATAL' => 'all';
no warnings qw(experimental::signatures);
use feature qw(signatures);
use boolean qw(:all);
use version;

use Cwd;
use Data::Dumper;
use Fcntl qw(:DEFAULT);
use File::Basename;
use File::Temp qw(tempfile);
use IO::File;
use POSIX qw(strftime);
use Taint::Util;

BEGIN {
    require Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT = qw();
    our @EXPORT_OK = qw();
    $Data::Dumper::Sortkeys = 1;
}

our $VERSION = version->declare('v0.0.4')->stringify;
our $ERROR = boolean::false;

=pod

=head1 B<METHODS>

=cut

sub new :prototype($$$) ($class, $filename, $options = {}) {
    #{{{

=pod #{{{ new() method description

=over 4

=item B<new(FILENAME, { OPTIONS })>

Create new B<Config::Writer> object as follows:

    my $fh = Config::Writer->new('file.conf', {
        'workdir'       => '/path/to/workdir',
        'retain'        => 3,
        'overwrite'     => 1,
        'extension'     => '-%+4Y-%m-%d',
        'owner'         => 'bird',
        'group'         => 'bird',
        'permissions'   => 0640
    });

Configuration file to be created or replaced name can contain either absolute or
relative path part. Path part handling is described in B<workdir> option description
below.

New temporary file will be created on success and all write operations will be
performed on this temporary file. On `close` method invocation existing configuration
file can be moved to a backup file (see descrition of B<overwrite> option below) and
temporary file is renamed in place of the original configuration file.

=over 4

=item B<FILENAME>

Configuration file to be created or replaced name. Can contain either absolute or
relative path part. Path part handling is described in B<workdir> option description below.

New temporary file will be created on success and all write operations will be performed
on this temporary file. On B<close()> method invocation existing configuration file can
be moved to a backup file (see descrition of B<overwrite> option below) and temporary file
is renamed in place of the original configuration file.

=item B<format> = STRING

Configuration file format. Currently unused.

=item B<workdir> = STRING

If filename contains absolute path, work directory is set to a B<dirname(1)>
implicitly regardless of whether B<workdir> option is set or not.

If B<workdir> is not set, work directory defaults to B<getcwd(3)>.

If filename contains relative path, it is appended to a work directory name,
provided either in B<workdir> option or returned by B<getcwd(3)>.

Work directory existence check is performed. If work directory does not exist, `undef`
is returned and error flag is set!

=item B<retain> = INTEGER

Quantity of configuration file backups to retain. Default is 0 - do not retain any.

=item B<overwrite> = BOOLEAN

Existing backup file will be either overwritten if the flag is set to true
(overwrite = 1) or stayed untouched (overwrite = 0). E. g. if you choose to
store single backup per day, you'll get either the latest configuration version
before it being updated, or the configuration you've got at the beginning of the
day.

Default is 0.

=item B<extension> = STRING

Configuration file backup extension format as described in POSIX strftime function
documentation. The new extension will replace original one, so the backup files
should not be loaded even in case wildcards (e. g. 'B<*.conf>') are used to include
configuration from a several files. Existing backup files will either stay untouched
or overwritten depending on B<overwrite> flag value.

Default is '-%Y-%m-%d'.

=item B<owner> = STRING

Configuration file owner name. If file owner can not be changed, error flag is set.

Defaults to process EUID.

=item B<group> = STRING

Configuration file group name. If not provided, process EGID is used.

=item B<permissions> = OCTAL

Configuration file permissions in numeric format. Read B<chmod(1)> manual for
details.

Default is 0600.

=back

=back

=cut #}}}

    my $self = bless { 'error' => boolean::false }, __PACKAGE__;
    my @filename = File::Basename::fileparse $filename, qw(.cfg .conf .json .yaml), '';
    $self->{'filename'} = $filename[0];
    $self->{'retain'} = (defined $options->{'retain'} and $options->{'retain'} =~ /^\d+$/)
        ? $options->{'retain'} + 0
        : 0;
    $self->{'overwrite'} = (defined $options->{'overwrite'} and $options->{'overwrite'} =~ /^1$/)
        ? boolean::true
        : boolean::false;
    $self->{'extension'} = (defined $options->{'extension'} and $options->{'extension'} !~ m|/|)
        ? $options->{'extension'}
        : '-%Y-%m-%d';
    $self->{'owner'} = defined $options->{'owner'}
        ? (getpwnam $options->{'owner'})[2]
        : $>;
    $self->{'group'} = defined $options->{'group'}
        ? (getpwnam $options->{'group'})[3]
        : (getpwuid $self->{'owner'})[3];
    $self->{'permissions'} = (defined $options->{'permissions'} and $options->{'permissions'} =~ /^\d+$/)
        ? $options->{'permissions'}
        : 0600;
    if ($filename =~ m|^/|) {
        $self->{'workdir'} = Cwd::realpath((File::Basename::fileparse $filename)[1]);
    } else {
        $self->{'workdir'} = (defined $options->{'workdir'} and -d $options->{'workdir'})
            ? $options->{'workdir'}
            : Cwd::getcwd;
        $self->{'workdir'} = Cwd::realpath($self->{'workdir'} . '/' . $filename[1]);
    }
    unless (defined $self->{'workdir'}) {
        $self->{'error'} = boolean::true;
        return $self;
    }
    $self->{'fullname'} = $self->{'workdir'} . '/' . $self->{'filename'} . $filename[2];
    untaint $self->{'filename'} if tainted $self->{'filename'};
    untaint $self->{'fullname'} if tainted $self->{'fullname'};
    untaint $self->{'workdir'} if tainted $self->{'workdir'};
    $self->{'fh'} = File::Temp->new(
        'TEMPLATE' => $self->{'filename'} . '.XXXXXX',
        'DIR'      => $self->{'workdir'},
        'PERMS'    => $self->{'permissions'},
        'UNLINK'   => 0,
        'EXLOCK'   => 1
    );
    unless (defined $self->{'fh'}) {
        $self->{'error'} = boolean::true;
        return $self;
    }
    $self->{'fh'}->autoflush(1);
    $self->{'tmpfile'} = $self->{'fh'}->filename;
    untaint $self->{'tmpfile'} if tainted $self->{'tmpfile'};
    chown($self->{'owner'}, $self->{'group'}, $self->{'tmpfile'}) or $self->{'error'} = boolean::true;
    return $self;

} #}}}

sub error :prototype($) ($self = undef) {
    #{{{

=pod #{{{ error() method description

=over 4

=item B<error()>

Takes no arguments. Returns `false` if B<Config::Writer> object is
defined and `error` flag is not set and `true` otherwise.

=back

=cut #}}}

    return (defined $self and isFalse $self->{'error'})
        ? boolean::false
        : boolean::true;

} #}}}

sub say :prototype($$) ($self, $string) {
    #{{{

=pod #{{{ say() method description

=over 4

=item B<say(STRING)>

Is equivalent to B<print()> method except that $/ is added to the end of the line.

=back

=cut #}}}

    $self->print($string . $/);

} #}}}

sub sayf :prototype($$@) ($self, $format, @list) {
    #{{{

=pod #{{{ sayf() method description

=over 4

=item B<sayf(STRING, ARRAY)>

Is equivalent to B<printf()> method except that $/ is added to the end of the format line.

=back

=cut #}}}

    $self->printf($format . $/, @list);

} #}}}

sub print :prototype($$) ($self, $string) {
    #{{{

=pod #{{{ print() method description

=over 4

=item B<print(STRING)>

Prints STRING to temporary file as is.

=back

=cut #}}}

    print {($self->{'fh'})} $string;

} #}}}

sub printf :prototype($$@) ($self, $format, @list) {
    #{{{

=pod #{{{ printf() method description

=over 4

=item B<printf(STRING, ARRAY)>

Prints formatted string to the temporary file. See B<printf(3)> for
more details.

=back

=cut #}}}

    printf {($self->{'fh'})} $format, @list;

} #}}}

sub close :prototype($) ($self) {
    #{{{

=pod #{{{ close() method description

=over 4

=item B<close()>

When called:

=over 4

=item *

closes temporary configuration file;

=item *

tries to rename target configuration file to a backup file (if `retain`
option is non-zero);

=item *

tries to remove surplus (oldest) backup files (if `retain` option is non-zero); 

=item *

tries to rename temporary configuration file to a target name.

=back

If any errors occurs, `error` flag is set.

=back

=cut #}}}

    if (fileno $self->{'fh'} != -1 and fileno $self->{'fh'} != fileno STDOUT) {
        undef $self->{'fh'};
        unless ($self->{'retain'} == 0) {
            my $backup = $self->{'workdir'} . '/' . $self->{'filename'} . POSIX::strftime($self->{'extension'}, localtime time);
            if (! -f $backup or isTrue $self->{'overwrite'}) {
                rename($self->{'fullname'}, $backup) or $self->{'error'} = boolean::true;
            }
            opendir(DH, $self->{'workdir'}) or $self->{'error'} = boolean::true;
            my $tmpfiles = {};
            foreach my $filename (readdir DH) {
                next if $filename !~ /^$self->{'filename'}(?!$|\.[_\w]{6}$)/;
                $filename = Cwd::realpath($self->{'workdir'} . '/' . $filename);
                $tmpfiles->{$filename} = (stat $filename)[9];
            }
            closedir DH;
            my @tmpfiles = map { $_ } sort { $tmpfiles->{$b} <=> $tmpfiles->{$a} } keys %{$tmpfiles};
            splice @tmpfiles, 0, $self->{'retain'};
            map { unlink($_) or $self->{'error'} = boolean::true } @tmpfiles;
        }
        rename($self->{'tmpfile'}, $self->{'fullname'}) or $self->{'error'} = boolean::true;
    }

} #}}}

=pod

=head1 B<AUTHORS>

=over 4

=item *

Volodymyr Pidgornyi, vpE<lt>atE<gt>dtel-ix.net;

=back

=head1 B<CHANGELOG>

=over 4

=item B<v0.0.4>

- Minor CPAN compatibility fixes;

- README.md is generated from Netbox/Config.pm now.

=item B<v0.0.3>

PAUSE compatibility issues fixed.

=item B<v0.0.2>

B<sayf()> metrod added.

=item B<v0.0.1>

Initial release, since basic features seems to work as intended.

=back

=head1 B<TODO>

=over 4

=item *

Implement helpers for a different configuration files formats.

=back

=cut

1;
