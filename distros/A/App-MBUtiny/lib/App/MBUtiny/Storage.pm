package App::MBUtiny::Storage; # $Id: Storage.pm 121 2019-07-01 19:51:50Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MBUtiny::Storage - App::MBUtiny storage class

=head1 VIRSION

Version 1.00

=head1 SYNOPSIS

    use App::MBUtiny::Storage;

    my $storage = new App::MBUtiny::Storage(
        name => $name, # Backup name
        host => $host, # Host config section
        path => "/tmp/mbutiny/files", # Where is located backup archive
    );

    print $storage->error unless $storage->status;

=head1 DESCRIPTION

App::MBUtiny storage class

Storage - is a directory on disk, a remote FTP/SFTP/ HTTP server
or CLI process that simulates storage functional.

=head2 new

    my $storage = new App::MBUtiny::Storage(
        name => $name, # Backup name
        host => $host, # Host config section
        path => "/tmp/mbutiny/files", # Where is located backup archive
        fixup => sub {
            my $strg = shift; # Storage object
            my $oper = shift // 'noop'; # Operation name
            my @args = @_;

            return 1;
        },
        validate => sub {
            my $strg = shift; # storage object
            my $file = shift; # fetched file name

            return 1;
        },
    );

Returns storage object

=head2 cleanup

    $storage->cleanup();

Flushes errors and the status property to defaults

=head2 del

    my $status = $storage->del("foo-2019-06-25.tar.gz");

Performs the "del" method in all storage subclasses

Returns summary status. See L</summary>

=head2 error

    print $storage->error("Foo"); # Foo
    print $storage->error("Bar"); # Foo\nBar
    print $storage->error; # Foo\nBar
    print $storage->error(""); # <"">

Sets and gets the error pool

=head2 fixup

Callback the "fixup" method. This method called automatically
when the put method performs

=head2 get

    $st = $storage->get(
        name => "foo-2019-06-25.tar.gz",
        file => "/full/path/to/foo-2019-06-25.tar.gz",
    );

Fetching backup file to specified file path from each storage until first successful result

Returns summary status. See L</summary>

=head2 init

Performs the "init" method in all storage subclasses and returns self object instance

For internal use only

=head2 list

    my @filelist = $storage->list;

Returns summary list of backup files from all available storages

=head2 put

    $st = $storage->put(
        name => "foo-2019-06-25.tar.gz",
        file => "/full/path/to/foo-2019-06-25.tar.gz",
        size => 123456,
    );

Sending backup file to each available storage

Returns summary status. See L</summary>

=head2 status

    my $new_status = $storage->status(0);

Sets new status value and returns it

    my $status = $storage->status;

Returns status value. 0 - Error; 1 - Ok

=head2 storage_status

    $storage->storage_status(HTTP => 0);
    my $storage_status = $storage->storage_status("HTTP");

Sets/gets storage status. For internal use only

=head2 summary

    my $status = $storage->summary;

Returns summary status.

=over 4

=item B<1> PASS status. Process successful

=item B<0> FAIL status. Process failed

=item B<-1> SKIP status. Process was skipped

=back

=head2 test

    my $test = $storage->test or die $storage->error;

Performs testing each storage and returns summary status. See L</summary>

=head2 test_report

    foreach my $tr ($storage->test_report) {
        my ($st, $vl, $er) = @$tr;
            print STDOUT $vl, "\n";
            print STDOUT $st ? $st < 0 ? 'SKIP' : 'PASS' : 'FAIL', "\n";
            print STDERR $er, "\n";
        );
    }

Returns list of test result for each storage as:

    [
        [STATUS, NAME, ERROR],
        # ...
    ]

=head2 validate

Callback the "validate" method. This method called automatically
when the get method performs

This method can returns 0 or 1. 0 - validation failed; 1 - validation successful

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MBUtiny>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION /;
$VERSION = '1.00';

use Class::C3::Adopt::NEXT;
use List::Util qw/uniq/;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;

use base qw/
        App::MBUtiny::Storage::Local
        App::MBUtiny::Storage::FTP
        App::MBUtiny::Storage::SFTP
        App::MBUtiny::Storage::HTTP
        App::MBUtiny::Storage::Command
    /;

use constant {
        STORAGE_SIGN=> "core",
        NAME        => "virtual",
        SKIP        => -1,
        FAIL        => 0,
        PASS        => 1,
    };

sub new {
    my $class = shift;
    my %args = @_;
    my $name = $args{name} || NAME;
    my $host = $args{host} || {};
    my $path = $args{path} || '.';

    my $self = bless {
            errors  => [],
            status  => 1, # 1 - Ok; 0 - Error
            name    => $name,
            host    => $host,
            path    => $path,
            fixup   => $args{fixup},
            validate=> $args{validate},
            storages=> {},
            test    => {},
            list    => {},
        }, $class;

    return $self->init();
}
sub error {
    my $cnt = @_;
    my $self = shift;
    my $s = shift;
    my $errors = $self->{errors} || [];
    if ($cnt >= 2) {
        if ($s) {
            push @$errors, $s;
        } else {
            $errors = [];
        }
        $self->{errors} = $errors;
    }
    return join("\n", @$errors);
}
sub status {
    my $self = shift;
    my $s = shift;
    $self->{status} = $s if defined $s;
    return $self->{status};
}
sub storage_status {
    my $self = shift;
    my $sign = shift || STORAGE_SIGN;
    my $v = shift;
    my $h = $self->{storages};
    $h->{"$sign"} = $v if defined $v;
    return $h->{"$sign"};
}
sub summary {
    my $self = shift;
    my $list = $self->{storages};
    my $ret = SKIP;
    foreach my $k (keys %$list) {
        my $v = $list->{$k};
        return $self->status(FAIL) unless $v;
        $ret = PASS if $v > 0;
    }
    return $self->status($ret);
}
sub test_report {
    my $self = shift;
    my $list = $self->{storages};
    my @storages;
    #foreach my $sign (grep { $list->{$_} >=0 } keys %$list) { # Not SKIPped only!
    foreach my $sign (keys %$list) {
        my $test = $self->{test}->{$sign};
        push @storages, @$test if $test;
    }
    return @storages;
}
sub cleanup {
    my $self = shift;
    $self->error("");
    $self->status(1);
}
sub init {
    my $self = shift;
    $self->maybe::next::method();
    return $self;
}
sub test {
    my $self = shift;
    my %params = @_;
    $self->maybe::next::method(%params) unless $params{dummy};
    my $reqired_all = $params{reqired_all} || 0; # Must be passed all tests! Default: any

    # Get storages list
    my $storages = $self->{storages};
    my @ok = grep {$storages->{$_}} keys %$storages;
    unless (@ok) { # If all failed!
        $self->error("All tests failed") if $self->status;
        return $self->status(FAIL);
    }

    # Check each test
    my $ret = SKIP; # Default!
    my @fails = ();
    foreach my $k (keys %$storages) {
        my $v = $storages->{$k};
        push @fails, $k unless $v; # Test failed!
        $ret = PASS if $v > 0; # Any is PASS - change default value to PASS
    }
    unless ($reqired_all) {
        $self->status(PASS);
        return $ret;
    }
    if (@fails == 1) { # One fail catched!
        $self->error(sprintf("Test %s failed", $fails[0])) if $self->status;
        $ret = FAIL;
    } elsif (@fails > 1) { # Fails catched!
        $self->error(sprintf("Tests %s failed", join(", ", @fails))) if $self->status;
        $ret = FAIL;
    }
    $self->status($ret ? PASS : FAIL);
    return $ret;
}
sub put {
    my $self = shift;
    $self->cleanup;
    $self->maybe::next::method(@_);
    return $self->summary;
}
sub get {
    my $self = shift;
    $self->cleanup;
    $self->maybe::next::method(@_);
    return $self->summary;
}
sub del {
    my $self = shift;
    $self->cleanup;
    $self->maybe::next::method(@_);
    return $self->summary;
}
sub list {
    my $self = shift;
    $self->cleanup;
    $self->maybe::next::method(@_);

    my @files = ();
    my $storages = $self->{storages};
    foreach my $sign (grep { $storages->{$_} >=0 } keys %$storages) { # Not SKIPped only!
        my $list = $self->{list}->{$sign};
        push @files, @$list if $list;
    }
    return (sort {$a cmp $b} uniq(@files));
}
sub fixup {
    my $self = shift;
    my @ar = @_;
    my $fixup = $self->{fixup};
    return SKIP unless $fixup && ref($fixup) eq 'CODE';
    return $self->$fixup(@ar);
}
sub validate {
    my $self = shift;
    my @ar = @_;
    my $validate = $self->{validate};
    return SKIP unless $validate && ref($validate) eq 'CODE';
    return $self->$validate(@ar);
}

1;

__END__
