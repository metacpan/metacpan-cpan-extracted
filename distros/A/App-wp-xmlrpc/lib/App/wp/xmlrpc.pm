package App::wp::xmlrpc;

our $DATE = '2017-04-24'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

my %args_common = (
    proxy => {
        schema => 'str*',
        req => 1,
        tags => ['common'],
    },
    blog_id => {
        schema => 'posint*',
        default => 1,
        tags => ['common'],
    },
    username => {
        schema => 'str*',
        req => 1,
        cmdline_aliases => {u=>{}},
        tags => ['common'],
    },
    password => {
        schema => 'str*',
        req => 1,
        cmdline_aliases => {p=>{}},
        tags => ['common'],
    },
);

# for each non-common arg, if the arg's value starts with '[' or '{' then it
# will be assumed to be JSON and will be JSON-decoded.
sub _convert_args_to_struct {
    require JSON::MaybeXS;

    my $args = shift;
    for my $k (keys %$args) {
        next if $args_common{$k};
        next unless $args->{$k} =~ /\A(?:\[|\{)/;
        eval { $args->{$k} = JSON::MaybeXS::decode_json($args->{$k}) };
        die "Invalid JSON in '$k' argument: $@\n" if $@;
    }
}

sub _api {
    require XMLRPC::Lite;

    my ($args, $method, $argnames) = @_;

    my @xmlrpc_args = (
        $method,
        $args->{blog_id},
        $args->{username},
        $args->{password},
        grep {defined} map { $args->{$_} } @$argnames,
    );

    my $call = XMLRPC::Lite->proxy($args->{proxy})->call(@xmlrpc_args);
    my $fault = $call->fault;
    if ($fault && $fault->{faultCode}) {
        return [$fault->{faultCode}, $fault->{faultString}];
    }
    [200, "OK", $call->result, {'cmdline.default_format'=>'json-pretty'}];
}

our %API_Methods = (
    # Posts
    'wp.getPost' => {
        args => [
            ['post_id*', {schema=>'posint*'}],
            ['fields',   {schema=>'str*'}],
        ],
    },
    'wp.getPosts' => {
        args => [
            ['filter',   {schema=>'str*'}],
        ],
    },
    'wp.newPost' => {
        args => [
            ['content*', {schema=>'str*'}],
        ],
    },
    'wp.editPost' => {
        args => [
            ['content*', {schema=>'str*'}],
        ],
    },
    'wp.deletePost' => {
        args => [
            ['post_id*', {schema=>'posint*'}],
        ],
    },
    'wp.getPostType' => {
        args => [
            ['post_type_name*', {schema=>'str*'}],
            ['fields', {schema=>'str*'}],
        ],
    },
    'wp.getPostTypes' => {
        args => [
            ['filter', {schema=>'str*'}],
            ['fields', {schema=>'str*'}],
        ],
    },
    'wp.getPostFormats' => {
        args => [
            ['filter', {schema=>'str*'}],
        ],
    },
    'wp.getPostStatusList' => {
        args => [
        ],
    },

    # Taxonomies
    'wp.getTaxonomy' => {
        args => [
            ['taxonomy*', {schema=>'str*'}],
        ],
    },
    'wp.getTaxonomies' => {
        args => [
        ],
    },
    'wp.getTerm' => {
        args => [
            ['taxonomy*', {schema=>'str*'}],
            ['term_id*', {schema=>'posint*'}],
        ],
    },
    'wp.getTerms' => {
        args => [
            ['taxonomy*', {schema=>'str*'}],
        ],
    },
    'wp.newTerm' => {
        args => [
            ['content*', {schema=>'str*'}],
        ],
    },
    'wp.editTerm' => {
        args => [
            ['term_id*', {schema=>'posint*'}],
            ['content*', {schema=>'str*'}],
        ],
    },
    'wp.deleteTerm' => {
        args => [
            ['term_id*', {schema=>'posint*'}],
        ],
    },

    # Media
    'wp.getMediaItem' => {
        args => [
            ['attachment_id*', {schema=>'posint*'}],
        ],
    },
    'wp.getMediaLibrary' => {
        args => [
            ['filter', {schema=>'str*'}],
        ],
    },
    # TODO: wp.uploadFile

    # Comments
    'wp.getCommentCount' => {
        args => [
            ['post_id*', {schema=>'posint*'}],
        ],
    },
    'wp.getComment' => {
        args => [
            ['comment_id*', {schema=>'posint*'}],
        ],
    },
    'wp.getComments' => {
        args => [
            ['filter', {schema=>'str*'}],
        ],
    },
    'wp.newComment' => {
        args => [
            ['post_id*', {schema=>'posint*'}],
            ['comment*', {schema=>'str*'}],
        ],
    },
    'wp.editComment' => {
        args => [
            ['comment_id*', {schema=>'posint*'}],
            ['comment*', {schema=>'str*'}],
        ],
    },
    'wp.deleteComment' => {
        args => [
            ['comment_id*', {schema=>'posint*'}],
        ],
    },
    'wp.getCommentStatusList' => {
        args => [
        ],
    },

    # Options
    'wp.getOptions' => {
        args => [
            ['options', {schema=>'str*'}],
        ],
    },
    'wp.setOptions' => {
        args => [
            ['options*', {schema=>'str*'}],
        ],
    },

    # Users
    'wp.getUsersBlogs' => {
        args => [
            ['xmlrpc*', {schema=>'str*'}],
            ['isAdmin*', {schema=>'bool*'}],
        ],
    },
    'wp.getUser' => {
        args => [
            ['user_id*', {schema=>'posint*'}],
            ['fields', {schema=>'str*'}],
        ],
    },
    'wp.getUsers' => {
        args => [
            ['fields', {schema=>'str*'}],
        ],
    },
    'wp.getProfile' => {
        args => [
            ['fields', {schema=>'str*'}],
        ],
    },
    'wp.editProfile' => {
        args => [
            ['content*', {schema=>'str*'}],
        ],
    },
    'wp.getAuthors' => {
        args => [
        ],
    },
);

GENERATE_API_FUNCTIONS: {
    no strict 'refs';
    for my $meth (sort keys %API_Methods) {
        my $apispec = $API_Methods{$meth};
        (my $funcname = $meth) =~ s/\W+/_/g;
        my $argnames = [];
        my $meta = {
            v => 1.1,
            args => {
                %args_common,
            },
        };
        my $pos = -1;
        for my $argspec (@{ $apispec->{args} }) {
            $pos++;
            my $argname = $argspec->[0];
            my $req = $argname =~ s/\*$// ? 1:0;
            push @$argnames, $argname;
            $meta->{args}{$argname} = {
                %{ $argspec->[1] },
                req => $req,
                pos => $pos,
            };
        }
        $meta->{examples} = $apispec->{examples} if $apispec->{examples};
        *{$funcname} = sub {
            my %args = @_;
            _convert_args_to_struct(\%args);
            _api(\%args, $meth, $argnames);
        };
        $SPEC{$funcname} = $meta;
    } # for $meth
} # GENERATE_API_FUNCTIONS

1;
# ABSTRACT: A thin layer of CLI over WordPress XML-RPC API

__END__

=pod

=encoding UTF-8

=head1 NAME

App::wp::xmlrpc - A thin layer of CLI over WordPress XML-RPC API

=head1 VERSION

This document describes version 0.003 of App::wp::xmlrpc (from Perl distribution App-wp-xmlrpc), released on 2017-04-24.

=head1 SYNOPSIS

This module is meant to be used only via the included CLI script L<wp-xmlrpc>.
If you want to make XML-RPC calls to a WordPress website, you can use
L<XMLRCCP::Lite> directly, e.g. to delete a comment with ID 13:

 use XMLRPC::Lite;
 my $call = XMLRPC::Lite->proxy("http://example.org/yourblog")->call(
     "wp.deleteComment", # method
     1, # blog ID, usually just set to 1
     "username",
     "password",
     13,
 );
 my $fault = $call->fault;
 if ($fault && $fault->{faultCode}) {
     die "Can't delete comment: $fault->{faultCode} - $fault->{faultString}";
 }

To find the list of available methods and arguments, see the WordPress API
reference (see L</"SEE ALSO">).

=head1 FUNCTIONS


=head2 wp_deleteComment

Usage:

 wp_deleteComment(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<comment_id>* => I<posint>

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_deletePost

Usage:

 wp_deletePost(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<password>* => I<str>

=item * B<post_id>* => I<posint>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_deleteTerm

Usage:

 wp_deleteTerm(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<term_id>* => I<posint>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_editComment

Usage:

 wp_editComment(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<comment>* => I<str>

=item * B<comment_id>* => I<posint>

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_editPost

Usage:

 wp_editPost(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<content>* => I<str>

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_editProfile

Usage:

 wp_editProfile(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<content>* => I<str>

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_editTerm

Usage:

 wp_editTerm(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<content>* => I<str>

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<term_id>* => I<posint>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_getAuthors

Usage:

 wp_getAuthors(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_getComment

Usage:

 wp_getComment(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<comment_id>* => I<posint>

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_getCommentCount

Usage:

 wp_getCommentCount(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<password>* => I<str>

=item * B<post_id>* => I<posint>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_getCommentStatusList

Usage:

 wp_getCommentStatusList(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_getComments

Usage:

 wp_getComments(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<filter> => I<str>

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_getMediaItem

Usage:

 wp_getMediaItem(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<attachment_id>* => I<posint>

=item * B<blog_id> => I<posint> (default: 1)

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_getMediaLibrary

Usage:

 wp_getMediaLibrary(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<filter> => I<str>

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_getOptions

Usage:

 wp_getOptions(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<options> => I<str>

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_getPost

Usage:

 wp_getPost(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<fields> => I<str>

=item * B<password>* => I<str>

=item * B<post_id>* => I<posint>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_getPostFormats

Usage:

 wp_getPostFormats(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<filter> => I<str>

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_getPostStatusList

Usage:

 wp_getPostStatusList(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_getPostType

Usage:

 wp_getPostType(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<fields> => I<str>

=item * B<password>* => I<str>

=item * B<post_type_name>* => I<str>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_getPostTypes

Usage:

 wp_getPostTypes(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<fields> => I<str>

=item * B<filter> => I<str>

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_getPosts

Usage:

 wp_getPosts(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<filter> => I<str>

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_getProfile

Usage:

 wp_getProfile(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<fields> => I<str>

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_getTaxonomies

Usage:

 wp_getTaxonomies(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_getTaxonomy

Usage:

 wp_getTaxonomy(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<taxonomy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_getTerm

Usage:

 wp_getTerm(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<taxonomy>* => I<str>

=item * B<term_id>* => I<posint>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_getTerms

Usage:

 wp_getTerms(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<taxonomy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_getUser

Usage:

 wp_getUser(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<fields> => I<str>

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<user_id>* => I<posint>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_getUsers

Usage:

 wp_getUsers(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<fields> => I<str>

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_getUsersBlogs

Usage:

 wp_getUsersBlogs(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<isAdmin>* => I<bool>

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=item * B<xmlrpc>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_newComment

Usage:

 wp_newComment(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<comment>* => I<str>

=item * B<password>* => I<str>

=item * B<post_id>* => I<posint>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_newPost

Usage:

 wp_newPost(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<content>* => I<str>

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_newTerm

Usage:

 wp_newTerm(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<content>* => I<str>

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 wp_setOptions

Usage:

 wp_setOptions(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blog_id> => I<posint> (default: 1)

=item * B<options>* => I<str>

=item * B<password>* => I<str>

=item * B<proxy>* => I<str>

=item * B<username>* => I<str>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-wp-xmlrpc>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-wp-xmlrpc>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-wp-xmlrpc>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

API reference: L<https://codex.wordpress.org/XML-RPC_WordPress_API>

Other WordPress API modules on CPAN: L<WordPress::XMLRPC> by Leo Charre (a thin
wrapper over L<XMLRPC::Lite>), L<WordPress::API> by Leo Charre (an OO wrapper
over WordPress::XMLRPC, but at time of this writing the module has not been
updated since 2008/WordPress 2.7 era), L<WP::API> by Dave Rolsky (OO interface,
incomplete).

Other WordPress API CLI on CPAN: L<wordpress-info>, L<wordpress-upload-media>,
L<wordpress-upload-post> (from L<WordPress::CLI> distribution, also by Leo
Charre).

L<XMLRPC::Lite>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
