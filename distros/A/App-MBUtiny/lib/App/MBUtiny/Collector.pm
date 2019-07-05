package App::MBUtiny::Collector; # $Id: Collector.pm 121 2019-07-01 19:51:50Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MBUtiny::Collector - Collector class

=head1 VIRSION

Version 1.02

=head1 SYNOPSIS

    use App::MBUtiny::Collector;

    my $collector_config = [
        {
            url => 'https://user:pass@example.com/mbutiny',
            comment => 'Remote collector said blah-blah-blah',
            timeout => 180
        },
        {
            comment => 'Local collector said blah-blah-blah',
        },
        # ...
    ];

    my $collector = new App::MBUtiny::Collector(
            collector_config => $collector_config,
            dbi => $dbi, # App::MBUtiny::Collector::DBI object
        );

    my $colret = $collector->check;

    print STDERR $collector->error if $collector->error;

=head1 DESCRIPTION

Collector class

=head2 new

    my $collector = new App::MBUtiny::Collector(
            collector_config => [{}, {}, ...],
            dbi_config => {...}, # App::MBUtiny::Collector::DBI arguments
            dbi => $dbi, # App::MBUtiny::Collector::DBI object
        );

Creates the collector object with local database supporting

=over 4

=item B<collector_config>

    collector_config => [
        {
            url => 'https://user:pass@example.com/mbutiny',
            comment => 'Remote collector said blah-blah-blah',
            timeout => 180
        },
        {
            comment => 'Local collector said blah-blah-blah',
        },
        # ...
    ],

Array of attributes for initializing specified collectors

=item B<dbi>

    dbi => new App::MBUtiny::Collector::DBI(...),

Sets pre-initialized L<App::MBUtiny::Collector::DBI> object

=item B<dbi_config>

    dbi_config => {...},

Hash of L<App::MBUtiny::Collector::DBI> arguments

=back

=head2 check

    my @collector_ids = $collector->check;
    my $collector_ids = $collector->check; # text notation

Checks clist of available collectors and returns list of
checked collectors as URLs or DSNs

See also L</error> method

=head2 collectors

    my @collector_list = $collector->collectora;

Returns list of initialized collectors

=head2 dbi

    my $dbi = $collector->dbi;

Returns DBI object of local database (local collector)

=head2 error

    print $collector->error("Foo"); # Foo
    print $collector->error("Bar"); # Foo\nBar
    print $collector->error; # Foo\nBar
    print $collector->error(""); # <"">

Sets and gets the error pool

=head2 fixup

    my @collector_ids = $collector->fixup(
        operation => "del",
        name => "foo",
        file => "foo-2019-06-25.tar.gz",
    );

Fixation of the "del" operation on current storage

    my @collector_ids = $collector->fixup(
        operation => "put",
        name => "foo",
        file => "foo-2019-06-25.tar.gz",
        size => 123453,
        md5 => "...",
        sha1 => "...",
        status => 1,
        error => "...",
        comment => "...",
    );

Fixation of the "put" operation on current storage

=over 4

=item B<comment>

Comment of the "put" operation

Scope: put

=item B<error>

Error message of the performed operation

Scope: put

=item B<file>

Name of backup file. Required argument

Scope: put, del

=item B<md5>, B<sha1>

MD5 and SHA1 checksums of backup file

Scope: put

=item B<name>

Name of backup. Required argument

Scope: put, del

=item B<operation>

Name of operation: del/put

Default: put

=item B<size>

Size of backup file

Scope: put

=item B<status>

Status of backup operation: 0 or 1

Default: 0 (operation failed)

Scope: put

=back

=head2 info

    my %info = $collector->info(
        name => "foo",
        file => "foo-2019-06-25.tar.gz",
    );

Gets information about specified file name

Returns hash of values in "AS IN DATABASE DEFINED" format,
see L<App::MBUtiny::Collector::DBI>

=head2 report

    my @last_backup_files = $collector->report( start => 123456789 );

Returns list of last backups from all collectors as array of info-hashes.

See L</info> method

=head1 PUBLIC FUNCTIONS

=head2 int2type

    my $type = int2type(0); # internal

Returns name of specified type

NOTE: This variable NOT imported automatically

=head1 VARIABLES

=head2 COLLECTOR_TYPES

Returns hash-structure ("type_name" => int_value) of available collector types

NOTE: This variable imported automatically

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

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

use vars qw/ $VERSION @EXPORT @EXPORT_OK /;
$VERSION = '1.02';

use Carp;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use App::MBUtiny::Collector::DBI;
use App::MBUtiny::Collector::Client;
use App::MBUtiny::Util qw/hide_password/;

use constant {
        COLLECTOR_TYPES => {
                internal => 0,
                external => 1,
            },
    };

use base qw/Exporter/;
@EXPORT_OK = qw/
        int2type
    /;
@EXPORT = qw/
        COLLECTOR_TYPES
    /;

sub new {
    my $class = shift;
    my %args = @_;
    my $collector_config = $args{collector_config} || [];
    my $dbi_config = $args{dbi_config} || {};
    croak("Incorrect collector config. Array expected!") unless is_array($collector_config);
    my $dbi = $args{dbi} || App::MBUtiny::Collector::DBI->new(%$dbi_config);
    croak("Can't use incorrect dbi object") unless $dbi && ref($dbi) eq 'App::MBUtiny::Collector::DBI';

    # Collectors
    my @collectors = ();
    my $internal = 0;
    foreach my $cltr (@$collector_config) {
        my $url = value($cltr, "url");
        if ($url) {
            push @collectors, {
                type    => "external",
                url     => $url,
                comment => uv2null(value($cltr, "comment")),
                timeout => uv2zero(value($cltr, "timeout")),
            };
        } else {
            push @collectors, {
                type    => "internal",
                comment => uv2null(value($cltr, "comment")),
            } unless $internal;
            $internal++;
        }
    }
    unless (@collectors) {
        push @collectors, {
            type    => "internal",
            comment => "",
        } unless $internal;
    }

    my $self = bless {
            collectors  => [@collectors],
            dbi         => $dbi,
            errors      => [],
        }, $class;

    return $self;
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
sub dbi {
    my $self = shift;
    return $self->{dbi};
}
sub collectors {
    my $self = shift;
    my $collectors = $self->{collectors};
    return scalar(@$collectors) unless wantarray;
    return @$collectors;
}

sub check {
    my $self = shift;
    $self->error("");
    my $dbi = $self->dbi;
    return "" unless $self->collectors;
    my @ret = (); # List of DSN/URL_wo_password
    foreach my $collector ($self->collectors) {
        my $type = $collector->{type};
        if ($type eq 'internal') { # Internal
            if ($dbi->error) {
                $self->error($dbi->error());
                next;
            };
            push @ret, $dbi->dsn;
        } else { # External
            my $url = $collector->{url} || "";
            my $timeout = $collector->{timeout} || 0;
            my $client = new App::MBUtiny::Collector::Client(
                    url     => $url,
                    timeout => $timeout,
                );
            unless ($client->status) {
                $self->error(join("%s\n%s", $client->transaction, $client->error));
                next;
            }
            my $check = $client->check;
            unless ($client->status) {
                $self->error(join("\n", $client->transaction, $client->error));
                next;
            }
            push @ret, hide_password($url);
        }
    }
    return @ret ? join("\n", @ret) : "";
}
sub fixup {
    my $self = shift;
    my %args = @_;
    $self->error("");
    my $dbi = $self->dbi;
    return "" unless $self->collectors;
    my @ret = (); # List of DSN/URL_wo_password

    foreach my $collector ($self->collectors) {
        my $type = $collector->{type};
        my $url = $collector->{url} || "";
        my $timeout = $collector->{timeout} || 0;
        my $comment = join("\n", grep {$_} ($args{comment}, $collector->{comment})) // "";
        my $op = $args{operation} || '';
        if ($op =~ /^(del)|(rem)/) { # Delete (op)
            if ($type eq 'internal') { # Internal
                $dbi->del(
                    type    => _type2int($type),
                    name    => $args{name},
                    file    => $args{file},
                ) or do {
                    $self->error($dbi->error());
                    next;
                };
                push @ret, $dbi->dsn;
            } else { # External
                my $client = new App::MBUtiny::Collector::Client( url => $url, timeout => $timeout );
                unless ($client->status) {
                    $self->error(join("%s\n%s", $client->transaction, $client->error));
                    next;
                }
                $client->del(
                    type    => _type2int($type),
                    name    => $args{name},
                    file    => $args{file},
                ) or do {
                    $self->error(join("\n", $client->transaction, $client->error));
                    next;
                };
                push @ret, hide_password($url);
            }
        } else { # Put (op)
            if ($type eq 'internal') { # Internal
                $dbi->add(
                    type    => _type2int($type),
                    name    => $args{name},
                    file    => $args{file},
                    size    => $args{size},
                    md5     => $args{md5},
                    sha1    => $args{sha1},
                    status  => $args{status},
                    error   => $args{error},
                    comment => $comment,
                ) or do {
                    $self->error($dbi->error());
                    next;
                };
                push @ret, $dbi->dsn;
            } else { # External
                my $client = new App::MBUtiny::Collector::Client( url => $url, timeout => $timeout );
                unless ($client->status) {
                    $self->error(join("%s\n%s", $client->transaction, $client->error));
                    next;
                }
                $client->add(
                    type    => _type2int($type),
                    name    => $args{name},
                    file    => $args{file},
                    size    => $args{size},
                    md5     => $args{md5},
                    sha1    => $args{sha1},
                    status  => $args{status},
                    error   => $args{error},
                    comment => $comment,
                ) or do {
                    $self->error(join("\n", $client->transaction, $client->error));
                    next;
                };
                push @ret, hide_password($url);
            }
        }
    }

    return @ret ? join("\n", @ret) : "";
}
sub info {
    my $self = shift;
    my %args = @_;
    $self->error("");
    my $dbi = $self->dbi;
    return () unless $self->collectors;
    my %info = (); # Information about file
    foreach my $collector ($self->collectors) {
        if ($collector->{type} eq 'internal') { # Internal
            %info = $dbi->get(
                name    => $args{name},
                file    => $args{file},
            ) or do {
                $self->error($dbi->error());
                next;
            };
        } else { # External
            my $client = new App::MBUtiny::Collector::Client(
                    url     => $collector->{url} || "",
                    timeout => $collector->{timeout} || 0,
                );
            unless ($client->status) {
                $self->error(join("%s\n%s", $client->transaction, $client->error));
                next;
            }
            %info = $client->get(
                name    => $args{name},
                file    => $args{file},
            ) or do {
                $self->error(join("\n", $client->transaction, $client->error));
                next;
            };
        }
        last if $info{id} && $info{status};
    }
    return %info;
}
sub report {
    my $self = shift;
    my %args = @_;
    $self->error("");
    my $dbi = $self->dbi;
    return () unless $self->collectors;
    my %mreport = (); # Report
    foreach my $collector ($self->collectors) {
        my @rep = ();
        if ($collector->{type} eq 'internal') { # Internal
            @rep = $dbi->report( start => $args{start});
            if ($dbi->error()) {
                $self->error($dbi->error());
                next;
            };
        } else { # External
            my $client = new App::MBUtiny::Collector::Client(
                    url     => $collector->{url} || "",
                    timeout => $collector->{timeout} || 0,
                );
            if ($client->error) {
                $self->error(join("%s\n%s", $client->transaction, $client->error));
                next;
            }
            @rep = $client->report( start => $args{start});
            if ($client->error) {
                $self->error(join("\n", $client->transaction, $client->error));
                next;
            };
        }

        # Select here!
        foreach my $rec (@rep) {
            my $k = sprintf("%s-t%d-s%d", $rec->{name} || 'noname', $rec->{type} || 0, $rec->{status} || 0);
            my $t = $mreport{$k};
            unless ($t) {
                $mreport{$k} = $rec;
                next;
            }
            $mreport{$k} = $rec if $t->{'time'} < $rec->{'time'};
        }
    }
    return sort {$a->{'time'} <=> $b->{'time'}} values %mreport;
}
sub int2type {
    my $s = shift;
    $s = 0 unless $s;
    my %types = %{(COLLECTOR_TYPES())};
    my %inv = reverse %types;
    $inv{$s} || $inv{0};
}
sub _type2int {
    my $s = shift;
    return 0 unless $s;
    my %types = %{(COLLECTOR_TYPES())};
    $types{$s} || 0;
}

1;

__END__
