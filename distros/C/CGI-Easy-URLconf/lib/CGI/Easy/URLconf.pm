package CGI::Easy::URLconf;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v2.0.0';

use Export::Attrs;
use URI::Escape qw( uri_escape_utf8 );


my %PATH2VIEW;
my %VIEW2PATH;


sub setup_path :Export {
    my (@data) = @_;
    my $method = ref $data[0] || $data[0] =~ m{\A/}xms ? q{} : shift @data;
    for (my $i = 0; $i <= $#data; $i++) {
        my $match = $data[$i];
        if (ref $match) {
            croak "expect SCALAR or Regexp at parameter $i" if ref $match ne 'Regexp';
        } else {
            croak "path at parameter $i must begin with /"  if $match !~ m{\A/}xms;
        }
        croak 'not enough params'               if $i == $#data;
        my @code = ($data[++$i]);
        croak "expect CODE at parameter $i"     if ref $code[0] ne 'CODE';
        while (ref $data[$i+1] eq 'CODE') {
            push @code, $data[++$i];
        }
        my $view = pop @code;
        push @{ $PATH2VIEW{$method} }, {
            match   => $match,
            view    => $view,
            prepare => \@code,
        };
    }
    return;
}

sub path2view :Export {
    my ($r) = @_;
    my $path = $r->{path};
    my $view;
    my $for_method = $PATH2VIEW{ $r->{ENV}{REQUEST_METHOD} } || [];
    my $for_any    = $PATH2VIEW{ q{}                       } || [];
    for my $path2view (@{$for_method}, @{$for_any}) {
        my @match;
        my $match = $path2view->{match};
        if (!ref $match) {
            next if $path ne $match;
        } else {
            next if $path !~ /$match/xms;
            for my $i (0 .. $#-) {
                if (defined $-[$i]) {
                    push @match, substr $path, $-[$i], $+[$i] - $-[$i];
                }
                else {
                    push @match, undef;
                }
            }
        }
        for my $prepare (@{ $path2view->{prepare} }) {
            $prepare->($r, \@match);
        }
        return $path2view->{view};
    }
    return;
}

sub set_param :Export {
    my (@names) = @_;
    return sub {
        my ($r, $values) = @_;
        for my $i (0 .. $#names) {
            if (defined $values->[$i+1]) {
                if (ref $r->{GET}{ $names[$i] }) {
                    $r->{GET}{ $names[$i] } = [ $values->[$i+1] ];
                } else {
                    $r->{GET}{ $names[$i] } = $values->[$i+1];
                }
            }
            else {
                delete $r->{GET}{ $names[$i] };
            }
        }
        return;
    };
}

###

sub setup_view :Export {
    my (@data) = @_;
    for (my $i = 0; $i <= $#data; $i++) {
        my $view = $data[$i];
        croak "expect CODE at parameter $i"         if ref $view ne 'CODE';
        croak "already exists CODE at parameter $i" if exists $VIEW2PATH{$view};
        croak 'not enough params'                   if $i == $#data;
        my $path = $data[++$i];
        croak "expect SCALAR or ARRAY at parameter $i"  if ref $path && ref $path ne 'ARRAY';
        croak "expect even elements in parameter $i"    if ref $path && @{$path} % 2;
        $VIEW2PATH{$view} = $path;
    }
    return;
}

sub view2path :Export {
    my ($view, %p) = @_;
    my $path = $VIEW2PATH{$view};
    if (!defined $path) {
        my @path = grep { $_->{view} eq $view } map { @{$_} } values %PATH2VIEW;
        if (@path == 1 && !ref $path[0]{match}) {
            $path = $path[0]{match};
        }
    }
    croak 'unknown CODE, use setup_view first'  if !defined $path;
    if (ref $path) {
        my @try = @{$path};
        $path = undef;
        while (@try) {
            my $try = shift @try;
            my $tmpl= shift @try;
            my $values = $try->(\%p) or next;
            if (@{$values} != ($tmpl =~ tr/?//)) {
                croak "incorrect values amount for template '$tmpl'";
            }
            # WARNING apache doesn't allow %2F in path (nginx allow)
            for (@{$values}) {
                $_ = uri_escape_utf8($_);
                s/%2F/\//msg;
            }
            $tmpl =~ s/[?]/shift @{$values}/xmsge;
            $path = $tmpl;
            last;
        }
        croak 'these parameters do not match configured urls' if !defined $path;
    }
    my @params;
    for my $n (keys %p) {
        my @v = ref $p{$n} ? @{ $p{$n} } : $p{$n};
        for my $v (@v) {
            push @params, uri_escape_utf8($n).q{=}.uri_escape_utf8($v);
        }
    }
    if (@params) {
        $path .= q{?} . join q{&}, @params;
    }
    return $path;
}

sub with_params :Export {
    my (@names) = @_;
    return sub {
        my ($p) = @_;
        my @values;
        for my $name (@names) {
            return if !defined $p->{ $name };
            push @values, $p->{ $name };
        }
        for (@names) {
            delete $p->{$_};
        }
        return \@values;
    };
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

CGI::Easy::URLconf - map url path to handler sub and vice versa


=head1 VERSION

This document describes CGI::Easy::URLconf version v2.0.0


=head1 SYNOPSIS

    use CGI::Easy::URLconf qw( setup_path path2view set_param );

    setup_path(
        '/about/'               => \&myabout,
        '/terms.php'            => \&terms,
        qr{\A /articles/ \z}xms => \&list_all_articles,
    );
    setup_path(
        qr{\A /articles/(\d+)/ \z}xms
            => set_param('year')
            => \&list_articles,
        qr{\A /articles/tag/(\w+)/(\d+)/ \z}xms
            => set_param('tag','year')
            => \&list_articles,
    );
    setup_path( POST =>
        '/articles/'            => \&add_article,
    );

    my $r = CGI::Easy::Request->new();
    my $handler = path2view($r);


    use CGI::Easy::URLconf qw( setup_view view2path with_params );

    setup_view(
        \&list_all_articles     => '/articles/',
        \&list_articles         => [
            with_params('tag','year')   => '/articles/tag/?/?/',
            with_params('year')         => '/articles/?/',
        ],
    );

    # set $url to '/about/'
    my $url = view2path( \&myabout );

    # set $url to '/articles/'
    my $url = view2path( \&list_all_articles );

    # set $url to '/articles/2010/?month=12'
    my $url = view2path( \&list_articles, year=>2010, month=>12 );


=head1 DESCRIPTION

This module provide support for clean, user-friendly URLs. This can be
archived by configuring web server to run your CGI/FastCGI script for any
url requested by user, and let you manually dispatch different urls to
corresponding handlers (subroutines). Additionally, you can take some
CGI parameters from url's path instead of usual GET parameters.

 The idea is to set rules when CGI/FastCGI starts using:
   a) setup_path() - to map url's path to handler subroutine
      (also called "view")
   b) setup_view() - to map handler subroutine to url
 and then use:
   a) path2view() - to get handler subroutine matching current url's path
   b) view2path() - to get url matching some handler subroutine
      (for inserting into HTML templates or sending redirects).

Example:

    # -- while CGI/FastCGI initialization
    setup_path(
        '/articles/'        => \&list_articles,
        '/articles.php'     => \&list_articles,
        '/index.php'        => \&show_home_page,
    );
    setup_path( POST =>
        '/articles/'        => \&add_new_article,
    );

    # -- when beginning to handle new CGI/FastCGI request
    my $r = CGI::Easy::Request->new();
    my $handler = path2view($r);
    # $handler now set to:
    #   \&list_articles   if url path /articles/ and request method is GET
    #   \&add_new_article if url path /articles/ and request method is POST
    #   \&list_articles   if url path /articles.php (any request method)
    #   \&show_home_page  if url path /index.php (any request method)
    #   undef             (in all other cases)

    # -- while CGI/FastCGI initialization
    setup_view(
        \&list_articles     => '/articles/',
        # we don't have to configure mapping for \&show_home_page
        # and \&add_new_article because their mappings can be
        # unambiguously automatically detected from above setup_path()
    );

    # -- when preparing reply (HTML escaping omitted for simplicity)
    printf '<a href="%s">Articles</a>', view2path(\&list_articles);
    printf '<form method=POST action="%s">', view2path(\&add_new_article);
    # -- or redirecting to another url
    my $h = CGI::Easy::Headers->new();
    $h->redirect(view2path(\&show_home_page));

These two parts (setup_path() with path2view() and setup_view() with view2path())
can be used independently - for example, you don't have to use
setup_view() and view2path() if you prefer to hardcode urls in HTML templates
instead of generating them dynamically. But using both parts will let you
configure I<all> urls used in your application in single place, which make
it easier to control and modify them.

In addition to simple constant path to handler and vice versa mapping you
can also map any path matching regular expression and even copy some data
from path to GET parameters. Example:

    # make /article/123/ same as /index.php?id=123
    # use same handler for any url beginning with /old/
    setup_path(
        '/article.php'          => \&show_article,
        qr{^/article/(\d+)/$}   => set_param('id') => \&show_article,
        qr{^/old/}              => \&unsupported,
    );

    # generate urls like /article/123/ dynamically
    setup_view(
        \&show_article          => [
            with_params('id')       => '/article/?/',
        ],
    );
    $url = view2path(\&show_article, id=>123);


=head1 INTERFACE 

=over

=item setup_path( [METHOD =>] MATCH => [CALLBACK => ...] HANDLER, ... )

Configure mapping of url's path to handler subroutine (which will be used
by path2view()).
Can be called multiple times and will just B<add> new mapping rules on each call.

If optional METHOD parameter defined, then all mapping rules in this
setup_path() call will be applied only for requests with that HTTP method.
If METHOD doesn't used, then these rules will be applied to all HTTP methods.
If some path match both rules defined for current HTTP method and rules
defined for any HTTP methods, will be used rule defined for current HTTP
method.

MATCH parameter should be either SCALAR (string equal to url path) or
Regexp (which can match any part of url path).

HANDLER is REF to your subroutine, which will be returned by path2view()
when this rule will match current url.

Between MATCH and HANDLER any amount of optional CALLBACK subroutines can
be used. These CALLBACKs will be called when MATCH rule matches current
url with two parameters: CGI::Easy::Request object and ARRAYREF with
contents of all capturing parentheses (when MATCH rule is Regexp with
capturing parentheses). Usual task for such CALLBACKs is convert "hidden"
CGI parameters included in url path into usual C<< $r->{GET} >> parameters.

Return nothing.


=item path2view( $r )

Take CGI::Easy::Request object as parameter, and analyse this request
according to rules defined previously using setup_path().

Return: HANDLER if find rule which match current request, else undef().


=item set_param( @names )

Take names of C<< {GET} >> parameters which should be set using parts of
url path selected by capturing parentheses in MATCH Regexp.

Return CALLBACK subroutine suitable for using in setup_path().


=item setup_view( HANDLER => PATH, ... )

Configure mapping of handler subroutine to url path (which will be used by
view2path()).
Can be called multiple times and will just B<add> new mapping rules on each call.

HANDLER must be REF to user's subroutine used to handle requests on PATH.

PATH can be either STRING or ARRAYREF.

If PATH is ARRAYREF, then this array should consist of CALLBACK =>
TEMPLATE pairs. CALLBACK is subroutine which will be executed by
view2path() with single parameter C<< \%params >>, and should return
either FALSE if this CALLBACK unable to handle these %params, or ARRAYREF
with values to substitute into path TEMPLATE. TEMPLATE is path STRING
which may contain '?' symbols - these will be replaced by values returned
in ARRAYREF by CALLBACK which successfully handle %params.

Example: map \&handler to /first/ or /second/ with 50% probability

    setup_view(
        \&handler   => [
            sub { return rand < 0.5 ? [] : undef }  => '/first/',
            sub { return []                      }  => '/second/',
        ],
    );

Example: map \&handler to random article with id 0-999

    setup_view(
        \&handler   => [
            sub { return [ int rand 1000 ] }    => '/article/?/',
        ],
    );

Return nothing.


=item view2path( HANDLER, %params )

Take user handler subroutine and it parameters, and convert it to url
according to rules defined previously using setup_view().

Example:

    setup_view(
        \&handler   => 'index.php',
    );
    my $url = view2path(\&handler, a=>'some string', b=>[6,7]);
    # $url will be: 'index.php?a=some%20string&b=6&b=7'

If simple mapping from STRING to HANDLER was defined using setup_path(),
and this is only mapping to HANDLER defined, then it's not necessary to
define reverse mapping using setup_view() - it will be defined
automatically.

Example:

    setup_path(
        '/articles/'    => \&list_articles,
    );
    my $url = view2path(\&list_articles);
    # $url will be: '/articles/'

Return: url. Throw exception if unable to make url.


=item with_params( @names )

Take names of parameters which B<must> exists in %params given to
view2path().

Return CALLBACK subroutine suitable for using in setup_view().


=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-CGI-Easy-URLconf/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-CGI-Easy-URLconf>

    git clone https://github.com/powerman/perl-CGI-Easy-URLconf.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=CGI-Easy-URLconf>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/CGI-Easy-URLconf>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Easy-URLconf>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=CGI-Easy-URLconf>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/CGI-Easy-URLconf>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009-2010 by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
