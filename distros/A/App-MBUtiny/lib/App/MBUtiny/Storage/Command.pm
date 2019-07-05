package App::MBUtiny::Storage::Command; # $Id: Command.pm 121 2019-07-01 19:51:50Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MBUtiny::Storage::Command - App::MBUtiny::Storage subclass for Command storage support

=head1 VIRSION

Version 1.00

=head1 SYNOPSIS

  <Host "foo">
    <Command>
        #FixUP   on
        test    "test -d ./foo  && ls -1 ./foo || mkdir ./foo"
        put     "cp [FILE] ./foo/[NAME]"
        get     "cp ./foo/[NAME] [FILE]"
        del     "test -e ./foo/[NAME] && unlink ./foo/[NAME] || true"
        list    "ls -1 ./foo"
        comment Command storage said blah-blah-blah # Optional for collector
    </Command>

    # . . .

  </Host>

=head1 DESCRIPTION

App::MBUtiny::Storage subclass for Command storage support

=head2 del

Removes the specified file.
This is backend method of L<App::MBUtiny::Storage/del>

Variables: B<PATH>, B<HOST>, B<NAME>

=head2 get

Gets the backup file from storage and saves it to specified path.
This is backend method of L<App::MBUtiny::Storage/get>

Variables: B<PATH>, B<HOST>, B<NAME>, B<FILE>

=head2 init

The method performs initialization of storage.
This is backend method of L<App::MBUtiny::Storage/init>

=head2 list

Gets backup file list on storage.
This is backend method of L<App::MBUtiny::Storage/list>

Variables: B<PATH>, B<HOST>

=head2 cmd_storages

    my @list = $storage->cmd_storages;

Returns list of command storage nodes

=head2 put

Sends backup file to storage.
This is backend method of L<App::MBUtiny::Storage/put>

Variables: B<PATH>, B<HOST>, B<SIZE>, B<NAME>, B<FILE>

=head2 test

Storage testing.
This is backend method of L<App::MBUtiny::Storage/test>

Variables: B<PATH>, B<HOST>

=head1 VARIABLES

=over 4

=item B<FILE>

Full file path of backup file

For example:

    /tmp/mbutiny/files/foo-2019-06-20.tar.gz

=item B<HOST>

MBUtiny host name

For example:

    foo

=item B<NAME>

File name of backup file

For example:

    foo-2019-06-20.tar.gz

=item B<PATH>

Path to backup files

For example:

    /tmp/mbutiny/files

=item B<SIZE>

Size of backup file (bytes)

For example:

    32423

=back

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MBUtiny::Storage>

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

use Storable qw/dclone/;
use List::Util qw/uniq/;
use CTK::Util qw/dformat trim execute/;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use App::MBUtiny::Util qw/ node2anode /;

use constant {
        STORAGE_SIGN => 'Command',
    };

sub init {
    my $self = shift;
    $self->maybe::next::method();
    $self->storage_status(STORAGE_SIGN, -1);
    my $usecmd = 0;

    my $cmd_nodes = dclone(node2anode(node($self->{host}, 'command')));
    #print explain($ftp_nodes), "\n";

    my %cmd_storages;
    my $i = 0;
    foreach my $cmd_node (@$cmd_nodes) {
        my $id = sprintf("%s-%s-%d", STORAGE_SIGN, $self->{name}, ++$i);
        my %attr = (
                HOST => $self->{name},
                PATH => $self->{path},
            );
        my $cmd_test = value($cmd_node, 'test') || "";
        my $cmd_put  = value($cmd_node, 'put') || "";
        my $cmd_get  = value($cmd_node, 'get') || "";
        my $cmd_list = value($cmd_node, 'list') || "";
        my $cmd_del  = value($cmd_node, 'del') || "";
        my $comment  = value($cmd_node, 'comment') || "";
        $cmd_storages{$id} = {
                id       => $id,
                cmd_test => $cmd_test,
                cmd_put  => $cmd_put,
                cmd_get  => $cmd_get,
                cmd_list => $cmd_list,
                cmd_del  => $cmd_del,
                attr     => {%attr},
                comment  => join("\n", grep {$_} ($cmd_put || sprintf("Command storage: %s", $id), $comment)),
                fixup    => value($cmd_node, 'fixup') ? 1 : 0,
            };
        $usecmd++;

    }
    $self->{cmd_storages} = [(values(%cmd_storages))];

    $self->storage_status(STORAGE_SIGN, $usecmd) if $usecmd;
    #print explain($self->{cmd_storages}), "\n";
    return $self;
}
sub cmd_storages {
    my $self = shift;
    my $storages = $self->{cmd_storages} || [];
    return @$storages;
}
sub test {
    my $self = shift;
    my %params = @_; $self->maybe::next::method(%params);
    my $sign = STORAGE_SIGN;
    return -1 if $self->storage_status($sign) <= 0; # SKIP

    my @test = ();
    foreach my $storage ($self->cmd_storages) {
        my $id = $storage->{id};
        my $attr = $storage->{attr};
        my $cmd_test = dformat($storage->{cmd_test}, $attr);

        # Execute
        my $exe_err = '';
        my $exe_out = execute($cmd_test, undef, \$exe_err);
        my $exe_stt = $? >> 8;
        if ($exe_stt) {
            $self->storage_status($sign, 0);
            push @test, [0, $id, sprintf("Can't execute %s: %s", $cmd_test, $exe_err)];
            next;
        }
        #print explain($exe_out), "\n";

        # Result
        push @test, [1, $id];
    }

    $self->{test}->{$sign} = [@test];
    return 1;
}
sub put {
    my $self = shift;
    my %params = @_; $self->maybe::next::method(%params);
    return $self->storage_status(STORAGE_SIGN, -1) if $self->storage_status(STORAGE_SIGN) <= 0; # SKIP and set SKIP
    my $status = 1;
    my $name = $params{name}; # File name only
    my $file = $params{file}; # Path to local file
    my $src_size = $params{size} || 0;

    foreach my $storage ($self->cmd_storages) {
        my $attr = $storage->{attr};
           $attr->{SIZE} = $src_size;
           $attr->{NAME} = $name;
           $attr->{FILE} = $file;
        my $cmd_put = dformat($storage->{cmd_put}, $attr);
        my $comment = $storage->{comment} || "";
        my $ostat = 1;

        # Execute
        my $exe_err = '';
        my $exe_out = execute($cmd_put, undef, \$exe_err);
        my $exe_stt = $? >> 8;
        if ($exe_stt) {
            $self->error(sprintf("Can't execute %s", $cmd_put));
            $self->error($exe_out) if $exe_out;
            $self->error($exe_err) if $exe_err;
            $ostat = 0;
        }
        #print explain($exe_out), "\n";

        # Fixup!
        $self->fixup("put", $ostat, $comment) if $storage->{fixup};
        $status = 0 unless $ostat;
    }

    $self->storage_status(STORAGE_SIGN, 0) unless $status;
}
sub get {
    my $self = shift;
    my %params = @_;
    if ($self->storage_status(STORAGE_SIGN) <= 0) { # SKIP and set SKIP
        $self->maybe::next::method(%params);
        return $self->storage_status(STORAGE_SIGN, -1);
    }
    my $name = $params{name}; # archive name
    my $file = $params{file}; # destination archive file path

    foreach my $storage ($self->cmd_storages) {
        my $attr = $storage->{attr};
           $attr->{NAME} = $name;
           $attr->{FILE} = $file;
        my $cmd_get = dformat($storage->{cmd_get}, $attr);

        # Execute
        my $exe_err = '';
        my $exe_out = execute($cmd_get, undef, \$exe_err);
        my $exe_stt = $? >> 8;
        if ($exe_stt) {
            $self->error(sprintf("Can't execute %s", $cmd_get));
            $self->error($exe_out) if $exe_out;
            $self->error($exe_err) if $exe_err;
            next;
        }

        # Validate
        unless ($self->validate($file)) { # FAIL validation!
            $self->error(sprintf("Command storage %s failed: file %s is not valid!", $cmd_get, $file));
            next
        }

        # Done!
        return $self->storage_status(STORAGE_SIGN, 1);
    }

    $self->storage_status(STORAGE_SIGN, 0);
    $self->maybe::next::method(%params);
}
sub del {
    my $self = shift;
    my $name = shift;
    $self->maybe::next::method($name);
    return $self->storage_status(STORAGE_SIGN, -1) if $self->storage_status(STORAGE_SIGN) <= 0; # SKIP and set SKIP
    my $status = 1;

    foreach my $storage ($self->cmd_storages) {
        my $attr = $storage->{attr};
           $attr->{NAME} = $name;
        my $cmd_del = dformat($storage->{cmd_del}, $attr);
        my $comment = $storage->{comment} || "";
        my $ostat = 1;

        # Execute
        my $exe_err = '';
        my $exe_out = execute($cmd_del, undef, \$exe_err);
        my $exe_stt = $? >> 8;
        if ($exe_stt) {
            $self->error(sprintf("Can't execute %s", $cmd_del));
            $self->error($exe_out) if $exe_out;
            $self->error($exe_err) if $exe_err;
            $ostat = 0;
        }

        # Fixup!
        $self->fixup("del", $name) if $storage->{fixup};
        $status = 0 unless $ostat;
    }
    $self->storage_status(STORAGE_SIGN, 0) unless $status;
}
sub list {
    my $self = shift;
    my %params = @_; $self->maybe::next::method(%params);
    return $self->storage_status(STORAGE_SIGN, -1) if $self->storage_status(STORAGE_SIGN) <= 0; # SKIP and set SKIP
    my $sign = STORAGE_SIGN;

    my @list = ();
    foreach my $storage ($self->cmd_storages) {
        my $attr = $storage->{attr};
        my $cmd_list = dformat($storage->{cmd_list}, $attr);
        my $ostat = 1;

        # Execute
        my $exe_err = '';
        my $exe_out = execute($cmd_list, undef, \$exe_err);
        my $exe_stt = $? >> 8;
        if ($exe_stt) {
            $self->error(sprintf("Can't execute %s", $cmd_list));
            $self->error($exe_out) if $exe_out;
            $self->error($exe_err) if $exe_err;
            $ostat = 0;
        }

        # Get list
        if ($ostat) {
            my @ls = map {$_ = trim($_)} (split /\s*\n+\s*/, $exe_out);
            push @list, grep { defined($_) && length($_) } @ls;
        }
    }
    $self->{list}->{$sign} = [uniq(@list)];
    return 1;
}

1;

__END__
