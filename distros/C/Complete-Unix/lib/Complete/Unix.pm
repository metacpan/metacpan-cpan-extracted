package Complete::Unix;

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

use Complete::Common qw(:all);
use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-02'; # DATE
our $DIST = 'Complete-Unix'; # DIST
our $VERSION = '0.080'; # VERSION

our @EXPORT_OK = qw(
                       complete_uid
                       complete_user
                       complete_gid
                       complete_group

                       complete_pid
                       complete_proc_name

                       complete_service_name
                       complete_service_port
                );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Unix-related completion routines',
};

$SPEC{complete_uid} = {
    v => 1.1,
    summary => 'Complete from list of Unix UID\'s',
    args => {
        %arg_word,
        etc_dir => { schema=>['str*'] },
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_uid {
    require Complete::Util;
    require Unix::Passwd::File;

    my %args  = @_;
    my $word  = $args{word} // "";

    my $res = Unix::Passwd::File::list_users(
        etc_dir=>$args{etc_dir}, detail=>1);
    return unless $res->[0] == 200;
    Complete::Util::complete_array_elem(
        array     => [map {$_->{uid}} @{ $res->[2] }],
        summaries => [map {$_->{user}} @{ $res->[2] }],
        word      => $word,
    );
}

$SPEC{complete_user} = {
    v => 1.1,
    summary => 'Complete from list of Unix users',
    args => {
        %arg_word,
        etc_dir => { schema=>['str*'] },
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_user {
    require Complete::Util;
    require Unix::Passwd::File;

    my %args  = @_;
    my $word  = $args{word} // "";

    my $res = Unix::Passwd::File::list_users(
        etc_dir=>$args{etc_dir}, detail=>1);
    return unless $res->[0] == 200;
    Complete::Util::complete_array_elem(
        array     => [map {$_->{user}} @{ $res->[2] }],
        summaries => [map {$_->{gecko}} @{ $res->[2] }],
        word      => $word);
}

$SPEC{complete_gid} = {
    v => 1.1,
    summary => 'Complete from list of Unix GID\'s',
    args => {
        %arg_word,
        etc_dir => { schema=>['str*'] },
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_gid {
    require Complete::Util;
    require Unix::Passwd::File;

    my %args  = @_;
    my $word  = $args{word} // "";

    my $res = Unix::Passwd::File::list_groups(
        etc_dir=>$args{etc_dir}, detail=>1);
    return unless $res->[0] == 200;
    Complete::Util::complete_array_elem(
        array     => [map {$_->{gid}} @{ $res->[2] }],
        summaries => [map {$_->{group}} @{ $res->[2] }],
        word      => $word);
}

$SPEC{complete_group} = {
    v => 1.1,
    summary => 'Complete from list of Unix groups',
    args => {
        %arg_word,
        etc_dir => { schema=>['str*'] },
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_group {
    require Complete::Util;
    require Unix::Passwd::File;

    my %args  = @_;
    my $word  = $args{word} // "";

    my $res = Unix::Passwd::File::list_groups(
        etc_dir=>$args{etc_dir}, detail=>1);
    return unless $res->[0] == 200;
    Complete::Util::complete_array_elem(
        array     => [map {$_->{group}} @{ $res->[2] }],
        word      => $word);
}

$SPEC{complete_pid} = {
    v => 1.1,
    summary => 'Complete from list of running PIDs',
    args => {
        %arg_word,
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_pid {
    require Complete::Util;
    require Proc::Find;

    my %args  = @_;
    my $word  = $args{word} // "";

    my $procs = Proc::Find::find_proc(detail=>1);
    Complete::Util::complete_array_elem(
        array     => [map {$_->{pid}} @$procs],
        summaries => [map {$_->{cmndline}} @$procs],
        word      => $word);
}

$SPEC{complete_proc_name} = {
    v => 1.1,
    summary => 'Complete from list of process names',
    args => {
        %arg_word,
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_proc_name {
    require Complete::Util;
    require List::MoreUtils;
    require Proc::Find;

    my %args  = @_;
    my $word  = $args{word} // "";

    Complete::Util::complete_array_elem(
        array=>[List::MoreUtils::uniq(
            grep {length}
                map { $_->{name} }
                    @{ Proc::Find::find_proc(detail=>1) })],
        word=>$word);
}

$SPEC{complete_service_name} = {
    v => 1.1,
    summary => 'Complete from list of service names from /etc/services',
    args => {
        %arg_word,
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_service_name {
    require Parse::Services;

    my %args  = @_;
    my $word  = $args{word} // "";

    my %services;

    # from /etc/services
    {
        my $res = Parse::Services::parse_services();
        last if $res->[0] != 200;
        for my $row (@{ $res->[2] }) {
            $services{$row->{name}}++;
            $services{$_}++ for @{$row->{aliases}};
        }
    }

    require Complete::Util;
    Complete::Util::complete_hash_key(
        word => $word,
        hash => \%services,
    );
}

$SPEC{complete_service_port} = {
    v => 1.1,
    summary => 'Complete from list of service ports from /etc/services',
    args => {
        %arg_word,
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_service_port {
    require Parse::Services;

    my %args  = @_;
    my $word  = $args{word} // "";

    my %services;

    # from /etc/services
    {
        my $res = Parse::Services::parse_services();
        last if $res->[0] != 200;
        for my $row (@{ $res->[2] }) {
            $services{$row->{port}} = $row->{name};
        }
    }

    require Complete::Util;
    Complete::Util::complete_hash_key(
        word => $word,
        hash => \%services,
        summaries_from_hash_values => 1,
    );
}

1;
# ABSTRACT: Unix-related completion routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Unix - Unix-related completion routines

=head1 VERSION

This document describes version 0.080 of Complete::Unix (from Perl distribution Complete-Unix), released on 2022-09-02.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 complete_gid

Usage:

 complete_gid(%args) -> array

Complete from list of Unix GID's.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<etc_dir> => I<str>

=item * B<word>* => I<str> (default: "")

Word to complete.


=back

Return value:  (array)



=head2 complete_group

Usage:

 complete_group(%args) -> array

Complete from list of Unix groups.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<etc_dir> => I<str>

=item * B<word>* => I<str> (default: "")

Word to complete.


=back

Return value:  (array)



=head2 complete_pid

Usage:

 complete_pid(%args) -> array

Complete from list of running PIDs.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str> (default: "")

Word to complete.


=back

Return value:  (array)



=head2 complete_proc_name

Usage:

 complete_proc_name(%args) -> array

Complete from list of process names.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str> (default: "")

Word to complete.


=back

Return value:  (array)



=head2 complete_service_name

Usage:

 complete_service_name(%args) -> array

Complete from list of service names from E<sol>etcE<sol>services.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str> (default: "")

Word to complete.


=back

Return value:  (array)



=head2 complete_service_port

Usage:

 complete_service_port(%args) -> array

Complete from list of service ports from E<sol>etcE<sol>services.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str> (default: "")

Word to complete.


=back

Return value:  (array)



=head2 complete_uid

Usage:

 complete_uid(%args) -> array

Complete from list of Unix UID's.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<etc_dir> => I<str>

=item * B<word>* => I<str> (default: "")

Word to complete.


=back

Return value:  (array)



=head2 complete_user

Usage:

 complete_user(%args) -> array

Complete from list of Unix users.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<etc_dir> => I<str>

=item * B<word>* => I<str> (default: "")

Word to complete.


=back

Return value:  (array)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Unix>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Unix>.

=head1 SEE ALSO

L<Complete::Util>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2016, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Unix>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
