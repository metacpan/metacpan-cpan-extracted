package App::grep::email;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-02'; # DATE
our $DIST = 'App-grep-email'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use AppBase::Grep;
use Perinci::Sub::Util qw(gen_modified_sub);

our %SPEC;

gen_modified_sub(
    output_name => 'grep_email',
    base_name   => 'AppBase::Grep::grep',
    summary     => 'Print lines having email address(es) (optionally of certain criteria) in them',
    description => <<'_',

This is a grep-like utility that greps for emails of certain criteria.

_
    remove_args => [
        'regexps',
        'pattern',
        'dash_prefix_inverts',
        'all',
    ],
    add_args    => {
        min_emails => {
            schema => 'uint*',
            default => 1,
            tags => ['category:filtering'],
        },
        max_emails => {
            schema => 'int*',
            default => -1,
            tags => ['category:filtering'],
        },

        comment_contains => {
            schema => 'str*',
            tags => ['category:email-criteria'],
        },
        comment_not_contains => {
            schema => 'str*',
            tags => ['category:email-criteria'],
        },
        comment_matches => {
            schema => 're*',
            tags => ['category:email-criteria'],
        },

        address_contains => {
            schema => 'str*',
            tags => ['category:email-criteria'],
        },
        address_not_contains => {
            schema => 'str*',
            tags => ['category:email-criteria'],
        },
        address_matches => {
            schema => 're*',
            tags => ['category:email-criteria'],
        },

        host_contains => {
            schema => 'str*',
            tags => ['category:email-criteria'],
        },
        host_not_contains => {
            schema => 'str*',
            tags => ['category:email-criteria'],
        },
        host_matches => {
            schema => 're*',
            tags => ['category:email-criteria'],
        },

        user_contains => {
            schema => 'str*',
            tags => ['category:email-criteria'],
        },
        user_not_contains => {
            schema => 'str*',
            tags => ['category:email-criteria'],
        },
        user_matches => {
            schema => 're*',
            tags => ['category:email-criteria'],
        },

        name_contains => {
            schema => 'str*',
            tags => ['category:email-criteria'],
        },
        name_not_contains => {
            schema => 'str*',
            tags => ['category:email-criteria'],
        },
        name_matches => {
            schema => 're*',
            tags => ['category:email-criteria'],
        },

        files => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'file',
            schema => ['array*', of=>'filename*'],
            pos => 0,
            slurpy => 1,
        },

        # XXX recursive (-r)
    },
    modify_meta => sub {
        my $meta = shift;
        $meta->{examples} = [
            {
                summary => 'Show lines that contain at least 2 emails',
                'src' => q([[prog]] --min-emails 2 file.txt),
                'src_plang' => 'bash',
                'test' => 0,
                'x.doc.show_result' => 0,
            },
            {
                summary => 'Show lines that contain emails from gmail',
                'src' => q([[prog]] --host-contains gmail.com file.txt),
                'src_plang' => 'bash',
                'test' => 0,
                'x.doc.show_result' => 0,
            },
        ];

        $meta->{links} = [
            {url=>'prog:grep-url'},
        ];
    },
    output_code => sub {
        my %args = @_;
        my ($fh, $file);

        my @files = @{ delete($args{files}) // [] };

        my $show_label = 0;
        if (!@files) {
            $fh = \*STDIN;
        } elsif (@files > 1) {
            $show_label = 1;
        }

        $args{_source} = sub {
          READ_LINE:
            {
                if (!defined $fh) {
                    return unless @files;
                    $file = shift @files;
                    log_trace "Opening $file ...";
                    open $fh, "<", $file or do {
                        warn "abgrep: Can't open '$file': $!, skipped\n";
                        undef $fh;
                    };
                    redo READ_LINE;
                }

                my $line = <$fh>;
                if (defined $line) {
                    return ($line, $show_label ? $file : undef);
                } else {
                    undef $fh;
                    redo READ_LINE;
                }
            }
        };

        require Regexp::Pattern::Email;
        require Email::Address;

        my $re = qr/(?:\b|\A)$Regexp::Pattern::Email::RE{email_address}{pat}(?:\b|\z)/;

        $args{_highlight_regexp} = $re;
        $args{_filter_code} = sub {
            my ($line, $fargs) = @_;

            my @emails;
            while ($line =~ /($re)/g) {
                push @emails, $1;
            }
            return 0 if $fargs->{min_emails} >= 0 && @emails < $fargs->{min_emails};
            return 0 if $fargs->{max_emails} >= 0 && @emails > $fargs->{max_emails};

            return 1 unless @emails;
            my @email_objs;
            for (@emails) { push @email_objs, Email::Address->parse($_) }

            my $match = 0;
          URL:
            for my $email (@email_objs) {

                # comment criteria
                if (defined $fargs->{comment_contains}) {
                    if ($fargs->{ignore_case} ?
                         index(lc($email->comment), lc($fargs->{comment_contains})) >= 0 :
                         index($email->comment    , $fargs->{comment_contains})     >= 0) {
                    } else {
                        next;
                    }
                }
                if (defined $fargs->{comment_not_contains}) {
                    if ($fargs->{ignore_case} ?
                         index(lc($email->comment), lc($fargs->{comment_not_contains})) < 0 :
                         index($email->comment    , $fargs->{comment_not_contains})     < 0) {
                    } else {
                        next;
                    }
                }
                if (defined $fargs->{comment_matches}) {
                    if ($fargs->{ignore_case} ?
                            $email->comment =~ qr/$fargs->{comment_matches}/i :
                            $email->comment =~ qr/$fargs->{comment_matches}/) {
                    } else {
                        next;
                    }
                }

                # address criteria
                if (defined $fargs->{address_contains}) {
                    if ($fargs->{ignore_case} ?
                         index(lc($email->address), lc($fargs->{address_contains})) >= 0 :
                         index($email->address    , $fargs->{address_contains})     >= 0) {
                    } else {
                        next;
                    }
                }
                if (defined $fargs->{address_not_contains}) {
                    if ($fargs->{ignore_case} ?
                         index(lc($email->address), lc($fargs->{address_not_contains})) < 0 :
                         index($email->address    , $fargs->{address_not_contains})     < 0) {
                    } else {
                        next;
                    }
                }
                if (defined $fargs->{address_matches}) {
                    if ($fargs->{ignore_case} ?
                            $email->address =~ qr/$fargs->{address_matches}/i :
                            $email->address =~ qr/$fargs->{address_matches}/) {
                    } else {
                        next;
                    }
                }

                # host criteria
                if (defined $fargs->{host_contains}) {
                    if ($fargs->{ignore_case} ?
                         index(lc($email->host), lc($fargs->{host_contains})) >= 0 :
                         index($email->host    , $fargs->{host_contains})     >= 0) {
                    } else {
                        next;
                    }
                }
                if (defined $fargs->{host_not_contains}) {
                    if ($fargs->{ignore_case} ?
                         index(lc($email->host), lc($fargs->{host_not_contains})) < 0 :
                         index($email->host    , $fargs->{host_not_contains})     < 0) {
                    } else {
                        next;
                    }
                }
                if (defined $fargs->{host_matches}) {
                    if ($fargs->{ignore_case} ?
                            $email->host =~ qr/$fargs->{host_matches}/i :
                            $email->host =~ qr/$fargs->{host_matches}/) {
                    } else {
                        next;
                    }
                }

                # user criteria
                if (defined $fargs->{user_contains}) {
                    if ($fargs->{ignore_case} ?
                         index(lc($email->user), lc($fargs->{user_contains})) >= 0 :
                         index($email->user    , $fargs->{user_contains})     >= 0) {
                    } else {
                        next;
                    }
                }
                if (defined $fargs->{user_not_contains}) {
                    if ($fargs->{ignore_case} ?
                         index(lc($email->user), lc($fargs->{user_not_contains})) < 0 :
                         index($email->user    , $fargs->{user_not_contains})     < 0) {
                    } else {
                        next;
                    }
                }
                if (defined $fargs->{user_matches}) {
                    if ($fargs->{ignore_case} ?
                            $email->user =~ qr/$fargs->{user_matches}/i :
                            $email->user =~ qr/$fargs->{user_matches}/) {
                    } else {
                        next;
                    }
                }

                # name criteria
                if (defined $fargs->{name_contains}) {
                    if ($fargs->{ignore_case} ?
                         index(lc($email->name), lc($fargs->{name_contains})) >= 0 :
                         index($email->name    , $fargs->{name_contains})     >= 0) {
                    } else {
                        next;
                    }
                }
                if (defined $fargs->{name_not_contains}) {
                    if ($fargs->{ignore_case} ?
                         index(lc($email->name), lc($fargs->{name_not_contains})) < 0 :
                         index($email->name    , $fargs->{name_not_contains})     < 0) {
                    } else {
                        next;
                    }
                }
                if (defined $fargs->{name_matches}) {
                    if ($fargs->{ignore_case} ?
                            $email->name =~ qr/$fargs->{name_matches}/i :
                            $email->name =~ qr/$fargs->{name_matches}/) {
                    } else {
                        next;
                    }
                }

                $match++; last;
            }
            $match;
        };

        AppBase::Grep::grep(%args);
    },
);

1;
# ABSTRACT: Print lines having email address(es) (optionally of certain criteria) in them

__END__

=pod

=encoding UTF-8

=head1 NAME

App::grep::email - Print lines having email address(es) (optionally of certain criteria) in them

=head1 VERSION

This document describes version 0.001 of App::grep::email (from Perl distribution App-grep-email), released on 2021-08-02.

=head1 FUNCTIONS


=head2 grep_email

Usage:

 grep_email(%args) -> [$status_code, $reason, $payload, \%result_meta]

Print lines having email address(es) (optionally of certain criteria) in them.

This is a grep-like utility that greps for emails of certain criteria.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<address_contains> => I<str>

=item * B<address_matches> => I<re>

=item * B<address_not_contains> => I<str>

=item * B<color> => I<str> (default: "auto")

=item * B<comment_contains> => I<str>

=item * B<comment_matches> => I<re>

=item * B<comment_not_contains> => I<str>

=item * B<count> => I<true>

Supress normal output, return a count of matching lines.

=item * B<files> => I<array[filename]>

=item * B<host_contains> => I<str>

=item * B<host_matches> => I<re>

=item * B<host_not_contains> => I<str>

=item * B<ignore_case> => I<bool>

=item * B<invert_match> => I<bool>

Invert the sense of matching.

=item * B<line_number> => I<true>

=item * B<max_emails> => I<int> (default: -1)

=item * B<min_emails> => I<uint> (default: 1)

=item * B<name_contains> => I<str>

=item * B<name_matches> => I<re>

=item * B<name_not_contains> => I<str>

=item * B<quiet> => I<true>

=item * B<user_contains> => I<str>

=item * B<user_matches> => I<re>

=item * B<user_not_contains> => I<str>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-grep-email>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-grep-email>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-grep-email>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
