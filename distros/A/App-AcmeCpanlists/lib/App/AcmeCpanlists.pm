package App::AcmeCpanlists;

our $DATE = '2016-11-19'; # DATE
our $VERSION = '0.09'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'The Acme::CPANLists CLI',
};

sub _complete_module {
    require Complete::Module;
    my %args = @_;

    Complete::Module::complete_module(
        %args,
        ns_prefix => 'Acme::CPANLists',
    );
}

sub _complete_summary_or_id {
    require Complete::Util;
    my %args = @_;

    my $res = list_lists(detail=>1);
    my $array;
    if ($res->[0] == 200) {
        for (@{ $res->[2] }) {
            push @$array, $_->{id} if $_->{id};
            push @$array, $_->{summary};
        }
    } else {
        $array = [];
    }

    Complete::Util::complete_array_elem(
        %args,
        array => $array,
    );
}

my %rels_filtering = (
    choose_one => [qw/mentions_author mentions_module/],
);

my %args_filtering = (
    module => {
        schema => 'str*',
        cmdline_aliases => {m=>{}},
        completion => \&_complete_module,
        tags => ['category:filtering'],
    },
    type => {
        schema => ['str*', in=>[qw/author a module m/]],
        cmdline_aliases => {t=>{}},
        tags => ['category:filtering'],
    },
    mentions_module => {
        schema => ['str*'],
        tags => ['category:filtering'],
    },
    mentions_author => {
        schema => ['str*'],
        tags => ['category:filtering'],
    },
);

my %args_related_and_alternate = (
    related => {
        summary => 'Filter based on whether entry is in related',
        'summary.alt.bool.yes' => 'Only list related entries',
        'summary.alt.bool.not' => 'Do not list related entries',
        schema => 'bool',
    },
    alternate => {
        summary => 'Filter based on whether entry is in alternate',
        'summary.alt.bool.yes' => 'Only list alternate entries',
        'summary.alt.bool.not' => 'Do not list alternate entries',
        schema => 'bool',
    },
);

my %arg_detail = (
    detail => {
        name => 'Return detailed records instead of just name/ID',
        schema => 'bool',
        cmdline_aliases => {l=>{}},
    },
);

my %arg_query = (
    query => {
        schema => 'str*',
        req => 1,
        pos => 0,
        completion => \&_complete_summary_or_id,
    },
);

my %arg_query_opt = (
    query => {
        schema => 'str*',
        pos => 0,
        completion => \&_complete_summary_or_id,
    },
);

$SPEC{list_mods} = {
    v => 1.1,
    summary => 'List all installed Acme::CPANLists modules',
    args => {
        # XXX detail
    },
};
sub list_mods {
    require PERLANCAR::Module::List;

    my $res = PERLANCAR::Module::List::list_modules(
        'Acme::CPANLists::', {list_modules=>1, recurse=>1});

    my @res;
    for (sort keys %$res) {
        s/^Acme::CPANLists:://;
        push @res, $_;
    }

    [200, "OK", \@res];
}

$SPEC{list_lists} = {
    v => 1.1,
    summary => 'List CPAN lists',
    args_rels => {
        %rels_filtering,
    },
    args => {
        %args_filtering,
        %arg_query_opt,
        %arg_detail,
    },
};
sub list_lists {
    no strict 'refs';

    my %args = @_;

    my $detail = $args{detail};
    my $type = $args{type};

    $type = 'a' if $args{mentions_author};
    $type = 'm' if $args{mentions_module};

    $detail = 1 if defined $args{query};

    my @mods;
    if ($args{module}) {
        @mods = ($args{module});
    } else {
        my $res = list_mods();
        @mods = @{$res->[2]};
    }

    for my $mod (@mods) {
        my $mod_pm = $mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm";
        require "Acme/CPANLists/$mod_pm";
    }

    my @cols;
    if ($detail) {
        @cols = (qw/id type summary num_entries mentioned_authors_or_modules/);
    } else {
        @cols = (qw/summary/);
    }

    my @rows;
    if (!$type || $type eq 'author' || $type eq 'a') {
        for my $mod (@mods) {
            for my $l (@{ "Acme::CPANLists::$mod\::Author_Lists" }) {
                my $entries = $l->{entries} // [];
                my $rec = {
                    type => 'author',
                    id => $l->{id},
                    module => $mod,
                    summary => $l->{summary},
                    num_entries => ~~@$entries,
                };

                my %mentioned;
                for my $ent (@$entries) {
                    $mentioned{$ent->{author}}++;
                    $mentioned{$_}++ for @{ $ent->{related_authors} // [] };
                    $mentioned{$_}++ for @{ $ent->{alternate_authors} // [] };
                }
                $rec->{mentioned_authors_or_modules} = join(", ", sort keys %mentioned);

                $rec->{_ref} = $l if $args{_with_ref};
                if ($args{mentions_author}) {
                    next unless grep {
                        $_->{author} eq $args{mentions_author}
                    } @$entries;
                }
                push @rows, $detail ? $rec : $rec->{summary};
            }
        }
    }
    if (!$type || $type eq 'module' || $type eq 'm') {
        for my $mod (@mods) {
            for my $l (@{ "Acme::CPANLists::$mod\::Module_Lists" }) {
                my $entries = $l->{entries} // [];
                my $rec = {
                    type => 'module',
                    id => $l->{id},
                    module => $mod,
                    summary => $l->{summary},
                    num_entries => ~~@$entries,
                };

                my %mentioned;
                for my $ent (@$entries) {
                    $mentioned{$ent->{module}}++;
                    $mentioned{$_}++ for @{ $ent->{related_modules} // [] };
                    $mentioned{$_}++ for @{ $ent->{alternate_modules} // [] };
                }
                $rec->{mentioned_authors_or_modules} = join(", ", sort keys %mentioned);

                $rec->{_ref} = $l if $args{_with_ref};
                if ($args{mentions_module}) {
                    next unless grep {
                        $_->{module} eq $args{mentions_module} ||
                            (defined($_->{alternate_module}) &&
                             $_->{alternate_module} eq $args{mentions_module})
                    } @$entries;
                }
                push @rows, $detail ? $rec : $rec->{summary};
            }
        }
    }

    my $resmeta = {
        'table.fields' => \@cols,
    };

    # filter by query
    if (defined(my $q = $args{query})) {
        $q = lc($q);

        my @match_rows;
        my @exact_match_rows;
        my $type;
        for my $row (@rows) {
            my $summary = lc($row->{summary} // '');
            if (index($summary, $q) >= 0 ||
                (defined($row->{id}) && index(lc($row->{id}), $q) >= 0)) {
                my $rec = $row->{_ref};
                push @match_rows, $row;
                push @exact_match_rows, $row
                    if $summary eq $q ||
                        defined($row->{id}) && lc($row->{id}) eq $q;
            }
        }
        @rows = @match_rows;
        $resmeta->{'func.num_exact_matches'} = @exact_match_rows;
    }

    # remove detail if we forced detail earlier for matching against query
    if (!$args{detail} && $detail) {
        @rows = map { $_->{summary} } @rows;
    }

    [200, "OK", \@rows, $resmeta];
}

$SPEC{get_list} = {
    v => 1.1,
    summary => 'Get a CPAN list as raw data',
    args_rels => {
        %rels_filtering,
    },
    args => {
        %args_filtering,
        %arg_query,
    },
};
sub get_list {
    no strict 'refs';

    my %args = @_;

    my $res = list_lists(
        (map {(module=>$args{$_}) x !!defined($args{$_})}
             keys %args_filtering),
        query => $args{query},
        detail => 1,
        _with_ref => 1,
    );

    return $res unless $res->[0] == 200;

    my $rows = $res->[2];
    if (!@$rows) {
        return [404, "No such list"];
    } elsif ($res->[3]{'func.num_exact_matches'} == 1) {
        return [200, "OK", $rows->[0]{_ref}, {'func.type'=>$rows->[0]{type}}];
    } elsif (@$rows > 1) {
        return [300, "Multiple lists found (".~~@{$rows}."), please specify"];
    } else {
        return [200, "OK", $rows->[0]{_ref}, {'func.type'=>$rows->[0]{type}}];
    }
}

$SPEC{view_list} = {
    v => 1.1,
    summary => 'View a CPAN list as rendered POD',
    args_rels => {
        %rels_filtering,
    },
    args => {
        %args_filtering,
        %arg_query,
    },
};
sub view_list {
    require Pod::From::Acme::CPANLists;
    no strict 'refs';

    my %args = @_;

    my $res = get_list(%args);
    return $res unless $res->[0] == 200;

    my %podargs;
    if ($res->[3]{'func.type'} eq 'author') {
        $podargs{author_lists} = [$res->[2]];
        $podargs{module_lists} = [];
    } else {
        $podargs{author_lists} = [];
        $podargs{module_lists} = [$res->[2]];
    }
    my $podres = Pod::From::Acme::CPANLists::gen_pod_from_acme_cpanlists(
        %podargs);

    [200, "OK", $podres, {
        "cmdline.page_result"=>1,
        "cmdline.pager"=>"pod2man | man -l -"}];
}

sub _is_false { defined($_[0]) && !$_[0] }

$SPEC{list_entries_all} = {
    v => 1.1,
    summary => 'List entries from all installed CPAN lists',
    args_rels => {
        %rels_filtering,
    },
    args => {
        %args_filtering,
        %arg_query_opt,
        %arg_detail,
        %args_related_and_alternate,
    },
};
sub list_entries_all {
    no strict 'refs';

    my %args = @_;

    my $mode = $args{_mode} // '';
    my $is_single_list_mode = $mode eq 'single_list';

    my $res;
    my $lists;
    my $entity_field = $args{type};

    if ($is_single_list_mode) {
        $res = get_list(%args);
        return $res unless $res->[0] == 200;
        $lists = [{_ref=>$res->[2], type=>$res->[3]{'func.type'}}];
        $entity_field //= $res->[3]{'func.type'};
    } else {
        # we use query to filter against entity name, not list name
        delete local $args{query};

        $res = list_lists(%args, detail=>1, _with_ref=>1);
        return $res unless $res->[0] == 200;
        $lists = $res->[2];
    }
    $entity_field //= 'module_or_author';

    my @cols;
    if ($mode eq 'entry_lists') {
        @cols = ('type', 'summary');
    } elsif ($args{detail}) {
        push @cols, $entity_field;
        if ($is_single_list_mode) {
            push @cols, qw/summary rating/;
        } else {
            push @cols, qw/num_occurrences avg_rating/;
        }
    } else {
        @cols = ($entity_field);
    }

    my %seen;
    my @rows;
    for my $list (@$lists) {
        my $type = $list->{type};
        for my $e (@{ $list->{_ref}{entries} }) {
            my $n = $e->{$type};
            unless ($args{related} || $args{alternate}) {
                unless ($seen{$n}++ && $is_single_list_mode) {
                    push @rows, {
                        $entity_field => $n,
                        summary=>$e->{summary},
                        rating=>$e->{rating},
                        (_list_ref => $list) x !!($mode eq 'entry_lists'),
                    };
                }
            }
            for my $n (@{ $e->{"related_${type}s"} // [] }) {
                if ($args{related}) {
                    unless ($seen{$n}++ && $is_single_list_mode) {
                        push @rows, {
                            $entity_field => $n,
                            summary=>$e->{summary},
                            related=>1,
                            (_list_ref => $list) x !!($mode eq 'entry_lists'),
                        };
                    }
                }
            }
            for my $n (@{ $e->{"alternate_${type}s"} // [] }) {
                if ($args{alternate} && $is_single_list_mode) {
                    unless ($seen{$n}++ && $is_single_list_mode) {
                        push @rows, {
                            $entity_field => $n,
                            summary=>$e->{summary},
                            alternate=>1,
                            (_list_ref => $list) x !!($mode eq 'entry_lists'),
                        };
                    }
                }
            }
        } # for each entry

    } # for each list

    # filter by query
    {
        last if $is_single_list_mode;
        last unless defined(my $q = $args{query});
        $q = lc($q);

        my @filtered_rows;
        for my $row (@rows) {
            if ($args{query_type} && $args{query_type} eq 'exact-name') {
                next unless lc($row->{$entity_field}) eq $q;
            } else {
                next unless index(lc($row->{$entity_field}), $q) >= 0;
            }
            push @filtered_rows, $row;
        }

        @rows = @filtered_rows;
    }

    # return entry lists
    if ($mode eq 'entry_lists') {
        no warnings 'uninitialized';
        my @new_rows;
        my %seen;
        for my $row (@rows) {
            my $list = $row->{_list_ref};
            next if $seen{"$list->{type}|$list->{summary}"}++;
            push @new_rows, {
                type => $list->{type},
                summary => $list->{summary},
            };
        }
        @rows = @new_rows;
        $args{detail} = 1; # TMP
    }

    # group by entity
    if ($mode eq '') {
        my %occurrences; # key: entity name, value: n
        my %ratings;    # key: entity name, value = [rating, ...]
        for my $row (@rows) {
            my $name = $row->{$entity_field};
            $occurrences{$name}++;
            push @{ $ratings{$name} }, $row->{rating} if defined $row->{rating};
        }

        my @new_rows;
        for my $name (sort keys %occurrences) {
            my $row = {
                $entity_field => $name,
                num_occurrences => $occurrences{$name},
                avg_rating => undef,
            };
            if ($ratings{$name}) {
                my $sum = 0;
                for (@{ $ratings{$name} }) { $sum += $_ }
                $row->{avg_rating} = $sum/@{ $ratings{$name} };
            }
            push @new_rows, $row;
        }
        @rows = @new_rows;
    }

    unless ($args{detail}) {
        @rows = map {$_->{$entity_field}} @rows;
    }

    [200, "OK", \@rows, {'table.fields' => \@cols}];
}

$SPEC{list_entries} = {
    v => 1.1,
    summary => 'List entries of a CPAN list',
    args_rels => {
        %rels_filtering,
    },
    args => {
        %args_filtering,
        %arg_query,
        %arg_detail,
        %args_related_and_alternate,
    },
};
sub list_entries {
    list_entries_all(@_, _mode=>'single_list');
}

$SPEC{list_entry_lists} = {
    v => 1.1,
    summary => 'Find out in which lists a module or author is mentioned',
    args_rels => {
        %rels_filtering,
    },
    args => {
        %args_filtering,
        %arg_query,
        %args_related_and_alternate,
    },
};
sub list_entry_lists {
    list_entries_all(
        @_,
        query_type => 'exact-name',
        _mode => 'entry_lists',
    );
}

1;
# ABSTRACT: The Acme::CPANLists CLI

__END__

=pod

=encoding UTF-8

=head1 NAME

App::AcmeCpanlists - The Acme::CPANLists CLI

=head1 VERSION

This document describes version 0.09 of App::AcmeCpanlists (from Perl distribution App-AcmeCpanlists), released on 2016-11-19.

=head1 SYNOPSIS

Use the included script L<acme-cpanlists>.

=head1 FUNCTIONS


=head2 get_list(%args) -> [status, msg, result, meta]

Get a CPAN list as raw data.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<mentions_author> => I<str>

=item * B<mentions_module> => I<str>

=item * B<module> => I<str>

=item * B<query>* => I<str>

=item * B<type> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_entries(%args) -> [status, msg, result, meta]

List entries of a CPAN list.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<alternate> => I<bool>

Filter based on whether entry is in alternate.

=item * B<detail> => I<bool>

=item * B<mentions_author> => I<str>

=item * B<mentions_module> => I<str>

=item * B<module> => I<str>

=item * B<query>* => I<str>

=item * B<related> => I<bool>

Filter based on whether entry is in related.

=item * B<type> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_entries_all(%args) -> [status, msg, result, meta]

List entries from all installed CPAN lists.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<alternate> => I<bool>

Filter based on whether entry is in alternate.

=item * B<detail> => I<bool>

=item * B<mentions_author> => I<str>

=item * B<mentions_module> => I<str>

=item * B<module> => I<str>

=item * B<query> => I<str>

=item * B<related> => I<bool>

Filter based on whether entry is in related.

=item * B<type> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_entry_lists(%args) -> [status, msg, result, meta]

Find out in which lists a module or author is mentioned.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<alternate> => I<bool>

Filter based on whether entry is in alternate.

=item * B<mentions_author> => I<str>

=item * B<mentions_module> => I<str>

=item * B<module> => I<str>

=item * B<query>* => I<str>

=item * B<related> => I<bool>

Filter based on whether entry is in related.

=item * B<type> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_lists(%args) -> [status, msg, result, meta]

List CPAN lists.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<mentions_author> => I<str>

=item * B<mentions_module> => I<str>

=item * B<module> => I<str>

=item * B<query> => I<str>

=item * B<type> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_mods() -> [status, msg, result, meta]

List all installed Acme::CPANLists modules.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 view_list(%args) -> [status, msg, result, meta]

View a CPAN list as rendered POD.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<mentions_author> => I<str>

=item * B<mentions_module> => I<str>

=item * B<module> => I<str>

=item * B<query>* => I<str>

=item * B<type> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-AcmeCpanlists>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-AcmeCpanlists>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-AcmeCpanlists>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
